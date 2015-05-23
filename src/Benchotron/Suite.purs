
module Benchotron.Suite
  ( runSuite
  ) where

import Benchotron.Core

runSuite :: forall e. Array (Benchmark e) -> BenchM e Unit
runSuite bs = return unit
