## JJ Adapter Interface
##
## Abstract interface for JJ operations.
## Implementations: JJCliAdapter (real), JJMockAdapter (testing)

import std/options
import types

export types

# =============================================================================
# JJ Adapter Interface
# =============================================================================

type
  JJAdapter* = ref object of RootObj
    ## Base interface for JJ operations
    repoPath*: string

# =============================================================================
# Virtual Methods - to be implemented by concrete adapters
# =============================================================================

method resolveRef*(adapter: JJAdapter, refName: string): Option[JJRef] {.base.} =
  ## Resolve a reference name to revision
  raise newException(CatchableError, "resolveRef not implemented")

method getRevision*(adapter: JJAdapter, revId: JJRevId): Option[JJRevision] {.base.} =
  ## Get revision metadata
  raise newException(CatchableError, "getRevision not implemented")

method computeMergeBase*(adapter: JJAdapter, baseRev, headRev: JJRevId): Option[JJMergeBase] {.base.} =
  ## Compute merge base between two revisions
  raise newException(CatchableError, "computeMergeBase not implemented")

method isAncestor*(adapter: JJAdapter, ancestor, descendant: JJRevId): bool {.base.} =
  ## Check if ancestor is an ancestor of descendant
  raise newException(CatchableError, "isAncestor not implemented")

method checkConflicts*(adapter: JJAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy): JJConflictResult {.base.} =
  ## Check for conflicts without actually merging (dry-run)
  raise newException(CatchableError, "checkConflicts not implemented")

method performMerge*(adapter: JJAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy, message: string): JJMergeResult {.base.} =
  ## Actually perform the merge
  raise newException(CatchableError, "performMerge not implemented")

method getChangeTip*(adapter: JJAdapter, changeId: JJChangeId): Option[JJRevId] {.base.} =
  ## Get current tip revision for a change
  raise newException(CatchableError, "getChangeTip not implemented")

method observeRewrite*(adapter: JJAdapter, oldRev, newRev: JJRevId): void {.base.} =
  ## Record a rewrite (for tracking)
  raise newException(CatchableError, "observeRewrite not implemented")

# =============================================================================
# Rewrite Tracking Methods
# =============================================================================

method getRewriteHistory*(adapter: JJAdapter, changeId: JJChangeId): seq[JJRewriteEntry] {.base.} =
  ## Get rewrite history for a change
  raise newException(CatchableError, "getRewriteHistory not implemented")

method trackChangeEvolution*(adapter: JJAdapter, changeId: JJChangeId): JJRewriteMap {.base.} =
  ## Build complete rewrite map for a change
  raise newException(CatchableError, "trackChangeEvolution not implemented")

method wasRewritten*(adapter: JJAdapter, oldRev: JJRevId, changeId: JJChangeId): Option[JJRevId] {.base.} =
  ## Check if a revision was rewritten
  raise newException(CatchableError, "wasRewritten not implemented")

method getCurrentRevForChange*(adapter: JJAdapter, changeId: JJChangeId): Option[JJRevId] {.base.} =
  ## Get the current revision for a change
  raise newException(CatchableError, "getCurrentRevForChange not implemented")

method getChangedPaths*(adapter: JJAdapter, revId: JJRevId): seq[string] {.base.} =
  ## Get list of paths changed in a revision
  raise newException(CatchableError, "getChangedPaths not implemented")

# =============================================================================
# Bookmark Operations
# =============================================================================

method listBookmarks*(adapter: JJAdapter): JJBookmarkList {.base.} =
  ## List all bookmarks
  raise newException(CatchableError, "listBookmarks not implemented")

method createBookmark*(adapter: JJAdapter, name: string, revId: JJRevId): bool {.base.} =
  ## Create a bookmark at the given revision
  raise newException(CatchableError, "createBookmark not implemented")

method deleteBookmark*(adapter: JJAdapter, name: string): bool {.base.} =
  ## Delete a bookmark
  raise newException(CatchableError, "deleteBookmark not implemented")

method moveBookmark*(adapter: JJAdapter, name: string, revId: JJRevId): bool {.base.} =
  ## Move a bookmark to a new revision
  raise newException(CatchableError, "moveBookmark not implemented")

method getBookmark*(adapter: JJAdapter, name: string): Option[JJBookmark] {.base.} =
  ## Get a specific bookmark
  raise newException(CatchableError, "getBookmark not implemented")

# =============================================================================
# Operation Log (Audit Trail)
# =============================================================================

method getOperationLog*(adapter: JJAdapter, limit: int = 100): JJOperationLog {.base.} =
  ## Get operation log (audit trail)
  raise newException(CatchableError, "getOperationLog not implemented")

method getOperation*(adapter: JJAdapter, opId: JJOperationId): Option[JJOperation] {.base.} =
  ## Get a specific operation by ID
  raise newException(CatchableError, "getOperation not implemented")

method undoOperation*(adapter: JJAdapter, opId: JJOperationId): bool {.base.} =
  ## Undo a specific operation
  raise newException(CatchableError, "undoOperation not implemented")

method restoreToOperation*(adapter: JJAdapter, opId: JJOperationId): bool {.base.} =
  ## Restore repository to a specific operation state
  raise newException(CatchableError, "restoreToOperation not implemented")

# =============================================================================
# Workspace Operations
# =============================================================================

method listWorkspaces*(adapter: JJAdapter): JJWorkspaceList {.base.} =
  ## List all workspaces
  raise newException(CatchableError, "listWorkspaces not implemented")

method addWorkspace*(adapter: JJAdapter, name: string, path: string): bool {.base.} =
  ## Add a new workspace
  raise newException(CatchableError, "addWorkspace not implemented")

method forgetWorkspace*(adapter: JJAdapter, name: string): bool {.base.} =
  ## Forget a workspace (stop tracking)
  raise newException(CatchableError, "forgetWorkspace not implemented")

# =============================================================================
# Git Operations
# =============================================================================

method listGitRemotes*(adapter: JJAdapter): seq[JJGitRemote] {.base.} =
  ## List configured Git remotes
  raise newException(CatchableError, "listGitRemotes not implemented")

method gitFetch*(adapter: JJAdapter, remote: string = "origin"): JJGitFetchResult {.base.} =
  ## Fetch from a Git remote
  raise newException(CatchableError, "gitFetch not implemented")

method gitPush*(adapter: JJAdapter, remote: string = "origin", bookmarks: seq[string] = @[]): JJGitPushResult {.base.} =
  ## Push to a Git remote
  raise newException(CatchableError, "gitPush not implemented")
