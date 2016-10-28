## Module Benchotron.UI.Console

#### `Answer`

``` purescript
data Answer
  = All
  | One Int
```

#### `parseAnswer`

``` purescript
parseAnswer :: String -> Maybe Answer
```

#### `runSuite`

``` purescript
runSuite :: forall e. Array Benchmark -> Eff (BenchEffects e) Unit
```

TODO: Only fetch one seed from global random generator, have this return
BenchM instead?

#### `showOptions`

``` purescript
showOptions :: Array Benchmark -> Array String
```

#### `runBenchmarkConsole`

``` purescript
runBenchmarkConsole :: forall e. Benchmark -> BenchM e BenchmarkResult
```

#### `getInitialState`

``` purescript
getInitialState :: forall e. Eff (random :: RANDOM | e) GenState
```

#### `runBenchM'`

``` purescript
runBenchM' :: forall e a. BenchM e a -> Eff (BenchEffects e) a
```

#### `benchmarkToFile`

``` purescript
benchmarkToFile :: forall e. Benchmark -> String -> Eff (BenchEffects e) Unit
```

Run a benchmark and print the results to a file. This will only work on
node.js.

#### `benchmarkToStdout`

``` purescript
benchmarkToStdout :: forall e. Benchmark -> Eff (BenchEffects e) Unit
```

Run a benchmark and print the results to standard output. This will only
work on node.js.

#### `stringifyResult`

``` purescript
stringifyResult :: BenchmarkResult -> String
```


