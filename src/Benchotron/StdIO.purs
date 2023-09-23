
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  , question
  ) where

import Prelude
import Effect (Effect)
import Node.EventEmitter (on_)
import Node.ReadLine (Interface, prompt, setPrompt, close,
                      lineH, noCompletion, createConsoleInterface)

foreign import stdoutWrite :: String -> Effect Unit

foreign import stderrWrite :: String -> Effect Unit

question ::
  String ->
  (String ->
   Effect Unit) ->
  Effect Unit
question q callback = do
  i <- createConsoleInterface noCompletion
  setPrompt q i
  prompt i
  i # on_ lineH \s -> do
    close i
    callback s

foreign import closeInterface ::
  Interface -> Effect Unit
