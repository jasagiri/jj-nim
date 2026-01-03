# jj-nim Examples

Detailed usage examples for jj-nim.

## Table of Contents

- [Basic Operations](#basic-operations)
- [Merge Workflow](#merge-workflow)
- [Bookmark Management](#bookmark-management)
- [Audit Trail](#audit-trail)
- [Workspace Management](#workspace-management)
- [Git Integration](#git-integration)
- [Testing with Mock Adapter](#testing-with-mock-adapter)
- [Polymorphic Usage](#polymorphic-usage)
- [Error Handling](#error-handling)

---

## Basic Operations

### Creating an Adapter

```nim
import jj

# CLI adapter for real JJ repository
let adapter = newJJCliAdapter("/path/to/repo")

# With custom JJ binary path
let customAdapter = newJJCliAdapter("/path/to/repo", "/opt/jj/bin/jj")

# Mock adapter for testing
let mockAdapter = newJJMockAdapter()
```

### Resolving References

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# Resolve various references
let main = adapter.resolveRef("main")
let working = adapter.resolveRef("@")  # Working copy
let parent = adapter.resolveRef("@-")  # Parent

if main.isSome:
  echo "Main branch:"
  echo "  Name: ", main.get.name
  echo "  RevId: ", main.get.revId
  if main.get.changeId.isSome:
    echo "  ChangeId: ", main.get.changeId.get
```

### Getting Revision Metadata

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

let mainRef = adapter.resolveRef("main")
if mainRef.isSome:
  let revision = adapter.getRevision(mainRef.get.revId)
  if revision.isSome:
    let rev = revision.get
    echo "Revision: ", rev.revId
    echo "Author: ", rev.author
    echo "Description: ", rev.description
    echo "Timestamp: ", rev.timestamp.toDateTime()
    echo "Parents: ", rev.parents.len
```

### Checking Ancestry

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

let main = adapter.resolveRef("main").get.revId
let feature = adapter.resolveRef("feature").get.revId

if adapter.isAncestor(main, feature):
  echo "Feature is ahead of main"
else:
  echo "Feature may need rebasing"
```

---

## Merge Workflow

### Complete Merge Example

```nim
import jj

proc mergeFeature(repoPath: string, featureBranch: string): bool =
  let adapter = newJJCliAdapter(repoPath)

  # 1. Resolve references
  let mainOpt = adapter.resolveRef("main")
  let featureOpt = adapter.resolveRef(featureBranch)

  if mainOpt.isNone or featureOpt.isNone:
    echo "Could not resolve references"
    return false

  let mainRev = mainOpt.get.revId
  let featureRev = featureOpt.get.revId

  # 2. Check if already merged
  if adapter.isAncestor(featureRev, mainRev):
    echo "Feature already merged into main"
    return true

  # 3. Check for conflicts
  let conflicts = adapter.checkConflicts(mainRev, featureRev, jjStrategyRebase)
  if conflicts.hasConflict:
    echo "Conflicts detected:"
    for file in conflicts.conflictingFiles:
      echo "  - ", file
    return false

  # 4. Perform merge
  let result = adapter.performMerge(
    mainRev,
    featureRev,
    jjStrategyRebase,
    "Merge " & featureBranch & " into main"
  )

  if result.success:
    echo "Successfully merged to: ", result.mergedRev.get
    return true
  else:
    echo "Merge failed: ", result.errorMessage.get
    return false

# Usage
if mergeFeature("/path/to/repo", "feature-login"):
  echo "Merge successful!"
```

### Using Different Merge Strategies

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")
let base = newJJRevId("abc123")
let head = newJJRevId("def456")

# Rebase strategy - replay commits on top of base
let rebaseResult = adapter.performMerge(
  base, head, jjStrategyRebase, "Rebase feature"
)

# Squash strategy - combine all commits into one
let squashResult = adapter.performMerge(
  base, head, jjStrategySquash, "Squash feature"
)

# Merge strategy - create merge commit
let mergeResult = adapter.performMerge(
  base, head, jjStrategyMerge, "Merge feature"
)
```

---

## Bookmark Management

### Managing Bookmarks

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# List all bookmarks
echo "Current bookmarks:"
for bookmark in adapter.listBookmarks():
  echo "  ", bookmark.name, " -> ", bookmark.revId
  if bookmark.remote.isSome:
    echo "    (tracking ", bookmark.remote.get, ")"

# Create a new bookmark
let currentRev = adapter.resolveRef("@").get.revId
if adapter.createBookmark("my-feature", currentRev):
  echo "Created bookmark: my-feature"

# Move bookmark to new revision
let newRev = adapter.resolveRef("@").get.revId
if adapter.moveBookmark("my-feature", newRev):
  echo "Moved bookmark to: ", newRev

# Get specific bookmark
let bookmark = adapter.getBookmark("main")
if bookmark.isSome:
  echo "Main is at: ", bookmark.get.revId

# Delete bookmark
if adapter.deleteBookmark("my-feature"):
  echo "Deleted bookmark: my-feature"
```

---

## Audit Trail

### Operation Log for Auditing

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# Get recent operations
echo "Recent operations:"
let log = adapter.getOperationLog(limit = 20)
for op in log:
  echo "  ", op.id
  echo "    Type: ", op.opType
  echo "    Description: ", op.description
  echo "    User: ", op.user
  echo "    Time: ", op.timestamp.toDateTime()
  echo ""

# Get specific operation
let opId = newJJOperationId("abc123")
let op = adapter.getOperation(opId)
if op.isSome:
  echo "Operation details: ", op.get.description
```

### Undo and Restore Operations

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# Undo a specific operation
let opId = newJJOperationId("abc123")
if adapter.undoOperation(opId):
  echo "Operation undone successfully"

# Restore to a previous state
let restorePoint = newJJOperationId("xyz789")
if adapter.restoreToOperation(restorePoint):
  echo "Restored to operation: ", restorePoint
```

### Audit Trail for Governance

```nim
import jj
import std/json

proc generateAuditReport(repoPath: string): JsonNode =
  let adapter = newJJCliAdapter(repoPath)

  result = %*{
    "repository": repoPath,
    "generatedAt": $jjNowMs().toDateTime(),
    "operations": []
  }

  for op in adapter.getOperationLog(limit = 100):
    result["operations"].add(op.toJson())

# Usage
let report = generateAuditReport("/path/to/repo")
writeFile("audit-report.json", $report)
```

---

## Workspace Management

### Multiple Workspaces

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# List existing workspaces
echo "Workspaces:"
for ws in adapter.listWorkspaces():
  echo "  ", ws.name, " at ", ws.path
  if ws.workingCopyRev.isSome:
    echo "    Working copy: ", ws.workingCopyRev.get

# Add new workspace for parallel work
if adapter.addWorkspace("feature-auth", "/path/to/workspace/auth"):
  echo "Created workspace for auth feature"

if adapter.addWorkspace("feature-api", "/path/to/workspace/api"):
  echo "Created workspace for API feature"

# Remove workspace when done
if adapter.forgetWorkspace("feature-auth"):
  echo "Removed auth workspace"
```

---

## Git Integration

### Syncing with Git Remotes

```nim
import jj

let adapter = newJJCliAdapter("/path/to/repo")

# List remotes
echo "Git remotes:"
for remote in adapter.listGitRemotes():
  echo "  ", remote.name, ": ", remote.url

# Fetch from remote
let fetchResult = adapter.gitFetch("origin")
if fetchResult.success:
  echo "Fetch successful"
  if fetchResult.updatedBookmarks.len > 0:
    echo "Updated bookmarks:"
    for b in fetchResult.updatedBookmarks:
      echo "  ", b
else:
  echo "Fetch failed: ", fetchResult.errorMessage.get

# Push to remote
let pushResult = adapter.gitPush("origin", @["main", "feature"])
if pushResult.success:
  echo "Pushed bookmarks: ", pushResult.pushedBookmarks
else:
  echo "Push failed: ", pushResult.errorCode.get
  echo "  ", pushResult.errorMessage.get
```

---

## Testing with Mock Adapter

### Unit Testing Example

```nim
import jj
import std/unittest

suite "Merge Controller Tests":
  test "should detect conflicts":
    let mock = newJJMockAdapter()

    # Setup mock data
    let base = newJJRevId("base-rev")
    let head = newJJRevId("head-rev")
    mock.addConflict(base, head)

    # Test
    let result = mock.checkConflicts(base, head, jjStrategyRebase)
    check result.hasConflict == true
    check result.conflictingFiles.len > 0

  test "should perform successful merge":
    let mock = newJJMockAdapter()

    let base = newJJRevId("base")
    let head = newJJRevId("head")
    # No conflicts registered

    let result = mock.performMerge(base, head, jjStrategyRebase, "Test merge")
    check result.success == true
    check result.mergedRev.isSome

  test "should track ancestry":
    let mock = newJJMockAdapter()

    let parent = newJJRevId("parent")
    let child = newJJRevId("child")
    mock.addAncestry(parent, child)

    check mock.isAncestor(parent, child) == true
    check mock.isAncestor(child, parent) == false

  test "should resolve references":
    let mock = newJJMockAdapter()

    mock.addRef("main", newJJRevId("abc123"), some(newJJChangeId("ch-001")))

    let ref = mock.resolveRef("main")
    check ref.isSome
    check $ref.get.revId == "abc123"
    check ref.get.changeId.get == newJJChangeId("ch-001")
```

### Integration Testing

```nim
import jj
import std/unittest
import std/os

suite "Integration Tests":
  var adapter: JJCliAdapter

  setup:
    let testRepo = getEnv("JJ_TEST_REPO", "")
    if testRepo.len > 0:
      adapter = newJJCliAdapter(testRepo)

  test "should list bookmarks in real repo":
    if adapter.isNil:
      skip()
      return

    let bookmarks = adapter.listBookmarks()
    # Just verify it doesn't crash
    check true

  test "should get operation log":
    if adapter.isNil:
      skip()
      return

    let log = adapter.getOperationLog(10)
    check log.len <= 10
```

---

## Polymorphic Usage

### Dependency Injection Pattern

```nim
import jj

type
  MergeService* = ref object
    adapter: JJAdapter  # Abstract type

proc newMergeService*(adapter: JJAdapter): MergeService =
  MergeService(adapter: adapter)

proc canMerge*(self: MergeService, base, head: string): bool =
  let baseRef = self.adapter.resolveRef(base)
  let headRef = self.adapter.resolveRef(head)

  if baseRef.isNone or headRef.isNone:
    return false

  let conflicts = self.adapter.checkConflicts(
    baseRef.get.revId,
    headRef.get.revId,
    jjStrategyRebase
  )
  return not conflicts.hasConflict

# Production usage
let prodService = newMergeService(newJJCliAdapter("/path/to/repo"))
echo prodService.canMerge("main", "feature")

# Test usage
let mockAdapter = newJJMockAdapter()
mockAdapter.addRef("main", newJJRevId("abc"))
mockAdapter.addRef("feature", newJJRevId("def"))
let testService = newMergeService(mockAdapter)
echo testService.canMerge("main", "feature")  # true (no conflicts)
```

---

## Error Handling

### Robust Error Handling

```nim
import jj

proc safeResolve(adapter: JJAdapter, refName: string): Option[JJRef] =
  try:
    result = adapter.resolveRef(refName)
  except CatchableError as e:
    echo "Error resolving ref: ", e.msg
    result = none(JJRef)

proc safeMerge(adapter: JJAdapter, base, head: JJRevId,
               message: string): tuple[success: bool, error: string] =
  # Check for conflicts first
  let conflicts = adapter.checkConflicts(base, head, jjStrategyRebase)
  if conflicts.hasConflict:
    return (false, "Conflicts: " & conflicts.detail)

  # Perform merge
  let result = adapter.performMerge(base, head, jjStrategyRebase, message)
  if result.success:
    return (true, "")
  else:
    return (false, result.errorMessage.get("Unknown error"))

# Usage
let adapter = newJJCliAdapter("/path/to/repo")

let mainOpt = safeResolve(adapter, "main")
let featureOpt = safeResolve(adapter, "feature")

if mainOpt.isSome and featureOpt.isSome:
  let (success, error) = safeMerge(
    adapter,
    mainOpt.get.revId,
    featureOpt.get.revId,
    "Merge feature"
  )
  if success:
    echo "Merge successful!"
  else:
    echo "Merge failed: ", error
```

### Handling Invalid Repository

```nim
import jj

let adapter = newJJCliAdapter("/nonexistent/path")

# All operations return safe values for invalid repos
let ref = adapter.resolveRef("main")
assert ref.isNone  # Returns None, doesn't crash

let bookmarks = adapter.listBookmarks()
assert bookmarks.len == 0  # Returns empty list

let result = adapter.performMerge(
  newJJRevId("a"), newJJRevId("b"),
  jjStrategyRebase, "Test"
)
assert result.success == false  # Returns failure
assert result.errorMessage.isSome
```
