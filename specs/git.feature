Feature: JJ Git Operations
  As a developer using jj-nim
  I want to interact with Git remotes
  So that I can collaborate with others using Git

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Git Remote Types
  # ==========================================================================

  Scenario: Create JJGitRemote object
    When I create a JJGitRemote with:
      | name | origin                              |
      | url  | https://github.com/jj-vcs/jj.git    |
    Then the remote should have name "origin"
    And the remote should have url "https://github.com/jj-vcs/jj.git"

  Scenario: Create JJGitFetchResult success
    When I create a successful JJGitFetchResult
    Then success should be true
    And errorMessage should be None

  Scenario: Create JJGitFetchResult failure
    When I create a failed JJGitFetchResult with message "Connection refused"
    Then success should be false
    And errorMessage should be Some("Connection refused")

  Scenario: Create JJGitPushResult success
    When I create a successful JJGitPushResult with bookmarks ["main", "feature"]
    Then success should be true
    And pushedBookmarks should contain "main" and "feature"
    And errorCode should be None

  Scenario: Create JJGitPushResult failure
    When I create a failed JJGitPushResult with code "ERR_REJECTED"
    Then success should be false
    And errorCode should be Some("ERR_REJECTED")

  # ==========================================================================
  # Mock Adapter - Git Remote List
  # ==========================================================================

  Scenario: List remotes on empty adapter
    Given a JJMockAdapter
    When I call listGitRemotes
    Then I should get an empty list

  Scenario: Add and list remotes
    Given a JJMockAdapter
    When I add a remote "origin" with url "https://github.com/test/repo.git"
    And I call listGitRemotes
    Then I should get 1 remote
    And the remote name should be "origin"

  # ==========================================================================
  # Mock Adapter - Git Fetch
  # ==========================================================================

  Scenario: Fetch from non-existent remote fails
    Given a JJMockAdapter
    When I call gitFetch with "origin"
    Then success should be false
    And errorMessage should indicate remote not found

  Scenario: Fetch from existing remote succeeds
    Given a JJMockAdapter with remote "origin"
    When I call gitFetch with "origin"
    Then success should be true
    And errorMessage should be None

  Scenario: Fetch with default remote
    Given a JJMockAdapter with remote "origin"
    When I call gitFetch without parameters
    Then success should be true

  # ==========================================================================
  # Mock Adapter - Git Push
  # ==========================================================================

  Scenario: Push to non-existent remote fails
    Given a JJMockAdapter
    When I call gitPush with "origin" and bookmarks ["main"]
    Then success should be false
    And errorCode should be Some("ERR_REMOTE_NOT_FOUND")

  Scenario: Push to existing remote succeeds
    Given a JJMockAdapter with remote "origin"
    When I call gitPush with "origin" and bookmarks ["main"]
    Then success should be true
    And pushedBookmarks should contain "main"

  Scenario: Push with default remote
    Given a JJMockAdapter with remote "origin"
    When I call gitPush without parameters
    Then success should be true

  # ==========================================================================
  # CLI Adapter - Git Operations
  # ==========================================================================

  @requires-jj
  Scenario: List remotes in valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call listGitRemotes
    Then I should get a list of JJGitRemote objects

  @requires-jj
  Scenario: Fetch from valid remote
    Given a JJCliAdapter with a valid JJ repository
    And a configured remote "origin"
    When I call gitFetch with "origin"
    Then the result should indicate success or failure
    And updatedBookmarks should be populated if successful

  @requires-jj
  Scenario: Push to valid remote
    Given a JJCliAdapter with a valid JJ repository
    And a configured remote "origin"
    And bookmarks to push
    When I call gitPush with "origin"
    Then the result should indicate success or failure
    And errorCode should be set on failure

  @requires-jj
  Scenario: Push with rejected changes
    Given a JJCliAdapter with a valid JJ repository
    And changes that would be rejected
    When I call gitPush
    Then success should be false
    And errorCode should be "ERR_REJECTED"

  # ==========================================================================
  # Error Handling
  # ==========================================================================

  Scenario: Git fetch error codes
    Given a JJCliAdapter with invalid repository
    When I call gitFetch
    Then success should be false
    And errorMessage should contain error details

  Scenario: Git push error codes
    Given a JJCliAdapter with invalid repository
    When I call gitPush
    Then success should be false
    And errorCode should indicate the failure reason

  Scenario Outline: Push error code detection
    Given a push result with output containing "<keyword>"
    Then errorCode should be "<code>"

    Examples:
      | keyword    | code            |
      | rejected   | ERR_REJECTED    |
      | permission | ERR_PERMISSION  |
      | other      | ERR_PUSH_FAILED |

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: Git methods work through JJAdapter interface
    Given a JJAdapter variable holding a JJMockAdapter
    And the mock has remote "origin"
    When I call gitFetch through the JJAdapter interface
    Then JJMockAdapter implementation should be used
    And the result should be a JJGitFetchResult

  # ==========================================================================
  # JSON Serialization
  # ==========================================================================

  Scenario: Serialize JJGitRemote to JSON
    Given a JJGitRemote
    When I serialize it to JSON
    Then the JSON should contain "name"
    And the JSON should contain "url"
