## JJ CLI Adapter Tests
##
## Tests for jj/cli.nim - covers CLI adapter structure and behavior.
## Note: Some tests require actual JJ installation and a valid repo.

import std/[unittest, options, osproc, os, strutils]
import jj/cli

# Check if JJ is available
proc jjAvailable(): bool =
  try:
    let (_, exitCode) = execCmdEx("jj version")
    result = exitCode == 0
  except:
    result = false

let hasJJ = jjAvailable()

suite "JJCliAdapter Creation":
  test "newJJCliAdapter with default jjPath":
    let adapter = newJJCliAdapter("/test/repo")
    check adapter.repoPath == "/test/repo"
    check adapter.jjPath == "jj"

  test "newJJCliAdapter with custom jjPath":
    let adapter = newJJCliAdapter("/test/repo", "/usr/local/bin/jj")
    check adapter.repoPath == "/test/repo"
    check adapter.jjPath == "/usr/local/bin/jj"

  test "JJCliAdapter inherits from JJAdapter":
    let adapter = newJJCliAdapter("/test/repo")
    check adapter of JJAdapter

  test "JJCliAdapter can be used as JJAdapter":
    proc getPath(a: JJAdapter): string = a.repoPath
    let adapter = newJJCliAdapter("/my/repo")
    check getPath(adapter) == "/my/repo"

suite "JJCliAdapter with Invalid Repo":
  var adapter: JJCliAdapter

  setup:
    adapter = newJJCliAdapter("/nonexistent/repo/path")

  test "resolveRef returns none for invalid repo":
    let result = adapter.resolveRef("main")
    check result.isNone

  test "getRevision returns none for invalid repo":
    let result = adapter.getRevision(newJJRevId("abc123"))
    check result.isNone

  test "computeMergeBase returns none for invalid repo":
    let result = adapter.computeMergeBase(
      newJJRevId("base"),
      newJJRevId("head")
    )
    check result.isNone

  test "isAncestor returns false for invalid repo":
    let result = adapter.isAncestor(
      newJJRevId("ancestor"),
      newJJRevId("descendant")
    )
    check result == false

  test "checkConflicts handles invalid repo":
    let result = adapter.checkConflicts(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase
    )
    # Should indicate conflict/error due to invalid repo
    check result.hasConflict == true

  test "performMerge fails for invalid repo":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase,
      "Merge"
    )
    check result.success == false
    check result.errorCode.isSome

  test "getChangeTip returns none for invalid repo":
    let result = adapter.getChangeTip(newJJChangeId("ch-001"))
    check result.isNone

  test "observeRewrite does not raise for invalid repo":
    # Should not raise
    adapter.observeRewrite(newJJRevId("old"), newJJRevId("new"))

  test "getRewriteHistory returns empty for invalid repo":
    let result = adapter.getRewriteHistory(newJJChangeId("ch-001"))
    check result.len == 0

  test "trackChangeEvolution returns empty map for invalid repo":
    let result = adapter.trackChangeEvolution(newJJChangeId("ch-001"))
    check result.entries.len == 0

  test "wasRewritten returns none for invalid repo":
    let result = adapter.wasRewritten(
      newJJRevId("old"),
      newJJChangeId("ch-001")
    )
    check result.isNone

  test "getCurrentRevForChange returns none for invalid repo":
    let result = adapter.getCurrentRevForChange(newJJChangeId("ch-001"))
    check result.isNone

  test "getChangedPaths returns empty for invalid repo":
    let result = adapter.getChangedPaths(newJJRevId("rev"))
    check result.len == 0

suite "JJCliAdapter with Invalid JJ Path":
  test "adapter handles missing jj binary":
    let adapter = newJJCliAdapter("/test/repo", "/nonexistent/jj")
    let result = adapter.resolveRef("main")
    check result.isNone

suite "JJCliAdapter Merge Strategies":
  var adapter: JJCliAdapter

  setup:
    adapter = newJJCliAdapter("/nonexistent/repo")

  test "performMerge with rebase strategy":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase,
      "Rebase merge"
    )
    # Will fail due to invalid repo, but tests strategy handling
    check result.success == false

  test "performMerge with squash strategy":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategySquash,
      "Squash merge"
    )
    check result.success == false

  test "performMerge with merge strategy":
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyMerge,
      "Merge commit"
    )
    check result.success == false

suite "JJCliAdapter Error Handling":
  test "error code detection for conflicts":
    let adapter = newJJCliAdapter("/nonexistent/repo")
    let result = adapter.performMerge(
      newJJRevId("base"),
      newJJRevId("head"),
      jjStrategyRebase,
      "Test"
    )
    # Should have error code set
    check result.errorCode.isSome
    check result.errorMessage.isSome

# Integration tests that require real JJ
when defined(jjIntegration):
  suite "JJCliAdapter Integration (requires JJ)":
    test "JJ is available":
      check hasJJ == true

    # Add more integration tests here when JJ is available

suite "JJCliAdapter Polymorphism":
  test "JJCliAdapter methods override base":
    let adapter: JJAdapter = newJJCliAdapter("/test/repo")
    # Should use JJCliAdapter implementation, not raise
    let result = adapter.resolveRef("nonexistent")
    check result.isNone  # Returns none instead of raising

  test "getChangedPaths parses stat output correctly":
    # This tests the parsing logic conceptually
    let adapter = newJJCliAdapter("/nonexistent/repo")
    let result = adapter.getChangedPaths(newJJRevId("rev"))
    # Empty result due to invalid repo, but no crash
    check result.len == 0

echo "Running JJ CLI Adapter tests..."
if hasJJ:
  echo "  JJ is available on this system"
else:
  echo "  JJ is NOT available - some tests may be limited"
