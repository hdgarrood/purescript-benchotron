
module Benchotron.Utils where

import Data.Identity
import Data.Exists

type Any = Exists Identity

toAny :: forall a. a -> Any
toAny = mkExists <<< Identity

foreign import unsafeJsonStringify ::
  forall a. a -> String

(>>) :: forall m a b. (Bind m) => m a -> m b -> m b
(>>) x y = x >>= const y
