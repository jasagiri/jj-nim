Feature: JJ Bookmark Operations
  As a developer using jj-nim
  I want to manage bookmarks (named references)
  So that I can organize and track branches in my repository

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Bookmark Types
  # ==========================================================================

  Scenario: JJBookmarkState enum values
    Then jjBookmarkLocal should represent "local"
    And jjBookmarkTracking should represent "tracking"
    And jjBookmarkConflict should represent "conflict"

  Scenario: Create JJBookmark object
    When I create a JJBookmark with:
      | name   | main      |
      | revId  | abc123    |
      | state  | local     |
    Then the bookmark should have name "main"
    And the bookmark should have revId "abc123"
    And the bookmark state should be jjBookmarkLocal
    And the remote should be None

  Scenario: Create JJBookmark with remote
    When I create a JJBookmark with remote "origin"
    Then the remote should be Some("origin")
    And the state should be jjBookmarkTracking

  # ==========================================================================
  # Mock Adapter - Bookmark Operations
  # ==========================================================================

  Scenario: List bookmarks on empty adapter
    Given a JJMockAdapter
    When I call listBookmarks
    Then I should get an empty list

  Scenario: Create bookmark
    Given a JJMockAdapter
    When I call createBookmark with name "main" and revId "abc123"
    Then the result should be true
    And listBookmarks should return 1 bookmark

  Scenario: Create duplicate bookmark fails
    Given a JJMockAdapter with bookmark "main"
    When I call createBookmark with name "main" and revId "def456"
    Then the result should be false
    And listBookmarks should still have 1 bookmark

  Scenario: Get existing bookmark
    Given a JJMockAdapter with bookmark "main"
    When I call getBookmark with "main"
    Then I should get Some(JJBookmark)
    And the bookmark name should be "main"

  Scenario: Get non-existent bookmark
    Given a JJMockAdapter
    When I call getBookmark with "nonexistent"
    Then I should get None

  Scenario: Delete bookmark
    Given a JJMockAdapter with bookmark "main"
    When I call deleteBookmark with "main"
    Then the result should be true
    And listBookmarks should be empty

  Scenario: Delete non-existent bookmark
    Given a JJMockAdapter
    When I call deleteBookmark with "nonexistent"
    Then the result should be false

  Scenario: Move bookmark
    Given a JJMockAdapter with bookmark "main" at revId "abc123"
    When I call moveBookmark with name "main" and revId "def456"
    Then the result should be true
    And getBookmark("main").revId should be "def456"

  Scenario: Move non-existent bookmark
    Given a JJMockAdapter
    When I call moveBookmark with name "nonexistent" and revId "abc123"
    Then the result should be false

  # ==========================================================================
  # CLI Adapter - Bookmark Operations
  # ==========================================================================

  @requires-jj
  Scenario: List bookmarks in valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call listBookmarks
    Then I should get a list of JJBookmark objects
    And each bookmark should have name, revId, and state

  @requires-jj
  Scenario: Create bookmark in valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call createBookmark with a new name
    Then the result should be true
    And the bookmark should be visible in listBookmarks

  @requires-jj
  Scenario: Move bookmark in valid repository
    Given a JJCliAdapter with a valid JJ repository
    And an existing bookmark "feature"
    When I call moveBookmark to a different revision
    Then the result should be true

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: Bookmark methods work through JJAdapter interface
    Given a JJAdapter variable holding a JJMockAdapter
    When I call listBookmarks
    Then JJMockAdapter implementation should be used
    And the result should be a JJBookmarkList

  # ==========================================================================
  # JSON Serialization
  # ==========================================================================

  Scenario: Serialize JJBookmark to JSON without remote
    Given a JJBookmark without remote
    When I serialize it to JSON
    Then the JSON should contain "name"
    And the JSON should contain "revId"
    And the JSON should contain "state"
    And the JSON should not contain "remote"

  Scenario: Serialize JJBookmark to JSON with remote
    Given a JJBookmark with remote "origin"
    When I serialize it to JSON
    Then the JSON should contain "remote" with value "origin"
