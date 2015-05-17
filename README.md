# purescript-benchotron

Straightforward benchmarking via [Benchmark.js][]. I am sorry about the name
(purescript-benchmark was taken).

## usage

Suppose you want to find out which is faster out of `foldr (+) 0` and
`runAdditive <<< foldMap Additive`. Start by creating a `Benchmark`:

```purescript
import Data.Foldable
import Data.Monoid.Additive
import Benchotron

benchSum :: forall e. Benchmark e (Array Number)
benchSum =
  { title: "Finding the sum of an array"
  , sizes: (1..50) <#> (*1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: randomArray
  , functions: [ { name: "foldr",   fn: toAny <<< foldr (+) 0 }
               , { name: "foldMap", fn: toAny <<< runAdditive <<< foldMap Additive }
               ]
  }

foreign import randomArray """
  function randomArray(n) {
    return function() {
      var arr = []
      for (var i = 0; i < n; i++) {
        arr.push(Math.random())
      }
      return arr;
    }
  } """ :: forall e. Number -> Eff (BenchEffects e) (Array Number)
```

Then, run it and save the results as JSON to a file:

```purescript
main = do
  benchmarkToFile benchSum "tmp/benchSum.json"
```

You can now generate SVG graphs of these results by visiting
<http://harry.garrood.me/purescript-benchotron-svg-renderer>.

Further information, such as the meaning of each of the attributes of a
`Benchmark` value, is available in the [documentation](docs/Benchotron.md).

[Benchmark.js]: http://benchmarkjs.com
