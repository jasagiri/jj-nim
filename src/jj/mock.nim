## JJ Mock Adapter
##
## Mock implementation of JJ adapter for testing without real JJ.

import std/options
import types
import adapter

export adapter

# =============================================================================
# Mock Adapter
# =============================================================================

type
  JJMockAdapter* = ref object of JJAdapter
    ## Mock adapter for testing without real JJ
    refs*: seq[JJRef]
    revisions*: seq[JJRevision]
    conflicts*: seq[(JJRevId, JJRevId)]  # Pairs that have conflicts
    ancestryPairs*: seq[(JJRevId, JJRevId)]  # (ancestor, descendant) pairs
    # New mock data storage
    bookmarks*: seq[JJBookmark]
    operations*: seq[JJOperation]
    workspaces*: seq[JJWorkspace]
    gitRemotes*: seq[JJGitRemote]

proc newJJMockAdapter*(repoPath = "/mock/repo"): JJMockAdapter =
  result = JJMockAdapter(repoPath: repoPath)
  result.refs = @[]
  result.revisions = @[]
  result.conflicts = @[]
  result.ancestryPairs = @[]
  result.bookmarks = @[]
  result.operations = @[]
  result.workspaces = @[]
  result.gitRemotes = @[]

# =============================================================================
# Setup Methods (for configuring mock behavior)
# =============================================================================

proc addRef*(adapter: JJMockAdapter, name: string, revId: JJRevId, changeId: Option[JJChangeId] = none(JJChangeId)) =
  adapter.refs.add(JJRef(name: name, revId: revId, changeId: changeId))

proc addRevision*(adapter: JJMockAdapter, rev: JJRevision) =
  adapter.revisions.add(rev)

proc addConflict*(adapter: JJMockAdapter, base, head: JJRevId) =
  adapter.conflicts.add((base, head))

proc addAncestry*(adapter: JJMockAdapter, ancestor, descendant: JJRevId) =
  adapter.ancestryPairs.add((ancestor, descendant))

proc addBookmark*(adapter: JJMockAdapter, bookmark: JJBookmark) =
  adapter.bookmarks.add(bookmark)

proc addBookmark*(adapter: JJMockAdapter, name: string, revId: JJRevId, remote: Option[string] = none(string), state: JJBookmarkState = jjBookmarkLocal) =
  adapter.bookmarks.add(JJBookmark(name: name, revId: revId, remote: remote, state: state))

proc addOperation*(adapter: JJMockAdapter, op: JJOperation) =
  adapter.operations.add(op)

proc addWorkspace*(adapter: JJMockAdapter, workspace: JJWorkspace) =
  adapter.workspaces.add(workspace)

proc setupWorkspace*(adapter: JJMockAdapter, name: string, path: string, workingCopyRev: Option[JJRevId] = none(JJRevId)) =
  ## Setup method for configuring mock workspaces (for test setup)
  adapter.workspaces.add(JJWorkspace(name: name, path: path, workingCopyRev: workingCopyRev))

proc addGitRemote*(adapter: JJMockAdapter, remote: JJGitRemote) =
  adapter.gitRemotes.add(remote)

proc addGitRemote*(adapter: JJMockAdapter, name: string, url: string) =
  adapter.gitRemotes.add(JJGitRemote(name: name, url: url))

# =============================================================================
# Interface Implementation
# =============================================================================

method resolveRef*(adapter: JJMockAdapter, refName: string): Option[JJRef] =
  for r in adapter.refs:
    if r.name == refName:
      return some(r)
  return none(JJRef)

method getRevision*(adapter: JJMockAdapter, revId: JJRevId): Option[JJRevision] =
  for r in adapter.revisions:
    if r.revId == revId:
      return some(r)
  return none(JJRevision)

method computeMergeBase*(adapter: JJMockAdapter, baseRev, headRev: JJRevId): Option[JJMergeBase] =
  # Simple mock: merge base is the base revision
  return some(JJMergeBase(
    baseRev: baseRev,
    headRev: headRev,
    mergeBaseRev: baseRev
  ))

method isAncestor*(adapter: JJMockAdapter, ancestor, descendant: JJRevId): bool =
  for (a, d) in adapter.ancestryPairs:
    if a == ancestor and d == descendant:
      return true
  return false

method checkConflicts*(adapter: JJMockAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy): JJConflictResult =
  for (b, h) in adapter.conflicts:
    if b == baseRev and h == headRev:
      return JJConflictResult(
        hasConflict: true,
        conflictingFiles: @["mock/conflict.txt"],
        detail: "Mock conflict detected"
      )
  return JJConflictResult(
    hasConflict: false,
    conflictingFiles: @[],
    detail: ""
  )

method performMerge*(adapter: JJMockAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy, message: string): JJMergeResult =
  # Check for conflicts first
  let conflicts = adapter.checkConflicts(baseRev, headRev, strategy)
  if conflicts.hasConflict:
    return JJMergeResult(
      success: false,
      mergedRev: none(JJRevId),
      errorCode: some("ERR_CONFLICT"),
      errorMessage: some("Merge conflict: " & conflicts.detail)
    )

  # Mock successful merge
  let mergedRev = newJJRevId($headRev & "-merged")
  return JJMergeResult(
    success: true,
    mergedRev: some(mergedRev),
    errorCode: none(string),
    errorMessage: none(string)
  )

method getChangeTip*(adapter: JJMockAdapter, changeId: JJChangeId): Option[JJRevId] =
  for r in adapter.revisions:
    if r.changeId == changeId:
      return some(r.revId)
  return none(JJRevId)

