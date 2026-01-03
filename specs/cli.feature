Feature: JJ CLI Adapter
  As a developer using jj-nim
  I want a CLI adapter that wraps the jj command
  So that I can interact with real JJ repositories

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # CLI Adapter Creation
  # ==========================================================================

  Scenario: Create CLI adapter with default jj path
    When I create a JJCliAdapter with repoPath "/my/repo"
    Then the repoPath should be "/my/repo"
    And the jjPath should be "jj"

  Scenario: Create CLI adapter with custom jj path
    When I create a JJCliAdapter with repoPath "/my/repo" and jjPath "/usr/local/bin/jj"
    Then the jjPath should be "/usr/local/bin/jj"

  Scenario: CLI adapter inherits from JJAdapter
    Given a JJCliAdapter instance
    Then it should be an instance of JJAdapter
    And it can be used where JJAdapter is expected

  # ==========================================================================
  # Invalid Repository Handling
  # ==========================================================================

  Scenario: resolveRef with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call resolveRef with "main"
    Then I should get None

  Scenario: getRevision with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call getRevision with any revId
    Then I should get None

  Scenario: computeMergeBase with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call computeMergeBase with any revisions
    Then I should get None

  Scenario: isAncestor with invalid repo returns false
    Given a JJCliAdapter with non-existent repoPath
    When I call isAncestor with any revisions
    Then I should get false

  Scenario: checkConflicts with invalid repo indicates error
    Given a JJCliAdapter with non-existent repoPath
    When I call checkConflicts with any revisions
    Then hasConflict should be true
    And detail should contain error information

  Scenario: performMerge with invalid repo fails
    Given a JJCliAdapter with non-existent repoPath
    When I call performMerge with any parameters
    Then success should be false
    And errorCode should be set
    And errorMessage should contain error details

  Scenario: getChangeTip with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call getChangeTip with any changeId
    Then I should get None

  Scenario: observeRewrite with invalid repo does not raise
    Given a JJCliAdapter with non-existent repoPath
    When I call observeRewrite with any revisions
    Then the method should complete without error

  Scenario: getRewriteHistory with invalid repo returns empty
    Given a JJCliAdapter with non-existent repoPath
    When I call getRewriteHistory with any changeId
    Then I should get an empty sequence

  Scenario: trackChangeEvolution with invalid repo returns empty map
    Given a JJCliAdapter with non-existent repoPath
    When I call trackChangeEvolution with any changeId
    Then entries should be empty

  Scenario: wasRewritten with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call wasRewritten with any parameters
    Then I should get None

  Scenario: getCurrentRevForChange with invalid repo returns None
    Given a JJCliAdapter with non-existent repoPath
    When I call getCurrentRevForChange with any changeId
    Then I should get None

  Scenario: getChangedPaths with invalid repo returns empty
    Given a JJCliAdapter with non-existent repoPath
    When I call getChangedPaths with any revId
    Then I should get an empty sequence

  # ==========================================================================
  # Invalid JJ Binary Handling
  # ==========================================================================

  Scenario: Adapter handles missing jj binary
    Given a JJCliAdapter with non-existent jjPath "/nonexistent/jj"
    When I call resolveRef with "main"
    Then I should get None
    And no exception should be raised

  # ==========================================================================
  # Merge Strategies
  # ==========================================================================

  Scenario: performMerge with rebase strategy
    Given a JJCliAdapter
    When I call performMerge with strategy rebase
    Then the underlying command should use "rebase" arguments

  Scenario: performMerge with squash strategy
    Given a JJCliAdapter
    When I call performMerge with strategy squash
    Then the underlying command should use "squash" arguments

  Scenario: performMerge with merge strategy
    Given a JJCliAdapter
    When I call performMerge with strategy merge
    Then the underlying command should use "new" command for merge commit

  # ==========================================================================
  # Error Code Detection
  # ==========================================================================

  Scenario: Detect conflict error
    Given a JJCliAdapter
    When a merge operation fails with conflict
    Then errorCode should be "ERR_CONFLICT"

  Scenario: Detect internal error
    Given a JJCliAdapter
    When a merge operation fails without conflict keyword
    Then errorCode should be "ERR_INTERNAL"

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: CLI adapter as JJAdapter
    Given a JJAdapter variable holding a JJCliAdapter
    When I call methods on it
    Then JJCliAdapter implementations should be used
    And not the base class implementations

  Scenario: Method dispatch does not raise
    Given a JJAdapter variable holding a JJCliAdapter
    When I call resolveRef on invalid repo
    Then I should get None (not raise exception)

  # ==========================================================================
  # Integration Tests (require real JJ)
  # ==========================================================================

  @requires-jj
  Scenario: resolveRef finds existing branch
    Given a JJCliAdapter with a valid JJ repository
    And the repository has a "main" branch
    When I call resolveRef with "main"
    Then I should get Some(JJRef)
    And the ref should have valid revId
    And the ref should have valid changeId

  @requires-jj
  Scenario: getRevision returns revision metadata
    Given a JJCliAdapter with a valid JJ repository
    And a known revision ID
    When I call getRevision with the revision ID
    Then I should get Some(JJRevision)
    And the revision should have author
    And the revision should have description
    And the revision should have timestamp

  @requires-jj
  Scenario: computeMergeBase finds common ancestor
    Given a JJCliAdapter with a valid JJ repository
    And two branches with common ancestor
    When I call computeMergeBase with the branch heads
    Then I should get Some(JJMergeBase)
    And mergeBaseRev should be the common ancestor

  @requires-jj
  Scenario: isAncestor detects ancestry
    Given a JJCliAdapter with a valid JJ repository
    And a parent-child commit relationship
    When I call isAncestor with parent and child
    Then I should get true

  @requires-jj
  Scenario: checkConflicts detects no conflict
    Given a JJCliAdapter with a valid JJ repository
    And two branches that can be cleanly merged
    When I call checkConflicts
    Then hasConflict should be false

  @requires-jj
  Scenario: getRewriteHistory returns evolution
    Given a JJCliAdapter with a valid JJ repository
    And a change that has been amended multiple times
    When I call getRewriteHistory with the changeId
    Then I should get the rewrite entries
    And entries should track old to new mappings

  @requires-jj
  Scenario: getChangedPaths returns modified files
    Given a JJCliAdapter with a valid JJ repository
    And a revision that modified files
    When I call getChangedPaths with the revId
    Then I should get the list of modified file paths
