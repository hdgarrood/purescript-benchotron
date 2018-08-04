module Main where

import Prelude
import Effect (Effect)
import Data.Array ((..))
import Data.Foldable (foldMap, foldr)
import Data.Monoid.Additive (Additive(..))
import Data.Monoid.Multiplicative (Multiplicative(..))
import Data.Newtype (ala)
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Gen (vectorOf)
import Benchotron.Core (Benchmark, benchFn, mkBenchmark)
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
main :: Effect Unit
main = runSuite [benchSum, benchProduct]
