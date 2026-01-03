## JJ Mock Adapter Tests
##
## Comprehensive tests for jj/mock.nim with 100% coverage.

import std/[unittest, options, strutils]
import jj/mock

suite "JJMockAdapter Creation":
  test "newJJMockAdapter with default path":
    let adapter = newJJMockAdapter()
    check adapter.repoPath == "/mock/repo"
    check adapter.refs.len == 0
    check adapter.revisions.len == 0
    check adapter.conflicts.len == 0
    check adapter.ancestryPairs.len == 0

  test "newJJMockAdapter with custom path":
    let adapter = newJJMockAdapter("/custom/path")
    check adapter.repoPath == "/custom/path"

  test "JJMockAdapter inherits from JJAdapter":
    let adapter = newJJMockAdapter()
    check adapter of JJAdapter

suite "JJMockAdapter Setup Methods":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "addRef without changeId":
    adapter.addRef("main", newJJRevId("abc123"))
    check adapter.refs.len == 1
    check adapter.refs[0].name == "main"
    check $adapter.refs[0].revId == "abc123"
    check adapter.refs[0].changeId.isNone

  test "addRef with changeId":
    adapter.addRef("feature", newJJRevId("def456"), some(newJJChangeId("ch-001")))
    check adapter.refs.len == 1
    check adapter.refs[0].changeId.isSome
    check $adapter.refs[0].changeId.get == "ch-001"

  test "addRef multiple refs":
    adapter.addRef("main", newJJRevId("abc123"))
    adapter.addRef("develop", newJJRevId("def456"))
    adapter.addRef("feature", newJJRevId("ghi789"))
    check adapter.refs.len == 3

  test "addRevision":
    let rev = JJRevision(
      revId: newJJRevId("abc123"),
      changeId: newJJChangeId("ch-001"),
      author: "Test Author",
      timestamp: 1704067200000,
      description: "Test commit",
      parents: @[]
    )
    adapter.addRevision(rev)
    check adapter.revisions.len == 1
    check $adapter.revisions[0].revId == "abc123"

  test "addRevision multiple revisions":
    for i in 1..3:
      let rev = JJRevision(
        revId: newJJRevId("rev" & $i),
        changeId: newJJChangeId("ch-" & $i),
        author: "Author " & $i,
        timestamp: int64(i * 1000),
        description: "Commit " & $i,
        parents: @[]
      )
      adapter.addRevision(rev)
    check adapter.revisions.len == 3

  test "addConflict":
    adapter.addConflict(newJJRevId("base"), newJJRevId("head"))
    check adapter.conflicts.len == 1

  test "addConflict multiple conflicts":
    adapter.addConflict(newJJRevId("base1"), newJJRevId("head1"))
    adapter.addConflict(newJJRevId("base2"), newJJRevId("head2"))
    check adapter.conflicts.len == 2

  test "addAncestry":
    adapter.addAncestry(newJJRevId("ancestor"), newJJRevId("descendant"))
    check adapter.ancestryPairs.len == 1

  test "addAncestry multiple pairs":
    adapter.addAncestry(newJJRevId("a1"), newJJRevId("d1"))
    adapter.addAncestry(newJJRevId("a2"), newJJRevId("d2"))
    adapter.addAncestry(newJJRevId("a3"), newJJRevId("d3"))
    check adapter.ancestryPairs.len == 3

suite "JJMockAdapter resolveRef":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    adapter.addRef("main", newJJRevId("abc123"))
    adapter.addRef("develop", newJJRevId("def456"), some(newJJChangeId("ch-dev")))

  test "resolveRef finds existing ref":
    let result = adapter.resolveRef("main")
    check result.isSome
    check result.get.name == "main"
    check $result.get.revId == "abc123"

  test "resolveRef finds ref with changeId":
    let result = adapter.resolveRef("develop")
    check result.isSome
    check result.get.changeId.isSome
    check $result.get.changeId.get == "ch-dev"

  test "resolveRef returns none for non-existent ref":
    let result = adapter.resolveRef("nonexistent")
    check result.isNone

  test "resolveRef empty adapter returns none":
    let emptyAdapter = newJJMockAdapter()
    let result = emptyAdapter.resolveRef("main")
    check result.isNone

