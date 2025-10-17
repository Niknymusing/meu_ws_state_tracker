-- |
-- Module      : MEU.Core.Triplet
-- Description : MEU triplet GADT implementation with type-safe domains
-- Copyright   : (c) MEU Framework Team, 2025
-- License     : MIT
-- Maintainer  : team@meu-framework.org
--
-- This module defines the core MEU triplet data structure using GADTs for
-- type-safe domain handling and phantom types for compile-time validation.

module MEU.Core.Triplet
  ( -- * MEU Triplet Types
    MEUTriplet (..)
  , TripletDomains (..)
  , TripletDomain (..)

    -- * Domain State Types
  , ModelState (..)
  , ExecutionState (..)
  , UpdateState (..)

    -- * Related Types
  , ExecutionEnvironment (..)
  , DeployedModel (..)
  , LoggingConfiguration (..)
  , ResourceAllocation (..)
  , FeedbackChannel (..)
  , Evaluator (..)
  , Verifier (..)
  , UpdatePolicy (..)
  , Specification (..)

    -- * Smart Constructors
  , mkModelDomain
  , mkExecutionDomain
  , mkUpdateDomain
  , mkMEUTriplet

    -- * Accessors
  , getTripletId
  , getTripletType
  , getTripletDomains
  , getDomainState

    -- * Validation
  , validateTripletStructure
  , validateDomainInclusion
  ) where

import Data.Aeson (FromJSON, ToJSON, parseJSON, toJSON)
import Data.Kind (Type)
import Data.Map.Strict (Map)
import Data.Set (Set)
import Data.Text (Text)
import GHC.Generics (Generic)

import MEU.Core.Types

-- | Core MEU triplet data structure with monadic computation capability
data MEUTriplet (m :: Type -> Type) = MEUTriplet
  { tripletId                :: !TripletId
  , tripletType              :: !TripletType
  , tripletMetadata          :: !TripletMetadata
  , tripletDomains           :: !(TripletDomains m)
  , tripletAcceptanceCriteria :: !AcceptanceCriteria
  , tripletInclusions        :: !InclusionMap
  , tripletState             :: !TripletState
  } deriving stock (Generic)

