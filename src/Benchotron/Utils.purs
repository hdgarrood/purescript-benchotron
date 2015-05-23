
module Benchotron.Utils where

import Data.Identity
import Data.Exists

type Any = Exists Identity

toAny :: forall a. a -> Any
toAny = mkExists <<< Identity

foreign import jsonStringify
  """
  function jsonStringify(obj) {
    return JSON.stringify(obj)
  }
  """ :: forall a. a -> String

(>>) :: forall m a b. (Bind m) => m a -> m b -> m b
(>>) x y = x >>= const y
