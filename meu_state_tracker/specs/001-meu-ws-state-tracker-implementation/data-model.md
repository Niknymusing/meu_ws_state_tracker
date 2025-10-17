# Data Model: MEU System Workspace State Tracker

**Feature**: MEU System Workspace State Tracker
**Created**: 2025-10-17
**Status**: Phase 1 Design

## Core Entities Overview

The MEU System Workspace State Tracker manages a complex hierarchy of interconnected entities that implement the Model-Execute-Update framework. The data model is designed for type safety, concurrent access, and efficient operation with 1000+ interconnected triplets.

## 1. MEU Triplet Structure

### MEUTriplet
**Purpose**: Core data structure representing a Model-Execute-Update triplet with three monadic domains

```haskell
data MEUTriplet (m :: * -> *) = MEUTriplet
  { tripletId :: TripletId
  , tripletType :: TripletType
  , tripletMetadata :: TripletMetadata
  , tripletDomains :: TripletDomains m
  , tripletArrows :: DataflowArrows m
  , tripletAcceptanceCriteria :: AcceptanceCriteria
  , tripletInclusions :: InclusionMap
  , tripletState :: TripletState
  }

data TripletType = SourceTriplet | BranchTriplet | LeafTriplet
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)

newtype TripletId = TripletId UUID
  deriving (Show, Eq, Ord, Hashable, Generic, ToJSON, FromJSON)

data TripletMetadata = TripletMetadata
  { metaCreatedAt :: UTCTime
  , metaUpdatedAt :: UTCTime
  , metaVersion :: Version
  , metaDescription :: Text
  , metaParentId :: Maybe TripletId
  , metaChildren :: Set TripletId
  , metaSiblings :: Set TripletId
  , metaDepth :: Int
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

**Validation Rules**:
- `tripletId` must be globally unique within MEU system
- `tripletType` determines hierarchy constraints (SourceTriplet has no parent, LeafTriplet has no children)
- `metaDepth` must be consistent with actual hierarchy position
- `metaParentId` and `metaChildren` must form valid tree structure

**State Transitions**:
- `Initializing` → `Active` → `Refining` → `Active` (refinement cycle)
- `Active` → `Coarsening` → `Merged` (coarsening cycle)
- `Active` → `Suspended` → `Active` (temporary suspension)

### TripletDomains
**Purpose**: Type-safe container for the three monadic domains (M, E, U) of a MEU triplet

```haskell
data TripletDomains (m :: * -> *) = TripletDomains
  { domainModel :: TripletDomain m 'ModelDomain
  , domainExecution :: TripletDomain m 'ExecutionDomain
  , domainUpdate :: TripletDomain m 'UpdateDomain
  } deriving (Generic)

data DomainId = ModelDomain | ExecutionDomain | UpdateDomain
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)

data TripletDomain (m :: * -> *) (d :: DomainId) where
  ModelDom :: ModelState -> TripletDomain m 'ModelDomain
  ExecDom :: ExecutionState -> TripletDomain m 'ExecutionDomain
  UpdateDom :: UpdateState -> TripletDomain m 'UpdateDomain

