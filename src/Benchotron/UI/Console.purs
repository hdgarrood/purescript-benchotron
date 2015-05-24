
module Benchotron.UI.Console where

import Data.Tuple
import Data.Maybe
import Data.Foldable (traverse_)
import Data.Profunctor.Strong (second, (&&&))
import qualified Data.Array as A
import Data.String (joinWith)
import Data.Date (now, Now())
import Data.Date.Locale (toLocaleTimeString, Locale())
import Control.Monad (when)
import Control.Monad.Eff
import Node.FS.Sync (writeTextFile, mkdir, stat, exists)
import Node.FS.Stats (isDirectory)
import Node.Encoding (Encoding(..))
import Global (readInt, isNaN)

import Benchotron.Core
import Benchotron.StdIO
import Benchotron.Utils

data Answer = All | One Number

parseAnswer :: String -> Maybe Answer
parseAnswer "*" = Just All
parseAnswer x = let y = readInt 10 x
                in  if isNaN y then Nothing else Just (One y)

runSuite :: forall e. Array (Benchmark e) -> BenchM e Unit
runSuite bs = do
  case bs of
    []  -> stdoutWrite "Empty suite; nothing to do.\n"
    [b] -> go b
    _   -> do
      stdoutWrite "Choose a benchmark to run:\n\n"
      stdoutWrite (joinWith "\n" (showOptions bs))
      stdoutWrite "\n\n"
      questionLoop

  where
  go b = do
    stdoutWrite "\n"
    exists <- doesDirectoryExist "tmp"
    when (not exists) (mkdir "tmp")
    benchmarkToFile b ("tmp/" <> slug b <> ".json")

  doesDirectoryExist dir = do
    ex <- exists dir
    if ex
       then isDirectory <$> stat dir
       else return false

  slug = unpackBenchmark _.slug

  questionLoop =
    question "Enter a number, or enter '*' to run all benchmarks: " \answer ->
      case parseAnswer answer of
        Nothing -> stdoutWrite "Unrecognised input.\n" >> questionLoop
        Just All -> traverse_ go bs
        Just (One i) ->
          case bs A.!! (i - 1) of
            Just b  -> go b
            Nothing -> stdoutWrite "No such benchmark.\n" >> questionLoop

showOptions :: forall e. Array (Benchmark e) -> Array String
showOptions = A.map (showOption <<< second getSlugAndTitle) <<< withIndices
  where
  getSlugAndTitle =
    unpackBenchmark _.slug &&& unpackBenchmark _.title
  showOption (Tuple index (Tuple slug title)) =
    "  " <> show index <> ") " <> slug <> " - " <> title
  withIndices arr =
    zip (A.range 1 (A.length arr)) arr

runBenchmarkConsole :: forall e. Benchmark e -> BenchM e BenchmarkResult
runBenchmarkConsole = unpackBenchmark runBenchmarkFConsole

runBenchmarkFConsole :: forall e a. BenchmarkF e a -> BenchM e BenchmarkResult
runBenchmarkFConsole benchmark = do
  stderrWrite $ "### Benchmark: " <> benchmark.title <> " ###\n"
  noteTime \t -> "Started at: " <> t <> "\n"
  r <- runBenchmarkF benchmark progress
  stderrWrite "\n"
  noteTime \t -> "Finished at: " <> t <> "\n"
  return r
  where
  noteTime f = now >>= toLocaleTimeString >>= (stderrWrite <<< f)
  countSizes = A.length benchmark.sizes
  clearLine = "\r\ESC[K"
  progress idx size =
    stderrWrite $ joinWith ""
      [ clearLine
      , "Running... n="
      , show size
      , " ("
      , show idx
      , "/"
      , show countSizes
      , ")"
      ]

-- | Run a benchmark and print the results to a file. This will only work on
-- | node.js.
benchmarkToFile :: forall e. Benchmark e -> String -> Eff (BenchEffects e) Unit
benchmarkToFile = unpackBenchmark benchmarkFToFile

benchmarkFToFile :: forall e a. BenchmarkF e a -> String -> Eff (BenchEffects e) Unit
benchmarkFToFile bench path = do
  results <- runBenchmarkFConsole bench
  writeTextFile UTF8 path $ stringifyResult results
  stderrWrite $ "Results written to " <> path <> "\n"

-- | Run a benchmark and print the results to standard output. This will only
-- | work on node.js.
benchmarkToStdout :: forall e. Benchmark e -> Eff (BenchEffects e) Unit
benchmarkToStdout = unpackBenchmark benchmarkFToStdout

benchmarkFToStdout :: forall e a. BenchmarkF e a -> Eff (BenchEffects e) Unit
benchmarkFToStdout bench = do
  results <- runBenchmarkFConsole bench
  stdoutWrite $ stringifyResult results

stringifyResult :: BenchmarkResult -> String
stringifyResult = jsonStringify