suite "JJMockAdapter getRevision":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    let rev = JJRevision(
      revId: newJJRevId("abc123"),
      changeId: newJJChangeId("ch-001"),
      author: "Author",
      timestamp: 1000,
      description: "Test",
      parents: @[newJJRevId("parent1")]
    )
    adapter.addRevision(rev)

  test "getRevision finds existing revision":
    let result = adapter.getRevision(newJJRevId("abc123"))
    check result.isSome
    check result.get.author == "Author"
    check result.get.description == "Test"
    check result.get.parents.len == 1

  test "getRevision returns none for non-existent revision":
    let result = adapter.getRevision(newJJRevId("nonexistent"))
    check result.isNone

  test "getRevision empty adapter returns none":
    let emptyAdapter = newJJMockAdapter()
    let result = emptyAdapter.getRevision(newJJRevId("abc123"))
    check result.isNone

suite "JJMockAdapter computeMergeBase":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "computeMergeBase returns merge base":
    let result = adapter.computeMergeBase(
      newJJRevId("base"),
      newJJRevId("head")
    )
    check result.isSome
    check $result.get.baseRev == "base"
    check $result.get.headRev == "head"
    # Mock returns base as merge base
    check $result.get.mergeBaseRev == "base"

  test "computeMergeBase always returns some":
    # Mock implementation always returns a result
    let result = adapter.computeMergeBase(
      newJJRevId("any"),
      newJJRevId("other")
    )
    check result.isSome

suite "JJMockAdapter isAncestor":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    adapter.addAncestry(newJJRevId("parent"), newJJRevId("child"))
    adapter.addAncestry(newJJRevId("grandparent"), newJJRevId("grandchild"))

  test "isAncestor returns true for registered pair":
    check adapter.isAncestor(newJJRevId("parent"), newJJRevId("child")) == true

  test "isAncestor returns false for unregistered pair":
    check adapter.isAncestor(newJJRevId("child"), newJJRevId("parent")) == false

  test "isAncestor returns false for unknown revisions":
    check adapter.isAncestor(newJJRevId("unknown1"), newJJRevId("unknown2")) == false

  test "isAncestor empty adapter returns false":
    let emptyAdapter = newJJMockAdapter()
    check emptyAdapter.isAncestor(newJJRevId("a"), newJJRevId("b")) == false

  test "isAncestor multiple ancestry pairs":
    check adapter.isAncestor(newJJRevId("grandparent"), newJJRevId("grandchild")) == true

suite "JJMockAdapter checkConflicts":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    adapter.addConflict(newJJRevId("conflict-base"), newJJRevId("conflict-head"))

  test "checkConflicts detects registered conflict":
    let result = adapter.checkConflicts(
      newJJRevId("conflict-base"),
      newJJRevId("conflict-head"),
      jjStrategyRebase
    )
    check result.hasConflict == true
    check result.conflictingFiles.len > 0
    check "mock/conflict.txt" in result.conflictingFiles
    check result.detail == "Mock conflict detected"

  test "checkConflicts no conflict for unregistered pair":
    let result = adapter.checkConflicts(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase
    )
    check result.hasConflict == false
    check result.conflictingFiles.len == 0
    check result.detail == ""

  test "checkConflicts works with all strategies":
    for strategy in [jjStrategyRebase, jjStrategySquash, jjStrategyMerge]:
      let result = adapter.checkConflicts(
        newJJRevId("base"),
        newJJRevId("head"),
        strategy
      )
      check result.hasConflict == false

  test "checkConflicts empty adapter returns no conflict":
    let emptyAdapter = newJJMockAdapter()
    let result = emptyAdapter.checkConflicts(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyMerge
    )
    check result.hasConflict == false

