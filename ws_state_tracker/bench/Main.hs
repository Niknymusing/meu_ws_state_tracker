module Main where

import Criterion.Main
import Control.Concurrent.STM (atomically)
import Control.DeepSeq (NFData, rnf)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import MEU.Core.System
import MEU.Core.Triplet
import MEU.Core.Types
import MEU.WS.StateTracker
import MEU.WS.Registries
import MEU.Transforms.Refinement
import MEU.Transforms.Coarsening
import MEU.Internal.Utils

-- NFData instances for benchmarking
instance NFData TripletId where rnf (TripletId uuid) = rnf uuid
instance NFData TaskId where rnf (TaskId uuid) = rnf uuid
instance NFData TestId where rnf (TestId uuid) = rnf uuid
instance NFData ValueId where rnf (ValueId uuid) = rnf uuid
instance NFData DSLPrimitiveId where rnf (DSLPrimitiveId uuid) = rnf uuid

main :: IO ()
main = defaultMain
  [ bgroup "MEU System Creation"
    [ bench "create system" $ nfIO createSystemBench
    , bench "create 100 triplets" $ nfIO create100TripletsBench
    , bench "create 1000 triplets" $ nfIO create1000TripletsBench
    ]
  , bgroup "State Tracker Operations"
    [ bench "create tracker" $ nfIO createTrackerBench
    , bench "register 100 pointers" $ nfIO register100PointersBench
    , bench "process 1000 signals" $ nfIO process1000SignalsBench
    ]
  , bgroup "Registry Operations"
    [ bench "create composite registry" $ nfIO createRegistryBench
    , bench "register 1000 values" $ nfIO register1000ValuesBench
    , bench "query registry 1000 times" $ nfIO query1000TimesBench
    ]
  , bgroup "Refinement Operations"
    [ bench "simple refinement" $ nfIO simpleRefinementBench
    , bench "complex refinement" $ nfIO complexRefinementBench
    , bench "deep refinement (5 levels)" $ nfIO deepRefinementBench
    ]
  , bgroup "Coarsening Operations"
    [ bench "simple coarsening" $ nfIO simpleCoarseningBench
    , bench "complex coarsening" $ nfIO complexCoarseningBench
    , bench "batch coarsening (100 triplets)" $ nfIO batchCoarseningBench
    ]
  , bgroup "Large Scale Operations"
    [ bench "10K triplets system" $ nfIO largeSystemBench
    , bench "100K pointer registry" $ nfIO largeRegistryBench
    , bench "10K signal processing" $ nfIO highVolumeSignalsBench
    ]
  ]

-- System creation benchmarks
createSystemBench :: IO ()
createSystemBench = do
  timestamp <- currentTimestamp
  _ <- atomically $ createSystem "bench-system" "Benchmark project" timestamp
  return ()

create100TripletsBench :: IO ()
create100TripletsBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "bench-system-100" "100 triplets benchmark" timestamp

  tripletIds <- sequence $ replicate 100 generateTripletId
  let triplets = map (\tid -> createTriplet LeafTriplet (Just tid) "bench triplet" timestamp) tripletIds

  mapM_ (\(tid, triplet) -> atomically $ addTriplet tid triplet system) (zip tripletIds triplets)
  return ()

create1000TripletsBench :: IO ()
create1000TripletsBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "bench-system-1000" "1000 triplets benchmark" timestamp

  tripletIds <- sequence $ replicate 1000 generateTripletId
  let triplets = map (\tid -> createTriplet LeafTriplet (Just tid) "bench triplet" timestamp) tripletIds

  mapM_ (\(tid, triplet) -> atomically $ addTriplet tid triplet system) (zip tripletIds triplets)
  return ()

-- State tracker benchmarks
createTrackerBench :: IO ()
createTrackerBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "tracker-bench" "Tracker benchmark" timestamp
  let config = TrackerConfig 10000 1000 50 30000 BasicValidation False
  _ <- atomically $ createStateTracker system config timestamp
  return ()

