
module Benchotron
  ( Benchmark()
  , BenchmarkFunction()
  , benchFn
  , benchFn'
  , runBenchmark
  , benchmarkToFile
  , benchmarkToStdout
  , BenchEffects()
  , BenchmarkResult()
  , ResultSeries()
  , DataPoint()
  , Stats()
  ) where

import Data.Exists
import Data.Identity
import Data.Tuple
import Data.Array (map, filter, (..), length)
import Data.Array.Unsafe (head)
import Data.String (joinWith)
import Data.Traversable (for)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (Exception(), Error(), catchException,
                                    throwException, message, error)
import Node.FS (FS())
import Node.FS.Sync (writeTextFile)
import Node.Encoding (Encoding(..))

-- | A value representing a benchmark to be performed. The type parameter 'e'
-- | is provided to allow you to supply a random value generator with arbitrary
-- | effects, if you need to. The type parameter 'a' is the type of the input
-- | to each of the competing functions in the benchmark.
-- |
-- | **Attributes**
-- |
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
type Benchmark e a =
  { title              :: String
  , sizes              :: Array Number
  , sizeInterpretation :: String
  , inputsPerSize      :: Number
  , gen                :: Number -> Eff (BenchEffects e) a
  , functions          :: Array (BenchmarkFunction a)
  }

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

runBenchmark :: forall e a. Benchmark e a -> Eff (BenchEffects e) BenchmarkResult
runBenchmark benchmark = do
  let countSizes = length benchmark.sizes
  results <- for (withIndices benchmark.sizes) $ \(Tuple idx size) -> do
    stderrWrite $ joinWith "" [ "Benchmarking... n="
                              , show size
                              , " ("
                              , show idx
                              , "/"
                              , show countSizes
                              , ") \r"
                              ]

    inputs   <- for (1..benchmark.inputsPerSize) (const (benchmark.gen size))
    allStats <- for benchmark.functions $ \function -> do
                  let name = getName function
                  handleBenchmarkException name size $ do
                    stats <- runBenchmarkFunction inputs function
                    return { name: name, stats: stats }

    return { size: size, allStats: allStats }

  stderrWrite "\n"
  let series = rejig results
  return
    { title: benchmark.title
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

benchmarkToFile :: forall e a. Benchmark e a -> String -> Eff (BenchEffects e) Unit
benchmarkToFile bench path = do
  results <- runBenchmark bench
  writeTextFile UTF8 path $ jsonStringify results
  stderrWrite $ "Benchmark \""<> bench.title <> "\" results written to " <> path <> "\n"

benchmarkToStdout :: forall e a. Benchmark e a -> Eff (BenchEffects e) Unit
benchmarkToStdout bench = do
  results <- runBenchmark bench
  stdoutWrite $ jsonStringify results

type BenchEffects e
  = ( err :: Exception
    , fs :: FS
    | e
    )

type BenchmarkResult =
  { title              :: String
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

type Stats =
  { deviation :: Number
  , mean      :: Number
  , moe       :: Number
  , rme       :: Number
  , sample    :: Array Number
  , sem       :: Number
  , variance  :: Number
  }

type Any = Exists Identity

toAny :: forall a. a -> Any
toAny = mkExists <<< Identity

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

foreign import data BenchmarkJS :: *
foreign import benchmarkJS "var benchmarkJS = require('benchmark')" :: BenchmarkJS

-- this is (unfortunately) necessary to stop Benchmark from trying to decompile
-- your functions to Strings, and then using 'eval' in the tests. I'm not quite
-- sure why it does this, but it breaks things, due to imported modules no
-- longer being in scope :(
--
-- Here, we monkey-patch the Benchmark object to fool the library into thinking
-- function decompilation is not supported, which should hopefully stop this
-- from happening.
foreign import monkeyPatchBenchmark
  """
  function monkeyPatchBenchmark(b) {
    return function() {
      b.support.decompilation = false;
    }
  }
  """ :: forall e. BenchmarkJS -> Eff (BenchEffects e) Unit

foreign import runBenchmarkImpl
  """
  function runBenchmarkImpl(Benchmark) {
    return function(fn) {
      return function() {
        var b = new Benchmark(fn)
        b.run()
        if (typeof b.error !== 'undefined') {
           throw b.error
        }
        return b.stats
      }
    }
  }
  """ :: forall e. BenchmarkJS -> (Unit -> Any) -> Eff e Stats

foreign import jsonStringify
  """
  function jsonStringify(obj) {
    return JSON.stringify(obj)
  }
  """ :: BenchmarkResult -> String

foreign import stdoutWrite
  """
  function stdoutWrite(str) {
    return function() {
      process.stdout.write(str)
    }
  } """ :: forall e. String -> Eff (BenchEffects e) Unit

foreign import stderrWrite
  """
  function stderrWrite(str) {
    return function() {
      process.stderr.write(str)
    }
  } """ :: forall e. String -> Eff (BenchEffects e) Unit
