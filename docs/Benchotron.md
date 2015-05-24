# Module Documentation

## Module Benchotron.Core

#### `BenchmarkF`

``` purescript
type BenchmarkF e a = { functions :: Array (BenchmarkFunction a), gen :: Number -> Eff (BenchEffects e) a, inputsPerSize :: Number, sizeInterpretation :: String, sizes :: Array Number, title :: String, slug :: String }
```

A value representing a benchmark to be performed. The type parameter 'e'
is provided to allow you to supply a random value generator with arbitrary
effects, if you need to. The type parameter 'a' is the type of the input
to each of the competing functions in the benchmark.

**Attributes**

* `slug`: An identifier for the benchmark. Used for filenames.
* `title`: The title of the benchmark.
* `sizes`: An array of numbers representing each input size you would like
  your benchmark to be run with. The interpretation of 'size' depends on
  the specific case; if the input is an array, for example, the size would
  usually be the number of elements in the array.
* `sizeInterpretation`: A `String` with a human-readable description of
  how the size is meant to be interpreted in this specific case.
* `inputsPerSize`: The number of inputs to be generated for each each
  input size. Often it's acceptable to set this to 1. By using higher
  values, you can have more confidence in your results; however, your
  benchmarks will also take much longer to run.
* `gen`: An Eff action which should produce a random input of the given
  argument size when executed.
* `functions`: An array of competing functions to be benchmarked.

#### `Benchmark`

``` purescript
newtype Benchmark e
```


#### `mkBenchmark`

``` purescript
mkBenchmark :: forall e a. BenchmarkF e a -> Benchmark e
```


#### `unpackBenchmark`

``` purescript
unpackBenchmark :: forall e r. (forall a. BenchmarkF e a -> r) -> Benchmark e -> r
```


#### `BenchmarkFunction`

``` purescript
newtype BenchmarkFunction a
```


#### `benchFn`

``` purescript
benchFn :: forall a r. String -> (a -> r) -> BenchmarkFunction a
```

Create a `BenchmarkFunction`, given a name and a function to be
benchmarked.

#### `benchFn'`

``` purescript
benchFn' :: forall a b r. String -> (b -> r) -> (a -> b) -> BenchmarkFunction a
```

Create a `BenchmarkFunction`. Like `benchFn`, except that it accepts a
third argument which will be used to preprocess the input, before starting
the benchmark. This is useful if you want to compare two functions which
have different argument types.

#### `BenchM`

``` purescript
type BenchM e a = Eff (BenchEffects e) a
```


#### `runBenchmark`

``` purescript
runBenchmark :: forall e. Benchmark e -> (Number -> Number -> BenchM e Unit) -> BenchM e BenchmarkResult
```


#### `runBenchmarkF`

``` purescript
runBenchmarkF :: forall e a. BenchmarkF e a -> (Number -> Number -> BenchM e Unit) -> BenchM e BenchmarkResult
```


#### `BenchEffects`

``` purescript
type BenchEffects e = (benchmark :: BENCHMARK, console :: Console, trace :: Trace, locale :: Locale, now :: Now, fs :: FS, err :: Exception | e)
```


#### `BenchmarkResult`

``` purescript
type BenchmarkResult = { series :: Array ResultSeries, sizeInterpretation :: String, title :: String }
```


#### `ResultSeries`

``` purescript
type ResultSeries = { results :: Array DataPoint, name :: String }
```


#### `DataPoint`

``` purescript
type DataPoint = { stats :: Stats, size :: Number }
```



## Module Benchotron.UI.Console

#### `Answer`

``` purescript
data Answer
  = All 
  | One Number
```


#### `parseAnswer`

``` purescript
parseAnswer :: String -> Maybe Answer
```


#### `runSuite`

``` purescript
runSuite :: forall e. Array (Benchmark e) -> BenchM e Unit
```


#### `showOptions`

``` purescript
showOptions :: forall e. Array (Benchmark e) -> Array String
```


#### `runBenchmarkConsole`

``` purescript
runBenchmarkConsole :: forall e. Benchmark e -> BenchM e BenchmarkResult
```


#### `runBenchmarkFConsole`

``` purescript
runBenchmarkFConsole :: forall e a. BenchmarkF e a -> BenchM e BenchmarkResult
```


#### `benchmarkToFile`

``` purescript
benchmarkToFile :: forall e. Benchmark e -> String -> Eff (BenchEffects e) Unit
```

Run a benchmark and print the results to a file. This will only work on
node.js.

#### `benchmarkFToFile`

``` purescript
benchmarkFToFile :: forall e a. BenchmarkF e a -> String -> Eff (BenchEffects e) Unit
```


#### `benchmarkToStdout`

``` purescript
benchmarkToStdout :: forall e. Benchmark e -> Eff (BenchEffects e) Unit
```

Run a benchmark and print the results to standard output. This will only
work on node.js.

#### `benchmarkFToStdout`

``` purescript
benchmarkFToStdout :: forall e a. BenchmarkF e a -> Eff (BenchEffects e) Unit
```


#### `stringifyResult`

``` purescript
stringifyResult :: BenchmarkResult -> String
```




