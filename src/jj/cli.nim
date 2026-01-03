## JJ CLI Adapter
##
## Real implementation of JJ adapter using CLI commands.
## Wraps `jj` command-line tool for version control operations.

import std/[osproc, options, strutils, strformat]
import types
import adapter

export adapter

# =============================================================================
# JJ CLI Adapter
# =============================================================================

type
  JJCliAdapter* = ref object of JJAdapter
    ## JJ CLI wrapper adapter
    jjPath*: string  # Path to jj binary

proc newJJCliAdapter*(repoPath: string, jjPath = "jj"): JJCliAdapter =
  ## Create a new JJ CLI adapter
  result = JJCliAdapter(repoPath: repoPath, jjPath: jjPath)

proc runJJ(adapter: JJCliAdapter, args: seq[string]): tuple[output: string, exitCode: int] =
  ## Run a jj command and return output
  let fullArgs = @["--repository", adapter.repoPath] & args
  let cmd = adapter.jjPath & " " & fullArgs.join(" ")

  let (output, exitCode) = execCmdEx(cmd)
  result = (output.strip(), exitCode)


# =============================================================================
# Interface Implementation
# =============================================================================

method resolveRef*(adapter: JJCliAdapter, refName: string): Option[JJRef] =
  ## Resolve a reference to revision using jj log
  let (output, exitCode) = adapter.runJJ(@[
    "log",
    "-r", refName,
    "--no-graph",
    "-T", """concat(commit_id, "\n", change_id, "\n")"""
  ])

  if exitCode != 0:
    return none(JJRef)

  let lines = output.splitLines()
  if lines.len < 2:
    return none(JJRef)

  return some(JJRef(
    name: refName,
    revId: newJJRevId(lines[0]),
    changeId: some(newJJChangeId(lines[1]))
  ))

method getRevision*(adapter: JJCliAdapter, revId: JJRevId): Option[JJRevision] =
  ## Get revision metadata
  let (output, exitCode) = adapter.runJJ(@[
    "log",
    "-r", $revId,
    "--no-graph",
    "-T", """concat(
      commit_id, "\n",
      change_id, "\n",
      author.name(), "\n",
      author.timestamp().utc().format("%Y-%m-%dT%H:%M:%SZ"), "\n",
      description.first_line(), "\n",
      parents.map(|p| p.commit_id()).join(","), "\n"
    )"""
  ])

  if exitCode != 0:
    return none(JJRevision)

  let lines = output.splitLines()
  if lines.len < 6:
    return none(JJRevision)

  var parents: seq[JJRevId] = @[]
  if lines[5].len > 0:
    for p in lines[5].split(","):
      if p.len > 0:
        parents.add(newJJRevId(p))

  # Parse timestamp (simplified)
  let timestamp = jjNowMs()  # TODO: Parse actual timestamp

  return some(JJRevision(
    revId: newJJRevId(lines[0]),
    changeId: newJJChangeId(lines[1]),
    author: lines[2],
    timestamp: timestamp,
    description: lines[4],
    parents: parents
  ))

method computeMergeBase*(adapter: JJCliAdapter, baseRev, headRev: JJRevId): Option[JJMergeBase] =
  ## Compute merge base using jj log with ancestor query
  let (output, exitCode) = adapter.runJJ(@[
    "log",
    "-r", fmt"heads(ancestors({$baseRev}) & ancestors({$headRev}))",
    "--no-graph",
    "-T", "commit_id"
  ])

  if exitCode != 0:
    return none(JJMergeBase)

  let mergeBaseStr = output.strip()
  if mergeBaseStr.len == 0:
    return none(JJMergeBase)

  return some(JJMergeBase(
    baseRev: baseRev,
    headRev: headRev,
    mergeBaseRev: newJJRevId(mergeBaseStr)
  ))

method isAncestor*(adapter: JJCliAdapter, ancestor, descendant: JJRevId): bool =
  ## Check ancestry using jj log with ancestor query
  let (output, exitCode) = adapter.runJJ(@[
    "log",
    "-r", fmt"{$ancestor} & ancestors({$descendant})",
    "--no-graph",
    "-T", "commit_id"
  ])

  if exitCode != 0:
    return false

  return output.strip().len > 0

