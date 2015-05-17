# Module Documentation

## Module Benchotron

#### `Benchmark`

``` purescript
type Benchmark e a = { functions :: Array { fn :: a -> Any, name :: String }, gen :: Number -> Eff (BenchEffects e) a, inputsPerSize :: Number, sizeInterpretation :: String, sizes :: Array Number, name :: String }
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
type BenchmarkResult = { series :: Array ResultSeries, sizeInterpretation :: String, name :: String }
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




