
module Benchotron.Utils where

import Prelude
import Data.Identity
import Data.Exists

type Any = Exists Identity

toAny :: forall a. a -> Any
toAny = mkExists <<< Identity

foreign import unsafeJsonStringify ::
  forall a. a -> String

bindConst :: forall m a b. (Bind m) => m a -> m b -> m b
bindConst x y = x >>= const y

infixl 4 bindConst as >>
