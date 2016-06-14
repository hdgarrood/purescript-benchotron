
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
  , runBenchM
  , BenchEffects()
  , BenchmarkResult()
  , ResultSeries()
  , DataPoint()
  ) where

import Prelude
import Data.Exists (Exists, runExists, mkExists)
import Data.Tuple (Tuple(..), fst, snd)
import Data.Array (filter, (..), length, zip)
import Data.Array.Partial (head)
import Data.Traversable (for)
import Data.Unfoldable (replicateA)
import Control.Monad.State.Trans (StateT(), evalStateT)
import Control.Monad.State.Class (get, put)
import Control.Monad.Trans (lift)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (EXCEPTION())
import Control.Monad.Eff.Exception.Unsafe (unsafeThrow)
import Control.Monad.Eff.Now (NOW())
import Node.FS (FS())
import Node.ReadLine (READLINE)
import Control.Monad.Eff.Console (CONSOLE())
import Control.Monad.Eff.Random  (RANDOM())
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck.Gen (Gen(), GenState(), runGen)

import Benchotron.BenchmarkJS (Stats, BENCHMARK, benchmarkJS, runBenchmarkImpl, 
                               monkeyPatchBenchmark)
import Benchotron.Utils (Any, toAny)

-- | A value representing a benchmark to be performed. The type parameter is
-- | the type of the input to each of the competing functions in the benchmark.
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
-- | * `gen`: a QuickCheck generator, which should produce a random input of
-- |   the given argument size when executed.
-- | * `functions`: An array of competing functions to be benchmarked.
type BenchmarkF a =
  { slug               :: String
  , title              :: String
  , sizes              :: Array Int
  , sizeInterpretation :: String
  , inputsPerSize      :: Int
  , gen                :: Int -> Gen a
  , functions          :: Array (BenchmarkFunction a)
  }

-- This is only necessary because psc doesn't support partially applied type
-- synonyms.
newtype BenchmarkFF a = BenchmarkFF (BenchmarkF a)

newtype Benchmark = Benchmark (Exists (BenchmarkFF))

mkBenchmark :: forall a. BenchmarkF a -> Benchmark
mkBenchmark = Benchmark <<< mkExists <<< BenchmarkFF

unpackBenchmark :: forall r. (forall a. BenchmarkF a -> r) -> Benchmark -> r
unpackBenchmark f (Benchmark b) = runExists f' b
  where
  f' :: forall a. BenchmarkFF a -> r
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

type BenchM e a = StateT GenState (Eff (BenchEffects e)) a

runBenchM :: forall e a. BenchM e a -> GenState -> Eff (BenchEffects e) a
runBenchM = evalStateT

-- | Use the given generator to generate a random value, using (and modifying)
-- | the state of the BenchM computation.
stepGen :: forall e a. Gen a -> BenchM e a
stepGen gen = do
  st <- get
  let out = runGen gen st
  put $ snd out
  pure $ fst out

runBenchmark :: forall e.
  Benchmark ->
  -- ^ The Benchmark to be run.
  (Int -> Int -> BenchM e Unit) ->
  -- ^ Callback for when the size changes; the arguments are current size index
  --   (1-based) , and the current size.
  BenchM e BenchmarkResult
runBenchmark = unpackBenchmark runBenchmarkF

runBenchmarkF :: forall e a.
  BenchmarkF a ->
  -- ^ The Benchmark to be run.
  (Int -> Int -> BenchM e Unit) ->
  -- ^ Callback for when the size changes; the arguments are current size index
  --   (1-based) , and the current size.
  BenchM e BenchmarkResult
runBenchmarkF benchmark onChange = do
  results <- for (withIndices benchmark.sizes) $ \(Tuple idx size) -> do
    onChange idx size
    let getAnInput = stepGen $ benchmark.gen size
    inputs   <- replicateA benchmark.inputsPerSize getAnInput
    allStats <- for benchmark.functions $ \function -> do
                  let name = getName function
                  lift $
                    handleBenchmarkException name size $ do
                      stats <- runBenchmarkFunction inputs function
                      pure { name: name, stats: stats }

    pure { size: size, allStats: allStats }

  let series = rejig results
  pure
    { slug: benchmark.slug
    , title: benchmark.title
    , sizeInterpretation: benchmark.sizeInterpretation
    , series: series
    }

  where
  withIndices arr = zip (1..(length arr)) arr

-- TODO: use purescript-exceptions instead. This appears to be blocked on:
--    https://github.com/purescript/purescript-exceptions/issues/5
foreign import handleBenchmarkException ::
  forall e a. String -> Int -> Eff (BenchEffects e) a -> Eff (BenchEffects e) a

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
  = ( err       :: EXCEPTION
    , fs        :: FS
    , now       :: NOW
    , console   :: CONSOLE
    , random    :: RANDOM
    , benchmark :: BENCHMARK
    , readline  :: READLINE
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
  { size  :: Int
  , stats :: Stats
  }

type IntermediateResult =
  Array { size :: Int, allStats :: Array { name :: String, stats :: Stats } }

rejig :: IntermediateResult -> Array ResultSeries
rejig [] = []
rejig results = map toSeries names
  where
  r = unsafePartial $ head results
  names = map _.name r.allStats
  toSeries name =
    { name: name
    , results: map (\o -> { size: o.size
                          , stats: _.stats $ the $ filter ((==) name <<< _.name) o.allStats
                          }) results
    }
  the [x] = x
  the _ = unsafeThrow "Benchotron.Core.the: invalid input"
