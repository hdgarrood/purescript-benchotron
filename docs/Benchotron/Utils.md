## Module Benchotron.Utils

#### `Any`

``` purescript
type Any = Exists Identity
```

#### `toAny`

``` purescript
toAny :: forall a. a -> Any
```

#### `unsafeJsonStringify`

``` purescript
unsafeJsonStringify :: forall a. a -> String
```

#### `(>>)`

``` purescript
(>>) :: forall m a b. (Bind m) => m a -> m b -> m b
```

_left-associative / precedence -1_


