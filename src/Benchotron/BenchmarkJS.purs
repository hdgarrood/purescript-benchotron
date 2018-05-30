
module Benchotron.BenchmarkJS where

import Prelude
import Effect (Effect)
import Benchotron.Utils (Any)

foreign import data BenchmarkJS :: Type

type Stats =
  { deviation :: Number
  , mean      :: Number
  , moe       :: Number
  , rme       :: Number
  , sample    :: Array Number
  , sem       :: Number
  , variance  :: Number
  }

foreign import benchmarkJS  :: BenchmarkJS

-- | This is (unfortunately) necessary to stop Benchmark from trying to decompile
-- | your functions to Strings, and then using 'eval' in the tests. I'm not quite
-- | sure why it does this, but it breaks things, due to imported modules no
-- | longer being in scope :(
-- |
-- | Here, we monkey-patch the Benchmark object to fool the library into thinking
-- | function decompilation is not supported, which should hopefully stop this
-- | from happening.
foreign import monkeyPatchBenchmark ::
  BenchmarkJS -> Effect Unit

foreign import runBenchmarkImpl ::
  BenchmarkJS -> (Unit -> Any) -> Effect Stats
