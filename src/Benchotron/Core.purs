
module Benchotron.Core
  ( Benchmark()
  , BenchmarkF()
  , BenchmarkFunction()
  , mkBenchmark
  , unpackBenchmark
  , benchFn
  , benchFn'
  , runBenchmark
  , runBenchmarkF
  , BenchM()
  , BenchEffects()
  , BenchmarkResult()
  , ResultSeries()
  , DataPoint()
  ) where

import Data.Exists
import Data.Identity
import Data.Tuple
import Data.Array (map, filter, (..), length)
import Data.Array.Unsafe (head)
import Data.String (joinWith)
import Data.Traversable (for)
import Data.Date (Now())
import Data.Date.Locale (Locale())
import Control.Apply ((<*))
import Control.Monad (replicateM)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (Exception(), Error(), catchException,
                                    throwException, message, error)
import Node.FS (FS())
import Node.ReadLine (Console())
import Debug.Trace (Trace())

import Benchotron.StdIO
import Benchotron.BenchmarkJS
import Benchotron.Utils

-- | A value representing a benchmark to be performed. The type parameter 'e'
-- | is provided to allow you to supply a random value generator with arbitrary
-- | effects, if you need to. The type parameter 'a' is the type of the input
-- | to each of the competing functions in the benchmark.
-- |
-- | **Attributes**
-- |
-- | * `slug`: An identifier for the benchmark. Used for filenames.
-- | * `title`: The title of the benchmark.
-- | * `sizes`: An array of numbers representing each input size you would like
-- |   your benchmark to be run with. The interpretation of 'size' depends on
-- |   the specific case; if the input is an array, for example, the size would
-- |   usually be the number of elements in the array.
-- | * `sizeInterpretation`: A `String` with a human-readable description of
-- |   how the size is meant to be interpreted in this specific case.
-- | * `inputsPerSize`: The number of inputs to be generated for each each
-- |   input size. Often it's acceptable to set this to 1. By using higher
-- |   values, you can have more confidence in your results; however, your
-- |   benchmarks will also take much longer to run.
-- | * `gen`: An Eff action which should produce a random input of the given
-- |   argument size when executed.
-- | * `functions`: An array of competing functions to be benchmarked.
type BenchmarkF e a =
  { slug               :: String
  , title              :: String
  , sizes              :: Array Number
  , sizeInterpretation :: String
  , inputsPerSize      :: Number
  , gen                :: Number -> Eff (BenchEffects e) a
  , functions          :: Array (BenchmarkFunction a)
  }

-- This is only necessary because psc doesn't support partially applied type
-- synonyms.
newtype BenchmarkFF e a = BenchmarkFF (BenchmarkF e a)

newtype Benchmark e = Benchmark (Exists (BenchmarkFF e))

mkBenchmark :: forall e a. BenchmarkF e a -> Benchmark e
mkBenchmark = Benchmark <<< mkExists <<< BenchmarkFF

unpackBenchmark :: forall e r. (forall a. BenchmarkF e a -> r) -> Benchmark e -> r
unpackBenchmark f (Benchmark b) = runExists f' b
  where
  f' :: forall a. BenchmarkFF e a -> r
  f' (BenchmarkFF b') = f b'

newtype BenchmarkFunction a = BenchmarkFunction (Exists (BenchmarkFunctionF a))

newtype BenchmarkFunctionF a b = BenchmarkFunctionF
  { name :: String
  , fn :: b -> Any
  , before :: a -> b
  }

-- | Create a `BenchmarkFunction`, given a name and a function to be
-- | benchmarked.
benchFn :: forall a r. String -> (a -> r) -> BenchmarkFunction a
benchFn name fn = benchFn' name fn id

-- | Create a `BenchmarkFunction`. Like `benchFn`, except that it accepts a
-- | third argument which will be used to preprocess the input, before starting
-- | the benchmark. This is useful if you want to compare two functions which
-- | have different argument types.
benchFn' :: forall a b r. String -> (b -> r) -> (a -> b) -> BenchmarkFunction a
benchFn' name fn before =
  BenchmarkFunction $ mkExists $ BenchmarkFunctionF
    { name: name, fn: toAny <<< fn, before: before }

