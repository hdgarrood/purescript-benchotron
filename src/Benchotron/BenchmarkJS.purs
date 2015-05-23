
module Benchotron.BenchmarkJS where

import Control.Monad.Eff
import Benchotron.Utils

foreign import data BenchmarkJS :: *
foreign import data BENCHMARK :: !

type Stats =
  { deviation :: Number
  , mean      :: Number
  , moe       :: Number
  , rme       :: Number
  , sample    :: Array Number
  , sem       :: Number
  , variance  :: Number
  }

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
  """ :: forall e. BenchmarkJS -> Eff (benchmark :: BENCHMARK | e) Unit

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
  """ :: forall e. BenchmarkJS -> (Unit -> Any) -> Eff (benchmark :: BENCHMARK | e) Stats
