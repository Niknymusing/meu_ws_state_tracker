{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TemplateHaskell #-}

module MEU.Core.Types
  ( -- * Core Type System
    MEUType(..)
  , BaseType(..)
  , TypeConstructor(..)
  , TypeSignature(..)

    -- * Domain Types
  , DomainId(..)
  , Domain(..)

    -- * MEU Triplet Identifiers
  , TripletId(..)
  , TripletType(..)

    -- * Task and Ticket Types
  , TaskId(..)
  , TicketId(..)
  , Task(..)
  , Ticket(..)

    -- * Acceptance Criteria
  , AcceptanceCriteria(..)
  , GeometricFormula(..)
  , LogicalRelation(..)
  , Axiom(..)

    -- * Test Types
  , TestId(..)
  , TestType(..)
  , TestStatus(..)
  , Test(..)

    -- * Utility Types
  , Timestamp(..)
  , MEUError(..)
  ) where

import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import GHC.Generics (Generic)

-- | Core type system for MEU framework DSL
data MEUType
  = BaseType BaseType
  | ProductType MEUType MEUType        -- (×, ∧)
  | SumType MEUType MEUType           -- (+, ∨)
  | FunctionType MEUType MEUType      -- (→, ⇒)
  | UnitType                          -- (1, ⊤)
  | BottomType                        -- (0, ⊥)
  | NegationType MEUType              -- (¬A := A → ⊥)
  deriving (Eq, Show, Generic)

-- | Base types for MEU framework domains
data BaseType
  = StringType
  | IntType
  | BoolType
  | FloatType
  | ModelType
  | ExecutionType
  | UpdateType
  | ValueType
  | TestType
  | VerifierType
  | CustomType Text
  deriving (Eq, Show, Generic)

-- | Type constructors for building complex types
data TypeConstructor
  = Product
  | Sum
  | Function
  | Unit
  | Bottom
  | Negation
  deriving (Eq, Show, Generic)

-- | Type signature for DSL primitives
data TypeSignature = TypeSignature
  { inputTypes :: [MEUType]
  , outputType :: MEUType
  , constraints :: [Text]
  } deriving (Eq, Show, Generic)

-- | Domain identifier for M, E, U domains
data DomainId
  = ModelDomain
  | ExecutionDomain
  | UpdateDomain
  deriving (Eq, Show, Ord, Generic)

-- | Domain representation with type information
data Domain = Domain
  { domainId :: DomainId
  , domainTypes :: [MEUType]
  , domainConstraints :: [Text]
  } deriving (Eq, Show, Generic)

-- | Unique identifier for MEU triplets
newtype TripletId = TripletId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Type of MEU triplet in the system tree
data TripletType
  = SourceTriplet     -- τ0 - root triplet from project specification
  | BranchTriplet     -- top-down managing subtriplets
  | LeafTriplet       -- bottom-up operating in execution environment
  deriving (Eq, Show, Generic)

-- | Task identifier
newtype TaskId = TaskId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Ticket identifier
newtype TicketId = TicketId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Task specification
data Task = Task
  { taskId :: TaskId
  , taskDescription :: Text
  , taskSpecification :: Text
  , taskDependencies :: [TaskId]
  , taskStatus :: TestStatus
  , taskCreated :: Timestamp
  , taskUpdated :: Timestamp
  } deriving (Eq, Show, Generic)

-- | Ticket for implementation within MEU system
data Ticket = Ticket
  { ticketId :: TicketId
  , ticketTask :: TaskId
  , ticketTriplet :: TripletId
  , ticketSpecification :: Text
  , ticketAcceptanceCriteria :: [AcceptanceCriteria]
  , ticketStatus :: TestStatus
  , ticketCreated :: Timestamp
  , ticketUpdated :: Timestamp
  } deriving (Eq, Show, Generic)

-- | Acceptance criteria for development lifecycle verification
data AcceptanceCriteria = AcceptanceCriteria
  { criteriaId :: Text
  , criteriaDescription :: Text
  , criteriaFormulas :: [GeometricFormula]
  , criteriaAxioms :: [Axiom]
  , criteriaTestIds :: [TestId]
  } deriving (Eq, Show, Generic)

-- | Geometric logic formula for first-order geometric theory
data GeometricFormula = GeometricFormula
  { formulaVariables :: [(Text, MEUType)]
  , formulaConstraints :: [LogicalRelation]
  , formulaConclusion :: LogicalRelation
  } deriving (Eq, Show, Generic)

-- | Logical relations for geometric formulas
data LogicalRelation
  = Equals Text Text
  | GreaterThan Text Text
  | LessThan Text Text
  | GreaterEquals Text Text
  | LessEquals Text Text
  | And LogicalRelation LogicalRelation
  | Or LogicalRelation LogicalRelation
  | Not LogicalRelation
  | Exists Text MEUType LogicalRelation
  | ForAll Text MEUType LogicalRelation
  | Truth
  | Falsehood
  | CustomRelation Text [Text]
  deriving (Eq, Show, Generic)

-- | Axiom as sequent between formulas
data Axiom = Axiom
  { axiomId :: Text
  , axiomPremise :: GeometricFormula
  , axiomConclusion :: GeometricFormula
  , axiomDescription :: Text
  } deriving (Eq, Show, Generic)

-- | Test identifier
newtype TestId = TestId UUID
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Test type in hierarchy pyramid
data TestType
  = TypeTest          -- (i) Value-validating unit tests
  | ExecutionTest     -- (ii) Unit/integration tests of code modules
  | AcceptanceTest    -- (iii) E2E tests against acceptance criteria
  | AxiomCoherenceTest -- (iv) SMT verification of geometric theory
  | IntegrationMergeTest -- Integration of modular DSL functions
  deriving (Eq, Show, Generic)

-- | Test execution status
data TestStatus
  = Pending
  | InProgress
  | Passed
  | Failed Text
  | Blocked Text
  deriving (Eq, Show, Generic)

-- | Test specification and execution
data Test = Test
  { testId :: TestId
  , testType :: TestType
  , testDescription :: Text
  , testTripletId :: TripletId
  , testDomainId :: DomainId
  , testInputSignature :: TypeSignature
  , testOutputSignature :: TypeSignature
  , testStatus :: TestStatus
  , testCreated :: Timestamp
  , testLastRun :: Maybe Timestamp
  , testError :: Maybe Text
  } deriving (Eq, Show, Generic)

-- | Timestamp wrapper
newtype Timestamp = Timestamp UTCTime
  deriving (Eq, Show, Ord, Generic)
  deriving newtype (Read)

-- | Error types for MEU system
data MEUError
  = TypeMismatchError Text
  | DomainInclusionError Text
  | AxiomInconsistencyError Text
  | RefinementError Text
  | CoarseningError Text
  | RegistryError Text
  | IOError Text
  | UnknownError Text
  deriving (Eq, Show, Generic)