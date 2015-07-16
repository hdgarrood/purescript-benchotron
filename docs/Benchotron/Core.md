## Module Benchotron.Core

#### `BenchmarkF`

``` purescript
type BenchmarkF a = { slug :: String, title :: String, sizes :: Array Int, sizeInterpretation :: String, inputsPerSize :: Int, gen :: Int -> Gen a, functions :: Array (BenchmarkFunction a) }
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
newtype Benchmark
```

#### `mkBenchmark`

``` purescript
mkBenchmark :: forall a. BenchmarkF a -> Benchmark
```

#### `unpackBenchmark`

``` purescript
unpackBenchmark :: forall r. (forall a. BenchmarkF a -> r) -> Benchmark -> r
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
type BenchM e a = StateT GenState (Eff (BenchEffects e)) a
```

#### `runBenchM`

``` purescript
runBenchM :: forall e a. BenchM e a -> GenState -> Eff (BenchEffects e) a
```

#### `runBenchmark`

``` purescript
runBenchmark :: forall e. Benchmark -> (Int -> Int -> BenchM e Unit) -> BenchM e BenchmarkResult
```

#### `runBenchmarkF`

``` purescript
runBenchmarkF :: forall e a. BenchmarkF a -> (Int -> Int -> BenchM e Unit) -> BenchM e BenchmarkResult
```

#### `BenchEffects`

``` purescript
type BenchEffects e = (err :: EXCEPTION, fs :: FS, now :: Now, locale :: Locale, console :: CONSOLE, random :: RANDOM, benchmark :: BENCHMARK | e)
```

#### `BenchmarkResult`

``` purescript
type BenchmarkResult = { slug :: String, title :: String, sizeInterpretation :: String, series :: Array ResultSeries }
```

#### `ResultSeries`

``` purescript
type ResultSeries = { name :: String, results :: Array DataPoint }
```

#### `DataPoint`

``` purescript
type DataPoint = { size :: Int, stats :: Stats }
```


