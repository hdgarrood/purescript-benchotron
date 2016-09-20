module Main where

import Prelude
import Benchotron.BenchmarkJS (BENCHMARK)
import Benchotron.Core (Benchmark, benchFn, mkBenchmark)
import Benchotron.UI.Console (runSuite)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Eff.Now (NOW)
import Control.Monad.Eff.Random (RANDOM)
import Data.Array ((..))
import Data.Foldable (foldMap, foldr)
import Data.Monoid.Additive (Additive(..), runAdditive)
import Data.Monoid.Multiplicative (Multiplicative(..), runMultiplicative)
import Node.FS (FS)
import Node.ReadLine (READLINE)
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Gen (vectorOf)

benchSum :: Benchmark
benchSum = mkBenchmark
  { slug: "sum"
  , title: "Finding the sum of an array"
  , sizes: (1..5) <#> (_ * 1000)
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
  , sizes: (1..5) <#> (_ * 1000)
  , sizeInterpretation: "Number of elements in the array"
  , inputsPerSize: 1
  , gen: \n -> vectorOf n arbitrary
  , functions: [ benchFn "foldr" (foldr (*) 0)
               , benchFn "foldMap" (runMultiplicative <<< foldMap Multiplicative)
               ]
  }

main :: forall e. Eff ( err :: EXCEPTION, fs :: FS, now :: NOW, console :: CONSOLE, random :: RANDOM, benchmark :: BENCHMARK, readline :: READLINE | e) Unit
main = runSuite [benchSum, benchProduct]
