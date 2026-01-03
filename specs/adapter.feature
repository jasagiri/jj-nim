Feature: JJ Adapter Interface
  As a developer using jj-nim
  I want an abstract adapter interface
  So that I can implement different JJ backends

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Base Adapter Creation
  # ==========================================================================

  Scenario: Create base JJAdapter with repoPath
    When I create a JJAdapter with repoPath "/test/repo"
    Then the adapter should have repoPath "/test/repo"

  Scenario: Create base JJAdapter with default values
    When I create a JJAdapter without parameters
    Then the repoPath should be empty string

  Scenario: JJAdapter is RootObj
    Given a JJAdapter instance
    Then it should be an instance of RootObj

  # ==========================================================================
  # Base Methods Raise Not Implemented
  # ==========================================================================

  Scenario Outline: Base adapter methods raise not implemented
    Given a base JJAdapter instance
    When I call <method> on the base adapter
    Then a CatchableError should be raised
    And the error message should contain "not implemented"

    Examples:
      | method                |
      | resolveRef            |
      | getRevision           |
      | computeMergeBase      |
      | isAncestor            |
      | checkConflicts        |
      | performMerge          |
      | getChangeTip          |
      | observeRewrite        |
      | getRewriteHistory     |
      | trackChangeEvolution  |
      | wasRewritten          |
      | getCurrentRevForChange|
      | getChangedPaths       |

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: JJAdapter can be used as base type parameter
    Given a function that accepts JJAdapter
    When I pass a concrete adapter implementation
    Then the function should accept it
    And method dispatch should use the concrete implementation

  Scenario: Virtual method dispatch
    Given a JJAdapter variable holding a concrete adapter
    When I call a method on it
    Then the concrete adapter's implementation should be called
    And not the base class implementation

  # ==========================================================================
  # Interface Contract
  # ==========================================================================

  Scenario: resolveRef returns Option[JJRef]
    Given any JJAdapter implementation
    When I call resolveRef with a reference name
    Then I should get Option[JJRef]
    And Some if the reference exists
    And None if the reference does not exist

  Scenario: getRevision returns Option[JJRevision]
    Given any JJAdapter implementation
    When I call getRevision with a revision ID
    Then I should get Option[JJRevision]
    And Some with metadata if revision exists
    And None if revision does not exist

  Scenario: computeMergeBase returns Option[JJMergeBase]
    Given any JJAdapter implementation
    When I call computeMergeBase with base and head revisions
    Then I should get Option[JJMergeBase]
    And Some with merge base information if computable
    And None if no common ancestor exists

  Scenario: isAncestor returns bool
    Given any JJAdapter implementation
    When I call isAncestor with ancestor and descendant
    Then I should get a boolean result
    And true if ancestor is an ancestor of descendant
    And false otherwise

  Scenario: checkConflicts returns JJConflictResult
    Given any JJAdapter implementation
    When I call checkConflicts with base, head, and strategy
    Then I should get JJConflictResult
    And hasConflict should indicate if conflicts exist
    And conflictingFiles should list affected files

  Scenario: performMerge returns JJMergeResult
    Given any JJAdapter implementation
    When I call performMerge with base, head, strategy, and message
    Then I should get JJMergeResult
    And success should indicate if merge succeeded
    And mergedRev should contain new revision if successful
    And errorCode and errorMessage should be set on failure

  Scenario: getChangeTip returns Option[JJRevId]
    Given any JJAdapter implementation
    When I call getChangeTip with a change ID
    Then I should get Option[JJRevId]
    And Some with current revision if change exists
    And None if change does not exist

  Scenario: observeRewrite is void
    Given any JJAdapter implementation
    When I call observeRewrite with old and new revision
    Then the method should complete without error
    And the rewrite should be recorded (implementation-dependent)

  Scenario: getRewriteHistory returns seq[JJRewriteEntry]
    Given any JJAdapter implementation
    When I call getRewriteHistory with a change ID
    Then I should get a sequence of rewrite entries
    And each entry should have old/new revision mapping

  Scenario: trackChangeEvolution returns JJRewriteMap
    Given any JJAdapter implementation
    When I call trackChangeEvolution with a change ID
    Then I should get a JJRewriteMap
    And it should contain the complete evolution history

  Scenario: wasRewritten returns Option[JJRevId]
    Given any JJAdapter implementation
    When I call wasRewritten with old revision and change ID
    Then I should get Option[JJRevId]
    And Some with new revision if rewritten
    And None if not rewritten

  Scenario: getCurrentRevForChange returns Option[JJRevId]
    Given any JJAdapter implementation
    When I call getCurrentRevForChange with a change ID
    Then I should get Option[JJRevId]
    And Some with current (latest) revision if change exists
    And None if change does not exist

  Scenario: getChangedPaths returns seq[string]
    Given any JJAdapter implementation
    When I call getChangedPaths with a revision ID
    Then I should get a sequence of file paths
    And each path should be a file modified in that revision
