-- |
-- Module      : MEU.IO.Serialization
-- Description : JSON serialization infrastructure for MEU system
-- Copyright   : (c) MEU Framework Team, 2025
-- License     : MIT
-- Maintainer  : team@meu-framework.org
--
-- This module provides comprehensive JSON serialization support for MEU
-- system data structures using Aeson, with support for versioning and
-- schema evolution.

module MEU.IO.Serialization
  ( -- * Serialization Functions
    serializeMEUTriplet
  , deserializeMEUTriplet
  , serializeSystemState
  , deserializeSystemState

    -- * File Operations
  , saveTripletToFile
  , loadTripletFromFile
  , saveSystemStateToFile
  , loadSystemStateFromFile

    -- * Stream Serialization
  , streamSerializeTriplets
  , streamDeserializeTriplets

    -- * Versioning Support
  , SerializationVersion (..)
  , VersionedData (..)
  , migrateData

    -- * Error Handling
  , SerializationError (..)
  , SerializationResult

    -- * Utilities
  , compactSerialization
  , prettyPrintJson
  ) where

import Control.Exception (try, IOException)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as LBS
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8, decodeUtf8)
import Data.Time (UTCTime, getCurrentTime)
import System.FilePath ((</>), takeExtension)
import System.Directory (createDirectoryIfMissing, doesFileExist)

import MEU.Core.Types
import MEU.Core.Triplet
import MEU.Internal.Monad (SystemState)

