-- |
-- Module      : TripletSpec
-- Description : Property-based tests for MEU triplet creation and validation
-- Copyright   : (c) MEU Framework Team, 2025
-- License     : MIT

module TripletSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import Test.QuickCheck.Instances ()

import Data.UUID.V4 (nextRandom)
import Data.Time (getCurrentTime)

import MEU.Core.Types
import MEU.Core.Triplet

-- | Test specification for MEU triplet functionality
spec :: Spec
spec = describe "MEU Triplet" $ do

  describe "MEU Triplet Creation" $ do
    it "should create a valid source triplet" $ do
      tripletId <- TripletId <$> nextRandom
      timestamp <- getCurrentTime
      let metadata = TripletMetadata timestamp timestamp (Version 1 0 0) "Test triplet" Nothing [] [] 0
          modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          domains = TripletDomains (mkModelDomain modelState) (mkExecutionDomain execState) (mkUpdateDomain updateState)
          triplet = mkMEUTriplet tripletId SourceTriplet metadata domains undefined undefined Active

      getTripletId triplet `shouldBe` tripletId
      getTripletType triplet `shouldBe` SourceTriplet

    it "should fail to create source triplet with parent" $ do
      tripletId <- TripletId <$> nextRandom
      parentId <- TripletId <$> nextRandom
      timestamp <- getCurrentTime
      let metadata = TripletMetadata timestamp timestamp (Version 1 0 0) "Invalid triplet" (Just parentId) [] [] 0
          modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          domains = TripletDomains (mkModelDomain modelState) (mkExecutionDomain execState) (mkUpdateDomain updateState)
          triplet = mkMEUTriplet tripletId SourceTriplet metadata domains undefined undefined Active

      validateTripletStructure triplet `shouldSatisfy` isLeft

    it "should create a valid branch triplet with parent" $ do
      tripletId <- TripletId <$> nextRandom
      parentId <- TripletId <$> nextRandom
      timestamp <- getCurrentTime
      let metadata = TripletMetadata timestamp timestamp (Version 1 0 0) "Branch triplet" (Just parentId) [] [] 1
          modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          domains = TripletDomains (mkModelDomain modelState) (mkExecutionDomain execState) (mkUpdateDomain updateState)
          triplet = mkMEUTriplet tripletId BranchTriplet metadata domains undefined undefined Active

      getTripletId triplet `shouldBe` tripletId
      getTripletType triplet `shouldBe` BranchTriplet
      validateTripletStructure triplet `shouldSatisfy` isRight

  describe "Domain Operations" $ do
    it "should extract correct domain states" $ do
      let modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          modelDomain = mkModelDomain modelState
          execDomain = mkExecutionDomain execState
          updateDomain = mkUpdateDomain updateState

      getDomainState modelDomain `shouldBe` modelState
      getDomainState execDomain `shouldBe` execState
      getDomainState updateDomain `shouldBe` updateState

  describe "Property-based Tests" $ do
    it "should maintain triplet ID consistency" $ property $ \uuid -> do
      let tripletId = TripletId uuid
      timestamp <- getCurrentTime
      let metadata = TripletMetadata timestamp timestamp (Version 1 0 0) "Property test" Nothing [] [] 0
          modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          domains = TripletDomains (mkModelDomain modelState) (mkExecutionDomain execState) (mkUpdateDomain updateState)
          triplet = mkMEUTriplet tripletId SourceTriplet metadata domains undefined undefined Active

      pure $ getTripletId triplet === tripletId

    it "should validate triplet hierarchy constraints" $ property $ \tripletType parentExists -> do
      tripletId <- TripletId <$> nextRandom
      parentId <- if parentExists then Just . TripletId <$> nextRandom else pure Nothing
      timestamp <- getCurrentTime
      let metadata = TripletMetadata timestamp timestamp (Version 1 0 0) "Property test" parentId [] [] 0
          modelState = ModelState mempty mempty mempty mempty mempty
          execState = ExecutionState (ExecutionEnvironment "test" "test env" "{}") mempty (LoggingConfiguration "info" "stdout" "json") (ResourceAllocation 1 1024 1000) mempty
          updateState = UpdateState mempty mempty undefined mempty mempty
          domains = TripletDomains (mkModelDomain modelState) (mkExecutionDomain execState) (mkUpdateDomain updateState)
          triplet = mkMEUTriplet tripletId tripletType metadata domains undefined undefined Active

          expectedValid = case (tripletType, parentExists) of
            (SourceTriplet, False) -> True
            (BranchTriplet, True) -> True
            (LeafTriplet, True) -> True
            _ -> False

      pure $ if expectedValid
        then validateTripletStructure triplet === Right ()
        else validateTripletStructure triplet `shouldSatisfy` isLeft

-- Helper functions
isLeft :: Either a b -> Bool
isLeft (Left _) = True
isLeft (Right _) = False

isRight :: Either a b -> Bool
isRight (Right _) = True
isRight (Left _) = False

-- Arbitrary instances for property-based testing
instance Arbitrary TripletType where
  arbitrary = elements [SourceTriplet, BranchTriplet, LeafTriplet]

instance Arbitrary Version where
  arbitrary = Version <$> arbitrary <*> arbitrary <*> arbitrary