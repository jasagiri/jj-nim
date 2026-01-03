Feature: JJ Operation Log
  As a developer using jj-nim
  I want to access the operation log
  So that I can audit repository changes and undo operations

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Operation Types
  # ==========================================================================

  Scenario: JJOperationId type
    When I create a JJOperationId with value "op-abc123"
    Then the JJOperationId should be created successfully
    And the string representation should be "op-abc123"

  Scenario: Reject empty JJOperationId
    When I try to create a JJOperationId with empty string
    Then a ValueError should be raised

  Scenario Outline: JJOperationType enum values
    Given an operation type <type>
    Then the string representation should be "<value>"

    Examples:
      | type            | value       |
      | jjOpCheckout    | checkout    |
      | jjOpCommit      | commit      |
      | jjOpRebase      | rebase      |
      | jjOpSquash      | squash      |
      | jjOpMerge       | merge       |
      | jjOpNew         | new         |
      | jjOpDescribe    | describe    |
      | jjOpAbandon     | abandon     |
      | jjOpRestore     | restore     |
      | jjOpGitFetch    | git fetch   |
      | jjOpGitPush     | git push    |
      | jjOpUndo        | undo        |
      | jjOpOther       | other       |

  Scenario: Create JJOperation object
    When I create a JJOperation with:
      | id          | op-001    |
      | opType      | commit    |
      | description | Commit changes |
      | user        | test-user |
    Then the operation should have all fields accessible
    And the timestamp should be set

  # ==========================================================================
  # Mock Adapter - Operation Log
  # ==========================================================================

  Scenario: Get operation log on empty adapter
    Given a JJMockAdapter
    When I call getOperationLog
    Then I should get an empty sequence

  Scenario: Add and retrieve operation
    Given a JJMockAdapter
    When I add an operation with type "commit"
    And I call getOperationLog
    Then I should get 1 operation
    And the operation type should be jjOpCommit

  Scenario: Get specific operation by ID
    Given a JJMockAdapter with operation "op-001"
    When I call getOperation with "op-001"
    Then I should get Some(JJOperation)

  Scenario: Get non-existent operation
    Given a JJMockAdapter
    When I call getOperation with "nonexistent"
    Then I should get None

  Scenario: Undo operation
    Given a JJMockAdapter with operation "op-001"
    When I call undoOperation with "op-001"
    Then the result should be true
    And a new undo operation should be in the log

  Scenario: Restore to operation
    Given a JJMockAdapter with operation "op-001"
    When I call restoreToOperation with "op-001"
    Then the result should be true
    And a new restore operation should be in the log

  Scenario: Operation log respects limit
    Given a JJMockAdapter with 10 operations
    When I call getOperationLog with limit 5
    Then I should get 5 operations

  # ==========================================================================
  # CLI Adapter - Operation Log
  # ==========================================================================

  @requires-jj
  Scenario: Get operation log from valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call getOperationLog
    Then I should get a sequence of JJOperation objects
    And each operation should have id, type, and description

  @requires-jj
  Scenario: Get specific operation from valid repository
    Given a JJCliAdapter with a valid JJ repository
    And a known operation ID
    When I call getOperation with the ID
    Then I should get Some(JJOperation)

  @requires-jj
  Scenario: Undo operation in valid repository
    Given a JJCliAdapter with a valid JJ repository
    And a recent operation ID
    When I call undoOperation
    Then the operation should be undone
    And the repository state should be reverted

  @requires-jj
  Scenario: Restore to operation in valid repository
    Given a JJCliAdapter with a valid JJ repository
    And a known operation ID
    When I call restoreToOperation
    Then the repository should be at that operation state

  # ==========================================================================
  # Audit Trail Use Case
  # ==========================================================================

  Scenario: Operation log provides audit trail
    Given a JJMockAdapter
    When multiple operations are performed
    Then getOperationLog should return all operations in order
    And each operation should have timestamp for auditing
    And each operation should have user for accountability

  # ==========================================================================
  # JSON Serialization
  # ==========================================================================

  Scenario: Serialize JJOperation to JSON
    Given a JJOperation with all fields
    When I serialize it to JSON
    Then the JSON should contain "id"
    And the JSON should contain "timestamp"
    And the JSON should contain "type"
    And the JSON should contain "description"
    And the JSON should contain "user"
    And the JSON should contain "tags"