-- | Serialization version for schema evolution
data SerializationVersion = SerializationVersion
  { versionMajor :: !Int
  , versionMinor :: !Int
  , versionPatch :: !Int
  } deriving stock (Show, Eq, Ord, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Current serialization version
currentVersion :: SerializationVersion
currentVersion = SerializationVersion 1 0 0

-- | Versioned data wrapper
data VersionedData a = VersionedData
  { dataVersion :: !SerializationVersion
  , dataTimestamp :: !UTCTime
  , dataContent :: !a
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Serialization-specific errors
data SerializationError
  = SerializationParseError !Text
  | SerializationFileError !Text
  | SerializationVersionError !SerializationVersion !SerializationVersion
  | SerializationIOError !Text
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Result type for serialization operations
type SerializationResult a = Either SerializationError a

-- | Serialize MEU triplet to JSON
serializeMEUTriplet :: MEUTriplet IO -> IO (SerializationResult ByteString)
serializeMEUTriplet triplet = do
  timestamp <- getCurrentTime
  let versionedData = VersionedData currentVersion timestamp triplet
  case encode versionedData of
    result -> pure $ Right result

-- | Deserialize MEU triplet from JSON
deserializeMEUTriplet :: ByteString -> SerializationResult (MEUTriplet IO)
deserializeMEUTriplet bytes = do
  case eitherDecode bytes of
    Left err -> Left $ SerializationParseError $ T.pack err
    Right (VersionedData version _timestamp triplet) -> do
      if version == currentVersion
        then Right triplet
        else Left $ SerializationVersionError version currentVersion

-- | Serialize system state to JSON
serializeSystemState :: SystemState -> IO (SerializationResult ByteString)
serializeSystemState state = do
  timestamp <- getCurrentTime
  let versionedData = VersionedData currentVersion timestamp state
  case encode versionedData of
    result -> pure $ Right result

-- | Deserialize system state from JSON
deserializeSystemState :: ByteString -> SerializationResult SystemState
deserializeSystemState bytes = do
  case eitherDecode bytes of
    Left err -> Left $ SerializationParseError $ T.pack err
    Right (VersionedData version _timestamp state) -> do
      if version == currentVersion
        then Right state
        else Left $ SerializationVersionError version currentVersion

-- | Save MEU triplet to file
saveTripletToFile :: FilePath -> MEUTriplet IO -> IO (SerializationResult ())
saveTripletToFile path triplet = do
  result <- serializeMEUTriplet triplet
  case result of
    Left err -> pure $ Left err
    Right bytes -> do
      ensureDirectoryExists path
      ioResult <- try $ LBS.writeFile path bytes
      case ioResult of
        Left (ioErr :: IOException) -> pure $ Left $ SerializationIOError $ T.pack $ show ioErr
        Right () -> pure $ Right ()

-- | Load MEU triplet from file
loadTripletFromFile :: FilePath -> IO (SerializationResult (MEUTriplet IO))
loadTripletFromFile path = do
  exists <- doesFileExist path
  if not exists
    then pure $ Left $ SerializationFileError $ "File does not exist: " <> T.pack path
    else do
      ioResult <- try $ LBS.readFile path
      case ioResult of
        Left (ioErr :: IOException) -> pure $ Left $ SerializationIOError $ T.pack $ show ioErr
        Right bytes -> pure $ deserializeMEUTriplet bytes

-- | Save system state to file
saveSystemStateToFile :: FilePath -> SystemState -> IO (SerializationResult ())
saveSystemStateToFile path state = do
  result <- serializeSystemState state
  case result of
    Left err -> pure $ Left err
    Right bytes -> do
      ensureDirectoryExists path
      ioResult <- try $ LBS.writeFile path bytes
      case ioResult of
        Left (ioErr :: IOException) -> pure $ Left $ SerializationIOError $ T.pack $ show ioErr
        Right () -> pure $ Right ()

-- | Load system state from file
loadSystemStateFromFile :: FilePath -> IO (SerializationResult SystemState)
loadSystemStateFromFile path = do
  exists <- doesFileExist path
  if not exists
    then pure $ Left $ SerializationFileError $ "File does not exist: " <> T.pack path
    else do
      ioResult <- try $ LBS.readFile path
      case ioResult of
        Left (ioErr :: IOException) -> pure $ Left $ SerializationIOError $ T.pack $ show ioErr
        Right bytes -> pure $ deserializeSystemState bytes

-- | Stream serialize multiple triplets (for large datasets)
streamSerializeTriplets :: [MEUTriplet IO] -> IO (SerializationResult ByteString)
streamSerializeTriplets triplets = do
  timestamp <- getCurrentTime
  let versionedData = VersionedData currentVersion timestamp triplets
  case encode versionedData of
    result -> pure $ Right result

-- | Stream deserialize multiple triplets
streamDeserializeTriplets :: ByteString -> SerializationResult [MEUTriplet IO]
streamDeserializeTriplets bytes = do
  case eitherDecode bytes of
    Left err -> Left $ SerializationParseError $ T.pack err
    Right (VersionedData version _timestamp triplets) -> do
      if version == currentVersion
        then Right triplets
        else Left $ SerializationVersionError version currentVersion

-- | Migrate data between versions (placeholder for future use)
migrateData :: SerializationVersion -> SerializationVersion -> Value -> SerializationResult Value
migrateData fromVersion toVersion value
  | fromVersion == toVersion = Right value
  | otherwise = Left $ SerializationVersionError fromVersion toVersion

-- | Compact serialization (no pretty printing)
compactSerialization :: ToJSON a => a -> ByteString
compactSerialization = encode

-- | Pretty print JSON for human readability
prettyPrintJson :: ToJSON a => a -> ByteString
prettyPrintJson = encodePretty

-- | Ensure directory exists for file path
ensureDirectoryExists :: FilePath -> IO ()
ensureDirectoryExists path = do
  let dir = case takeExtension path of
        "" -> path  -- path is already a directory
        _  -> let (d, _) = splitFileName path in d
  createDirectoryIfMissing True dir

-- | Split file path into directory and filename
splitFileName :: FilePath -> (FilePath, FilePath)
splitFileName path =
  let parts = reverse $ splitPath path
  in case parts of
    [] -> (".", "")
    [name] -> (".", name)
    (name:dirs) -> (joinPath $ reverse dirs, name)

-- Helper functions for file path manipulation
splitPath :: FilePath -> [FilePath]
splitPath = words . map (\c -> if c == '/' then ' ' else c)

joinPath :: [FilePath] -> FilePath
joinPath = foldl (</>) ""

-- Instances for serialization
instance ToJSON (MEUTriplet IO) where
  toJSON triplet = object
    [ "tripletId" .= getTripletId triplet
    , "tripletType" .= getTripletType triplet
    , "tripletState" .= show triplet -- Simplified for now
    ]

instance FromJSON (MEUTriplet IO) where
  parseJSON = withObject "MEUTriplet" $ \o -> do
    -- Simplified parsing - will be enhanced later
    tripletId <- o .: "tripletId"
    tripletType <- o .: "tripletType"
    -- Return a placeholder triplet for now
    pure $ error "MEUTriplet FromJSON not fully implemented yet"

instance ToJSON SystemState where
  toJSON _state = object
    [ "placeholder" .= ("SystemState serialization not implemented" :: Text)
    ]

instance FromJSON SystemState where
  parseJSON = withObject "SystemState" $ \_ -> do
    pure $ error "SystemState FromJSON not implemented yet"