
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  , question
  ) where

import Prelude
import Data.String as S
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Node.ReadLine (Interface, READLINE, prompt, setPrompt, close,
                      setLineHandler, noCompletion, createConsoleInterface)

foreign import stdoutWrite ::
  forall e. String -> Eff (console :: CONSOLE | e) Unit

foreign import stderrWrite ::
  forall e. String -> Eff (console :: CONSOLE | e) Unit

question :: forall e.
  String ->
  (String ->
   Eff (readline :: READLINE, console :: CONSOLE, err :: EXCEPTION | e) Unit) ->
  Eff (readline :: READLINE, console :: CONSOLE, err :: EXCEPTION | e) Unit
question q callback = do
  i <- createConsoleInterface noCompletion
  setLineHandler i (\s -> close i >>= const (callback s))
  setPrompt q (S.length q) i
  prompt i
  pure unit

foreign import closeInterface ::
  forall e. Interface -> Eff (console :: CONSOLE | e) Unit
