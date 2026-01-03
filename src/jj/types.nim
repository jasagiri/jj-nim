## JJ Types
##
## Self-contained type definitions for Jujutsu VCS operations.
## No external dependencies - designed for maximum reusability.

import std/[times, hashes, options, json, sequtils]

# =============================================================================
# Basic ID Types (distinct strings for type safety)
# =============================================================================

type
  JJRevId* = distinct string
    ## Revision identifier (commit hash in JJ)

  JJChangeId* = distinct string
    ## Change identifier (JJ's immutable change tracking ID)

  JJTimestamp* = int64
    ## Timestamp in milliseconds since epoch

# String conversions
proc `$`*(x: JJRevId): string {.borrow.}
proc `$`*(x: JJChangeId): string {.borrow.}

# Equality comparisons
proc `==`*(a, b: JJRevId): bool {.borrow.}
proc `==`*(a, b: JJChangeId): bool {.borrow.}

# Hash functions for use in tables/sets
proc hash*(x: JJRevId): Hash {.borrow.}
proc hash*(x: JJChangeId): Hash {.borrow.}

# Constructors
proc newJJRevId*(s: string): JJRevId =
  ## Create a new revision identifier
  if s.len == 0:
    raise newException(ValueError, "JJRevId cannot be empty")
  result = JJRevId(s)

proc newJJChangeId*(s: string): JJChangeId =
  ## Create a new change identifier
  if s.len == 0:
    raise newException(ValueError, "JJChangeId cannot be empty")
  result = JJChangeId(s)

# Timestamp utilities
proc jjNowMs*(): JJTimestamp =
  ## Get current timestamp in milliseconds
  result = JJTimestamp(epochTime() * 1000)

proc toDateTime*(ts: JJTimestamp): DateTime =
  ## Convert millisecond timestamp to DateTime
  fromUnix(ts div 1000).utc()

# =============================================================================
# Merge Strategy
# =============================================================================

type
  JJMergeStrategy* = enum
    ## Merge strategy for integrating changes
    jjStrategyRebase = "rebase"
    jjStrategySquash = "squash"
    jjStrategyMerge = "merge"

# =============================================================================
# Result Types
# =============================================================================

type
  JJRef* = object
    ## Resolved JJ reference
    name*: string
    revId*: JJRevId
    changeId*: Option[JJChangeId]

  JJRevision* = object
    ## JJ revision metadata
    revId*: JJRevId
    changeId*: JJChangeId
    author*: string
    timestamp*: JJTimestamp
    description*: string
    parents*: seq[JJRevId]

  JJMergeBase* = object
    ## Merge base result
    baseRev*: JJRevId
    headRev*: JJRevId
    mergeBaseRev*: JJRevId

  JJAncestryResult* = object
    ## Ancestry check result
    baseRev*: JJRevId
    headRev*: JJRevId
    isAncestor*: bool

  JJConflictResult* = object
    ## Conflict detection result
    hasConflict*: bool
    conflictingFiles*: seq[string]
    detail*: string

  JJMergeResult* = object
    ## Merge execution result
    success*: bool
    mergedRev*: Option[JJRevId]
    errorCode*: Option[string]
    errorMessage*: Option[string]

  JJError* = object of CatchableError
    ## Error from JJ operations
    exitCode*: int
    stderr*: string

# =============================================================================
# Rewrite Tracking Types
# =============================================================================

type
  JJRewriteEntry* = object
    ## Entry in rewrite map
    oldRev*: JJRevId
    newRev*: JJRevId
    changeId*: JJChangeId
    rewrittenAt*: JJTimestamp

  JJRewriteMap* = ref object
    ## Tracks rev rewrites for a change
    changeId*: JJChangeId
    entries*: seq[JJRewriteEntry]

# =============================================================================
# Bookmark Types
# =============================================================================

type
  JJBookmarkState* = enum
    ## Bookmark tracking state
    jjBookmarkLocal = "local"         # Local only
    jjBookmarkTracking = "tracking"   # Tracking remote
    jjBookmarkConflict = "conflict"   # Conflicting with remote

  JJBookmark* = object
    ## JJ bookmark (named reference)
    name*: string
    revId*: JJRevId
    remote*: Option[string]           # Remote name if tracking
    state*: JJBookmarkState

  JJBookmarkList* = seq[JJBookmark]

