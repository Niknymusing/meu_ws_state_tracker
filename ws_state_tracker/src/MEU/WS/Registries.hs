{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE StrictData #-}

module MEU.WS.Registries
  ( -- * Registry Types
    Registry(..)
  , RegistryState(..)

    -- * Specific Registries
  , TypeRegistry(..)
  , ValueRegistry(..)
  , DSLPrimitiveRegistry(..)
  , TestRegistry(..)
  , VerifierRegistry(..)
  , AxiomRegistry(..)
  , TripletRegistry(..)

    -- * Registry Operations
  , createRegistry
  , registerEntry
  , unregisterEntry
  , lookupEntry
  , updateEntry
  , listEntries

    -- * Registry Validation
  , validateRegistry
  , checkRegistryInvariants

    -- * Composite Operations
  , CompositeRegistry(..)
  , createCompositeRegistry
  , queryComposite
  , updateComposite

    -- * Registry Hypergraph Operations
  , ValueMergeHypergraph(..)
  , FunctionExecutionHypergraph(..)
  , buildValueMergeGraph
  , buildFunctionExecutionGraph
  , findMergeableValues
  , findExecutableFunctions
  ) where

import Control.Concurrent.STM (STM, TVar, newTVar, readTVar, writeTVar, modifyTVar)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import Data.Matrix (Matrix)
import qualified Data.Matrix as Matrix
import GHC.Generics (Generic)

import MEU.Core.Types
import MEU.DSL.Types

-- | Generic registry for system components
data Registry k v = Registry
  { registryId :: Text
  , registryType :: RegistryType
  , registryEntries :: TVar (Map k v)
  , registryMetadata :: TVar (Map k [(Text, Text)])
  , registryActive :: TVar (Set k)
  , registryInactive :: TVar (Set k)
  , registryCreated :: Timestamp
  , registryUpdated :: TVar Timestamp
  } deriving (Generic)

-- | State of a registry
data RegistryState = RegistryState
  { stateActiveEntries :: Int
  , stateInactiveEntries :: Int
  , stateTotalEntries :: Int
  , stateLastUpdate :: Timestamp
  , stateErrors :: [MEUError]
  } deriving (Eq, Show, Generic)

-- | Type registry for tracking all defined types
newtype TypeRegistry = TypeRegistry (Registry MEUType (Set TripletId))
  deriving (Generic)

-- | Value registry for tracking typed values
newtype ValueRegistry = ValueRegistry (Registry ValueId TypedValue)
  deriving (Generic)

-- | DSL primitive registry for tracking executable functions
newtype DSLPrimitiveRegistry = DSLPrimitiveRegistry (Registry DSLPrimitiveId DSLPrimitive)
  deriving (Generic)

-- | Test registry for tracking all tests
newtype TestRegistry = TestRegistry (Registry TestId Test)
  deriving (Generic)

-- | Verifier registry for tracking verification functions
newtype VerifierRegistry = VerifierRegistry (Registry DSLPrimitiveId DSLPrimitive)
  deriving (Generic)

-- | Axiom registry for tracking logical axioms
newtype AxiomRegistry = AxiomRegistry (Registry Text Axiom)
  deriving (Generic)

-- | Triplet registry for tracking MEU triplets
newtype TripletRegistry = TripletRegistry (Registry TripletId TripletRegistryEntry)
  deriving (Generic)

-- | Entry for triplet registry
data TripletRegistryEntry = TripletRegistryEntry
  { entryTripletType :: TripletType
  , entryParentId :: Maybe TripletId
  , entryChildren :: Set TripletId
  , entrySiblings :: Set TripletId
  , entryAncestors :: [TripletId]
  , entryInclusions :: Map TripletId InclusionMap
  , entryRefinementFamily :: Set TripletId
  , entryMetadata :: [(Text, Text)]
  } deriving (Eq, Show, Generic)

-- | Composite registry combining all registries
data CompositeRegistry = CompositeRegistry
  { compositeTypes :: TypeRegistry
  , compositeValues :: ValueRegistry
  , compositePrimitives :: DSLPrimitiveRegistry
  , compositeTests :: TestRegistry
  , compositeVerifiers :: VerifierRegistry
  , compositeAxioms :: AxiomRegistry
  , compositeTriplets :: TripletRegistry
  } deriving (Generic)

-- | Value merge hypergraph for tracking mergeable values
data ValueMergeHypergraph = ValueMergeHypergraph
  { mergeGraphValues :: [ValueId]
  , mergeGraphSignatures :: [TypeSignature]
  , mergeGraphMatrix :: Matrix Bool
  , mergeGraphConstructors :: Map (Int, Int) TypeConstructor
  } deriving (Eq, Show, Generic)

-- | Function execution hypergraph for tracking executable functions
data FunctionExecutionHypergraph = FunctionExecutionHypergraph
  { execGraphValues :: [ValueId]
  , execGraphPrimitives :: [DSLPrimitiveId]
  , execGraphMatrix :: Matrix Bool
  , execGraphMask :: Matrix Bool
  , execGraphExecutable :: Set DSLPrimitiveId
  } deriving (Eq, Show, Generic)

-- | Create new registry
createRegistry :: Text -> RegistryType -> Timestamp -> STM (Registry k v)
createRegistry regId regType timestamp = do
  entries <- newTVar Map.empty
  metadata <- newTVar Map.empty
  active <- newTVar Set.empty
  inactive <- newTVar Set.empty
  updated <- newTVar timestamp

  return Registry
    { registryId = regId
    , registryType = regType
    , registryEntries = entries
    , registryMetadata = metadata
    , registryActive = active
    , registryInactive = inactive
    , registryCreated = timestamp
    , registryUpdated = updated
    }

-- | Register new entry
registerEntry :: Ord k => k -> v -> [(Text, Text)] -> Registry k v -> STM ()
registerEntry key value meta registry = do
  modifyTVar (registryEntries registry) (Map.insert key value)
  modifyTVar (registryMetadata registry) (Map.insert key meta)
  modifyTVar (registryActive registry) (Set.insert key)

-- | Unregister entry
unregisterEntry :: Ord k => k -> Registry k v -> STM ()
unregisterEntry key registry = do
  modifyTVar (registryEntries registry) (Map.delete key)
  modifyTVar (registryMetadata registry) (Map.delete key)
  modifyTVar (registryActive registry) (Set.delete key)
  modifyTVar (registryInactive registry) (Set.insert key)

-- | Lookup entry
lookupEntry :: Ord k => k -> Registry k v -> STM (Maybe v)
lookupEntry key registry = do
  entries <- readTVar (registryEntries registry)
  return (Map.lookup key entries)

-- | Update existing entry
updateEntry :: Ord k => k -> v -> Registry k v -> STM Bool
updateEntry key value registry = do
  entries <- readTVar (registryEntries registry)
  case Map.lookup key entries of
    Just _ -> do
      writeTVar (registryEntries registry) (Map.insert key value entries)
      return True
    Nothing -> return False

-- | List all entries
listEntries :: Registry k v -> STM [(k, v)]
listEntries registry = do
  entries <- readTVar (registryEntries registry)
  return (Map.toList entries)

-- | Validate registry consistency
validateRegistry :: Registry k v -> STM (Either [MEUError] ())
validateRegistry registry = do
  active <- readTVar (registryActive registry)
  inactive <- readTVar (registryInactive registry)
  entries <- readTVar (registryEntries registry)

  let activeKeys = Map.keysSet entries
      allKeys = Set.union active inactive
      errors = []

  -- Check that active keys match actual entries
  let missingActive = Set.difference active activeKeys
      extraEntries = Set.difference activeKeys active

  let validationErrors =
        [RegistryError "Missing active entries" | not (Set.null missingActive)] ++
        [RegistryError "Extra entries not marked active" | not (Set.null extraEntries)]

  if null validationErrors
    then return (Right ())
    else return (Left validationErrors)

-- | Check registry invariants
checkRegistryInvariants :: Registry k v -> STM Bool
checkRegistryInvariants registry = do
  validation <- validateRegistry registry
  case validation of
    Right () -> return True
    Left _ -> return False

-- | Create composite registry
createCompositeRegistry :: Timestamp -> STM CompositeRegistry
createCompositeRegistry timestamp = do
  types <- TypeRegistry <$> createRegistry "types" TypeRegistry timestamp
  values <- ValueRegistry <$> createRegistry "values" ValueRegistry timestamp
  primitives <- DSLPrimitiveRegistry <$> createRegistry "primitives" DSLPrimitiveRegistry timestamp
  tests <- TestRegistry <$> createRegistry "tests" TestRegistry timestamp
  verifiers <- VerifierRegistry <$> createRegistry "verifiers" VerifierRegistry timestamp
  axioms <- AxiomRegistry <$> createRegistry "axioms" AxiomRegistry timestamp
  triplets <- TripletRegistry <$> createRegistry "triplets" TripletRegistry timestamp

  return CompositeRegistry
    { compositeTypes = types
    , compositeValues = values
    , compositePrimitives = primitives
    , compositeTests = tests
    , compositeVerifiers = verifiers
    , compositeAxioms = axioms
    , compositeTriplets = triplets
    }

-- | Query composite registry
queryComposite :: CompositeQuery -> CompositeRegistry -> STM CompositeQueryResult
queryComposite query composite = case query of
  QueryByType meuType -> queryByType meuType composite
  QueryByTriplet tripletId -> queryByTriplet tripletId composite
  QueryByDomain domainId -> queryByDomain domainId composite
  QueryExecutable -> queryExecutableFunctions composite

-- | Update composite registry
updateComposite :: CompositeUpdate -> CompositeRegistry -> STM ()
updateComposite update composite = case update of
  AddValue valueId typedValue meta -> addValue valueId typedValue meta composite
  AddPrimitive primId primitive meta -> addPrimitive primId primitive meta composite
  AddTest testId test meta -> addTest testId test meta composite
  AddAxiom axiomId axiom meta -> addAxiom axiomId axiom meta composite

-- | Build value merge hypergraph
buildValueMergeGraph :: ValueRegistry -> DSLPrimitiveRegistry -> STM ValueMergeHypergraph
buildValueMergeGraph (ValueRegistry valueReg) (DSLPrimitiveRegistry primReg) = do
  values <- readTVar (registryEntries valueReg)
  primitives <- readTVar (registryEntries primReg)

  let valueList = Map.keys values
      primList = Map.elems primitives
      signatures = map primitiveSignature primList
      rows = length valueList
      cols = length signatures

  -- Build adjacency matrix
  let matrix = Matrix.matrix rows cols $ \(i, j) ->
        let valueId = valueList !! (i - 1)
            sig = signatures !! (j - 1)
            value = values Map.! valueId
        in canMergeValueToSignature value sig

  return ValueMergeHypergraph
    { mergeGraphValues = valueList
    , mergeGraphSignatures = signatures
    , mergeGraphMatrix = matrix
    , mergeGraphConstructors = Map.empty -- Build constructor mapping
    }

-- | Build function execution hypergraph
buildFunctionExecutionGraph :: ValueRegistry
                            -> DSLPrimitiveRegistry
                            -> AxiomRegistry
                            -> STM FunctionExecutionHypergraph
buildFunctionExecutionGraph (ValueRegistry valueReg) (DSLPrimitiveRegistry primReg) (AxiomRegistry axiomReg) = do
  values <- readTVar (registryEntries valueReg)
  primitives <- readTVar (registryEntries primReg)
  axioms <- readTVar (registryEntries axiomReg)

  let valueList = Map.keys values
      primList = Map.keys primitives
      rows = length valueList
      cols = length primList

  -- Build adjacency matrix
  let matrix = Matrix.matrix rows cols $ \(i, j) ->
        let valueId = valueList !! (i - 1)
            primId = primList !! (j - 1)
            value = values Map.! valueId
            primitive = primitives Map.! primId
        in isValueInputToPrimitive value primitive

  -- Build mask based on axioms
  let mask = Matrix.matrix rows cols $ \(i, j) ->
        let valueId = valueList !! (i - 1)
            primId = primList !! (j - 1)
        in isExecutionAllowed valueId primId axioms

  -- Find executable primitives
  let executable = Set.fromList [primId | (primId, j) <- zip primList [1..],
                                 any (\i -> Matrix.getElem i j matrix && Matrix.getElem i j mask) [1..rows]]

  return FunctionExecutionHypergraph
    { execGraphValues = valueList
    , execGraphPrimitives = primList
    , execGraphMatrix = matrix
    , execGraphMask = mask
    , execGraphExecutable = executable
    }

-- | Find mergeable values for type signature
findMergeableValues :: TypeSignature -> ValueMergeHypergraph -> [ValueId]
findMergeableValues sig graph =
  case elemIndex sig (mergeGraphSignatures graph) of
    Nothing -> []
    Just colIdx ->
      let col = colIdx + 1
          rows = Matrix.nrows (mergeGraphMatrix graph)
      in [mergeGraphValues graph !! (row - 1) | row <- [1..rows],
          Matrix.getElem row col (mergeGraphMatrix graph)]

-- | Find executable functions given available values
findExecutableFunctions :: Set ValueId -> FunctionExecutionHypergraph -> [DSLPrimitiveId]
findExecutableFunctions availableValues graph =
  let valueIndices = [i | (valId, i) <- zip (execGraphValues graph) [1..],
                      valId `Set.member` availableValues]
      cols = Matrix.ncols (execGraphMatrix graph)
  in [execGraphPrimitives graph !! (col - 1) | col <- [1..cols],
      all (\row -> Matrix.getElem row col (execGraphMatrix graph) &&
                   Matrix.getElem row col (execGraphMask graph)) valueIndices]

-- Helper types and functions
data CompositeQuery
  = QueryByType MEUType
  | QueryByTriplet TripletId
  | QueryByDomain DomainId
  | QueryExecutable
  deriving (Eq, Show)

data CompositeQueryResult
  = TypeResult [TripletId]
  | TripletResult [(RegistryType, [Text])]
  | DomainResult [(ValueId, TypedValue)]
  | ExecutableResult [DSLPrimitiveId]
  deriving (Eq, Show)

data CompositeUpdate
  = AddValue ValueId TypedValue [(Text, Text)]
  | AddPrimitive DSLPrimitiveId DSLPrimitive [(Text, Text)]
  | AddTest TestId Test [(Text, Text)]
  | AddAxiom Text Axiom [(Text, Text)]
  deriving (Eq, Show)

-- Implementation stubs for helper functions
queryByType :: MEUType -> CompositeRegistry -> STM CompositeQueryResult
queryByType _ _ = return (TypeResult [])

queryByTriplet :: TripletId -> CompositeRegistry -> STM CompositeQueryResult
queryByTriplet _ _ = return (TripletResult [])

queryByDomain :: DomainId -> CompositeRegistry -> STM CompositeQueryResult
queryByDomain _ _ = return (DomainResult [])

queryExecutableFunctions :: CompositeRegistry -> STM CompositeQueryResult
queryExecutableFunctions _ = return (ExecutableResult [])

addValue :: ValueId -> TypedValue -> [(Text, Text)] -> CompositeRegistry -> STM ()
addValue _ _ _ _ = return ()

addPrimitive :: DSLPrimitiveId -> DSLPrimitive -> [(Text, Text)] -> CompositeRegistry -> STM ()
addPrimitive _ _ _ _ = return ()

addTest :: TestId -> Test -> [(Text, Text)] -> CompositeRegistry -> STM ()
addTest _ _ _ _ = return ()

addAxiom :: Text -> Axiom -> [(Text, Text)] -> CompositeRegistry -> STM ()
addAxiom _ _ _ _ = return ()

canMergeValueToSignature :: TypedValue -> TypeSignature -> Bool
canMergeValueToSignature _ _ = False

isValueInputToPrimitive :: TypedValue -> DSLPrimitive -> Bool
isValueInputToPrimitive _ _ = False

isExecutionAllowed :: ValueId -> DSLPrimitiveId -> Map Text Axiom -> Bool
isExecutionAllowed _ _ _ = True

elemIndex :: Eq a => a -> [a] -> Maybe Int
elemIndex x xs = go x xs 0
  where
    go _ [] _ = Nothing
    go y (z:zs) i = if y == z then Just i else go y zs (i + 1)