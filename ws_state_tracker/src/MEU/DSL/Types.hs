{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE StrictData #-}

module MEU.DSL.Types
  ( -- * DSL Primitive Types
    DSLPrimitiveId(..)
  , DSLPrimitive(..)
  , DSLFunction(..)

    -- * Value Types
  , ValueId(..)
  , TypedValue(..)

    -- * Dataflow Arrow Types
  , DataflowArrow(..)
  , ArrowType(..)
  , DataflowCollection(..)

    -- * Registry Entry Types
  , RegistryEntry(..)
  , RegistryType(..)

    -- * Execution Context
  , ExecutionContext(..)
  , ExecutionResult(..)
  ) where

import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)

import MEU.Core.Types

-- | Unique identifier for DSL primitives
newtype DSLPrimitiveId = DSLPrimitiveId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | DSL primitive function specification
data DSLPrimitive = DSLPrimitive
  { primitiveId :: DSLPrimitiveId
  , primitiveName :: Text
  , primitiveDescription :: Text
  , primitiveSignature :: TypeSignature
  , primitiveDomain :: DomainId
  , primitiveTriplet :: TripletId
  , primitiveImplementation :: DSLFunction
  , primitiveCreated :: Timestamp
  , primitiveUpdated :: Timestamp
  } deriving (Eq, Show, Generic)

-- | DSL function implementation
data DSLFunction
  = PureFunction (TypedValue -> Either MEUError TypedValue)
  | EffectfulFunction (ExecutionContext -> TypedValue -> IO (Either MEUError TypedValue))
  | CompositeFunction [DSLPrimitiveId]
  | IdentityFunction
  | TestFunction TestId

instance Eq DSLFunction where
  IdentityFunction == IdentityFunction = True
  TestFunction t1 == TestFunction t2 = t1 == t2
  CompositeFunction ids1 == CompositeFunction ids2 = ids1 == ids2
  _ == _ = False

instance Show DSLFunction where
  show IdentityFunction = "IdentityFunction"
  show (TestFunction tid) = "TestFunction " <> show tid
  show (CompositeFunction ids) = "CompositeFunction " <> show ids
  show (PureFunction _) = "PureFunction <function>"
  show (EffectfulFunction _) = "EffectfulFunction <function>"

-- | Unique identifier for typed values
newtype ValueId = ValueId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Typed value in MEU system
data TypedValue = TypedValue
  { valueId :: ValueId
  , valueName :: Text
  , valueType :: MEUType
  , valueContent :: ValueContent
  , valueTriplet :: TripletId
  , valueDomain :: DomainId
  , valueCreated :: Timestamp
  , valueValidated :: Bool
  } deriving (Eq, Show, Generic)

-- | Content of a typed value
data ValueContent
  = StringValue Text
  | IntValue Int
  | BoolValue Bool
  | FloatValue Double
  | ListValue [TypedValue]
  | RecordValue [(Text, TypedValue)]
  | FunctionValue DSLPrimitiveId
  | CompositeValue [ValueContent]
  | NullValue
  deriving (Eq, Show, Generic)

-- | Dataflow arrow between domains
data DataflowArrow = DataflowArrow
  { arrowId :: Text
  , arrowType :: ArrowType
  , arrowSource :: DomainId
  , arrowTarget :: DomainId
  , arrowSourceTriplet :: TripletId
  , arrowTargetTriplet :: TripletId
  , arrowFunction :: DSLPrimitiveId
  , arrowSignature :: TypeSignature
  } deriving (Eq, Show, Generic)

-- | Type of dataflow arrow
data ArrowType
  = IArrow          -- I: M -> E (deployment)
  , IStarArrow      -- I*: E -> M (configuration feedback)
  | OArrow          -- O: E -> U (execution feedback)
  | OStarArrow      -- O*: U -> E (evaluation configuration)
  | RArrow          -- R: U -> M (model updates)
  | RStarArrow      -- R*: M -> U (verifier deployment)
  | IdentityArrow   -- Identity mappings
  | DependencyArrow -- Horizontal dependencies
  deriving (Eq, Show, Generic)

-- | Collection of dataflow arrows for MEU triplet
data DataflowCollection = DataflowCollection
  { iArrows :: [DataflowArrow]      -- {I: M->E}
  , iStarArrows :: [DataflowArrow]  -- {I*: E->M}
  , oArrows :: [DataflowArrow]      -- {O: E->U}
  , oStarArrows :: [DataflowArrow]  -- {O*: U->E}
  , rArrows :: [DataflowArrow]      -- {R: U->M}
  , rStarArrows :: [DataflowArrow]  -- {R*: M->U}
  , identityArrows :: [DataflowArrow] -- Identity mappings
  } deriving (Eq, Show, Generic)

-- | Registry entry for tracking system components
data RegistryEntry = RegistryEntry
  { entryId :: Text
  , entryType :: RegistryType
  , entryTriplet :: TripletId
  , entryDomain :: DomainId
  , entryMetadata :: [(Text, Text)]
  , entryCreated :: Timestamp
  , entryUpdated :: Timestamp
  , entryActive :: Bool
  } deriving (Eq, Show, Generic)

-- | Type of registry entry
data RegistryType
  = TypeRegistry
  | ValueRegistry
  | DSLPrimitiveRegistry
  | TestRegistry
  | VerifierRegistry
  | AxiomRegistry
  | TripletRegistry
  deriving (Eq, Show, Generic)

-- | Execution context for DSL functions
data ExecutionContext = ExecutionContext
  { contextTriplet :: TripletId
  , contextDomain :: DomainId
  , contextVariables :: [(Text, TypedValue)]
  , contextTimestamp :: Timestamp
  , contextTestMode :: Bool
  } deriving (Eq, Show, Generic)

-- | Result of DSL function execution
data ExecutionResult = ExecutionResult
  { resultValue :: TypedValue
  , resultLogs :: [Text]
  , resultTests :: [TestId]
  , resultErrors :: [MEUError]
  , resultTimestamp :: Timestamp
  } deriving (Eq, Show, Generic)