-- | Container for all three MEU domains
data TripletDomains (m :: Type -> Type) = TripletDomains
  { domainModel     :: !(TripletDomain m 'ModelDomain)
  , domainExecution :: !(TripletDomain m 'ExecutionDomain)
  , domainUpdate    :: !(TripletDomain m 'UpdateDomain)
  } deriving stock (Generic)

-- | Type-safe domain representation using GADTs and phantom types
data TripletDomain (m :: Type -> Type) (d :: DomainId) where
  ModelDom     :: !ModelState -> TripletDomain m 'ModelDomain
  ExecutionDom :: !ExecutionState -> TripletDomain m 'ExecutionDomain
  UpdateDom    :: !UpdateState -> TripletDomain m 'UpdateDomain

-- | State for the Model domain
data ModelState = ModelState
  { modelSpecifications :: !(Map SpecificationId Specification)
  , modelDSLPrimitives  :: !(Map DSLPrimitiveId DSLPrimitive)
  , modelTypes          :: !(Map TypeId TypeDefinition)
  , modelValues         :: !(Map ValueId TypedValue)
  , modelTests          :: !(Map TestId TestDefinition)
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | State for the Execution domain
data ExecutionState = ExecutionState
  { execEnvironment       :: !ExecutionEnvironment
  , execDeployedModels    :: !(Map ModelId DeployedModel)
  , execLoggingConfig     :: !LoggingConfiguration
  , execResourceAllocation :: !ResourceAllocation
  , execFeedbackChannels  :: !(Map ChannelId FeedbackChannel)
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | State for the Update domain
data UpdateState = UpdateState
  { updateEvaluators        :: !(Map EvaluatorId Evaluator)
  , updateVerifiers         :: !(Map VerifierId Verifier)
  , updateGeometricTheory   :: !GeometricTheory
  , updateAcceptanceCriteria :: !(Map CriteriaId AcceptanceCriterion)
  , updatePolicies          :: !(Map PolicyId UpdatePolicy)
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- Placeholder types for complete type definitions
-- These will be properly implemented in their respective modules

-- | Execution environment configuration
data ExecutionEnvironment = ExecutionEnvironment
  { envName        :: !Text
  , envDescription :: !Text
  , envConfig      :: !Text -- JSON configuration
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Deployed model in execution environment
data DeployedModel = DeployedModel
  { deployedModelId   :: !ModelId
  , deployedAt        :: !Timestamp
  , deployedConfig    :: !Text
  , deployedStatus    :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Logging configuration for execution environment
data LoggingConfiguration = LoggingConfiguration
  { logLevel       :: !Text
  , logDestination :: !Text
  , logFormat      :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Resource allocation for execution
data ResourceAllocation = ResourceAllocation
  { allocatedCPU    :: !Int
  , allocatedMemory :: !Int
  , allocatedStorage :: !Int
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Feedback channel from execution environment
data FeedbackChannel = FeedbackChannel
  { channelType :: !Text
  , channelConfig :: !Text
  , channelActive :: !Bool
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Evaluator in update domain
data Evaluator = Evaluator
  { evaluatorName :: !Text
  , evaluatorType :: !Text
  , evaluatorConfig :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Verifier in update domain
data Verifier = Verifier
  { verifierName :: !Text
  , verifierType :: !Text
  , verifierConfig :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Update policy for model updates
data UpdatePolicy = UpdatePolicy
  { policyName :: !Text
  , policyRules :: !Text
  , policyActive :: !Bool
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Specification in model domain
data Specification = Specification
  { specName :: !Text
  , specContent :: !Text
  , specVersion :: !Version
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- Forward declarations for types defined in other modules
data AcceptanceCriteria
data InclusionMap
data GeometricTheory
data AcceptanceCriterion
data DSLPrimitive
data TypeDefinition
data TypedValue
data TestDefinition

-- Derive Show instances for GADT
deriving stock instance Show (TripletDomain m d)
deriving stock instance Eq (TripletDomain m d)

-- Custom instances for MEUTriplet that handle the GADT properly
instance Show (MEUTriplet m) where
  show (MEUTriplet tid ttype _ _ _ _ tstate) =
    "MEUTriplet { tripletId = " <> show tid <>
    ", tripletType = " <> show ttype <>
    ", tripletState = " <> show tstate <> " }"

-- | Smart constructor for Model domain
mkModelDomain :: ModelState -> TripletDomain m 'ModelDomain
mkModelDomain = ModelDom

-- | Smart constructor for Execution domain
mkExecutionDomain :: ExecutionState -> TripletDomain m 'ExecutionDomain
mkExecutionDomain = ExecutionDom

-- | Smart constructor for Update domain
mkUpdateDomain :: UpdateState -> TripletDomain m 'UpdateDomain
mkUpdateDomain = UpdateDom

-- | Smart constructor for MEU triplet
mkMEUTriplet
  :: TripletId
  -> TripletType
  -> TripletMetadata
  -> TripletDomains m
  -> AcceptanceCriteria
  -> InclusionMap
  -> TripletState
  -> MEUTriplet m
mkMEUTriplet = MEUTriplet

-- | Get triplet ID
getTripletId :: MEUTriplet m -> TripletId
getTripletId = tripletId

-- | Get triplet type
getTripletType :: MEUTriplet m -> TripletType
getTripletType = tripletType

-- | Get triplet domains
getTripletDomains :: MEUTriplet m -> TripletDomains m
getTripletDomains = tripletDomains

-- | Extract domain state from GADT
getDomainState :: TripletDomain m d -> DomainState d
getDomainState = \case
  ModelDom state     -> state
  ExecutionDom state -> state
  UpdateDom state    -> state

-- | Type family for domain state extraction
type family DomainState (d :: DomainId) where
  DomainState 'ModelDomain = ModelState
  DomainState 'ExecutionDomain = ExecutionState
  DomainState 'UpdateDomain = UpdateState

-- | Validate triplet structure
validateTripletStructure :: MEUTriplet m -> Either MEUError ()
validateTripletStructure triplet = do
  -- Check that triplet type matches hierarchy constraints
  case (getTripletType triplet, metaParentId (tripletMetadata triplet)) of
    (SourceTriplet, Just _) -> Left $ ValidationError $ InvalidTripletStructure (getTripletId triplet) "Source triplet cannot have parent"
    (SourceTriplet, Nothing) -> Right ()
    (BranchTriplet, Nothing) -> Left $ ValidationError $ InvalidTripletStructure (getTripletId triplet) "Branch triplet must have parent"
    (LeafTriplet, Nothing) -> Left $ ValidationError $ InvalidTripletStructure (getTripletId triplet) "Leaf triplet must have parent"
    _ -> Right ()

-- | Validate domain inclusion relationships
validateDomainInclusion :: TripletDomain m d -> TripletDomain m d -> Either MEUError ()
validateDomainInclusion _child _parent = Right () -- Placeholder implementation

-- Placeholder instances to satisfy type checker
instance ToJSON AcceptanceCriteria where
  toJSON _ = error "AcceptanceCriteria ToJSON not implemented yet"

instance FromJSON AcceptanceCriteria where
  parseJSON _ = error "AcceptanceCriteria FromJSON not implemented yet"

instance Show AcceptanceCriteria where
  show _ = "AcceptanceCriteria"

instance Eq AcceptanceCriteria where
  _ == _ = True

instance ToJSON InclusionMap where
  toJSON _ = error "InclusionMap ToJSON not implemented yet"

instance FromJSON InclusionMap where
  parseJSON _ = error "InclusionMap FromJSON not implemented yet"

instance Show InclusionMap where
  show _ = "InclusionMap"

instance Eq InclusionMap where
  _ == _ = True

instance ToJSON GeometricTheory where
  toJSON _ = error "GeometricTheory ToJSON not implemented yet"

instance FromJSON GeometricTheory where
  parseJSON _ = error "GeometricTheory FromJSON not implemented yet"

instance Show GeometricTheory where
  show _ = "GeometricTheory"

instance Eq GeometricTheory where
  _ == _ = True

instance ToJSON AcceptanceCriterion where
  toJSON _ = error "AcceptanceCriterion ToJSON not implemented yet"

instance FromJSON AcceptanceCriterion where
  parseJSON _ = error "AcceptanceCriterion FromJSON not implemented yet"

instance Show AcceptanceCriterion where
  show _ = "AcceptanceCriterion"

instance Eq AcceptanceCriterion where
  _ == _ = True

instance ToJSON DSLPrimitive where
  toJSON _ = error "DSLPrimitive ToJSON not implemented yet"

instance FromJSON DSLPrimitive where
  parseJSON _ = error "DSLPrimitive FromJSON not implemented yet"

instance Show DSLPrimitive where
  show _ = "DSLPrimitive"

instance Eq DSLPrimitive where
  _ == _ = True

instance ToJSON TypeDefinition where
  toJSON _ = error "TypeDefinition ToJSON not implemented yet"

instance FromJSON TypeDefinition where
  parseJSON _ = error "TypeDefinition FromJSON not implemented yet"

instance Show TypeDefinition where
  show _ = "TypeDefinition"

instance Eq TypeDefinition where
  _ == _ = True

instance ToJSON TypedValue where
  toJSON _ = error "TypedValue ToJSON not implemented yet"

instance FromJSON TypedValue where
  parseJSON _ = error "TypedValue FromJSON not implemented yet"

instance Show TypedValue where
  show _ = "TypedValue"

instance Eq TypedValue where
  _ == _ = True

instance ToJSON TestDefinition where
  toJSON _ = error "TestDefinition ToJSON not implemented yet"

instance FromJSON TestDefinition where
  parseJSON _ = error "TestDefinition FromJSON not implemented yet"

instance Show TestDefinition where
  show _ = "TestDefinition"

instance Eq TestDefinition where
  _ == _ = True