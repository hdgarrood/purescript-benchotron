# purescript-benchotron

[![Build Status](https://travis-ci.org/hdgarrood/purescript-benchotron.svg?branch=master)](https://travis-ci.org/hdgarrood/purescript-benchotron)

Straightforward benchmarking via [Benchmark.js][]. I am sorry about the name
(purescript-benchmark was taken).

## usage

Suppose you want to find out which is faster out of `foldr (+) 0` and
`runAdditive <<< foldMap Additive`. Let's also do the same for `(*)` for good
measure. Start by creating some `Benchmark` values:

```purescript
module Main where

import Prelude
import Control.Monad.Eff (Eff)
import Data.Array ((..))
import Data.Foldable (foldMap, foldr)
import Data.Monoid.Additive (Additive(..))
import Data.Monoid.Multiplicative (Multiplicative(..))
import Data.Newtype (ala)
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Gen (vectorOf)
import Benchotron.Core (Benchmark, BenchEffects, benchFn, mkBenchmark)
import Benchotron.UI.Console (runSuite)

benchSum :: Benchmark
benchSum = mkBenchmark
  { slug: "sum"
  , title: "Finding the sum of an array"
  , sizes: (1..5) <#> (_ * 1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: \n -> vectorOf n arbitrary
  , functions: [ benchFn "foldr" (foldr (+) 0)
               , benchFn "foldMap" (ala Additive foldMap)
               ]
  }

benchProduct :: Benchmark
benchProduct = mkBenchmark
  { slug: "product"
  , title: "Finding the product of an array"
  , sizes: (1..5) <#> (_ * 1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: \n -> vectorOf n arbitrary
  , functions: [ benchFn "foldr" (foldr (*) 1)
               , benchFn "foldMap" (ala Multiplicative foldMap)
               ]
  }
main :: forall eff. Eff (BenchEffects eff) Unit
main = runSuite [benchSum, benchProduct]
```

Now, run them with `runSuite`; this will save the results data for each
benchmark to `tmp/sum.json` and `tmp/product.json` respectively.

```purescript
main = runSuite [benchSum, benchProduct]
```

You can now generate SVG graphs of these results by visiting
<http://harry.garrood.me/purescript-benchotron-svg-renderer>.

Further information, such as the meaning of each of the attributes of a
`Benchmark` value, is available in the [documentation](docs/).

[Benchmark.js]: http://benchmarkjs.com
