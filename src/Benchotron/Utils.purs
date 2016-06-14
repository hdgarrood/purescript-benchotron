
module Benchotron.Utils where

import Prelude
import Data.Identity (Identity(..))
import Data.Exists (Exists, mkExists)

type Any = Exists Identity

toAny :: forall a. a -> Any
toAny = mkExists <<< Identity

foreign import unsafeJsonStringify ::
  forall a. a -> String

