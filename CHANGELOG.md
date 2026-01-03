# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2024-12-24

### Added

#### Bookmark Operations
- `listBookmarks` - List all bookmarks in the repository
- `createBookmark` - Create a new bookmark at a revision
- `deleteBookmark` - Delete a bookmark
- `moveBookmark` - Move a bookmark to a new revision
- `getBookmark` - Get a specific bookmark by name
- `JJBookmark` type with name, revId, remote, and state
- `JJBookmarkState` enum (local, tracking, conflict)

#### Operation Log (Audit Trail)
- `getOperationLog` - Get operation history with limit
- `getOperation` - Get a specific operation by ID
- `undoOperation` - Undo a specific operation
- `restoreToOperation` - Restore repository to a specific operation state
- `JJOperationId` distinct type for operation identifiers
- `JJOperationType` enum for all operation types
- `JJOperation` type with id, timestamp, type, description, user, tags

#### Workspace Operations
- `listWorkspaces` - List all workspaces
- `addWorkspace` - Add a new workspace
- `forgetWorkspace` - Forget (remove) a workspace
- `JJWorkspace` type with name, path, workingCopyRev

#### Git Integration
- `listGitRemotes` - List configured Git remotes
- `gitFetch` - Fetch from a Git remote
- `gitPush` - Push to a Git remote
- `JJGitRemote` type with name and url
- `JJGitFetchResult` type with success, updatedBookmarks, errorMessage
- `JJGitPushResult` type with success, pushedBookmarks, errorCode, errorMessage

#### Mock Adapter Enhancements
- `addBookmark` - Setup method for bookmarks
- `addOperation` - Setup method for operations
- `setupWorkspace` - Setup method for workspaces
- `addGitRemote` - Setup method for git remotes

#### Documentation
- Comprehensive README.md with badges and examples
- API reference documentation (docs/API.md)
- Usage examples documentation (docs/EXAMPLES.md)
- Japanese documentation (README.ja.md)
- Gherkin specifications for new features:
  - specs/bookmarks.feature
  - specs/operations.feature
  - specs/workspaces.feature
  - specs/git.feature

### Changed
- Updated JJ repository URL to https://github.com/jj-vcs/jj
- Expanded adapter interface from 13 to 27 methods
- Improved specs/README.md with new feature documentation

### Tests
- Added 34 new tests for new features
- Total test count: 156 tests (all passing)

## [0.1.0] - 2024-12-23

### Added

#### Core Types
- `JJRevId` - Revision identifier (distinct string)
- `JJChangeId` - Change identifier (distinct string)
- `JJTimestamp` - Millisecond timestamp
- `JJMergeStrategy` - Merge strategy enum (rebase, squash, merge)
- `JJRef` - Resolved reference
- `JJRevision` - Revision metadata
- `JJMergeBase` - Merge base result
- `JJAncestryResult` - Ancestry check result
- `JJConflictResult` - Conflict detection result
- `JJMergeResult` - Merge execution result
- `JJError` - JJ operation error
- `JJRewriteEntry` - Rewrite history entry
- `JJRewriteMap` - Complete rewrite history

#### Adapter Interface
- `JJAdapter` - Abstract base class
- 13 virtual methods for JJ operations

#### Core Methods
- `resolveRef` - Resolve reference to revision
- `getRevision` - Get revision metadata
- `computeMergeBase` - Find common ancestor
- `isAncestor` - Check ancestry relationship
- `checkConflicts` - Detect conflicts (dry-run)
- `performMerge` - Execute merge
- `getChangeTip` - Get current revision for change
- `observeRewrite` - Record a rewrite
- `getRewriteHistory` - Get evolution history (obslog)
- `trackChangeEvolution` - Build complete rewrite map
- `wasRewritten` - Check if revision was rewritten
- `getCurrentRevForChange` - Get latest revision for change
- `getChangedPaths` - Get files changed in revision

#### CLI Adapter
- `JJCliAdapter` - CLI wrapper adapter
- Wraps real `jj` command
- Handles invalid repository gracefully
- Handles missing jj binary gracefully
- Supports all merge strategies

#### Mock Adapter
- `JJMockAdapter` - Mock adapter for testing
- Setup methods: addRef, addRevision, addConflict, addAncestry
- Full implementation of all 13 methods
- Configurable conflict and ancestry behavior

#### JSON Serialization
- `toJson` for JJRef, JJRevision, JJMergeResult

#### Tests
- 122 comprehensive tests
- Type tests, adapter tests, mock tests, CLI tests

#### Specifications
- Gherkin specifications:
  - specs/types.feature
  - specs/adapter.feature
  - specs/mock.feature
  - specs/cli.feature

[Unreleased]: https://github.com/your-org/jj-nim/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/your-org/jj-nim/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/your-org/jj-nim/releases/tag/v0.1.0