method observeRewrite*(adapter: JJMockAdapter, oldRev, newRev: JJRevId) =
  # No-op for mock
  discard

method getRewriteHistory*(adapter: JJMockAdapter, changeId: JJChangeId): seq[JJRewriteEntry] =
  # Return empty history for mock
  @[]

method trackChangeEvolution*(adapter: JJMockAdapter, changeId: JJChangeId): JJRewriteMap =
  JJRewriteMap(changeId: changeId, entries: @[])

method wasRewritten*(adapter: JJMockAdapter, oldRev: JJRevId, changeId: JJChangeId): Option[JJRevId] =
  none(JJRevId)

method getCurrentRevForChange*(adapter: JJMockAdapter, changeId: JJChangeId): Option[JJRevId] =
  adapter.getChangeTip(changeId)

method getChangedPaths*(adapter: JJMockAdapter, revId: JJRevId): seq[string] =
  @[]

# =============================================================================
# Bookmark Operations
# =============================================================================

method listBookmarks*(adapter: JJMockAdapter): JJBookmarkList =
  adapter.bookmarks

method createBookmark*(adapter: JJMockAdapter, name: string, revId: JJRevId): bool =
  # Check if bookmark already exists
  for b in adapter.bookmarks:
    if b.name == name:
      return false
  adapter.bookmarks.add(JJBookmark(
    name: name,
    revId: revId,
    remote: none(string),
    state: jjBookmarkLocal
  ))
  return true

method deleteBookmark*(adapter: JJMockAdapter, name: string): bool =
  for i in countdown(adapter.bookmarks.high, 0):
    if adapter.bookmarks[i].name == name:
      adapter.bookmarks.delete(i)
      return true
  return false

method moveBookmark*(adapter: JJMockAdapter, name: string, revId: JJRevId): bool =
  for i in 0..<adapter.bookmarks.len:
    if adapter.bookmarks[i].name == name:
      adapter.bookmarks[i].revId = revId
      return true
  return false

method getBookmark*(adapter: JJMockAdapter, name: string): Option[JJBookmark] =
  for b in adapter.bookmarks:
    if b.name == name:
      return some(b)
  return none(JJBookmark)

# =============================================================================
# Operation Log (Audit Trail)
# =============================================================================

method getOperationLog*(adapter: JJMockAdapter, limit: int = 100): JJOperationLog =
  if adapter.operations.len <= limit:
    return adapter.operations
  else:
    return adapter.operations[0..<limit]

method getOperation*(adapter: JJMockAdapter, opId: JJOperationId): Option[JJOperation] =
  for op in adapter.operations:
    if op.id == opId:
      return some(op)
  return none(JJOperation)

method undoOperation*(adapter: JJMockAdapter, opId: JJOperationId): bool =
  # Mock undo - just add an undo operation
  adapter.operations.add(JJOperation(
    id: newJJOperationId("undo-" & $opId),
    timestamp: jjNowMs(),
    opType: jjOpUndo,
    description: "Undo " & $opId,
    user: "mock-user",
    tags: @[]
  ))
  return true

method restoreToOperation*(adapter: JJMockAdapter, opId: JJOperationId): bool =
  # Mock restore - just add a restore operation
  adapter.operations.add(JJOperation(
    id: newJJOperationId("restore-" & $opId),
    timestamp: jjNowMs(),
    opType: jjOpRestore,
    description: "Restore to " & $opId,
    user: "mock-user",
    tags: @[]
  ))
  return true

# =============================================================================
# Workspace Operations
# =============================================================================

method listWorkspaces*(adapter: JJMockAdapter): JJWorkspaceList =
  adapter.workspaces

method addWorkspace*(adapter: JJMockAdapter, name: string, path: string): bool =
  # Check if workspace already exists
  for w in adapter.workspaces:
    if w.name == name:
      return false
  adapter.workspaces.add(JJWorkspace(
    name: name,
    path: path,
    workingCopyRev: none(JJRevId)
  ))
  return true

method forgetWorkspace*(adapter: JJMockAdapter, name: string): bool =
  for i in countdown(adapter.workspaces.high, 0):
    if adapter.workspaces[i].name == name:
      adapter.workspaces.delete(i)
      return true
  return false

# =============================================================================
# Git Operations
# =============================================================================

method listGitRemotes*(adapter: JJMockAdapter): seq[JJGitRemote] =
  adapter.gitRemotes

method gitFetch*(adapter: JJMockAdapter, remote: string = "origin"): JJGitFetchResult =
  # Check if remote exists
  var found = false
  for r in adapter.gitRemotes:
    if r.name == remote:
      found = true
      break

  if not found:
    return JJGitFetchResult(
      success: false,
      updatedBookmarks: @[],
      errorMessage: some("Remote not found: " & remote)
    )

  return JJGitFetchResult(
    success: true,
    updatedBookmarks: @[],
    errorMessage: none(string)
  )

method gitPush*(adapter: JJMockAdapter, remote: string = "origin", bookmarks: seq[string] = @[]): JJGitPushResult =
  # Check if remote exists
  var found = false
  for r in adapter.gitRemotes:
    if r.name == remote:
      found = true
      break

  if not found:
    return JJGitPushResult(
      success: false,
      pushedBookmarks: @[],
      errorCode: some("ERR_REMOTE_NOT_FOUND"),
      errorMessage: some("Remote not found: " & remote)
    )

  return JJGitPushResult(
    success: true,
    pushedBookmarks: bookmarks,
    errorCode: none(string),
    errorMessage: none(string)
  )
