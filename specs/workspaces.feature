Feature: JJ Workspace Operations
  As a developer using jj-nim
  I want to manage workspaces
  So that I can work on multiple tasks in parallel

  Background:
    Given jj-nim library is imported

  # ==========================================================================
  # Workspace Types
  # ==========================================================================

  Scenario: Create JJWorkspace object
    When I create a JJWorkspace with:
      | name | default    |
      | path | /my/repo   |
    Then the workspace should have name "default"
    And the workspace should have path "/my/repo"
    And workingCopyRev should be None

  Scenario: Create JJWorkspace with working copy revision
    When I create a JJWorkspace with workingCopyRev "abc123"
    Then workingCopyRev should be Some("abc123")

  # ==========================================================================
  # Mock Adapter - Workspace Operations
  # ==========================================================================

  Scenario: List workspaces on empty adapter
    Given a JJMockAdapter
    When I call listWorkspaces
    Then I should get an empty list

  Scenario: Add workspace using method
    Given a JJMockAdapter
    When I call addWorkspace with name "feature" and path "/feature/ws"
    Then the result should be true
    And listWorkspaces should return 1 workspace

  Scenario: Add duplicate workspace fails
    Given a JJMockAdapter with workspace "default"
    When I call addWorkspace with name "default" and path "/other/path"
    Then the result should be false
    And listWorkspaces should still have 1 workspace

  Scenario: Forget workspace
    Given a JJMockAdapter with workspace "feature"
    When I call forgetWorkspace with "feature"
    Then the result should be true
    And listWorkspaces should be empty

  Scenario: Forget non-existent workspace
    Given a JJMockAdapter
    When I call forgetWorkspace with "nonexistent"
    Then the result should be false

  Scenario: Setup workspace with working copy
    Given a JJMockAdapter
    When I setup a workspace with workingCopyRev "abc123"
    Then the workspace should have workingCopyRev Some("abc123")

  # ==========================================================================
  # CLI Adapter - Workspace Operations
  # ==========================================================================

  @requires-jj
  Scenario: List workspaces in valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call listWorkspaces
    Then I should get a list of JJWorkspace objects
    And each workspace should have name and path

  @requires-jj
  Scenario: Add workspace in valid repository
    Given a JJCliAdapter with a valid JJ repository
    When I call addWorkspace with a new name and path
    Then the result should be true
    And the workspace should be visible in listWorkspaces

  @requires-jj
  Scenario: Forget workspace in valid repository
    Given a JJCliAdapter with a valid JJ repository
    And an existing workspace "feature"
    When I call forgetWorkspace with "feature"
    Then the result should be true
    And the workspace should no longer appear in listWorkspaces

  # ==========================================================================
  # Polymorphism
  # ==========================================================================

  Scenario: Workspace methods work through JJAdapter interface
    Given a JJAdapter variable holding a JJMockAdapter
    When I call listWorkspaces
    Then JJMockAdapter implementation should be used
    And the result should be a JJWorkspaceList

  # ==========================================================================
  # JSON Serialization
  # ==========================================================================

  Scenario: Serialize JJWorkspace to JSON without workingCopyRev
    Given a JJWorkspace without workingCopyRev
    When I serialize it to JSON
    Then the JSON should contain "name"
    And the JSON should contain "path"
    And the JSON should not contain "workingCopyRev"

  Scenario: Serialize JJWorkspace to JSON with workingCopyRev
    Given a JJWorkspace with workingCopyRev "abc123"
    When I serialize it to JSON
    Then the JSON should contain "workingCopyRev" with value "abc123"