# =============================================================================
# Operation Log Types (Critical for Audit)
# =============================================================================

type
  JJOperationId* = distinct string
    ## Operation identifier

  JJOperationType* = enum
    ## Type of operation performed
    jjOpCheckout = "checkout"
    jjOpCommit = "commit"
    jjOpRebase = "rebase"
    jjOpSquash = "squash"
    jjOpMerge = "merge"
    jjOpNew = "new"
    jjOpDescribe = "describe"
    jjOpAbandon = "abandon"
    jjOpRestore = "restore"
    jjOpGitFetch = "git fetch"
    jjOpGitPush = "git push"
    jjOpUndo = "undo"
    jjOpOther = "other"

  JJOperation* = object
    ## Operation log entry
    id*: JJOperationId
    timestamp*: JJTimestamp
    opType*: JJOperationType
    description*: string
    user*: string
    tags*: seq[string]

  JJOperationLog* = seq[JJOperation]

# Operation ID utilities
proc `$`*(x: JJOperationId): string {.borrow.}
proc `==`*(a, b: JJOperationId): bool {.borrow.}
proc hash*(x: JJOperationId): Hash {.borrow.}

proc newJJOperationId*(s: string): JJOperationId =
  if s.len == 0:
    raise newException(ValueError, "JJOperationId cannot be empty")
  result = JJOperationId(s)

# =============================================================================
# Workspace Types
# =============================================================================

type
  JJWorkspace* = object
    ## JJ workspace
    name*: string
    path*: string
    workingCopyRev*: Option[JJRevId]

  JJWorkspaceList* = seq[JJWorkspace]

# =============================================================================
# Git Operation Types
# =============================================================================

type
  JJGitRemote* = object
    ## Git remote configuration
    name*: string
    url*: string

  JJGitFetchResult* = object
    ## Result of git fetch
    success*: bool
    updatedBookmarks*: seq[string]
    errorMessage*: Option[string]

  JJGitPushResult* = object
    ## Result of git push
    success*: bool
    pushedBookmarks*: seq[string]
    errorCode*: Option[string]
    errorMessage*: Option[string]

# =============================================================================
# JSON Serialization
# =============================================================================

proc toJson*(jjRef: JJRef): JsonNode =
  result = %*{
    "name": jjRef.name,
    "revId": $jjRef.revId
  }
  if jjRef.changeId.isSome:
    result["changeId"] = %($jjRef.changeId.get)

proc toJson*(rev: JJRevision): JsonNode =
  %*{
    "revId": $rev.revId,
    "changeId": $rev.changeId,
    "author": rev.author,
    "timestamp": rev.timestamp,
    "description": rev.description,
    "parents": rev.parents.mapIt($it)
  }

proc toJson*(mergeResult: JJMergeResult): JsonNode =
  var j = %*{
    "success": mergeResult.success
  }
  if mergeResult.mergedRev.isSome:
    j["mergedRev"] = %($mergeResult.mergedRev.get)
  if mergeResult.errorCode.isSome:
    j["errorCode"] = %(mergeResult.errorCode.get)
  if mergeResult.errorMessage.isSome:
    j["errorMessage"] = %(mergeResult.errorMessage.get)
  return j

proc toJson*(bookmark: JJBookmark): JsonNode =
  result = %*{
    "name": bookmark.name,
    "revId": $bookmark.revId,
    "state": $bookmark.state
  }
  if bookmark.remote.isSome:
    result["remote"] = %(bookmark.remote.get)

proc toJson*(op: JJOperation): JsonNode =
  %*{
    "id": $op.id,
    "timestamp": op.timestamp,
    "type": $op.opType,
    "description": op.description,
    "user": op.user,
    "tags": op.tags
  }

proc toJson*(workspace: JJWorkspace): JsonNode =
  result = %*{
    "name": workspace.name,
    "path": workspace.path
  }
  if workspace.workingCopyRev.isSome:
    result["workingCopyRev"] = %($workspace.workingCopyRev.get)

proc toJson*(remote: JJGitRemote): JsonNode =
  %*{
    "name": remote.name,
    "url": remote.url
  }
