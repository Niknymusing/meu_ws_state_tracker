{-# LANGUAGE TemplateHaskell #-}

-- |
-- Module      : MEU.Core.Types
-- Description : Core types and type families for the MEU system
-- Copyright   : (c) MEU Framework Team, 2025
-- License     : MIT
-- Maintainer  : team@meu-framework.org
--
-- This module defines the fundamental types and type families used throughout
-- the MEU system, including domain identifiers, basic data structures, and
-- error types.

module MEU.Core.Types
  ( -- * Domain Types
    DomainId (..)
  , DomainProxy (..)

    -- * Identifier Types
  , TripletId (..)
  , TypeId (..)
  , ValueId (..)
  , DSLPrimitiveId (..)
  , TestId (..)
  , AxiomId (..)
  , ArrowId (..)
  , SpecificationId (..)
  , ModelId (..)
  , ChannelId (..)
  , EvaluatorId (..)
  , VerifierId (..)
  , CriteriaId (..)
  , PolicyId (..)
  , PredicateId (..)
  , ConstantId (..)
  , SortId (..)
  , FunctionId (..)
  , RelationId (..)
  , CompositionId (..)
  , PlanId (..)

    -- * Metadata Types
  , TripletMetadata (..)
  , ArrowMetadata (..)
  , TypeMetadata (..)
  , ValueMetadata (..)
  , PrimitiveMetadata (..)
  , CriteriaMetadata (..)
  , AxiomMetadata (..)
  , TheoryMetadata (..)

    -- * State Types
  , TripletState (..)
  , TripletType (..)
  , ConsistencyStatus (..)
  , TestType (..)
  , RefinementLevel (..)

    -- * Error Types
  , MEUError (..)
  , ValidationError (..)
  , ConcurrencyError (..)
  , VerificationError (..)

    -- * Version and Time
  , Version (..)
  , Timestamp

    -- * Type Families
  , InclusionValid
  , RefinementDepth
  , DomainConstraint

    -- * Utility Types
  , Proxy (..)
  ) where

import Data.Aeson (FromJSON, ToJSON, FromJSONKey, ToJSONKey)
import Data.Hashable (Hashable)
import Data.Kind (Constraint, Type)
import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import GHC.TypeNats (Nat)

-- | Domain identifiers for MEU triplet domains
data DomainId = ModelDomain | ExecutionDomain | UpdateDomain
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

-- | Proxy type for domain identification at type level
data DomainProxy (d :: DomainId) = DomainProxy
  deriving stock (Show, Eq, Ord, Generic)

-- | Unique identifier for MEU triplets
newtype TripletId = TripletId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for type definitions
newtype TypeId = TypeId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for typed values
newtype ValueId = ValueId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for DSL primitives
newtype DSLPrimitiveId = DSLPrimitiveId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for tests
newtype TestId = TestId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for axioms
newtype AxiomId = AxiomId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Unique identifier for dataflow arrows
newtype ArrowId = ArrowId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Additional identifier types for complete MEU system
newtype SpecificationId = SpecificationId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype ModelId = ModelId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype ChannelId = ChannelId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype EvaluatorId = EvaluatorId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype VerifierId = VerifierId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype CriteriaId = CriteriaId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype PolicyId = PolicyId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype PredicateId = PredicateId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype ConstantId = ConstantId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype SortId = SortId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype FunctionId = FunctionId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype RelationId = RelationId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype CompositionId = CompositionId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype PlanId = PlanId UUID
  deriving stock (Show, Eq, Ord, Generic)
  deriving newtype (ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

-- | Metadata for MEU triplets
data TripletMetadata = TripletMetadata
  { metaCreatedAt    :: !UTCTime
  , metaUpdatedAt    :: !UTCTime
  , metaVersion      :: !Version
  , metaDescription  :: !Text
  , metaParentId     :: !(Maybe TripletId)
  , metaChildren     :: ![TripletId]
  , metaSiblings     :: ![TripletId]
  , metaDepth        :: !Int
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for dataflow arrows
data ArrowMetadata = ArrowMetadata
  { arrowCreatedAt     :: !UTCTime
  , arrowUpdatedAt     :: !UTCTime
  , arrowDescription   :: !Text
  , arrowPerformance   :: !(Maybe Text) -- Performance metrics as JSON
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for type definitions
data TypeMetadata = TypeMetadata
  { typeCreatedAt    :: !UTCTime
  , typeUpdatedAt    :: !UTCTime
  , typeDescription  :: !Text
  , typeUsageCount   :: !Int
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for typed values
data ValueMetadata = ValueMetadata
  { valueCreatedAt   :: !UTCTime
  , valueSource      :: !Text -- Where the value originated
  , valueValidated   :: !Bool
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for DSL primitives
data PrimitiveMetadata = PrimitiveMetadata
  { primitiveCreatedAt     :: !UTCTime
  , primitiveUpdatedAt     :: !UTCTime
  , primitiveDescription   :: !Text
  , primitiveUsageCount    :: !Int
  , primitivePerformance   :: !(Maybe Text)
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for acceptance criteria
data CriteriaMetadata = CriteriaMetadata
  { criteriaCreatedAt    :: !UTCTime
  , criteriaUpdatedAt    :: !UTCTime
  , criteriaPriority     :: !Int
  , criteriaSource       :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for geometric axioms
data AxiomMetadata = AxiomMetadata
  { axiomCreatedAt     :: !UTCTime
  , axiomSource        :: !Text
  , axiomPriority      :: !Int
  , axiomVerified      :: !Bool
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Metadata for geometric theories
data TheoryMetadata = TheoryMetadata
  { theoryCreatedAt    :: !UTCTime
  , theoryUpdatedAt    :: !UTCTime
  , theoryDescription  :: !Text
  , theoryVersion      :: !Version
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | MEU triplet state
data TripletState
  = Initializing
  | Active
  | Refining
  | Coarsening
  | Suspended
  | Merged
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | MEU triplet type
data TripletType = SourceTriplet | BranchTriplet | LeafTriplet
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Consistency status for geometric theories
data ConsistencyStatus
  = Consistent
  | Inconsistent
  | Unknown
  | Checking
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Test type hierarchy
data TestType
  = TypeTest        -- Value-validating unit test
  | ExecutionTest   -- Unit/integration test
  | FormulaTest     -- Acceptance criteria test
  | AxiomTest       -- Coherence test
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Refinement level for type-level depth tracking
data RefinementLevel = RootLevel | BranchLevel Nat | LeafLevel
  deriving stock (Show, Eq, Generic)

-- | Main error type for MEU operations
data MEUError
  = TripletNotFoundError !TripletId !Text
  | InclusionViolationError !Text !Text
  | AxiomInconsistencyError !Text !Text
  | ConcurrencyError !ConcurrencyError !Text
  | ResourceExhaustionError !Text !Int !Int
  | ValidationError !ValidationError
  | VerificationError !VerificationError
  | ParseError !Text
  | SerializationError !Text
  | ConfigurationError !Text
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Validation-specific errors
data ValidationError
  = InvalidTypeSignature !Text
  | InvalidValue !ValueId !Text
  | InvalidTripletStructure !TripletId !Text
  | InvalidInclusionMapping !Text
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Concurrency-specific errors
data ConcurrencyError
  = STMConflict !Text
  | DeadlockDetected !Text
  | ResourceLocked !Text
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Verification-specific errors
data VerificationError
  = SMTSolverTimeout !Int
  | SMTSolverError !Text
  | FormulaParseError !Text
  | UnsatisfiableFormula !Text
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

-- | Version information
data Version = Version
  { versionMajor :: !Int
  , versionMinor :: !Int
  , versionPatch :: !Int
  } deriving stock (Show, Eq, Ord, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Type alias for timestamps
type Timestamp = UTCTime

-- | Type family for inclusion validation constraints
type family InclusionValid (child :: DomainId) (parent :: DomainId) :: Constraint where
  InclusionValid 'ModelDomain 'ModelDomain = ()
  InclusionValid 'ExecutionDomain 'ExecutionDomain = ()
  InclusionValid 'UpdateDomain 'UpdateDomain = ()
  InclusionValid _ _ = () -- Allow cross-domain inclusions with explicit validation

-- | Type family for refinement depth tracking
type family RefinementDepth (l :: RefinementLevel) :: Nat where
  RefinementDepth 'RootLevel = 0
  RefinementDepth ('BranchLevel n) = n
  RefinementDepth 'LeafLevel = 10 -- Maximum depth

-- | Type family for domain-specific constraints
type family DomainConstraint (d :: DomainId) :: Type -> Constraint where
  DomainConstraint 'ModelDomain = Show
  DomainConstraint 'ExecutionDomain = Show
  DomainConstraint 'UpdateDomain = Show

-- | Re-export Proxy for convenience
data Proxy (a :: k) = Proxy
  deriving stock (Show, Eq, Ord, Generic)