suite "JJMockAdapter performMerge":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "performMerge success without conflicts":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase,
      "Merge message"
    )
    check result.success == true
    check result.mergedRev.isSome
    check $result.mergedRev.get == "head-merged"
    check result.errorCode.isNone
    check result.errorMessage.isNone

  test "performMerge failure with conflict":
    adapter.addConflict(newJJRevId("base"), newJJRevId("head"))
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase,
      "Merge message"
    )
    check result.success == false
    check result.mergedRev.isNone
    check result.errorCode.isSome
    check result.errorCode.get == "ERR_CONFLICT"
    check result.errorMessage.isSome
    check "conflict" in result.errorMessage.get.toLowerAscii()

  test "performMerge with squash strategy":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("feature"),
      jjStrategySquash,
      "Squash merge"
    )
    check result.success == true
    check $result.mergedRev.get == "feature-merged"

  test "performMerge with merge strategy":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("feature"),
      jjStrategyMerge,
      "Merge commit"
    )
    check result.success == true

suite "JJMockAdapter getChangeTip":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    let rev = JJRevision(
      revId: newJJRevId("tip-rev"),
      changeId: newJJChangeId("ch-001"),
      author: "Author",
      timestamp: 1000,
      description: "Tip",
      parents: @[]
    )
    adapter.addRevision(rev)

  test "getChangeTip finds revision by changeId":
    let result = adapter.getChangeTip(newJJChangeId("ch-001"))
    check result.isSome
    check $result.get == "tip-rev"

  test "getChangeTip returns none for unknown changeId":
    let result = adapter.getChangeTip(newJJChangeId("unknown"))
    check result.isNone

  test "getChangeTip returns first matching revision":
    let rev2 = JJRevision(
      revId: newJJRevId("tip-rev-2"),
      changeId: newJJChangeId("ch-001"),  # Same changeId
      author: "Author",
      timestamp: 2000,
      description: "Second",
      parents: @[]
    )
    adapter.addRevision(rev2)
    let result = adapter.getChangeTip(newJJChangeId("ch-001"))
    check result.isSome
    # Returns first match
    check $result.get == "tip-rev"

suite "JJMockAdapter observeRewrite":
  test "observeRewrite does nothing (no-op)":
    let adapter = newJJMockAdapter()
    # Should not raise
    adapter.observeRewrite(newJJRevId("old"), newJJRevId("new"))
    # No state change to verify - it's a no-op

suite "JJMockAdapter getRewriteHistory":
  test "getRewriteHistory returns empty seq":
    let adapter = newJJMockAdapter()
    let result = adapter.getRewriteHistory(newJJChangeId("ch-001"))
    check result.len == 0

suite "JJMockAdapter trackChangeEvolution":
  test "trackChangeEvolution returns empty map":
    let adapter = newJJMockAdapter()
    let result = adapter.trackChangeEvolution(newJJChangeId("ch-001"))
    check $result.changeId == "ch-001"
    check result.entries.len == 0

suite "JJMockAdapter wasRewritten":
  test "wasRewritten returns none":
    let adapter = newJJMockAdapter()
    let result = adapter.wasRewritten(
      newJJRevId("old"),
      newJJChangeId("ch-001")
    )
    check result.isNone

suite "JJMockAdapter getCurrentRevForChange":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()
    let rev = JJRevision(
      revId: newJJRevId("current-rev"),
      changeId: newJJChangeId("ch-001"),
      author: "Author",
      timestamp: 1000,
      description: "Current",
      parents: @[]
    )
    adapter.addRevision(rev)

  test "getCurrentRevForChange delegates to getChangeTip":
    let result = adapter.getCurrentRevForChange(newJJChangeId("ch-001"))
    check result.isSome
    check $result.get == "current-rev"

  test "getCurrentRevForChange returns none for unknown":
    let result = adapter.getCurrentRevForChange(newJJChangeId("unknown"))
    check result.isNone

