
module Benchotron.StdIO
  ( stderrWrite
  , stdoutWrite
  , question
  ) where

import Prelude
import Data.String as S
import Effect (Effect)
import Node.ReadLine (Interface, prompt, setPrompt, close,
                      setLineHandler, noCompletion, createConsoleInterface)

foreign import stdoutWrite :: String -> Effect Unit

foreign import stderrWrite :: String -> Effect Unit

question ::
  String ->
  (String ->
   Effect Unit) ->
  Effect Unit
question q callback = do
  i <- createConsoleInterface noCompletion
  setLineHandler i (\s -> close i >>= const (callback s))
  setPrompt q (S.length q) i
  prompt i
  pure unit

foreign import closeInterface ::
  Interface -> Effect Unit
