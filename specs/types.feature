Feature: JJ Type System
  As a developer using jj-nim
  I want type-safe identifiers and data structures
  So that I can work with JJ version control safely

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # JJRevId - Revision Identifier
  # ==========================================================================

  Scenario: Create a valid JJRevId
    When I create a JJRevId with value "abc123def456"
    Then the JJRevId should be created successfully
    And the string representation should be "abc123def456"

  Scenario: Reject empty JJRevId
    When I try to create a JJRevId with empty string
    Then a ValueError should be raised
    And the error message should contain "cannot be empty"

  Scenario: Compare JJRevId equality
    Given a JJRevId "rev1" with value "abc123"
    And a JJRevId "rev2" with value "abc123"
    And a JJRevId "rev3" with value "def456"
    Then rev1 should equal rev2
    And rev1 should not equal rev3

  Scenario: Use JJRevId as table key
    Given a JJRevId with value "abc123"
    When I use it as a key in a Table
    Then the hash should be computed correctly
    And I should be able to retrieve values by the key

  # ==========================================================================
  # JJChangeId - Change Identifier
  # ==========================================================================

  Scenario: Create a valid JJChangeId
    When I create a JJChangeId with value "change-001"
    Then the JJChangeId should be created successfully
    And the string representation should be "change-001"

  Scenario: Reject empty JJChangeId
    When I try to create a JJChangeId with empty string
    Then a ValueError should be raised

  Scenario: Compare JJChangeId equality
    Given a JJChangeId "ch1" with value "change-001"
    And a JJChangeId "ch2" with value "change-001"
    And a JJChangeId "ch3" with value "change-002"
    Then ch1 should equal ch2
    And ch1 should not equal ch3

  # ==========================================================================
  # JJTimestamp - Timestamp
  # ==========================================================================

  Scenario: Get current timestamp
    When I call jjNowMs()
    Then I should get a positive timestamp in milliseconds
    And consecutive calls should be non-decreasing

  Scenario: Convert timestamp to DateTime
    Given a timestamp 1704067200000 (2024-01-01 00:00:00 UTC)
    When I convert it to DateTime
    Then the year should be 2024
    And the month should be January
    And the day should be 1

  # ==========================================================================
  # JJMergeStrategy - Merge Strategy Enum
  # ==========================================================================

  Scenario Outline: Merge strategy string values
    Given a merge strategy <strategy>
    Then the string representation should be "<value>"

    Examples:
      | strategy         | value   |
      | jjStrategyRebase | rebase  |
      | jjStrategySquash | squash  |
      | jjStrategyMerge  | merge   |

  # ==========================================================================
  # JJRef - Reference
  # ==========================================================================

  Scenario: Create JJRef without changeId
    When I create a JJRef with:
      | name  | main    |
      | revId | abc123  |
    Then the JJRef should have name "main"
    And the JJRef should have revId "abc123"
    And the JJRef changeId should be None

  Scenario: Create JJRef with changeId
    When I create a JJRef with:
      | name     | feature  |
      | revId    | def456   |
      | changeId | ch-001   |
    Then the JJRef changeId should be Some("ch-001")

  Scenario: Serialize JJRef to JSON without changeId
    Given a JJRef without changeId
    When I serialize it to JSON
    Then the JSON should contain "name"
    And the JSON should contain "revId"
    And the JSON should not contain "changeId"

  Scenario: Serialize JJRef to JSON with changeId
    Given a JJRef with changeId "ch-001"
    When I serialize it to JSON
    Then the JSON should contain "changeId" with value "ch-001"

  # ==========================================================================
  # JJRevision - Revision Metadata
  # ==========================================================================

  Scenario: Create JJRevision with parents
    When I create a JJRevision with:
      | revId       | abc123       |
      | changeId    | ch-001       |
      | author      | Test Author  |
      | timestamp   | 1704067200000|
      | description | Test commit  |
      | parents     | parent1,parent2 |
    Then the JJRevision should have 2 parents
    And the author should be "Test Author"

  Scenario: Create JJRevision without parents (root commit)
    When I create a JJRevision with empty parents
    Then the parents sequence should be empty

  Scenario: Serialize JJRevision to JSON
    Given a JJRevision with all fields populated
    When I serialize it to JSON
    Then the JSON should contain all fields
    And the parents should be an array of strings

  # ==========================================================================
  # JJMergeBase - Merge Base Result
  # ==========================================================================

  Scenario: Create JJMergeBase
    When I create a JJMergeBase with:
      | baseRev      | base-rev   |
      | headRev      | head-rev   |
      | mergeBaseRev | common-rev |
    Then all revision fields should be accessible

  # ==========================================================================
  # JJConflictResult - Conflict Detection Result
  # ==========================================================================

  Scenario: No conflict result
    When I create a JJConflictResult with no conflict
    Then hasConflict should be false
    And conflictingFiles should be empty
    And detail should be empty

  Scenario: Conflict result with files
    When I create a JJConflictResult with conflict
    And conflicting files "file1.txt" and "file2.txt"
    Then hasConflict should be true
    And conflictingFiles should contain "file1.txt"
    And conflictingFiles should contain "file2.txt"

  # ==========================================================================
  # JJMergeResult - Merge Execution Result
  # ==========================================================================

  Scenario: Successful merge result
    When I create a successful JJMergeResult with mergedRev "merged-123"
    Then success should be true
    And mergedRev should be Some("merged-123")
    And errorCode should be None
    And errorMessage should be None

  Scenario: Failed merge result
    When I create a failed JJMergeResult with:
      | errorCode    | ERR_CONFLICT           |
      | errorMessage | Merge conflict detected |
    Then success should be false
    And mergedRev should be None
    And errorCode should be Some("ERR_CONFLICT")

  Scenario: Serialize successful merge result to JSON
    Given a successful JJMergeResult
    When I serialize it to JSON
    Then the JSON should contain "success" as true
    And the JSON should contain "mergedRev"
    And the JSON should not contain "errorCode"

  Scenario: Serialize failed merge result to JSON
    Given a failed JJMergeResult
    When I serialize it to JSON
    Then the JSON should contain "success" as false
    And the JSON should contain "errorCode"
    And the JSON should contain "errorMessage"
    And the JSON should not contain "mergedRev"

  # ==========================================================================
  # JJError - Error Type
  # ==========================================================================

  Scenario: Create and raise JJError
    Given a JJError with:
      | message  | JJ command failed     |
      | exitCode | 1                     |
      | stderr   | error: invalid revision |
    When I raise the error
    Then it should be catchable as CatchableError
    And the exitCode should be accessible
    And the stderr should be accessible

  # ==========================================================================
  # JJRewriteEntry - Rewrite Entry
  # ==========================================================================

  Scenario: Create JJRewriteEntry
    When I create a JJRewriteEntry with:
      | oldRev      | old-rev  |
      | newRev      | new-rev  |
      | changeId    | ch-001   |
      | rewrittenAt | 1704067200000 |
    Then all fields should be accessible
    And the rewrite should track old to new revision

  # ==========================================================================
  # JJRewriteMap - Rewrite Map
  # ==========================================================================

  Scenario: Create empty JJRewriteMap
    When I create a JJRewriteMap for changeId "ch-001"
    Then the changeId should be "ch-001"
    And entries should be empty

  Scenario: Create JJRewriteMap with entries
    Given a JJRewriteMap for changeId "ch-001"
    And rewrite entries from v1 to v2 to v3
    Then entries should have 2 items
    And entries should track the evolution chain
