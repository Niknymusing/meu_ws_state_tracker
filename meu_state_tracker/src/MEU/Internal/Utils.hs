-- |
-- Module      : MEU.Internal.Utils
-- Description : Internal utilities and concurrent data structures
-- Copyright   : (c) MEU Framework Team, 2025
-- License     : MIT
-- Maintainer  : team@meu-framework.org
--
-- This module provides internal utilities including STM-based concurrent
-- data structures, logging infrastructure, and performance monitoring.

module MEU.Internal.Utils
  ( -- * Concurrent Data Structures
    ConcurrentRegistry (..)
  , RegistryMetrics (..)
  , newConcurrentRegistry
  , registerEntry
  , registerEntrySTM
  , batchRegisterSTM
  , lookupEntry
  , getAllEntries

    -- * Bloom Filter Support
  , BloomFilter
  , newBloomFilter
  , insertBloom
  , memberBloom

    -- * Logging Infrastructure
  , LogLevel (..)
  , LogMessage (..)
  , Logger (..)
  , newLogger
  , logMessage
  , logDebug
  , logInfo
  , logWarn
  , logError

    -- * Performance Monitoring
  , PerformanceMonitor (..)
  , PerfMetric (..)
  , newPerfMonitor
  , recordMetric
  , getMetrics
  , resetMetrics

    -- * Memory Management
  , MemoryPool (..)
  , newMemoryPool
  , allocateFromPool
  , releaseToPool

    -- * Utility Functions
  , retrySTM
  , timeoutSTM
  , chunksOf
  , groupByShard
  ) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.STM
import Control.Monad (replicateM, when)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Bits ((.&.))
import Data.Hashable (Hashable, hash)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, getCurrentTime, diffUTCTime)
import Data.Vector (Vector)
import qualified Data.Vector as V
import Data.Word (Word64)
import GHC.Generics (Generic)
import System.IO (Handle, stdout, hPutStrLn)

import MEU.Core.Types

-- | Concurrent registry with sharding and bloom filter optimization
data ConcurrentRegistry k v = ConcurrentRegistry
  { registryEntries :: !(TVar (Map k v))
  , registryShards :: !(Vector (TVar (Map k v)))
  , registryBloomFilter :: !(TVar BloomFilter)
  , registryMetrics :: !(TVar RegistryMetrics)
  , registryLocks :: !(Vector (TMVar ()))
  } deriving stock (Generic)

-- | Metrics for registry performance monitoring
data RegistryMetrics = RegistryMetrics
  { metricsActiveEntries :: !Int
  , metricsOperationCount :: !Int
  , metricsCacheHits :: !Int
  , metricsCacheMisses :: !Int
  , metricsAverageOpTime :: !Double
  } deriving stock (Show, Eq, Generic)

-- | Create new concurrent registry with specified shard count
newConcurrentRegistry :: Int -> IO (ConcurrentRegistry k v)
newConcurrentRegistry shardCount = do
  entries <- newTVarIO Map.empty
  shards <- V.replicateM shardCount (newTVarIO Map.empty)
  bloomFilter <- newTVarIO =<< newBloomFilter
  metrics <- newTVarIO $ RegistryMetrics 0 0 0 0 0.0
  locks <- V.replicateM shardCount (newTMVarIO ())
  pure $ ConcurrentRegistry entries shards bloomFilter metrics locks

-- | Register entry in concurrent registry (IO version)
registerEntry :: (Hashable k, Ord k) => k -> v -> ConcurrentRegistry k v -> IO ()
registerEntry key value registry = atomically $ registerEntrySTM key value registry

-- | Register entry in concurrent registry (STM version)
registerEntrySTM :: (Hashable k, Ord k) => k -> v -> ConcurrentRegistry k v -> STM ()
registerEntrySTM key value registry = do
  let shardIndex = hash key `mod` V.length (registryShards registry)
      shard = registryShards registry V.! shardIndex

  -- Update shard atomically
  modifyTVar shard (Map.insert key value)

  -- Update bloom filter for fast lookups
  modifyTVar (registryBloomFilter registry) (insertBloom key)

  -- Update metrics
  modifyTVar (registryMetrics registry) $ \metrics ->
    metrics { metricsActiveEntries = metricsActiveEntries metrics + 1 }

