---
description: "MEU System Workspace State Tracker implementation tasks"
---

# Tasks: MEU System Workspace State Tracker

**Input**: Design documents from `/specs/001-meu-ws-state-tracker-implementation/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are included as the MEU framework requires comprehensive testing for geometric logic verification and concurrent operations.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Haskell project**: `src/`, `tests/`, `app/`, `bench/` at repository root
- Paths follow the structure defined in plan.md

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Haskell-specific structure

- [ ] T001 Create Haskell project structure with Cabal configuration in meu-ws-state-tracker.cabal
- [ ] T002 Initialize GHC 9.6+ project with effectful, free, mtl, aeson, stm dependencies in meu-ws-state-tracker.cabal
- [ ] T003 [P] Configure HLint and Ormolu formatting tools in .hlint.yaml and fourmolu.yaml
- [ ] T004 [P] Setup Nix development environment in flake.nix and shell.nix
- [ ] T005 [P] Create basic project documentation structure in README.md and docs/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core MEU framework infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Implement base type system with DomainId and type families in src/MEU/Core/Types.hs
- [ ] T007 [P] Create UUID-based identifier types (TripletId, TypeId, ValueId) in src/MEU/Core/Types.hs
- [ ] T008 [P] Implement GADT structure for TripletDomain with phantom types in src/MEU/Core/Triplet.hs
- [ ] T009 Implement monadic effect stack with effectful library in src/MEU/Internal/Monad.hs
- [ ] T010 [P] Setup STM-based concurrent data structures in src/MEU/Internal/Utils.hs
- [ ] T011 Create error handling hierarchy with MEUError types in src/MEU/Core/Types.hs
- [ ] T012 [P] Implement JSON serialization infrastructure with Aeson in src/MEU/IO/Serialization.hs
- [ ] T013 Setup SMT solver integration with SBV and Z3 backend in src/MEU/Logic/SMT.hs
- [ ] T014 [P] Create logging and metrics infrastructure in src/MEU/Internal/Utils.hs
- [ ] T015 Implement basic CLI argument parsing in src/MEU/IO/CLI.hs

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Initialize MEU System with Source Triplet (Priority: P1) 🎯 MVP

**Goal**: Enable creation and initialization of MEU systems with source triplets containing M, E, U domains

**Independent Test**: Create a new MEU project with basic specification and verify workspace state tracker correctly initializes with source triplet containing valid domains

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T016 [P] [US1] Property-based test for MEU triplet creation in tests/unit/TripletSpec.hs
- [ ] T017 [P] [US1] Integration test for source triplet initialization in tests/integration/InitializationSpec.hs
- [ ] T018 [P] [US1] Contract test for triplet creation API endpoint in tests/contract/TripletCreationSpec.hs

### Implementation for User Story 1

- [ ] T019 [P] [US1] Create MEUTriplet GADT with complete type safety in src/MEU/Core/Triplet.hs
- [ ] T020 [P] [US1] Implement TripletDomains structure with ModelState, ExecutionState, UpdateState in src/MEU/Core/Triplet.hs
- [ ] T021 [US1] Create triplet metadata management with versioning and timestamps in src/MEU/Core/Triplet.hs
- [ ] T022 [P] [US1] Implement basic WSStateTracker with triplet registry in src/MEU/WS/StateTracker.hs
- [ ] T023 [US1] Add triplet validation and state transition logic in src/MEU/WS/StateTracker.hs
- [ ] T024 [US1] Implement source triplet creation API in src/MEU/WS/API.hs
- [ ] T025 [US1] Add initialization commands to CLI interface in src/MEU/IO/CLI.hs
- [ ] T026 [US1] Implement triplet persistence and loading in src/MEU/IO/Serialization.hs

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Track Typed Values and DSL Primitives (Priority: P1)

**Goal**: Maintain comprehensive registries for all typed values, DSL primitives, and execution status across MEU triplet domains

**Independent Test**: Define types and DSL primitives in MEU triplet domain and verify proper registration with correct metadata

### Tests for User Story 2

- [ ] T027 [P] [US2] Property-based test for registry operations in tests/unit/RegistrySpec.hs
- [ ] T028 [P] [US2] Concurrent access test for sharded registries in tests/integration/RegistrySpec.hs
- [ ] T029 [P] [US2] Contract test for registry API endpoints in tests/contract/RegistryAPISpec.hs

### Implementation for User Story 2

- [ ] T030 [P] [US2] Create TypeDefinition and TypeSignature data structures in src/MEU/DSL/Types.hs
- [ ] T031 [P] [US2] Implement TypedValue with validation infrastructure in src/MEU/DSL/Types.hs
- [ ] T032 [P] [US2] Create DSLPrimitive data structure with function wrapping in src/MEU/DSL/Primitives.hs
- [ ] T033 [US2] Implement ConcurrentRegistry with STM and sharding in src/MEU/WS/Registries.hs
- [ ] T034 [US2] Create SystemRegistries orchestrator for all registry types in src/MEU/WS/Registries.hs
- [ ] T035 [US2] Add registry operations (register, query, update) to StateTracker in src/MEU/WS/StateTracker.hs
- [ ] T036 [P] [US2] Implement Bloom filter optimization for fast negative lookups in src/MEU/WS/Registries.hs
- [ ] T037 [US2] Add registry management API endpoints in src/MEU/WS/API.hs
- [ ] T038 [US2] Create CLI commands for registry operations in src/MEU/IO/CLI.hs

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Execute MEU Refinement Transform (Priority: P2)

**Goal**: Decompose MEU triplets into manageable sub-triplets while maintaining proper inclusion relationships

**Independent Test**: Take simple MEU triplet with defined task and refine into 2-3 sub-triplets, verifying inclusion relationships and domain inheritance

### Tests for User Story 3

- [ ] T039 [P] [US3] Property-based test for refinement inclusion relationships in tests/unit/RefinementSpec.hs
- [ ] T040 [P] [US3] Integration test for complete refinement workflow in tests/integration/RefinementSpec.hs
- [ ] T041 [P] [US3] Contract test for refinement API endpoint in tests/contract/RefinementAPISpec.hs

### Implementation for User Story 3

- [ ] T042 [P] [US3] Create InclusionMap and InclusionRelation data structures in src/MEU/Core/Triplet.hs
- [ ] T043 [P] [US3] Implement RefinementResult and refinement validation logic in src/MEU/Transforms/Refinement.hs
- [ ] T044 [US3] Create refinement transform function with inclusion relationship enforcement in src/MEU/Transforms/Refinement.hs
- [ ] T045 [US3] Implement family-based triplet management in StateTracker in src/MEU/WS/StateTracker.hs
- [ ] T046 [US3] Add parent-child relationship tracking to registry system in src/MEU/WS/Registries.hs
- [ ] T047 [US3] Create refinement API endpoints with validation in src/MEU/WS/API.hs
- [ ] T048 [US3] Add refinement commands to CLI interface in src/MEU/IO/CLI.hs
- [ ] T049 [US3] Implement refinement persistence and state recovery in src/MEU/IO/Serialization.hs

**Checkpoint**: All core MEU functionality should now be working with refinement capabilities

---

## Phase 6: User Story 4 - Execute Acceptance Criteria Verification (Priority: P2)

**Goal**: Verify acceptance criteria defined as geometric logic formulas against test execution results using SMT solving

**Independent Test**: Define simple acceptance criteria, execute related tests, and verify geometric logic formulas are properly evaluated

### Tests for User Story 4

- [ ] T050 [P] [US4] Unit test for geometric formula construction in tests/unit/LogicSpec.hs
- [ ] T051 [P] [US4] SMT solver integration test with timeout handling in tests/integration/SMTSpec.hs
- [ ] T052 [P] [US4] Contract test for verification API endpoints in tests/contract/VerificationAPISpec.hs

### Implementation for User Story 4

- [ ] T053 [P] [US4] Create GeometricFormula and LogicalRelation data structures in src/MEU/Logic/GeometricTheory.hs
- [ ] T054 [P] [US4] Implement AcceptanceCriteria with geometric axiom support in src/MEU/Logic/GeometricTheory.hs
- [ ] T055 [US4] Create SBV-based SMT solver integration with Z3 backend in src/MEU/Logic/SMT.hs
- [ ] T056 [US4] Implement geometric theory consistency checking in src/MEU/Logic/GeometricTheory.hs
- [ ] T057 [US4] Add verification workflow to StateTracker with timeout management in src/MEU/WS/StateTracker.hs
- [ ] T058 [US4] Create verification API endpoints with async support in src/MEU/WS/API.hs
- [ ] T059 [US4] Add verification commands to CLI with progress reporting in src/MEU/IO/CLI.hs
- [ ] T060 [US4] Implement verification result persistence and caching in src/MEU/IO/Serialization.hs

**Checkpoint**: MEU systems should now support complete acceptance criteria verification workflow

---

## Phase 7: User Story 5 - Execute MEU Coarsening Transform (Priority: P3)

**Goal**: Collapse completed or redundant sub-triplets back into parent triplets to maintain optimal system complexity

**Independent Test**: Create refinement family, complete some sub-tasks, then coarsen to verify proper consolidation

### Tests for User Story 5

- [ ] T061 [P] [US5] Property-based test for coarsening preservation rules in tests/unit/CoarseningSpec.hs
- [ ] T062 [P] [US5] Integration test for refinement-coarsening roundtrip in tests/integration/CoarseningSpec.hs
- [ ] T063 [P] [US5] Contract test for coarsening API endpoint in tests/contract/CoarseningAPISpec.hs

### Implementation for User Story 5

- [ ] T064 [P] [US5] Create CoarseningResult and preservation specification structures in src/MEU/Transforms/Coarsening.hs
- [ ] T065 [US5] Implement coarsening transform as dual to refinement in src/MEU/Transforms/Coarsening.hs
- [ ] T066 [US5] Add coarsening workflow to StateTracker with conflict resolution in src/MEU/WS/StateTracker.hs
- [ ] T067 [US5] Create coarsening API endpoints with validation in src/MEU/WS/API.hs
- [ ] T068 [US5] Add coarsening commands to CLI interface in src/MEU/IO/CLI.hs
- [ ] T069 [US5] Implement coarsening state persistence in src/MEU/IO/Serialization.hs

**Checkpoint**: Complete MEU transform operations (refinement and coarsening) should be working

---

## Phase 8: User Story 6 - Manage Dataflow Arrows Between Domains (Priority: P3)

**Goal**: Track and execute dataflow arrows (I, I*, O, O*, R, R*) between M, E, U domains with proper type checking

**Independent Test**: Define simple dataflow arrows between domains and verify execution with type validation and side effect management

### Tests for User Story 6

- [ ] T070 [P] [US6] Property-based test for dataflow arrow composition in tests/unit/ArrowsSpec.hs
- [ ] T071 [P] [US6] Integration test for cross-domain data flow in tests/integration/DataflowSpec.hs
- [ ] T072 [P] [US6] Contract test for arrow execution API in tests/contract/ArrowAPISpec.hs

### Implementation for User Story 6

- [ ] T073 [P] [US6] Create DataflowArrow and ArrowCollection data structures in src/MEU/Core/Arrows.hs
- [ ] T074 [P] [US6] Implement arrow composition and type checking in src/MEU/Core/Arrows.hs
- [ ] T075 [US6] Create arrow execution engine with effect management in src/MEU/Core/Arrows.hs
- [ ] T076 [US6] Add arrow management to StateTracker in src/MEU/WS/StateTracker.hs
- [ ] T077 [US6] Implement arrow execution API endpoints in src/MEU/WS/API.hs
- [ ] T078 [US6] Add arrow commands to CLI interface in src/MEU/IO/CLI.hs
- [ ] T079 [US6] Create arrow configuration persistence in src/MEU/IO/Serialization.hs

**Checkpoint**: All user stories should now be independently functional with complete MEU framework

---

## Phase 9: Performance Optimization & Hypergraphs

**Purpose**: Advanced features for enterprise-scale MEU systems

- [ ] T080 [P] Create ValueMergeHyperGraph with sparse matrix representation in src/MEU/WS/Hypergraph.hs
- [ ] T081 [P] Implement FunctionExecutionHyperGraph for composable primitives in src/MEU/WS/Hypergraph.hs
- [ ] T082 Create parallel processing infrastructure for independent triplet operations in src/MEU/Internal/Parallel.hs
- [ ] T083 [P] Implement memory optimization with compact regions in src/MEU/Internal/Utils.hs
- [ ] T084 [P] Add performance monitoring and benchmarking in bench/Performance.hs
- [ ] T085 Create streaming-based computation for large hierarchies in src/MEU/Internal/Streaming.hs

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T086 [P] Complete API documentation in docs/api/
- [ ] T087 [P] Create comprehensive user guide based on quickstart.md in docs/guide/
- [ ] T088 Code cleanup and refactoring across all modules
- [ ] T089 [P] Performance optimization profiling and tuning
- [ ] T090 [P] Security review for concurrent operations and SMT solver integration
- [ ] T091 [P] Create deployment documentation in docs/deployment/
- [ ] T092 Run quickstart.md validation and example verification
- [ ] T093 [P] Setup continuous integration with GitHub Actions in .github/workflows/
- [ ] T094 [P] Create Docker containerization for deployment in Dockerfile
- [ ] T095 Final integration testing with realistic MEU system scenarios

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P1 → P2 → P2 → P3 → P3)
- **Performance (Phase 9)**: Depends on core user stories (US1-US4) completion
- **Polish (Phase 10)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Can start after US1 and US2 completion - Depends on triplet and registry infrastructure
- **User Story 4 (P2)**: Can start after US1 and US2 completion - Depends on basic MEU infrastructure
- **User Story 5 (P3)**: Can start after US3 completion - Depends on refinement functionality
- **User Story 6 (P3)**: Can start after US1 and US2 completion - Independent dataflow implementation

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD approach critical for MEU verification)
- Data structures before business logic
- Core implementation before API endpoints
- CLI commands after API implementation
- Persistence after core functionality
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- User Stories 1 and 2 can run in parallel after Foundational phase (both are P1 priority)
- Once US1/US2 complete, US3, US4, and US6 can run in parallel
- All tests for a user story marked [P] can run in parallel
- Data structures within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Property-based test for MEU triplet creation in tests/unit/TripletSpec.hs"
Task: "Integration test for source triplet initialization in tests/integration/InitializationSpec.hs"
Task: "Contract test for triplet creation API endpoint in tests/contract/TripletCreationSpec.hs"

# Launch all data structures for User Story 1 together:
Task: "Create MEUTriplet GADT with complete type safety in src/MEU/Core/Triplet.hs"
Task: "Implement TripletDomains structure with ModelState, ExecutionState, UpdateState in src/MEU/Core/Triplet.hs"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (source triplet initialization)
4. Complete Phase 4: User Story 2 (registry management)
5. **STOP and VALIDATE**: Test US1 and US2 independently
6. Deploy/demo basic MEU system capability

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 + 2 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 3 → Test independently → Deploy/Demo (with refinement)
4. Add User Story 4 → Test independently → Deploy/Demo (with verification)
5. Add User Story 5 + 6 → Test independently → Deploy/Demo (complete framework)
6. Each increment adds significant value without breaking previous functionality

### Parallel Team Strategy

With multiple Haskell developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (triplet infrastructure)
   - Developer B: User Story 2 (registry system)
   - Developer C: Performance optimization and testing infrastructure
3. Once US1/US2 complete:
   - Developer A: User Story 3 (refinement)
   - Developer B: User Story 4 (verification)
   - Developer C: User Story 6 (dataflow)
4. User Story 5 (coarsening) can follow US3
5. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- TDD approach is critical - verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Property-based testing with QuickCheck is essential for GADT validation
- SMT solver integration requires careful timeout and resource management
- Concurrent operations need thorough testing with realistic workloads
- Memory profiling is important for large-scale MEU systems (1000+ triplets)

**Total Tasks**: 95 tasks
**Tasks per User Story**: US1(13), US2(12), US3(11), US4(11), US5(9), US6(10)
**Parallel Opportunities**: 45 tasks marked [P] for concurrent execution
**MVP Scope**: User Stories 1 + 2 (foundation for MEU system functionality)
**Format Validation**: ✅ All tasks follow checklist format with ID, labels, and file paths