suite "JJMockAdapter getChangedPaths":
  test "getChangedPaths returns empty seq":
    let adapter = newJJMockAdapter()
    let result = adapter.getChangedPaths(newJJRevId("rev"))
    check result.len == 0

suite "JJMockAdapter Polymorphism":
  test "JJMockAdapter can be used as JJAdapter":
    proc useAdapter(a: JJAdapter): bool =
      let result = a.computeMergeBase(newJJRevId("a"), newJJRevId("b"))
      result.isSome

    let mock = newJJMockAdapter()
    check useAdapter(mock) == true

  test "Method dispatch works correctly":
    let adapter: JJAdapter = newJJMockAdapter()
    # resolveRef should use JJMockAdapter implementation, not raise
    let result = adapter.resolveRef("nonexistent")
    check result.isNone  # Mock returns none, doesn't raise

# =============================================================================
# Bookmark Operations Tests
# =============================================================================

suite "JJMockAdapter Bookmark Operations":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "listBookmarks returns empty on new adapter":
    check adapter.listBookmarks().len == 0

  test "createBookmark adds a bookmark":
    let result = adapter.createBookmark("main", newJJRevId("rev-1"))
    check result == true
    check adapter.listBookmarks().len == 1

  test "createBookmark fails for duplicate name":
    discard adapter.createBookmark("main", newJJRevId("rev-1"))
    let result = adapter.createBookmark("main", newJJRevId("rev-2"))
    check result == false

  test "getBookmark finds existing bookmark":
    discard adapter.createBookmark("main", newJJRevId("rev-1"))
    let bookmark = adapter.getBookmark("main")
    check bookmark.isSome
    check bookmark.get.name == "main"
    check $bookmark.get.revId == "rev-1"

  test "getBookmark returns none for non-existent":
    let bookmark = adapter.getBookmark("nonexistent")
    check bookmark.isNone

  test "deleteBookmark removes bookmark":
    discard adapter.createBookmark("main", newJJRevId("rev-1"))
    let result = adapter.deleteBookmark("main")
    check result == true
    check adapter.listBookmarks().len == 0

  test "deleteBookmark returns false for non-existent":
    let result = adapter.deleteBookmark("nonexistent")
    check result == false

  test "moveBookmark updates revision":
    discard adapter.createBookmark("main", newJJRevId("rev-1"))
    let result = adapter.moveBookmark("main", newJJRevId("rev-2"))
    check result == true
    let bookmark = adapter.getBookmark("main")
    check $bookmark.get.revId == "rev-2"

  test "moveBookmark returns false for non-existent":
    let result = adapter.moveBookmark("nonexistent", newJJRevId("rev-1"))
    check result == false

  test "addBookmark with all parameters":
    adapter.addBookmark("feature", newJJRevId("rev-1"), some("origin"), jjBookmarkTracking)
    let bookmark = adapter.getBookmark("feature")
    check bookmark.isSome
    check bookmark.get.remote.isSome
    check bookmark.get.remote.get == "origin"
    check bookmark.get.state == jjBookmarkTracking

# =============================================================================
# Operation Log Tests
# =============================================================================