getName :: forall a. BenchmarkFunction a -> String
getName (BenchmarkFunction f) = runExists go f
  where
  go :: forall b. BenchmarkFunctionF a b -> String
  go (BenchmarkFunctionF o) = o.name

type BenchM e a = Eff (BenchEffects e) a

runBenchmark :: forall e.
  Benchmark e ->
  -- ^ The Benchmark to be run.
  (Number -> Number -> BenchM e Unit) ->
  -- ^ Callback for when the size changes; the arguments are current size index
  --   (1-based) , and the current size.
  BenchM e BenchmarkResult
runBenchmark = unpackBenchmark runBenchmarkF

runBenchmarkF :: forall e a.
  BenchmarkF e a ->
  -- ^ The Benchmark to be run.
  (Number -> Number -> BenchM e Unit) ->
  -- ^ Callback for when the size changes; the arguments are current size index
  --   (1-based) , and the current size.
  BenchM e BenchmarkResult
runBenchmarkF benchmark onChange = do
  results <- for (withIndices benchmark.sizes) $ \(Tuple idx size) -> do
    onChange idx size
    inputs   <- replicateM benchmark.inputsPerSize (benchmark.gen size)
    allStats <- for benchmark.functions $ \function -> do
                  let name = getName function
                  handleBenchmarkException name size $ do
                    stats <- runBenchmarkFunction inputs function
                    return { name: name, stats: stats }

    return { size: size, allStats: allStats }

  let series = rejig results
  return
    { slug: benchmark.slug
    , title: benchmark.title
    , sizeInterpretation: benchmark.sizeInterpretation
    , series: series
    }

  where
  withIndices arr = zip (1..(length arr)) arr

-- TODO: use purescript-exceptions instead. This appears to be blocked on:
--    https://github.com/purescript/purescript-exceptions/issues/5
foreign import handleBenchmarkException
  """
  function handleBenchmarkException(name) {
    return function(size) {
      return function(innerAction) {
        return function() {
          try {
            return innerAction()
          } catch(innerError) {
            throw new Error(
              'While running Benchotron benchmark function: ' + name + ' ' +
                'at n=' + String(size) + ':\n' +
                innerError.name + ': ' + innerError.message)
          }
        }
      }
    }
  }
  """ :: forall e a. String -> Number -> Eff (BenchEffects e) a -> Eff (BenchEffects e) a

runBenchmarkFunction :: forall e a. Array a -> BenchmarkFunction a -> Eff (BenchEffects e) Stats
runBenchmarkFunction inputs (BenchmarkFunction function') =
  runExists go function'
  where
  go :: forall b. BenchmarkFunctionF a b -> Eff (BenchEffects e) Stats
  go (BenchmarkFunctionF function) =
    let inputs' = map function.before inputs
        f = \_ -> toAny $ map function.fn inputs'
    in do
      monkeyPatchBenchmark benchmarkJS
      runBenchmarkImpl benchmarkJS f

type BenchEffects e
  = ( err       :: Exception
    , fs        :: FS
    , now       :: Now
    , locale    :: Locale
    , trace     :: Trace
    , console   :: Console
    , benchmark :: BENCHMARK
    | e
    )

type BenchmarkResult =
  { slug               :: String
  , title              :: String
  , sizeInterpretation :: String
  , series             :: Array ResultSeries
  }

type ResultSeries =
  { name    :: String
  , results :: Array DataPoint
  }

type DataPoint =
  { size  :: Number
  , stats :: Stats
  }

type IntermediateResult =
  Array { size :: Number, allStats :: Array { name :: String, stats :: Stats } }

rejig :: IntermediateResult -> Array ResultSeries
rejig [] = []
rejig results = map toSeries names
  where
  r = head results
  names = map _.name r.allStats
  toSeries name =
    { name: name
    , results: map (\o -> { size: o.size
                          , stats: _.stats $ the $ filter ((==) name <<< _.name) o.allStats
                          }) results
    }
  the [x] = x