method checkConflicts*(adapter: JJCliAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy): JJConflictResult =
  ## Check for conflicts using dry-run merge
  # Use jj merge --dry-run if available, otherwise simulate
  let (output, exitCode) = adapter.runJJ(@[
    "resolve",
    "--list",
    "-r", $headRev
  ])

  # If resolve --list shows conflicts, there are conflicts
  if exitCode != 0 or output.contains("Conflict"):
    return JJConflictResult(
      hasConflict: true,
      conflictingFiles: @[],  # Parse from output if needed
      detail: output
    )

  return JJConflictResult(
    hasConflict: false,
    conflictingFiles: @[],
    detail: ""
  )

method performMerge*(adapter: JJCliAdapter, baseRev, headRev: JJRevId, strategy: JJMergeStrategy, message: string): JJMergeResult =
  ## Perform the actual merge
  var mergeArgs: seq[string]

  case strategy
  of jjStrategyRebase:
    mergeArgs = @["rebase", "-r", $headRev, "-d", $baseRev, "-m", message]
  of jjStrategySquash:
    mergeArgs = @["squash", "-r", $headRev, "-d", $baseRev, "-m", message]
  of jjStrategyMerge:
    mergeArgs = @["new", $baseRev, $headRev, "-m", message]

  let (output, exitCode) = adapter.runJJ(mergeArgs)

  if exitCode != 0:
    let errorCode = if "conflict" in output.toLowerAscii(): "ERR_CONFLICT" else: "ERR_INTERNAL"
    return JJMergeResult(
      success: false,
      mergedRev: none(JJRevId),
      errorCode: some(errorCode),
      errorMessage: some(output)
    )

  # Get the new revision
  let (newRevOutput, _) = adapter.runJJ(@[
    "log",
    "-r", "@",
    "--no-graph",
    "-T", "commit_id"
  ])

  return JJMergeResult(
    success: true,
    mergedRev: some(newJJRevId(newRevOutput.strip())),
    errorCode: none(string),
    errorMessage: none(string)
  )

method getChangeTip*(adapter: JJCliAdapter, changeId: JJChangeId): Option[JJRevId] =
  ## Get current tip for a change
  let (output, exitCode) = adapter.runJJ(@[
    "log",
    "-r", $changeId,
    "--no-graph",
    "-T", "commit_id"
  ])

  if exitCode != 0:
    return none(JJRevId)

  let revStr = output.strip()
  if revStr.len == 0:
    return none(JJRevId)

  return some(newJJRevId(revStr))

method observeRewrite*(adapter: JJCliAdapter, oldRev, newRev: JJRevId) =
  ## Record a rewrite - JJ tracks this automatically, we just log it
  discard

# =============================================================================
# Rewrite Map Tracking
# =============================================================================

method getRewriteHistory*(adapter: JJCliAdapter, changeId: JJChangeId): seq[JJRewriteEntry] =
  ## Get rewrite history for a change using jj obslog
  let (output, exitCode) = adapter.runJJ(@[
    "obslog",
    "-r", $changeId,
    "--no-graph",
    "-T", """concat(commit_id, "\n")"""
  ])

  result = @[]
  if exitCode != 0:
    return

  var prevRev: Option[JJRevId] = none(JJRevId)
  for line in output.splitLines():
    let revStr = line.strip()
    if revStr.len > 0:
      let rev = newJJRevId(revStr)
      if prevRev.isSome:
        result.add(JJRewriteEntry(
          oldRev: prevRev.get,
          newRev: rev,
          changeId: changeId,
          rewrittenAt: jjNowMs()
        ))
      prevRev = some(rev)

method trackChangeEvolution*(adapter: JJCliAdapter, changeId: JJChangeId): JJRewriteMap =
  ## Build complete rewrite map for a change
  JJRewriteMap(
    changeId: changeId,
    entries: adapter.getRewriteHistory(changeId)
  )

method wasRewritten*(adapter: JJCliAdapter, oldRev: JJRevId, changeId: JJChangeId): Option[JJRevId] =
  ## Check if a revision was rewritten, return new revision if so
  let history = adapter.getRewriteHistory(changeId)
  for entry in history:
    if entry.oldRev == oldRev:
      return some(entry.newRev)
  return none(JJRevId)

method getCurrentRevForChange*(adapter: JJCliAdapter, changeId: JJChangeId): Option[JJRevId] =
  ## Get the current (latest) revision for a change
  adapter.getChangeTip(changeId)