suite "JJMockAdapter Operation Log":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "getOperationLog returns empty on new adapter":
    check adapter.getOperationLog().len == 0

  test "addOperation adds to log":
    let op = JJOperation(
      id: newJJOperationId("op-1"),
      timestamp: jjNowMs(),
      opType: jjOpCommit,
      description: "commit",
      user: "test",
      tags: @[]
    )
    adapter.addOperation(op)
    check adapter.getOperationLog().len == 1

  test "getOperation finds operation by ID":
    let op = JJOperation(
      id: newJJOperationId("op-1"),
      timestamp: jjNowMs(),
      opType: jjOpCommit,
      description: "commit",
      user: "test",
      tags: @[]
    )
    adapter.addOperation(op)
    let found = adapter.getOperation(newJJOperationId("op-1"))
    check found.isSome
    check found.get.opType == jjOpCommit

  test "getOperation returns none for non-existent":
    let found = adapter.getOperation(newJJOperationId("nonexistent"))
    check found.isNone

  test "undoOperation adds undo operation":
    let op = JJOperation(
      id: newJJOperationId("op-1"),
      timestamp: jjNowMs(),
      opType: jjOpCommit,
      description: "commit",
      user: "test",
      tags: @[]
    )
    adapter.addOperation(op)
    let result = adapter.undoOperation(newJJOperationId("op-1"))
    check result == true
    check adapter.getOperationLog().len == 2

  test "restoreToOperation adds restore operation":
    let op = JJOperation(
      id: newJJOperationId("op-1"),
      timestamp: jjNowMs(),
      opType: jjOpCommit,
      description: "commit",
      user: "test",
      tags: @[]
    )
    adapter.addOperation(op)
    let result = adapter.restoreToOperation(newJJOperationId("op-1"))
    check result == true
    check adapter.getOperationLog().len == 2

  test "getOperationLog respects limit":
    for i in 1..10:
      adapter.addOperation(JJOperation(
        id: newJJOperationId("op-" & $i),
        timestamp: jjNowMs(),
        opType: jjOpCommit,
        description: "commit " & $i,
        user: "test",
        tags: @[]
      ))
    let log = adapter.getOperationLog(5)
    check log.len == 5

# =============================================================================
# Workspace Tests
# =============================================================================

suite "JJMockAdapter Workspace Operations":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "listWorkspaces returns empty on new adapter":
    check adapter.listWorkspaces().len == 0

  test "addWorkspace using method adds workspace":
    let result = adapter.addWorkspace("default", "/path/to/ws")
    check result == true
    check adapter.listWorkspaces().len == 1

  test "addWorkspace fails for duplicate name":
    discard adapter.addWorkspace("default", "/path/to/ws1")
    let result = adapter.addWorkspace("default", "/path/to/ws2")
    check result == false

  test "forgetWorkspace removes workspace":
    discard adapter.addWorkspace("default", "/path/to/ws")
    let result = adapter.forgetWorkspace("default")
    check result == true
    check adapter.listWorkspaces().len == 0

  test "forgetWorkspace returns false for non-existent":
    let result = adapter.forgetWorkspace("nonexistent")
    check result == false

  test "setupWorkspace with working copy rev":
    adapter.setupWorkspace("ws1", "/ws1", some(newJJRevId("rev-1")))
    let workspaces = adapter.listWorkspaces()
    check workspaces.len == 1
    check workspaces[0].workingCopyRev.isSome
    check $workspaces[0].workingCopyRev.get == "rev-1"

# =============================================================================
# Git Operations Tests
# =============================================================================

suite "JJMockAdapter Git Operations":
  var adapter: JJMockAdapter

  setup:
    adapter = newJJMockAdapter()

  test "listGitRemotes returns empty on new adapter":
    check adapter.listGitRemotes().len == 0

  test "addGitRemote adds remote":
    adapter.addGitRemote("origin", "https://github.com/test/repo.git")
    check adapter.listGitRemotes().len == 1

  test "gitFetch fails for non-existent remote":
    let result = adapter.gitFetch("origin")
    check result.success == false
    check result.errorMessage.isSome

  test "gitFetch succeeds for existing remote":
    adapter.addGitRemote("origin", "https://github.com/test/repo.git")
    let result = adapter.gitFetch("origin")
    check result.success == true

  test "gitPush fails for non-existent remote":
    let result = adapter.gitPush("origin", @["main"])
    check result.success == false
    check result.errorCode.isSome

  test "gitPush succeeds for existing remote":
    adapter.addGitRemote("origin", "https://github.com/test/repo.git")
    let result = adapter.gitPush("origin", @["main"])
    check result.success == true
    check result.pushedBookmarks.len == 1

echo "Running JJ Mock Adapter tests..."