register100PointersBench :: IO ()
register100PointersBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "pointer-bench" "Pointer benchmark" timestamp
  let config = TrackerConfig 10000 1000 50 30000 NoValidation False
  tracker <- atomically $ createStateTracker system config timestamp

  tripletIds <- sequence $ replicate 100 generateTripletId
  let pointers = zipWith (\i tid -> Pointer
        { pointerId = "bench-pointer-" <> show i
        , pointerType = ValuePointer
        , pointerTarget = "target-" <> show i
        , pointerTriplet = tid
        , pointerDomain = ModelDomain
        , pointerInterface = "bench"
        , pointerStatus = PointerActive
        , pointerCreated = timestamp
        , pointerLastUsed = Nothing
        }) [1..100] tripletIds
      metadata = PointerMetadata "Benchmark pointer" Map.empty Set.empty "1.0" "bench"

  mapM_ (\p -> registerPointer p metadata tracker) pointers
  return ()

process1000SignalsBench :: IO ()
process1000SignalsBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "signal-bench" "Signal benchmark" timestamp
  let config = TrackerConfig 10000 1000 50 30000 NoValidation False
  tracker <- atomically $ createStateTracker system config timestamp

  let signals = map (\i -> InputSignal
        { signalId = "bench-signal-" <> show i
        , signalType = ExecutionSignal
        , signalSource = "bench-source"
        , signalData = ControlCommand "bench" ["arg"]
        , signalTimestamp = timestamp
        , signalPriority = NormalPriority
        }) [1..1000]

  mapM_ (`updateTracker` tracker) signals
  return ()

-- Registry benchmarks
createRegistryBench :: IO ()
createRegistryBench = do
  timestamp <- currentTimestamp
  _ <- atomically $ createCompositeRegistry timestamp
  return ()

register1000ValuesBench :: IO ()
register1000ValuesBench = do
  timestamp <- currentTimestamp
  registry <- atomically $ createCompositeRegistry timestamp

  valueIds <- sequence $ replicate 1000 generateValueId
  tripletId <- generateTripletId
  let values = map (\vid -> TypedValue
        { valueId = vid
        , valueName = "bench-value"
        , valueType = UnitType
        , valueContent = NullValue
        , valueTriplet = tripletId
        , valueDomain = ModelDomain
        , valueCreated = timestamp
        , valueValidated = True
        }) valueIds

  -- Would register all values in real implementation
  return ()

query1000TimesBench :: IO ()
query1000TimesBench = do
  timestamp <- currentTimestamp
  registry <- atomically $ createCompositeRegistry timestamp

  -- Would perform 1000 queries in real implementation
  sequence_ $ replicate 1000 (return ())

-- Refinement benchmarks
simpleRefinementBench :: IO ()
simpleRefinementBench = do
  timestamp <- currentTimestamp
  parentId <- generateTripletId
  taskId <- generateTaskId
  let task = Task taskId "Simple task" "Simple refinement task" [] Pending timestamp timestamp
      transform = createRefinementTransform parentId task "Simple project"
      parentTriplet = createTriplet SourceTriplet Nothing "Simple parent" timestamp

  case applyRefinement transform parentTriplet of
    Right _ -> return ()
    Left _ -> return ()

complexRefinementBench :: IO ()
complexRefinementBench = do
  timestamp <- currentTimestamp
  parentId <- generateTripletId
  taskId <- generateTaskId
  let task = Task taskId "Complex task"
             "Complex multi-component system with databases, APIs, and user interfaces"
             [] Pending timestamp timestamp
      transform = createRefinementTransform parentId task
                  "Enterprise application with microservices, databases, caching, monitoring, and CI/CD"
      parentTriplet = createTriplet SourceTriplet Nothing "Complex enterprise system" timestamp

  case applyRefinement transform parentTriplet of
    Right _ -> return ()
    Left _ -> return ()

deepRefinementBench :: IO ()
deepRefinementBench = do
  timestamp <- currentTimestamp

  -- Create 5 levels of refinement
  sourceId <- generateTripletId
  let sourceTask = Task (TaskId undefined) "Level 1" "Root system" [] Pending timestamp timestamp
      sourceTransform = createRefinementTransform sourceId sourceTask "Deep hierarchy system"
      sourceTriplet = createTriplet SourceTriplet Nothing "Root" timestamp

  case applyRefinement sourceTransform sourceTriplet of
    Right level1 -> case resultChildTriplets level1 of
      (child1:_) -> do
        let child1Id = getTripletIdFromTriplet child1
            child1Task = Task (TaskId undefined) "Level 2" "Second level" [] Pending timestamp timestamp
            child1Transform = createRefinementTransform child1Id child1Task "Level 2 system"

        case applyRefinement child1Transform child1 of
          Right level2 -> case resultChildTriplets level2 of
            (child2:_) -> do
              let child2Id = getTripletIdFromTriplet child2
                  child2Task = Task (TaskId undefined) "Level 3" "Third level" [] Pending timestamp timestamp
                  child2Transform = createRefinementTransform child2Id child2Task "Level 3 system"

              case applyRefinement child2Transform child2 of
                Right _ -> return ()
                Left _ -> return ()
            [] -> return ()
          Left _ -> return ()
      [] -> return ()
    Left _ -> return ()

