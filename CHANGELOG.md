# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.8] - 2026-01-03

### Added

#### Core Types (v0.0.1-v0.0.2)
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

#### Adapter Interface (v0.0.3)
- `JJAdapter` - Abstract base class
- 27 virtual methods for JJ operations

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

#### Mock Adapter (v0.0.4)
- `JJMockAdapter` - Mock adapter for testing
- Setup methods: addRef, addRevision, addConflict, addAncestry
- Full implementation of all methods
- Configurable conflict and ancestry behavior

#### Bookmark Operations (v0.0.5)
- `listBookmarks` - List all bookmarks in the repository
- `createBookmark` - Create a new bookmark at a revision
- `deleteBookmark` - Delete a bookmark
- `moveBookmark` - Move a bookmark to a new revision
- `getBookmark` - Get a specific bookmark by name
- `JJBookmark` type with name, revId, remote, and state
- `JJBookmarkState` enum (local, tracking, conflict)

#### Operation Log - Audit Trail (v0.0.6)
- `getOperationLog` - Get operation history with limit
- `getOperation` - Get a specific operation by ID
- `undoOperation` - Undo a specific operation
- `restoreToOperation` - Restore repository to a specific operation state
- `JJOperationId` distinct type for operation identifiers
- `JJOperationType` enum for all operation types
- `JJOperation` type with id, timestamp, type, description, user, tags

#### Workspace & Git Operations (v0.0.7)
- `listWorkspaces` - List all workspaces
- `addWorkspace` - Add a new workspace
- `forgetWorkspace` - Forget (remove) a workspace
- `listGitRemotes` - List configured Git remotes
- `gitFetch` - Fetch from a Git remote
- `gitPush` - Push to a Git remote

#### CLI Adapter (v0.0.8)
- `JJCliAdapter` - CLI wrapper adapter
- Wraps real `jj` command
- Handles invalid repository gracefully
- Handles missing jj binary gracefully
- Supports all merge strategies and operations

#### Documentation
- Comprehensive README.md with badges and examples
- API reference documentation (docs/API.md)
- Usage examples documentation (docs/EXAMPLES.md)
- Japanese documentation (README.ja.md)
- Gherkin BDD specifications for all features

#### JSON Serialization
- `toJson` for all major types

### Tests
- 156 comprehensive tests (all passing)
- Type tests, adapter tests, mock tests, CLI tests

[Unreleased]: https://github.com/jasagiri/jj-nim/compare/v0.0.8...HEAD
[0.0.8]: https://github.com/jasagiri/jj-nim/releases/tag/v0.0.8
