## Module Benchotron.StdIO

#### `stdoutWrite`

``` purescript
stdoutWrite :: forall e. String -> Eff (console :: CONSOLE | e) Unit
```

#### `stderrWrite`

``` purescript
stderrWrite :: forall e. String -> Eff (console :: CONSOLE | e) Unit
```

#### `question`

``` purescript
question :: forall e. String -> (String -> Eff (console :: CONSOLE | e) Unit) -> Eff (console :: CONSOLE | e) Unit
```


