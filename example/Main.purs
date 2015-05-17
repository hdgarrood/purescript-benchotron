module Main where

import Data.Array
import Data.Foldable
import Data.Monoid.Additive
import Control.Monad.Eff
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

main = do
  benchmarkToFile benchSum "tmp/benchSum.json"
