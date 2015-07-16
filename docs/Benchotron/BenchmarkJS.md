## Module Benchotron.BenchmarkJS

#### `BenchmarkJS`

``` purescript
data BenchmarkJS :: *
```

#### `BENCHMARK`

``` purescript
data BENCHMARK :: !
```

#### `Stats`

``` purescript
type Stats = { deviation :: Number, mean :: Number, moe :: Number, rme :: Number, sample :: Array Number, sem :: Number, variance :: Number }
```

#### `benchmarkJS`

``` purescript
benchmarkJS :: BenchmarkJS
```

#### `monkeyPatchBenchmark`

``` purescript
monkeyPatchBenchmark :: forall e. BenchmarkJS -> Eff (benchmark :: BENCHMARK | e) Unit
```

This is (unfortunately) necessary to stop Benchmark from trying to decompile
your functions to Strings, and then using 'eval' in the tests. I'm not quite
sure why it does this, but it breaks things, due to imported modules no
longer being in scope :(

Here, we monkey-patch the Benchmark object to fool the library into thinking
function decompilation is not supported, which should hopefully stop this
from happening.

#### `runBenchmarkImpl`

``` purescript
runBenchmarkImpl :: forall e. BenchmarkJS -> (Unit -> Any) -> Eff (benchmark :: BENCHMARK | e) Stats
```