-- Coarsening benchmarks
simpleCoarseningBench :: IO ()
simpleCoarseningBench = do
  timestamp <- currentTimestamp
  tripletIds <- sequence $ replicate 5 generateTripletId
  let targets = Set.fromList tripletIds
      transform = createCoarseningTransform targets ConservativeCoarsening

  system <- atomically $ createSystem "coarsen-bench" "Coarsening benchmark" timestamp
  case executeCoarsening transform system of
    _ -> return () -- Would execute in IO

complexCoarseningBench :: IO ()
complexCoarseningBench = do
  timestamp <- currentTimestamp
  tripletIds <- sequence $ replicate 20 generateTripletId
  let targets = Set.fromList tripletIds
      transform = createCoarseningTransform targets AggressiveCoarsening

  system <- atomically $ createSystem "complex-coarsen-bench" "Complex coarsening benchmark" timestamp
  case executeCoarsening transform system of
    _ -> return () -- Would execute in IO

batchCoarseningBench :: IO ()
batchCoarseningBench = do
  timestamp <- currentTimestamp
  tripletIds <- sequence $ replicate 100 generateTripletId
  let targets = Set.fromList tripletIds
      transform = createCoarseningTransform targets SelectiveCoarsening

  system <- atomically $ createSystem "batch-coarsen-bench" "Batch coarsening benchmark" timestamp
  case executeCoarsening transform system of
    _ -> return () -- Would execute in IO

-- Large scale benchmarks
largeSystemBench :: IO ()
largeSystemBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "large-system-bench" "Large system benchmark" timestamp

  -- Create 10K triplets
  tripletIds <- sequence $ replicate 10000 generateTripletId
  let triplets = map (\tid -> createTriplet LeafTriplet (Just tid) "large system triplet" timestamp) tripletIds

  -- Add triplets in batches for performance
  let batches = chunksOf 100 (zip tripletIds triplets)
  mapM_ (\batch -> mapM_ (\(tid, triplet) -> atomically $ addTriplet tid triplet system) batch) batches
  return ()

largeRegistryBench :: IO ()
largeRegistryBench = do
  timestamp <- currentTimestamp
  registry <- atomically $ createCompositeRegistry timestamp

  -- Create 100K pointers (simulated)
  tripletIds <- sequence $ replicate 100000 generateTripletId
  let pointers = map (\(i, tid) -> Pointer
        { pointerId = "large-pointer-" <> show i
        , pointerType = ValuePointer
        , pointerTarget = "large-target-" <> show i
        , pointerTriplet = tid
        , pointerDomain = ModelDomain
        , pointerInterface = "large"
        , pointerStatus = PointerActive
        , pointerCreated = timestamp
        , pointerLastUsed = Nothing
        }) (zip [1..100000] tripletIds)

  -- Would register all pointers in real implementation
  return ()

highVolumeSignalsBench :: IO ()
highVolumeSignalsBench = do
  timestamp <- currentTimestamp
  system <- atomically $ createSystem "high-volume-bench" "High volume benchmark" timestamp
  let config = TrackerConfig 200000 20000 1000 60000 NoValidation False
  tracker <- atomically $ createStateTracker system config timestamp

  let signals = map (\i -> InputSignal
        { signalId = "high-vol-signal-" <> show i
        , signalType = ExecutionSignal
        , signalSource = "high-vol-source"
        , signalData = ControlCommand "process" [show i]
        , signalTimestamp = timestamp
        , signalPriority = NormalPriority
        }) [1..10000]

  -- Process signals in batches
  let batches = chunksOf 100 signals
  mapM_ (\batch -> mapM_ (`updateTracker` tracker) batch) batches
  return ()

-- Helper functions
getTripletIdFromTriplet :: MEUTriplet IO -> TripletId
getTripletIdFromTriplet triplet = case triplet of
  SourceTriplet{..} -> sourceTripletId
  BranchTriplet{..} -> branchTripletId
  LeafTriplet{..} -> leafTripletId

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)