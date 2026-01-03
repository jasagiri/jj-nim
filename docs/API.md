# jj-nim API Reference

Complete API documentation for jj-nim.

## Table of Contents

- [Types](#types)
  - [Core Types](#core-types)
  - [Result Types](#result-types)
  - [Bookmark Types](#bookmark-types)
  - [Operation Types](#operation-types)
  - [Workspace Types](#workspace-types)
  - [Git Types](#git-types)
- [Adapters](#adapters)
  - [JJAdapter (Abstract)](#jjadapter-abstract)
  - [JJCliAdapter](#jjcliadapter)
  - [JJMockAdapter](#jjmockadapter)
- [Methods](#methods)
  - [Core Methods](#core-methods)
  - [Bookmark Methods](#bookmark-methods)
  - [Operation Log Methods](#operation-log-methods)
  - [Workspace Methods](#workspace-methods)
  - [Git Methods](#git-methods)

---

## Types

### Core Types

#### JJRevId

Revision identifier (commit hash). Type-safe wrapper around string.

```nim
type JJRevId* = distinct string

proc newJJRevId*(s: string): JJRevId
  ## Create a new revision ID. Raises ValueError if empty.

proc `$`*(x: JJRevId): string
  ## Convert to string.

proc `==`*(a, b: JJRevId): bool
  ## Compare for equality.

proc hash*(x: JJRevId): Hash
  ## Hash for use in tables.
```

**Example:**
```nim
let rev = newJJRevId("abc123def456")
echo rev  # "abc123def456"
```

#### JJChangeId

Change identifier (JJ's immutable tracking ID).

```nim
type JJChangeId* = distinct string

proc newJJChangeId*(s: string): JJChangeId
  ## Create a new change ID. Raises ValueError if empty.
```

#### JJTimestamp

Timestamp in milliseconds since epoch.

```nim
type JJTimestamp* = int64

proc jjNowMs*(): JJTimestamp
  ## Get current timestamp in milliseconds.

proc toDateTime*(ts: JJTimestamp): DateTime
  ## Convert to DateTime.
```

#### JJMergeStrategy

Merge strategy enumeration.

```nim
type JJMergeStrategy* = enum
  jjStrategyRebase = "rebase"  ## Rebase commits onto target
  jjStrategySquash = "squash"  ## Squash commits into one
  jjStrategyMerge = "merge"    ## Create merge commit
```

---

### Result Types

#### JJRef

Resolved JJ reference.

```nim
type JJRef* = object
  name*: string              ## Reference name (e.g., "main")
  revId*: JJRevId            ## Current revision ID
  changeId*: Option[JJChangeId]  ## Optional change ID

proc toJson*(jjRef: JJRef): JsonNode
  ## Serialize to JSON.
```

#### JJRevision

Revision metadata.

```nim
type JJRevision* = object
  revId*: JJRevId            ## Revision ID
  changeId*: JJChangeId      ## Change ID
  author*: string            ## Author name
  timestamp*: JJTimestamp    ## Commit timestamp
  description*: string       ## Commit message
  parents*: seq[JJRevId]     ## Parent revisions

proc toJson*(rev: JJRevision): JsonNode
  ## Serialize to JSON.
```

#### JJMergeBase

Merge base computation result.

```nim
type JJMergeBase* = object
  baseRev*: JJRevId          ## Base revision
  headRev*: JJRevId          ## Head revision
  mergeBaseRev*: JJRevId     ## Common ancestor
```

#### JJConflictResult

Conflict detection result.

```nim
type JJConflictResult* = object
  hasConflict*: bool         ## True if conflicts exist
  conflictingFiles*: seq[string]  ## List of conflicting files
  detail*: string            ## Detailed conflict information
```

#### JJMergeResult

Merge execution result.

```nim
type JJMergeResult* = object
  success*: bool             ## True if merge succeeded
  mergedRev*: Option[JJRevId]  ## New revision if successful
  errorCode*: Option[string]   ## Error code if failed
  errorMessage*: Option[string] ## Error message if failed

proc toJson*(mergeResult: JJMergeResult): JsonNode
  ## Serialize to JSON.
```

#### JJError

JJ operation error.

```nim
type JJError* = object of CatchableError
  exitCode*: int             ## JJ exit code
  stderr*: string            ## Standard error output
```

#### JJRewriteEntry

Entry in rewrite history.

```nim
type JJRewriteEntry* = object
  oldRev*: JJRevId           ## Original revision
  newRev*: JJRevId           ## Rewritten revision
  changeId*: JJChangeId      ## Change ID
  rewrittenAt*: JJTimestamp  ## When rewrite occurred
```

#### JJRewriteMap

Complete rewrite history for a change.

```nim
type JJRewriteMap* = ref object
  changeId*: JJChangeId      ## Change being tracked
  entries*: seq[JJRewriteEntry]  ## Rewrite history
```

---

### Bookmark Types

#### JJBookmarkState

Bookmark state enumeration.

```nim
type JJBookmarkState* = enum
  jjBookmarkLocal = "local"       ## Local bookmark only
  jjBookmarkTracking = "tracking" ## Tracking remote
  jjBookmarkConflict = "conflict" ## Conflicting with remote
```

#### JJBookmark

Named reference to a revision.

```nim
type JJBookmark* = object
  name*: string              ## Bookmark name
  revId*: JJRevId            ## Target revision
  remote*: Option[string]    ## Remote name if tracking
  state*: JJBookmarkState    ## Current state

proc toJson*(bookmark: JJBookmark): JsonNode
  ## Serialize to JSON.
```

#### JJBookmarkList

List of bookmarks.

```nim
type JJBookmarkList* = seq[JJBookmark]
```

---

### Operation Types

#### JJOperationId

Operation identifier.

```nim
type JJOperationId* = distinct string

proc newJJOperationId*(s: string): JJOperationId
  ## Create new operation ID. Raises ValueError if empty.
```

#### JJOperationType

Type of repository operation.

```nim
type JJOperationType* = enum
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
```

#### JJOperation

Operation log entry.

```nim
type JJOperation* = object
  id*: JJOperationId         ## Unique operation ID
  timestamp*: JJTimestamp    ## When operation occurred
  opType*: JJOperationType   ## Type of operation
  description*: string       ## Operation description
  user*: string              ## User who performed operation
  tags*: seq[string]         ## Optional tags

proc toJson*(op: JJOperation): JsonNode
  ## Serialize to JSON.
```

#### JJOperationLog

Sequence of operations.

```nim
type JJOperationLog* = seq[JJOperation]
```

---

### Workspace Types

#### JJWorkspace

JJ workspace.

```nim
type JJWorkspace* = object
  name*: string              ## Workspace name
  path*: string              ## Filesystem path
  workingCopyRev*: Option[JJRevId]  ## Current working copy

proc toJson*(workspace: JJWorkspace): JsonNode
  ## Serialize to JSON.
```

#### JJWorkspaceList

List of workspaces.

```nim
type JJWorkspaceList* = seq[JJWorkspace]
```

---

### Git Types

#### JJGitRemote

Git remote configuration.

```nim
type JJGitRemote* = object
  name*: string              ## Remote name (e.g., "origin")
  url*: string               ## Remote URL

proc toJson*(remote: JJGitRemote): JsonNode
  ## Serialize to JSON.
```

#### JJGitFetchResult

Result of git fetch operation.

```nim
type JJGitFetchResult* = object
  success*: bool             ## True if fetch succeeded
  updatedBookmarks*: seq[string]  ## Updated bookmark names
  errorMessage*: Option[string]   ## Error if failed
```

#### JJGitPushResult

Result of git push operation.

```nim
type JJGitPushResult* = object
  success*: bool             ## True if push succeeded
  pushedBookmarks*: seq[string]  ## Pushed bookmark names
  errorCode*: Option[string]     ## Error code if failed
  errorMessage*: Option[string]  ## Error message if failed
```

---

## Adapters

### JJAdapter (Abstract)

Base class for JJ adapters. Defines the interface.

```nim
type JJAdapter* = ref object of RootObj
  repoPath*: string          ## Path to repository
```

All methods raise `CatchableError` with "not implemented" if called on base class.

### JJCliAdapter

CLI adapter that wraps the `jj` command.

```nim
type JJCliAdapter* = ref object of JJAdapter
  jjPath*: string            ## Path to jj binary

proc newJJCliAdapter*(repoPath: string, jjPath = "jj"): JJCliAdapter
  ## Create new CLI adapter.
  ## - repoPath: Path to JJ repository
  ## - jjPath: Path to jj binary (default: "jj" in PATH)
```

**Example:**
```nim
let adapter = newJJCliAdapter("/path/to/repo")
let customJJ = newJJCliAdapter("/path/to/repo", "/usr/local/bin/jj")
```

### JJMockAdapter

Mock adapter for testing without real JJ.

```nim
type JJMockAdapter* = ref object of JJAdapter
  refs*: seq[JJRef]
  revisions*: seq[JJRevision]
  conflicts*: seq[(JJRevId, JJRevId)]
  ancestryPairs*: seq[(JJRevId, JJRevId)]
  bookmarks*: seq[JJBookmark]
  operations*: seq[JJOperation]
  workspaces*: seq[JJWorkspace]
  gitRemotes*: seq[JJGitRemote]

proc newJJMockAdapter*(repoPath = "/mock/repo"): JJMockAdapter
  ## Create new mock adapter.
```

#### Setup Methods

```nim
proc addRef*(adapter: JJMockAdapter, name: string, revId: JJRevId,
             changeId: Option[JJChangeId] = none(JJChangeId))
  ## Add a reference to mock.

proc addRevision*(adapter: JJMockAdapter, rev: JJRevision)
  ## Add a revision to mock.

proc addConflict*(adapter: JJMockAdapter, base, head: JJRevId)
  ## Add a conflict pair.

proc addAncestry*(adapter: JJMockAdapter, ancestor, descendant: JJRevId)
  ## Add an ancestry relationship.

proc addBookmark*(adapter: JJMockAdapter, name: string, revId: JJRevId,
                  remote: Option[string] = none(string),
                  state: JJBookmarkState = jjBookmarkLocal)
  ## Add a bookmark.

proc addOperation*(adapter: JJMockAdapter, op: JJOperation)
  ## Add an operation to the log.

proc setupWorkspace*(adapter: JJMockAdapter, name: string, path: string,
                     workingCopyRev: Option[JJRevId] = none(JJRevId))
  ## Setup a workspace.

proc addGitRemote*(adapter: JJMockAdapter, name: string, url: string)
  ## Add a git remote.
```

---

## Methods

### Core Methods

#### resolveRef

Resolve a reference name to a revision.

```nim
method resolveRef*(adapter: JJAdapter, refName: string): Option[JJRef]
```

**Parameters:**
- `refName`: Reference name (e.g., "main", "@", "HEAD")

**Returns:** `Some(JJRef)` if found, `None` otherwise.

**Example:**
```nim
let ref = adapter.resolveRef("main")
if ref.isSome:
  echo "Main is at: ", ref.get.revId
```

#### getRevision

Get revision metadata.

```nim
method getRevision*(adapter: JJAdapter, revId: JJRevId): Option[JJRevision]
```

**Parameters:**
- `revId`: Revision identifier

**Returns:** `Some(JJRevision)` with metadata, `None` if not found.

#### computeMergeBase

Find common ancestor of two revisions.

```nim
method computeMergeBase*(adapter: JJAdapter, baseRev, headRev: JJRevId): Option[JJMergeBase]
```

**Parameters:**
- `baseRev`: Base revision
- `headRev`: Head revision

**Returns:** `Some(JJMergeBase)` with common ancestor, `None` if none exists.

#### isAncestor

Check if one revision is an ancestor of another.

```nim
method isAncestor*(adapter: JJAdapter, ancestor, descendant: JJRevId): bool
```

**Parameters:**
- `ancestor`: Potential ancestor revision
- `descendant`: Potential descendant revision

**Returns:** `true` if ancestor is in descendant's history.

#### checkConflicts

Check for conflicts without actually merging.

```nim
method checkConflicts*(adapter: JJAdapter, baseRev, headRev: JJRevId,
                       strategy: JJMergeStrategy): JJConflictResult
```

**Parameters:**
- `baseRev`: Base revision
- `headRev`: Head revision to merge
- `strategy`: Merge strategy to use

**Returns:** `JJConflictResult` with conflict information.

#### performMerge

Execute a merge operation.

```nim
method performMerge*(adapter: JJAdapter, baseRev, headRev: JJRevId,
                     strategy: JJMergeStrategy, message: string): JJMergeResult
```

**Parameters:**
- `baseRev`: Base revision
- `headRev`: Head revision to merge
- `strategy`: Merge strategy
- `message`: Commit message

**Returns:** `JJMergeResult` with success status and new revision.

#### getChangeTip

Get current tip revision for a change.

```nim
method getChangeTip*(adapter: JJAdapter, changeId: JJChangeId): Option[JJRevId]
```

#### observeRewrite

Record a rewrite operation.

```nim
method observeRewrite*(adapter: JJAdapter, oldRev, newRev: JJRevId): void
```

#### getRewriteHistory

Get rewrite history for a change (obslog).

```nim
method getRewriteHistory*(adapter: JJAdapter, changeId: JJChangeId): seq[JJRewriteEntry]
```

#### trackChangeEvolution

Build complete rewrite map for a change.

```nim
method trackChangeEvolution*(adapter: JJAdapter, changeId: JJChangeId): JJRewriteMap
```

#### wasRewritten

Check if a revision was rewritten.

```nim
method wasRewritten*(adapter: JJAdapter, oldRev: JJRevId,
                     changeId: JJChangeId): Option[JJRevId]
```

**Returns:** `Some(newRevId)` if rewritten, `None` otherwise.

#### getCurrentRevForChange

Get the current (latest) revision for a change.

```nim
method getCurrentRevForChange*(adapter: JJAdapter, changeId: JJChangeId): Option[JJRevId]
```

#### getChangedPaths

Get list of paths changed in a revision.

```nim
method getChangedPaths*(adapter: JJAdapter, revId: JJRevId): seq[string]
```

---

### Bookmark Methods

#### listBookmarks

List all bookmarks in the repository.

```nim
method listBookmarks*(adapter: JJAdapter): JJBookmarkList
```

#### createBookmark

Create a new bookmark.

```nim
method createBookmark*(adapter: JJAdapter, name: string, revId: JJRevId): bool
```

**Returns:** `true` if created successfully.

#### deleteBookmark

Delete a bookmark.

```nim
method deleteBookmark*(adapter: JJAdapter, name: string): bool
```

**Returns:** `true` if deleted successfully.

#### moveBookmark

Move a bookmark to a new revision.

```nim
method moveBookmark*(adapter: JJAdapter, name: string, revId: JJRevId): bool
```

**Returns:** `true` if moved successfully.

#### getBookmark

Get a specific bookmark by name.

```nim
method getBookmark*(adapter: JJAdapter, name: string): Option[JJBookmark]
```

---

### Operation Log Methods

#### getOperationLog

Get operation history (audit trail).

```nim
method getOperationLog*(adapter: JJAdapter, limit: int = 100): JJOperationLog
```

**Parameters:**
- `limit`: Maximum number of operations to return (default: 100)

#### getOperation

Get a specific operation by ID.

```nim
method getOperation*(adapter: JJAdapter, opId: JJOperationId): Option[JJOperation]
```

#### undoOperation

Undo a specific operation.

```nim
method undoOperation*(adapter: JJAdapter, opId: JJOperationId): bool
```

**Returns:** `true` if undo succeeded.

#### restoreToOperation

Restore repository to a specific operation state.

```nim
method restoreToOperation*(adapter: JJAdapter, opId: JJOperationId): bool
```

**Returns:** `true` if restore succeeded.

---

### Workspace Methods

#### listWorkspaces

List all workspaces.

```nim
method listWorkspaces*(adapter: JJAdapter): JJWorkspaceList
```

#### addWorkspace

Add a new workspace.

```nim
method addWorkspace*(adapter: JJAdapter, name: string, path: string): bool
```

**Returns:** `true` if added successfully.

#### forgetWorkspace

Forget (remove) a workspace.

```nim
method forgetWorkspace*(adapter: JJAdapter, name: string): bool
```

**Returns:** `true` if removed successfully.

---

### Git Methods

#### listGitRemotes

List configured Git remotes.

```nim
method listGitRemotes*(adapter: JJAdapter): seq[JJGitRemote]
```

#### gitFetch

Fetch from a Git remote.

```nim
method gitFetch*(adapter: JJAdapter, remote: string = "origin"): JJGitFetchResult
```

**Parameters:**
- `remote`: Remote name (default: "origin")

#### gitPush

Push to a Git remote.

```nim
method gitPush*(adapter: JJAdapter, remote: string = "origin",
                bookmarks: seq[string] = @[]): JJGitPushResult
```

**Parameters:**
- `remote`: Remote name (default: "origin")
- `bookmarks`: Specific bookmarks to push (empty = all)

---

## Error Handling

All methods handle errors gracefully:

- **CLI Adapter**: Returns `None` or failure results for invalid repos/commands
- **Mock Adapter**: Returns configured mock data or empty results

```nim
# Safe pattern
let ref = adapter.resolveRef("main")
if ref.isNone:
  echo "Reference not found"
  return

# Access the value
let revision = ref.get.revId
```

For merge operations, check the result:

```nim
let result = adapter.performMerge(base, head, strategy, msg)
if not result.success:
  echo "Merge failed: ", result.errorMessage.get
else:
  echo "Merged to: ", result.mergedRev.get
```