-- | Batch register entries for better performance
batchRegisterSTM :: (Hashable k, Ord k) => [(k, v)] -> ConcurrentRegistry k v -> STM ()
batchRegisterSTM entries registry = do
  -- Group by shard to minimize TVar contention
  let shardGroups = groupByShard entries registry

  -- Update each shard atomically
  mapM_ updateShard shardGroups

  -- Update bloom filter
  mapM_ (\(k, _) -> modifyTVar (registryBloomFilter registry) (insertBloom k)) entries

  -- Update metrics
  modifyTVar (registryMetrics registry) $ \metrics ->
    metrics { metricsActiveEntries = metricsActiveEntries metrics + length entries }

  where
    updateShard (shardIndex, shardEntries) = do
      let shard = registryShards registry V.! shardIndex
      modifyTVar shard $ \m -> foldl (\acc (k, v) -> Map.insert k v acc) m shardEntries

-- | Lookup entry in concurrent registry
lookupEntry :: (Hashable k, Ord k) => k -> ConcurrentRegistry k v -> STM (Maybe v)
lookupEntry key registry = do
  -- Check bloom filter first for fast negative lookups
  bloomFilter <- readTVar (registryBloomFilter registry)
  if not (memberBloom key bloomFilter)
    then do
      -- Update cache miss metrics
      modifyTVar (registryMetrics registry) $ \metrics ->
        metrics { metricsCacheMisses = metricsCacheMisses metrics + 1 }
      pure Nothing
    else do
      let shardIndex = hash key `mod` V.length (registryShards registry)
          shard = registryShards registry V.! shardIndex
      result <- Map.lookup key <$> readTVar shard
      -- Update metrics
      modifyTVar (registryMetrics registry) $ \metrics ->
        case result of
          Just _ -> metrics { metricsCacheHits = metricsCacheHits metrics + 1 }
          Nothing -> metrics { metricsCacheMisses = metricsCacheMisses metrics + 1 }
      pure result

-- | Get all entries from concurrent registry
getAllEntries :: ConcurrentRegistry k v -> STM (Map k v)
getAllEntries registry = do
  shardMaps <- mapM readTVar (V.toList $ registryShards registry)
  pure $ foldl Map.union Map.empty shardMaps

-- | Simple bloom filter implementation
data BloomFilter = BloomFilter
  { bloomBits :: !(Set Word64)
  , bloomSize :: !Int
  } deriving stock (Show, Eq, Generic)

-- | Create new bloom filter
newBloomFilter :: IO BloomFilter
newBloomFilter = pure $ BloomFilter Set.empty 1000000

-- | Insert element into bloom filter
insertBloom :: Hashable a => a -> BloomFilter -> BloomFilter
insertBloom x bf = bf { bloomBits = Set.insert (fromIntegral $ hash x) (bloomBits bf) }

-- | Check if element might be in bloom filter
memberBloom :: Hashable a => a -> BloomFilter -> Bool
memberBloom x bf = Set.member (fromIntegral $ hash x) (bloomBits bf)

-- | Log levels for the logging system
data LogLevel = Debug | Info | Warn | Error
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)

-- | Log message structure
data LogMessage = LogMessage
  { logLevel :: !LogLevel
  , logTimestamp :: !UTCTime
  , logText :: !Text
  , logContext :: !(Map Text Text)
  } deriving stock (Show, Eq, Generic)

-- | Logger configuration and state
data Logger = Logger
  { loggerLevel :: !LogLevel
  , loggerHandle :: !Handle
  , loggerBuffer :: !(IORef [LogMessage])
  } deriving stock (Generic)

-- | Create new logger
newLogger :: LogLevel -> Handle -> IO Logger
newLogger level handle = do
  buffer <- newIORef []
  pure $ Logger level handle buffer

-- | Log message with specified level
logMessage :: MonadIO m => Logger -> LogLevel -> Text -> m ()
logMessage logger level msg = liftIO $ do
  when (level >= loggerLevel logger) $ do
    timestamp <- getCurrentTime
    let logMsg = LogMessage { logLevel = level, logTimestamp = timestamp, logText = msg, logContext = Map.empty }
    hPutStrLn (loggerHandle logger) $ formatLogMessage logMsg

-- | Log debug message
logDebug :: MonadIO m => Logger -> Text -> m ()
logDebug logger = logMessage logger Debug

-- | Log info message
logInfo :: MonadIO m => Logger -> Text -> m ()
logInfo logger = logMessage logger Info

-- | Log warning message
logWarn :: MonadIO m => Logger -> Text -> m ()
logWarn logger = logMessage logger Warn

-- | Log error message
logError :: MonadIO m => Logger -> Text -> m ()
logError logger = logMessage logger Error

