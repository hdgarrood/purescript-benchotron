
module Benchotron.UI.Console where

import Prelude
import Data.Tuple (Tuple(..))
import Data.Maybe (Maybe(..))
import Data.Foldable (traverse_)
import Data.Profunctor.Strong (second, (&&&))
import Data.Array as A
import Data.Int as Int
import Data.String (joinWith)
import Data.JSDate as JSD
import Data.DateTime.Instant as DDI
import Test.QuickCheck (randomSeed)
import Test.QuickCheck.Gen (GenState)
import Random.LCG (unSeed)
import Control.Monad.Trans.Class (lift)
import Control.Monad.State.Class (get)
import Effect (Effect)
import Effect.Now (now)
import Node.FS.Sync (writeTextFile, mkdir, stat, exists)
import Node.FS.Stats (isDirectory)
import Node.Encoding (Encoding(..))

import Benchotron.Core (BenchmarkResult, Benchmark, BenchM,
                        runBenchM, runBenchmark, unpackBenchmark)
import Benchotron.StdIO (stdoutWrite, stderrWrite, question)
import Benchotron.Utils (unsafeJsonStringify)

data Answer = All | One Int

parseAnswer :: String -> Maybe Answer
parseAnswer "*" = Just All
parseAnswer x = let y = Int.fromString x
                in  map One y

-- | TODO: Only fetch one seed from global random generator, have this return
-- | BenchM instead?
runSuite :: Array Benchmark -> Effect Unit
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
       else pure false

  slug = unpackBenchmark _.slug

  questionLoop =
    question "Enter a number, or enter '*' to run all benchmarks: " \answer ->
      case parseAnswer answer of
        Nothing -> stdoutWrite "Unrecognised input.\n" *> questionLoop
        Just All -> traverse_ go bs
        Just (One i) ->
          case bs A.!! (i - 1) of
            Just b  -> go b
            Nothing -> stdoutWrite "No such benchmark.\n" *> questionLoop

showOptions :: Array Benchmark -> Array String
showOptions = map (showOption <<< second getSlugAndTitle) <<< withIndices
  where
  getSlugAndTitle =
    unpackBenchmark _.slug &&& unpackBenchmark _.title
  showOption (Tuple index (Tuple slug title)) =
    "  " <> show index <> ") " <> slug <> " - " <> title
  withIndices arr =
    A.zip (A.range 1 (A.length arr)) arr

runBenchmarkConsole :: Benchmark -> BenchM BenchmarkResult
runBenchmarkConsole benchmark = do
  state <- get
  let seed = unSeed state.newSeed :: Int
  lift $ do
    stderrWrite $ "### Benchmark: " <> unpackBenchmark _.title benchmark <> " ###\n"
    stderrWrite $ "Using seed: " <> show seed <> "\n"
    noteTime \t -> "Started at: " <> t <> "\n"
  r <- runBenchmark benchmark progress
  lift $ do
    stderrWrite "\n"
    noteTime \t -> "Finished at: " <> t <> "\n"
  pure r
  where
  noteTime f = nowString >>= (stderrWrite <<< f)
  nowString = (JSD.toTimeString<<<JSD.fromDateTime<<<DDI.toDateTime) <$> now
  countSizes = A.length $ unpackBenchmark _.sizes benchmark
  clearLine = "\r\x1b[K"
  progress idx size =
    lift $ stderrWrite $ joinWith ""
      [ clearLine
      , "Running... n="
      , show size
      , " ("
      , show idx
      , "/"
      , show countSizes
      , ")"
      ]

getInitialState :: Effect GenState
getInitialState = { newSeed: _, size: 10 } <$> randomSeed

runBenchM' :: forall a. BenchM a -> Effect a
runBenchM' action =
  getInitialState >>= runBenchM action

-- | Run a benchmark and print the results to a file. This will only work on
-- | node.js.
benchmarkToFile :: Benchmark -> String -> Effect Unit
benchmarkToFile bench path = do
  results <- runBenchM' $ runBenchmarkConsole bench
  writeTextFile UTF8 path $ stringifyResult results
  stderrWrite $ "Results written to " <> path <> "\n"

-- | Run a benchmark and print the results to standard output. This will only
-- | work on node.js.
benchmarkToStdout :: Benchmark -> Effect Unit
benchmarkToStdout bench = do
  results <- runBenchM' $ runBenchmarkConsole bench
  stdoutWrite $ stringifyResult results

stringifyResult :: BenchmarkResult -> String
stringifyResult = unsafeJsonStringify