data ModelState = ModelState
  { modelSpecifications :: Map SpecificationId Specification
  , modelDSLPrimitives :: Map DSLPrimitiveId DSLPrimitive
  , modelTypes :: Map TypeId TypeDefinition
  , modelValues :: Map ValueId TypedValue
  , modelTests :: Map TestId TestDefinition
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data ExecutionState = ExecutionState
  { execEnvironment :: ExecutionEnvironment
  , execDeployedModels :: Map ModelId DeployedModel
  , execLoggingConfig :: LoggingConfiguration
  , execResourceAllocation :: ResourceAllocation
  , execFeedbackChannels :: Map ChannelId FeedbackChannel
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data UpdateState = UpdateState
  { updateEvaluators :: Map EvaluatorId Evaluator
  , updateVerifiers :: Map VerifierId Verifier
  , updateGeometricTheory :: GeometricTheory
  , updateAcceptanceCriteria :: Map CriteriaId AcceptanceCriterion
  , updatePolicies :: Map PolicyId UpdatePolicy
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

**Relationships**:
- Each domain contains domain-specific state and functionality
- Domains communicate through DataflowArrows (defined below)
- State changes must maintain monad laws and type safety

## 2. Dataflow Arrow System

### DataflowArrows
**Purpose**: Type-safe morphisms managing data flow between MEU triplet domains

```haskell
data DataflowArrows (m :: * -> *) = DataflowArrows
  { arrowsModelToExec :: ArrowCollection 'ModelDomain 'ExecutionDomain m
  , arrowsExecToModel :: ArrowCollection 'ExecutionDomain 'ModelDomain m
  , arrowsExecToUpdate :: ArrowCollection 'ExecutionDomain 'UpdateDomain m
  , arrowsUpdateToExec :: ArrowCollection 'UpdateDomain 'ExecutionDomain m
  , arrowsUpdateToModel :: ArrowCollection 'UpdateDomain 'ModelDomain m
  , arrowsModelToUpdate :: ArrowCollection 'ModelDomain 'UpdateDomain m
  } deriving (Generic)

data ArrowCollection (from :: DomainId) (to :: DomainId) (m :: * -> *) = ArrowCollection
  { collectionArrows :: Map ArrowId (DataflowArrow from to m)
  , collectionCompositions :: Map CompositionId (ArrowComposition from to m)
  , collectionMetrics :: ArrowMetrics
  } deriving (Generic)

data DataflowArrow (from :: DomainId) (to :: DomainId) (m :: * -> *) = DataflowArrow
  { arrowId :: ArrowId
  , arrowFunction :: TypedValue -> m (Either MEUError TypedValue)
  , arrowInputType :: TypeSignature
  , arrowOutputType :: TypeSignature
  , arrowConstraints :: [ArrowConstraint]
  , arrowMetadata :: ArrowMetadata
  }

newtype ArrowId = ArrowId UUID
  deriving (Show, Eq, Ord, Hashable, Generic, ToJSON, FromJSON)
```

**Validation Rules**:
- Arrow input/output types must be compatible with source/target domains
- Composed arrows must maintain type compatibility throughout chain
- Each arrow must have unique identity map within collection
- Arrow constraints must be satisfiable within target domain

## 3. Registry System

### WSStateTracker
**Purpose**: Central orchestrator maintaining all registries and coordinating MEU system evolution

```haskell
data WSStateTracker = WSStateTracker
  { trackerRegistries :: SystemRegistries
  , trackerTriplets :: TVar (Map TripletId (TVar (MEUTriplet IO)))
  , trackerTopology :: TVar SystemTopology
  , trackerConfig :: TrackerConfiguration
  , trackerMetrics :: TVar SystemMetrics
  , trackerChangeLog :: TVar [SystemChange]
  } deriving (Generic)

data SystemRegistries = SystemRegistries
  { registryTypes :: ConcurrentRegistry TypeId TypeDefinition
  , registryValues :: ConcurrentRegistry ValueId TypedValue
  , registryDSLPrimitives :: ConcurrentRegistry DSLPrimitiveId DSLPrimitive
  , registryTests :: ConcurrentRegistry TestId TestDefinition
  , registryAxioms :: ConcurrentRegistry AxiomId GeometricAxiom
  , registryTriplets :: ConcurrentRegistry TripletId TripletSummary
  } deriving (Generic)

data ConcurrentRegistry k v = ConcurrentRegistry
  { registryEntries :: TVar (Map k v)
  , registryShards :: Vector (TVar (Map k v))
  , registryBloomFilter :: TVar BloomFilter
  , registryMetrics :: TVar RegistryMetrics
  , registryLocks :: Vector (TMVar ())
  } deriving (Generic)
```

**Concurrent Access Pattern**:
- Each registry uses STM for atomic operations
- Sharding reduces contention for high-throughput scenarios
- Bloom filters provide fast negative lookups
- Lock-free operations ensure system responsiveness

### Registry Entities

#### TypeDefinition
```haskell
data TypeDefinition = TypeDefinition
  { typeId :: TypeId
  , typeName :: Text
  , typeSignature :: TypeSignature
  , typeValidators :: [TypeValidator]
  , typeConstructors :: [TypeConstructor]
  , typeDestructors :: [TypeDestructor]
  , typeMetadata :: TypeMetadata
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data TypeSignature
  = BaseType Text
  | ProductType [TypeSignature]
  | SumType [TypeSignature]
  | FunctionType TypeSignature TypeSignature
  | ForallType Text TypeSignature
  | ExistsType Text TypeSignature
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)
```

#### DSLPrimitive
```haskell
data DSLPrimitive = DSLPrimitive
  { primitiveId :: DSLPrimitiveId
  , primitiveName :: Text
  , primitiveFunction :: TypedValue -> IO (Either MEUError TypedValue)
  , primitiveInputType :: TypeSignature
  , primitiveOutputType :: TypeSignature
  , primitiveDescription :: Text
  , primitiveDomain :: DomainId
  , primitiveMetadata :: PrimitiveMetadata
  } deriving (Generic)
```

#### TestDefinition
```haskell
data TestDefinition = TestDefinition
  { testId :: TestId
  , testName :: Text
  , testType :: TestType
  , testInputs :: [TypedValue]
  , testExpectedOutput :: TestExpectation
  , testPreconditions :: [TestCondition]
  , testPostconditions :: [TestCondition]
  , testTimeout :: NominalDiffTime
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data TestType
  = TypeTest        -- Value-validating unit test
  | ExecutionTest   -- Unit/integration test
  | FormulaTest     -- Acceptance criteria test
  | AxiomTest       -- Coherence test
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)
```

## 4. Geometric Logic System

### GeometricTheory
**Purpose**: First-order logic system with axioms for acceptance criteria verification

```haskell
data GeometricTheory = GeometricTheory
  { theoryVocabulary :: Vocabulary
  , theoryAxioms :: Set GeometricAxiom
  , theoryRelations :: Map RelationId LogicalRelation
  , theoryConsistency :: ConsistencyStatus
  , theoryMetadata :: TheoryMetadata
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data Vocabulary = Vocabulary
  { vocabSorts :: Map SortId Sort
  , vocabFunctions :: Map FunctionId FunctionSymbol
  , vocabRelations :: Map RelationId RelationSymbol
  , vocabConstants :: Map ConstantId Constant
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data GeometricAxiom = GeometricAxiom
  { axiomId :: AxiomId
  , axiomPremise :: GeometricFormula
  , axiomConclusion :: GeometricFormula
  , axiomContext :: [TypedVariable]
  , axiomMetadata :: AxiomMetadata
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data GeometricFormula
  = Atom LogicalRelation
  | And GeometricFormula GeometricFormula
  | Or [GeometricFormula]
  | Exists TypedVariable GeometricFormula
  | Truth
  | Falsity
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)

data LogicalRelation
  = Equals TypedValue TypedValue
  | LessThan TypedValue TypedValue
  | GreaterThan TypedValue TypedValue
  | ElementOf TypedValue TypedValue
  | Predicate PredicateId [TypedValue]
  deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)
```

**Validation Rules**:
- All axioms must be well-formed geometric sequents
- Vocabulary must be consistent across theory
- SMT solver must verify theory consistency before axiom addition
- Variables in formulas must have declared types

## 5. Transform Operations

### RefinementResult
**Purpose**: Result of MEU triplet refinement operation

```haskell
data RefinementResult = RefinementResult
  { refinementParent :: TripletId
  , refinementChildren :: [MEUTriplet IO]
  , refinementInclusions :: Map TripletId InclusionMap
  , refinementArrows :: Map TripletId (DataflowArrows IO)
  , refinementMetrics :: RefinementMetrics
  } deriving (Generic)

data InclusionMap = InclusionMap
  { inclusionModel :: InclusionRelation 'ModelDomain
  , inclusionExecution :: InclusionRelation 'ExecutionDomain
  , inclusionUpdate :: InclusionRelation 'UpdateDomain
  } deriving (Generic)

data InclusionRelation (d :: DomainId) = InclusionRelation
  { inclusionMapping :: Map ValueId ValueId
  , inclusionConstraints :: [InclusionConstraint d]
  , inclusionVerified :: Bool
  } deriving (Generic)
```

### CoarseningResult
**Purpose**: Result of MEU triplet coarsening operation

```haskell
data CoarseningResult = CoarseningResult
  { coarseningTarget :: TripletId
  , coarseningCollapsed :: [TripletId]
  , coarseningConsolidated :: MEUTriplet IO
  , coarseningPreserved :: Map TripletId PreservationSpec
  , coarseningMetrics :: CoarseningMetrics
  } deriving (Generic)
```

## 6. Hypergraph Structures

### ValueMergeHyperGraph
**Purpose**: Efficient representation for value composition through type construction

```haskell
data ValueMergeHyperGraph = ValueMergeHyperGraph
  { vmhgAdjacencyMatrix :: SparseMatrix Bool
  , vmhgValueIndex :: HashMap ValueId Int
  , vmhgSignatureIndex :: HashMap TypeSignature [Int]
  , vmhgConstructors :: Vector TypeConstructor
  , vmhgCompositions :: Map CompositionId CompositionRule
  } deriving (Generic)

data CompositionRule = CompositionRule
  { ruleInputValues :: [ValueId]
  , ruleConstructor :: TypeConstructor
  , ruleOutputType :: TypeId
  , ruleConstraints :: [CompositionConstraint]
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

### FunctionExecutionHyperGraph
**Purpose**: Tracking composable DSL primitives for execution planning

```haskell
data FunctionExecutionHyperGraph = FunctionExecutionHyperGraph
  { fehgDependencyMatrix :: SparseMatrix Bool
  , fehgFunctionIndex :: HashMap DSLPrimitiveId Int
  , fehgInputMask :: Vector (BitSet ValueId)
  , fehgOutputTypes :: Vector TypeId
  , fehgExecutionPlans :: Map PlanId ExecutionPlan
  } deriving (Generic)

data ExecutionPlan = ExecutionPlan
  { planSteps :: Vector ExecutionStep
  , planParallelizable :: [ParallelGroup]
  , planEstimatedTime :: NominalDiffTime
  , planResourceRequirements :: ResourceRequirements
  } deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

## Entity Relationships Summary

```
MEUTriplet (1:1) -> TripletDomains
TripletDomains (1:3) -> TripletDomain[M,E,U]
MEUTriplet (1:1) -> DataflowArrows
DataflowArrows (1:6) -> ArrowCollection[M->E,E->M,E->U,U->E,U->M,M->U]
WSStateTracker (1:1) -> SystemRegistries
SystemRegistries (1:6) -> ConcurrentRegistry[Types,Values,DSL,Tests,Axioms,Triplets]
MEUTriplet (1:1) -> AcceptanceCriteria
AcceptanceCriteria (1:N) -> GeometricAxiom
GeometricAxiom (1:1) -> GeometricTheory
ValueMergeHyperGraph (N:M) -> TypedValue (composition relationships)
FunctionExecutionHyperGraph (N:M) -> DSLPrimitive (execution dependencies)
```

This data model provides a complete foundation for implementing the MEU System Workspace State Tracker with type safety, concurrent access patterns, and efficient operations for large-scale MEU systems.