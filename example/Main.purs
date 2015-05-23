module Main where

import Data.Array
import Data.Foldable
import Data.Monoid.Additive
import Data.Monoid.Multiplicative
import Control.Monad.Eff
import Benchotron.Core
import Benchotron.UI.Console

benchSum :: forall e. Benchmark e
benchSum = mkBenchmark
  { slug: "sum"
  , title: "Finding the sum of an array"
  , sizes: (1..5) <#> (*1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: randomArray
  , functions: [ benchFn "foldr" (foldr (+) 0)
               , benchFn "foldMap" (runAdditive <<< foldMap Additive)
               ]
  }

benchProduct :: forall e. Benchmark e
benchProduct = mkBenchmark
  { slug: "product"
  , title: "Finding the product of an array"
  , sizes: (1..5) <#> (*1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: randomArray
  , functions: [ benchFn "foldr" (foldr (*) 0)
               , benchFn "foldMap" (runMultiplicative <<< foldMap Multiplicative)
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

main = runSuite [benchSum, benchProduct]
