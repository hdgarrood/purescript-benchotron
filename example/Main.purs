module Main where

import Prelude
import Data.Array
import Data.Foldable
import Data.Monoid.Additive
import Data.Monoid.Multiplicative
import Control.Monad.Eff
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Gen (vectorOf)
import Benchotron.Core
import Benchotron.UI.Console

benchSum :: Benchmark
benchSum = mkBenchmark
  { slug: "sum"
  , title: "Finding the sum of an array"
  , sizes: (1..5) <#> (*1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: \n -> vectorOf n arbitrary
  , functions: [ benchFn "foldr" (foldr (+) 0)
               , benchFn "foldMap" (runAdditive <<< foldMap Additive)
               ]
  }

benchProduct :: Benchmark
benchProduct = mkBenchmark
  { slug: "product"
  , title: "Finding the product of an array"
  , sizes: (1..5) <#> (*1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: \n -> vectorOf n arbitrary
  , functions: [ benchFn "foldr" (foldr (*) 0)
               , benchFn "foldMap" (runMultiplicative <<< foldMap Multiplicative)
               ]
  }

main = runSuite [benchSum, benchProduct]