-- | Format log message for output
formatLogMessage :: LogMessage -> String
formatLogMessage logMsg =
  show (logTimestamp logMsg) <> " [" <> show (logLevel logMsg) <> "] " <> T.unpack (logText logMsg)

-- | Performance monitoring
data PerformanceMonitor = PerformanceMonitor
  { perfMetrics :: !(TVar (Map Text PerfMetric))
  , perfStartTime :: !UTCTime
  } deriving stock (Generic)

-- | Performance metric
data PerfMetric = PerfMetric
  { metricCount :: !Int
  , metricTotalTime :: !Double
  , metricMinTime :: !Double
  , metricMaxTime :: !Double
  } deriving stock (Show, Eq, Generic)

-- | Create new performance monitor
newPerfMonitor :: IO PerformanceMonitor
newPerfMonitor = do
  metrics <- newTVarIO Map.empty
  startTime <- getCurrentTime
  pure $ PerformanceMonitor metrics startTime

-- | Record performance metric
recordMetric :: PerformanceMonitor -> Text -> UTCTime -> UTCTime -> IO ()
recordMetric monitor name startTime endTime = do
  let duration = realToFrac $ diffUTCTime endTime startTime
  atomically $ do
    modifyTVar (perfMetrics monitor) $ \metrics ->
      let updateMetric Nothing = PerfMetric 1 duration duration duration
          updateMetric (Just old) = PerfMetric
            { metricCount = metricCount old + 1
            , metricTotalTime = metricTotalTime old + duration
            , metricMinTime = min (metricMinTime old) duration
            , metricMaxTime = max (metricMaxTime old) duration
            }
      in Map.alter (Just . updateMetric) name metrics

-- | Get all performance metrics
getMetrics :: PerformanceMonitor -> IO (Map Text PerfMetric)
getMetrics monitor = readTVarIO (perfMetrics monitor)

-- | Reset performance metrics
resetMetrics :: PerformanceMonitor -> IO ()
resetMetrics monitor = atomically $ writeTVar (perfMetrics monitor) Map.empty

-- | Memory pool for efficient allocation
data MemoryPool a = MemoryPool
  { poolItems :: !(TVar [a])
  , poolCreateItem :: !(IO a)
  , poolResetItem :: !(a -> IO a)
  } deriving stock (Generic)

-- | Create new memory pool
newMemoryPool :: IO a -> (a -> IO a) -> IO (MemoryPool a)
newMemoryPool create reset = do
  items <- newTVarIO []
  pure $ MemoryPool items create reset

-- | Allocate item from pool
allocateFromPool :: MemoryPool a -> IO a
allocateFromPool pool = do
  maybeItem <- atomically $ do
    items <- readTVar (poolItems pool)
    case items of
      [] -> pure Nothing
      (x:xs) -> do
        writeTVar (poolItems pool) xs
        pure (Just x)
  case maybeItem of
    Just item -> poolResetItem pool item
    Nothing -> poolCreateItem pool

-- | Release item back to pool
releaseToPool :: MemoryPool a -> a -> IO ()
releaseToPool pool item = atomically $ do
  modifyTVar (poolItems pool) (item:)

-- | Retry STM action with exponential backoff
retrySTM :: Int -> STM a -> IO (Maybe a)
retrySTM maxRetries action = go maxRetries
  where
    go 0 = pure Nothing
    go n = do
      result <- atomically $ (Just <$> action) `orElse` pure Nothing
      case result of
        Just x -> pure (Just x)
        Nothing -> do
          -- Simple delay before retry
          let delay = 1000 * (maxRetries - n + 1) -- microseconds
          threadDelay delay
          go (n - 1)

-- | STM action with timeout (simplified version)
timeoutSTM :: Int -> STM a -> IO (Maybe a)
timeoutSTM _timeoutMicros action = do
  -- Simplified implementation - in production would use proper timeout
  atomically $ (Just <$> action) `orElse` pure Nothing

-- | Split list into chunks of specified size
chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

-- | Group entries by shard for batch operations
groupByShard :: Hashable k => [(k, v)] -> ConcurrentRegistry k v -> [(Int, [(k, v)])]
groupByShard entries registry =
  let shardCount = V.length (registryShards registry)
      grouped = Map.toList $ foldl groupEntry Map.empty entries
  in grouped
  where
    groupEntry acc entry@(k, _) =
      let shardIndex = hash k `mod` V.length (registryShards registry)
      in Map.insertWith (++) shardIndex [entry] acc

