
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  , question
  ) where

import qualified Data.String as S
import Debug.Trace (Trace())
import Control.Monad.Eff (Eff())
import Node.ReadLine

foreign import stdoutWrite ::
  forall e. String -> Eff (trace :: Trace | e) Unit

foreign import stderrWrite ::
  forall e. String -> Eff (trace :: Trace | e) Unit

question :: forall e.
  String ->
  (String -> Eff (console :: Console | e) Unit) ->
  Eff (console :: Console | e) Unit
question q callback = do
  i <- createInterface process.stdin process.stdout noCompletion
  setLineHandler (\s -> closeInterface i >>= const (callback s)) i
  setPrompt q (S.length q) i
  prompt i
  return unit

foreign import closeInterface ::
  forall e. Interface -> Eff (console :: Console | e) Unit
