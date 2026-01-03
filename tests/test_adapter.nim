## JJ Adapter Interface Tests
##
## Tests for jj/adapter.nim - verifies base adapter raises exceptions.

import std/[unittest, options]
import jj/adapter

suite "JJAdapter Base Class":
  test "JJAdapter creation with repoPath":
    let adapter = JJAdapter(repoPath: "/test/repo")
    check adapter.repoPath == "/test/repo"

  test "JJAdapter default repoPath is empty":
    let adapter = JJAdapter()
    check adapter.repoPath == ""

suite "JJAdapter Base Methods Raise Exceptions":
  var adapter: JJAdapter

  setup:
    adapter = JJAdapter(repoPath: "/test/repo")

  test "resolveRef raises not implemented":
    expect CatchableError:
      discard adapter.resolveRef("main")

  test "getRevision raises not implemented":
    expect CatchableError:
      discard adapter.getRevision(newJJRevId("abc123"))

  test "computeMergeBase raises not implemented":
    expect CatchableError:
      discard adapter.computeMergeBase(
        newJJRevId("base"),
        newJJRevId("head")
      )

  test "isAncestor raises not implemented":
    expect CatchableError:
      discard adapter.isAncestor(
        newJJRevId("ancestor"),
        newJJRevId("descendant")
      )

  test "checkConflicts raises not implemented":
    expect CatchableError:
      discard adapter.checkConflicts(
        newJJRevId("base"),
        newJJRevId("head"),
        jjStrategyRebase
      )

  test "performMerge raises not implemented":
    expect CatchableError:
      discard adapter.performMerge(
        newJJRevId("base"),
        newJJRevId("head"),
        jjStrategyRebase,
        "Merge message"
      )

  test "getChangeTip raises not implemented":
    expect CatchableError:
      discard adapter.getChangeTip(newJJChangeId("ch-001"))

  test "observeRewrite raises not implemented":
    expect CatchableError:
      adapter.observeRewrite(
        newJJRevId("old"),
        newJJRevId("new")
      )

  test "getRewriteHistory raises not implemented":
    expect CatchableError:
      discard adapter.getRewriteHistory(newJJChangeId("ch-001"))

  test "trackChangeEvolution raises not implemented":
    expect CatchableError:
      discard adapter.trackChangeEvolution(newJJChangeId("ch-001"))

  test "wasRewritten raises not implemented":
    expect CatchableError:
      discard adapter.wasRewritten(
        newJJRevId("old"),
        newJJChangeId("ch-001")
      )

  test "getCurrentRevForChange raises not implemented":
    expect CatchableError:
      discard adapter.getCurrentRevForChange(newJJChangeId("ch-001"))

  test "getChangedPaths raises not implemented":
    expect CatchableError:
      discard adapter.getChangedPaths(newJJRevId("rev"))

suite "JJAdapter Inheritance":
  test "JJAdapter is RootObj":
    let adapter = JJAdapter()
    check adapter of RootObj

  test "JJAdapter can be used as base type":
    proc useAdapter(a: JJAdapter): string =
      a.repoPath

    let adapter = JJAdapter(repoPath: "/my/repo")
    check useAdapter(adapter) == "/my/repo"

echo "Running JJ Adapter tests..."
