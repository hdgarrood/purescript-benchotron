
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  ) where

import Debug.Trace (Trace())
import Control.Monad.Eff (Eff())

foreign import stdoutWrite
  """
  function stdoutWrite(str) {
    return function() {
      process.stdout.write(str)
    }
  } """ :: forall e. String -> Eff (trace :: Trace | e) Unit

foreign import stderrWrite
  """
  function stderrWrite(str) {
    return function() {
      process.stderr.write(str)
    }
  } """ :: forall e. String -> Eff (trace :: Trace | e) Unit