method getChangedPaths*(adapter: JJCliAdapter, revId: JJRevId): seq[string] =
  ## Get list of paths changed in a revision
  let (output, exitCode) = adapter.runJJ(@[
    "diff",
    "-r", $revId,
    "--stat"
  ])

  result = @[]
  if exitCode != 0:
    return

  for line in output.splitLines():
    # Parse stat output: "path | N +++ ---"
    let parts = line.split("|")
    if parts.len >= 1:
      let path = parts[0].strip()
      if path.len > 0 and not path.startsWith("changed"):
        result.add(path)

# =============================================================================
# Bookmark Operations
# =============================================================================

method listBookmarks*(adapter: JJCliAdapter): JJBookmarkList =
  ## List all bookmarks
  let (output, exitCode) = adapter.runJJ(@[
    "bookmark", "list", "--all",
    "-T", """concat(name, "\t", commit_id, "\t", if(remote, remote, ""), "\n")"""
  ])

  result = @[]
  if exitCode != 0:
    return

  for line in output.splitLines():
    let parts = line.split("\t")
    if parts.len >= 2 and parts[0].len > 0:
      let remote = if parts.len >= 3 and parts[2].len > 0: some(parts[2]) else: none(string)
      let state = if remote.isSome: jjBookmarkTracking else: jjBookmarkLocal
      result.add(JJBookmark(
        name: parts[0],
        revId: newJJRevId(parts[1]),
        remote: remote,
        state: state
      ))

method createBookmark*(adapter: JJCliAdapter, name: string, revId: JJRevId): bool =
  ## Create a bookmark at the given revision
  let (_, exitCode) = adapter.runJJ(@[
    "bookmark", "create", name, "-r", $revId
  ])
  return exitCode == 0

method deleteBookmark*(adapter: JJCliAdapter, name: string): bool =
  ## Delete a bookmark
  let (_, exitCode) = adapter.runJJ(@[
    "bookmark", "delete", name
  ])
  return exitCode == 0

method moveBookmark*(adapter: JJCliAdapter, name: string, revId: JJRevId): bool =
  ## Move a bookmark to a new revision
  let (_, exitCode) = adapter.runJJ(@[
    "bookmark", "move", name, "--to", $revId
  ])
  return exitCode == 0

method getBookmark*(adapter: JJCliAdapter, name: string): Option[JJBookmark] =
  ## Get a specific bookmark
  let bookmarks = adapter.listBookmarks()
  for bookmark in bookmarks:
    if bookmark.name == name:
      return some(bookmark)
  return none(JJBookmark)

# =============================================================================
# Operation Log (Audit Trail)
# =============================================================================

proc parseOperationType(s: string): JJOperationType =
  case s.toLowerAscii()
  of "checkout": jjOpCheckout
  of "commit": jjOpCommit
  of "rebase": jjOpRebase
  of "squash": jjOpSquash
  of "merge": jjOpMerge
  of "new": jjOpNew
  of "describe": jjOpDescribe
  of "abandon": jjOpAbandon
  of "restore": jjOpRestore
  of "git fetch": jjOpGitFetch
  of "git push": jjOpGitPush
  of "undo": jjOpUndo
  else: jjOpOther

method getOperationLog*(adapter: JJCliAdapter, limit: int = 100): JJOperationLog =
  ## Get operation log (audit trail)
  let (output, exitCode) = adapter.runJJ(@[
    "operation", "log",
    "--limit", $limit,
    "--no-graph",
    "-T", """concat(operation_id, "\t", current_operation.start_time().utc().format("%Y-%m-%dT%H:%M:%SZ"), "\t", description.first_line(), "\t", current_operation.user(), "\n")"""
  ])

  result = @[]
  if exitCode != 0:
    return

  for line in output.splitLines():
    let parts = line.split("\t")
    if parts.len >= 3 and parts[0].len > 0:
      let user = if parts.len >= 4: parts[3] else: ""
      result.add(JJOperation(
        id: newJJOperationId(parts[0]),
        timestamp: jjNowMs(),  # TODO: Parse actual timestamp
        opType: parseOperationType(parts[2]),
        description: parts[2],
        user: user,
        tags: @[]
      ))

