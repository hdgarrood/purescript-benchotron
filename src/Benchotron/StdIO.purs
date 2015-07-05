
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  , question
  ) where

import Prelude
import qualified Data.String as S
import Control.Monad.Eff.Console (CONSOLE())
import Control.Monad.Eff (Eff())
import Node.ReadLine

foreign import stdoutWrite ::
  forall e. String -> Eff (console :: CONSOLE | e) Unit

foreign import stderrWrite ::
  forall e. String -> Eff (console :: CONSOLE | e) Unit

question :: forall e.
  String ->
  (String -> Eff (console :: CONSOLE | e) Unit) ->
  Eff (console :: CONSOLE | e) Unit
question q callback = do
  i <- createInterface noCompletion
  setLineHandler (\s -> closeInterface i >>= const (callback s)) i
  setPrompt q (S.length q) i
  prompt i
  return unit

foreign import closeInterface ::
  forall e. Interface -> Eff (console :: CONSOLE | e) Unit
