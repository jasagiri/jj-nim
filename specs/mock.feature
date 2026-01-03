Feature: JJ Mock Adapter
  As a developer testing code that uses jj-nim
  I want a mock adapter for testing
  So that I can test without a real JJ repository

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Mock Adapter Creation
  # ==========================================================================

  Scenario: Create mock adapter with default path
    When I create a JJMockAdapter without parameters
    Then the repoPath should be "/mock/repo"
    And refs should be empty
    And revisions should be empty
    And conflicts should be empty
    And ancestryPairs should be empty

  Scenario: Create mock adapter with custom path
    When I create a JJMockAdapter with repoPath "/custom/path"
    Then the repoPath should be "/custom/path"

  Scenario: Mock adapter inherits from JJAdapter
    Given a JJMockAdapter instance
    Then it should be an instance of JJAdapter
    And it can be used where JJAdapter is expected

  # ==========================================================================
  # Setup Methods - Refs
  # ==========================================================================

  Scenario: Add ref without changeId
    Given a JJMockAdapter
    When I call addRef with name "main" and revId "abc123"
    Then the adapter should have 1 ref
    And the ref should have name "main"
    And the ref should have revId "abc123"
    And the ref changeId should be None

  Scenario: Add ref with changeId
    Given a JJMockAdapter
    When I call addRef with name "feature", revId "def456", and changeId "ch-001"
    Then the ref changeId should be Some("ch-001")

  Scenario: Add multiple refs
    Given a JJMockAdapter
    When I add 3 different refs
    Then the adapter should have 3 refs

  # ==========================================================================
  # Setup Methods - Revisions
  # ==========================================================================

  Scenario: Add revision
    Given a JJMockAdapter
    And a JJRevision with revId "abc123"
    When I call addRevision with the revision
    Then the adapter should have 1 revision

  Scenario: Add multiple revisions
    Given a JJMockAdapter
    When I add 5 different revisions
    Then the adapter should have 5 revisions

  # ==========================================================================
  # Setup Methods - Conflicts
  # ==========================================================================

  Scenario: Add conflict pair
    Given a JJMockAdapter
    When I call addConflict with base "base-rev" and head "head-rev"
    Then the adapter should have 1 conflict pair

  Scenario: Add multiple conflict pairs
    Given a JJMockAdapter
    When I add 3 conflict pairs
    Then the adapter should have 3 conflict pairs

  # ==========================================================================
  # Setup Methods - Ancestry
  # ==========================================================================

  Scenario: Add ancestry pair
    Given a JJMockAdapter
    When I call addAncestry with ancestor "parent" and descendant "child"
    Then the adapter should have 1 ancestry pair

  Scenario: Add multiple ancestry pairs
    Given a JJMockAdapter
    When I add 4 ancestry pairs
    Then the adapter should have 4 ancestry pairs

  # ==========================================================================
  # resolveRef
  # ==========================================================================

  Scenario: Resolve existing ref
    Given a JJMockAdapter
    And a ref "main" pointing to "abc123"
    When I call resolveRef with "main"
    Then I should get Some(JJRef)
    And the ref name should be "main"
    And the revId should be "abc123"

  Scenario: Resolve ref with changeId
    Given a JJMockAdapter
    And a ref "develop" with changeId "ch-dev"
    When I call resolveRef with "develop"
    Then the changeId should be Some("ch-dev")

  Scenario: Resolve non-existent ref
    Given a JJMockAdapter with refs
    When I call resolveRef with "nonexistent"
    Then I should get None

  Scenario: Resolve ref on empty adapter
    Given an empty JJMockAdapter
    When I call resolveRef with "main"
    Then I should get None

  # ==========================================================================
  # getRevision
  # ==========================================================================

  Scenario: Get existing revision
    Given a JJMockAdapter
    And a revision with revId "abc123" and author "Test Author"
    When I call getRevision with "abc123"
    Then I should get Some(JJRevision)
    And the author should be "Test Author"

  Scenario: Get non-existent revision
    Given a JJMockAdapter with revisions
    When I call getRevision with "nonexistent"
    Then I should get None

  Scenario: Get revision on empty adapter
    Given an empty JJMockAdapter
    When I call getRevision with "abc123"
    Then I should get None

  # ==========================================================================
  # computeMergeBase
  # ==========================================================================

  Scenario: Compute merge base returns base revision
    Given a JJMockAdapter
    When I call computeMergeBase with base "base-rev" and head "head-rev"
    Then I should get Some(JJMergeBase)
    And baseRev should be "base-rev"
    And headRev should be "head-rev"
    And mergeBaseRev should be "base-rev"

  Scenario: Compute merge base always succeeds
    Given a JJMockAdapter
    When I call computeMergeBase with any revisions
    Then I should always get Some result

  # ==========================================================================
  # isAncestor
  # ==========================================================================

  Scenario: Check registered ancestry - is ancestor
    Given a JJMockAdapter
    And ancestry pair (parent, child)
    When I call isAncestor with ancestor "parent" and descendant "child"
    Then I should get true

  Scenario: Check unregistered ancestry - not ancestor
    Given a JJMockAdapter
    And ancestry pair (parent, child)
    When I call isAncestor with ancestor "child" and descendant "parent"
    Then I should get false

  Scenario: Check unknown revisions
    Given a JJMockAdapter
    When I call isAncestor with unknown revisions
    Then I should get false

  Scenario: Check ancestry on empty adapter
    Given an empty JJMockAdapter
    When I call isAncestor with any revisions
    Then I should get false

  # ==========================================================================
  # checkConflicts
  # ==========================================================================

  Scenario: Check registered conflict
    Given a JJMockAdapter
    And conflict pair (base-rev, head-rev)
    When I call checkConflicts with base "base-rev", head "head-rev", and any strategy
    Then hasConflict should be true
    And conflictingFiles should contain "mock/conflict.txt"
    And detail should be "Mock conflict detected"

  Scenario: Check no conflict
    Given a JJMockAdapter
    When I call checkConflicts with non-conflicting revisions
    Then hasConflict should be false
    And conflictingFiles should be empty
    And detail should be empty

  Scenario: Check conflicts with all strategies
    Given a JJMockAdapter without conflicts
    When I call checkConflicts with strategy rebase
    Then hasConflict should be false
    When I call checkConflicts with strategy squash
    Then hasConflict should be false
    When I call checkConflicts with strategy merge
    Then hasConflict should be false

  # ==========================================================================
  # performMerge
  # ==========================================================================

  Scenario: Perform successful merge
    Given a JJMockAdapter without conflicts
    When I call performMerge with base "base", head "head", strategy rebase, message "Merge"
    Then success should be true
    And mergedRev should be Some("head-merged")
    And errorCode should be None
    And errorMessage should be None

  Scenario: Perform merge with conflict
    Given a JJMockAdapter
    And conflict pair (base, head)
    When I call performMerge with base "base" and head "head"
    Then success should be false
    And mergedRev should be None
    And errorCode should be Some("ERR_CONFLICT")
    And errorMessage should contain "conflict"

  Scenario: Perform merge with squash strategy
    Given a JJMockAdapter without conflicts
    When I call performMerge with strategy squash
    Then success should be true
    And mergedRev should contain "-merged" suffix

  Scenario: Perform merge with merge strategy
    Given a JJMockAdapter without conflicts
    When I call performMerge with strategy merge
    Then success should be true

  # ==========================================================================
  # getChangeTip
  # ==========================================================================

  Scenario: Get change tip for existing change
    Given a JJMockAdapter
    And a revision with changeId "ch-001" and revId "tip-rev"
    When I call getChangeTip with "ch-001"
    Then I should get Some("tip-rev")

  Scenario: Get change tip for unknown change
    Given a JJMockAdapter
    When I call getChangeTip with "unknown"
    Then I should get None

  Scenario: Get change tip returns first match
    Given a JJMockAdapter
    And multiple revisions with same changeId "ch-001"
    When I call getChangeTip with "ch-001"
    Then I should get the first matching revision

  # ==========================================================================
  # observeRewrite
  # ==========================================================================

  Scenario: Observe rewrite is no-op
    Given a JJMockAdapter
    When I call observeRewrite with old "old-rev" and new "new-rev"
    Then the method should complete without error
    And no state should change

  # ==========================================================================
  # getRewriteHistory
  # ==========================================================================

  Scenario: Get rewrite history returns empty
    Given a JJMockAdapter
    When I call getRewriteHistory with any changeId
    Then I should get an empty sequence

  # ==========================================================================
  # trackChangeEvolution
  # ==========================================================================

  Scenario: Track change evolution returns empty map
    Given a JJMockAdapter
    When I call trackChangeEvolution with changeId "ch-001"
    Then I should get a JJRewriteMap
    And the changeId should be "ch-001"
    And entries should be empty

  # ==========================================================================
  # wasRewritten
  # ==========================================================================

  Scenario: Was rewritten returns None
    Given a JJMockAdapter
    When I call wasRewritten with any revision and changeId
    Then I should get None

  # ==========================================================================
  # getCurrentRevForChange
  # ==========================================================================

  Scenario: Get current rev delegates to getChangeTip
    Given a JJMockAdapter
    And a revision with changeId "ch-001" and revId "current-rev"
    When I call getCurrentRevForChange with "ch-001"
    Then I should get Some("current-rev")

  Scenario: Get current rev for unknown change
    Given a JJMockAdapter
    When I call getCurrentRevForChange with "unknown"
    Then I should get None

  # ==========================================================================
  # getChangedPaths
  # ==========================================================================

  Scenario: Get changed paths returns empty
    Given a JJMockAdapter
    When I call getChangedPaths with any revId
    Then I should get an empty sequence

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: Mock adapter as JJAdapter
    Given a function accepting JJAdapter
    And a JJMockAdapter instance
    When I pass the mock to the function
    Then it should be accepted
    And mock methods should be called

  Scenario: Method dispatch uses mock implementation
    Given a JJAdapter variable holding a JJMockAdapter
    When I call resolveRef on non-existent ref
    Then I should get None (not raise exception)