method getOperation*(adapter: JJCliAdapter, opId: JJOperationId): Option[JJOperation] =
  ## Get a specific operation by ID
  let (output, exitCode) = adapter.runJJ(@[
    "operation", "show", $opId,
    "-T", """concat(operation_id, "\t", description.first_line(), "\t", current_operation.user(), "\n")"""
  ])

  if exitCode != 0:
    return none(JJOperation)

  let parts = output.strip().split("\t")
  if parts.len >= 2:
    let user = if parts.len >= 3: parts[2] else: ""
    return some(JJOperation(
      id: opId,
      timestamp: jjNowMs(),
      opType: parseOperationType(parts[1]),
      description: parts[1],
      user: user,
      tags: @[]
    ))
  return none(JJOperation)

method undoOperation*(adapter: JJCliAdapter, opId: JJOperationId): bool =
  ## Undo a specific operation
  let (_, exitCode) = adapter.runJJ(@[
    "operation", "undo", $opId
  ])
  return exitCode == 0

method restoreToOperation*(adapter: JJCliAdapter, opId: JJOperationId): bool =
  ## Restore repository to a specific operation state
  let (_, exitCode) = adapter.runJJ(@[
    "operation", "restore", $opId
  ])
  return exitCode == 0

# =============================================================================
# Workspace Operations
# =============================================================================

method listWorkspaces*(adapter: JJCliAdapter): JJWorkspaceList =
  ## List all workspaces
  let (output, exitCode) = adapter.runJJ(@[
    "workspace", "list"
  ])

  result = @[]
  if exitCode != 0:
    return

  for line in output.splitLines():
    # Parse workspace list output: "name: path"
    let colonPos = line.find(':')
    if colonPos > 0:
      let name = line[0..<colonPos].strip()
      let path = line[colonPos+1..^1].strip()
      result.add(JJWorkspace(
        name: name,
        path: path,
        workingCopyRev: none(JJRevId)
      ))

method addWorkspace*(adapter: JJCliAdapter, name: string, path: string): bool =
  ## Add a new workspace
  let (_, exitCode) = adapter.runJJ(@[
    "workspace", "add", "--name", name, path
  ])
  return exitCode == 0

method forgetWorkspace*(adapter: JJCliAdapter, name: string): bool =
  ## Forget a workspace (stop tracking)
  let (_, exitCode) = adapter.runJJ(@[
    "workspace", "forget", name
  ])
  return exitCode == 0

# =============================================================================
# Git Operations
# =============================================================================

method listGitRemotes*(adapter: JJCliAdapter): seq[JJGitRemote] =
  ## List configured Git remotes
  let (output, exitCode) = adapter.runJJ(@[
    "git", "remote", "list"
  ])

  result = @[]
  if exitCode != 0:
    return

  for line in output.splitLines():
    # Parse "name url" format
    let parts = line.splitWhitespace()
    if parts.len >= 2:
      result.add(JJGitRemote(
        name: parts[0],
        url: parts[1]
      ))

method gitFetch*(adapter: JJCliAdapter, remote: string = "origin"): JJGitFetchResult =
  ## Fetch from a Git remote
  let (output, exitCode) = adapter.runJJ(@[
    "git", "fetch", "--remote", remote
  ])

  if exitCode != 0:
    return JJGitFetchResult(
      success: false,
      updatedBookmarks: @[],
      errorMessage: some(output)
    )

  # Parse updated bookmarks from output
  var updatedBookmarks: seq[string] = @[]
  for line in output.splitLines():
    if "bookmark" in line.toLowerAscii():
      updatedBookmarks.add(line.strip())

  return JJGitFetchResult(
    success: true,
    updatedBookmarks: updatedBookmarks,
    errorMessage: none(string)
  )

method gitPush*(adapter: JJCliAdapter, remote: string = "origin", bookmarks: seq[string] = @[]): JJGitPushResult =
  ## Push to a Git remote
  var args = @["git", "push", "--remote", remote]
  if bookmarks.len > 0:
    for b in bookmarks:
      args.add("--bookmark")
      args.add(b)

  let (output, exitCode) = adapter.runJJ(args)

  if exitCode != 0:
    let errorCode = if "rejected" in output.toLowerAscii(): "ERR_REJECTED"
                    elif "permission" in output.toLowerAscii(): "ERR_PERMISSION"
                    else: "ERR_PUSH_FAILED"
    return JJGitPushResult(
      success: false,
      pushedBookmarks: @[],
      errorCode: some(errorCode),
      errorMessage: some(output)
    )

  return JJGitPushResult(
    success: true,
    pushedBookmarks: bookmarks,
    errorCode: none(string),
    errorMessage: none(string)
  )
