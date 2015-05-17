# Module Documentation

## Module Benchotron

#### `Benchmark`

``` purescript
type Benchmark e a = { functions :: Array (BenchmarkFunction a), gen :: Number -> Eff (BenchEffects e) a, inputsPerSize :: Number, sizeInterpretation :: String, sizes :: Array Number, title :: String }
```

A value representing a benchmark to be performed. The type parameter 'e'
is provided to allow you to supply a random value generator with arbitrary
effects, if you need to. The type parameter 'a' is the type of the input
to each of the competing functions in the benchmark.

**Attributes**

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
* `functions`: An array of competing functions to be benchmarked. The
  return type is `Any` just so that it typechecks; this module exports a
  function `toAny :: forall a. a -> Any` which you can use here.

#### `BenchmarkFunction`

``` purescript
newtype BenchmarkFunction a
```


#### `benchFn`

``` purescript
benchFn :: forall a r. String -> (a -> r) -> BenchmarkFunction a
```


#### `benchFn'`

``` purescript
benchFn' :: forall a b r. String -> (b -> r) -> (a -> b) -> BenchmarkFunction a
```


#### `runBenchmark`

``` purescript
runBenchmark :: forall e a. Benchmark e a -> Eff (BenchEffects e) BenchmarkResult
```


#### `benchmarkToFile`

``` purescript
benchmarkToFile :: forall e a. Benchmark e a -> String -> Eff (BenchEffects e) Unit
```


#### `benchmarkToStdout`

``` purescript
benchmarkToStdout :: forall e a. Benchmark e a -> Eff (BenchEffects e) Unit
```


#### `BenchEffects`

``` purescript
type BenchEffects e = (fs :: FS, err :: Exception | e)
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


#### `Stats`

``` purescript
type Stats = { variance :: Number, sem :: Number, sample :: Array Number, rme :: Number, moe :: Number, mean :: Number, deviation :: Number }
```


#### `Any`

``` purescript
type Any = Exists Identity
```


#### `toAny`

``` purescript
toAny :: forall a. a -> Any
```




