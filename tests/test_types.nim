## JJ Types Tests
##
## Comprehensive tests for jj/types.nim with 100% coverage.

import std/[unittest, options, json, tables, times]
import jj/types

suite "JJRevId":
  test "newJJRevId creates valid ID":
    let revId = newJJRevId("abc123")
    check $revId == "abc123"

  test "newJJRevId rejects empty string":
    expect ValueError:
      discard newJJRevId("")

  test "JJRevId equality":
    let rev1 = newJJRevId("abc123")
    let rev2 = newJJRevId("abc123")
    let rev3 = newJJRevId("def456")
    check rev1 == rev2
    check rev1 != rev3

  test "JJRevId hash works for tables":
    var t = initTable[JJRevId, string]()
    let rev1 = newJJRevId("abc123")
    let rev2 = newJJRevId("def456")
    t[rev1] = "first"
    t[rev2] = "second"
    check t[rev1] == "first"
    check t[rev2] == "second"

  test "JJRevId string conversion":
    let revId = newJJRevId("abc123def456")
    check $revId == "abc123def456"

suite "JJChangeId":
  test "newJJChangeId creates valid ID":
    let changeId = newJJChangeId("change-001")
    check $changeId == "change-001"

  test "newJJChangeId rejects empty string":
    expect ValueError:
      discard newJJChangeId("")

  test "JJChangeId equality":
    let ch1 = newJJChangeId("change-001")
    let ch2 = newJJChangeId("change-001")
    let ch3 = newJJChangeId("change-002")
    check ch1 == ch2
    check ch1 != ch3

  test "JJChangeId hash works for tables":
    var t = initTable[JJChangeId, int]()
    let ch1 = newJJChangeId("change-001")
    let ch2 = newJJChangeId("change-002")
    t[ch1] = 1
    t[ch2] = 2
    check t[ch1] == 1
    check t[ch2] == 2

suite "JJTimestamp":
  test "jjNowMs returns positive timestamp":
    let ts = jjNowMs()
    check ts > 0

  test "toDateTime converts timestamp":
    # Known timestamp: 2024-01-01 00:00:00 UTC = 1704067200000 ms
    let ts: JJTimestamp = 1704067200000
    let dt = ts.toDateTime()
    check dt.year == 2024
    check dt.month == mJan
    check dt.monthday == 1

  test "consecutive jjNowMs calls are non-decreasing":
    let ts1 = jjNowMs()
    let ts2 = jjNowMs()
    check ts2 >= ts1

suite "JJMergeStrategy":
  test "merge strategy enum values":
    check $jjStrategyRebase == "rebase"
    check $jjStrategySquash == "squash"
    check $jjStrategyMerge == "merge"

  test "merge strategy comparison":
    check jjStrategyRebase != jjStrategySquash
    check jjStrategySquash != jjStrategyMerge
    check jjStrategyMerge != jjStrategyRebase

suite "JJRef":
  test "JJRef without changeId":
    let jjRef = JJRef(
      name: "main",
      revId: newJJRevId("abc123"),
      changeId: none(JJChangeId)
    )
    check jjRef.name == "main"
    check $jjRef.revId == "abc123"
    check jjRef.changeId.isNone

  test "JJRef with changeId":
    let jjRef = JJRef(
      name: "feature",
      revId: newJJRevId("def456"),
      changeId: some(newJJChangeId("ch-001"))
    )
    check jjRef.name == "feature"
    check jjRef.changeId.isSome
    check $jjRef.changeId.get == "ch-001"

  test "JJRef toJson without changeId":
    let jjRef = JJRef(
      name: "main",
      revId: newJJRevId("abc123"),
      changeId: none(JJChangeId)
    )
    let j = jjRef.toJson()
    check j["name"].getStr() == "main"
    check j["revId"].getStr() == "abc123"
    check not j.hasKey("changeId")

  test "JJRef toJson with changeId":
    let jjRef = JJRef(
      name: "feature",
      revId: newJJRevId("def456"),
      changeId: some(newJJChangeId("ch-001"))
    )
    let j = jjRef.toJson()
    check j["name"].getStr() == "feature"
    check j["revId"].getStr() == "def456"
    check j["changeId"].getStr() == "ch-001"

suite "JJRevision":
  test "JJRevision creation":
    let rev = JJRevision(
      revId: newJJRevId("abc123"),
      changeId: newJJChangeId("ch-001"),
      author: "Test Author",
      timestamp: 1704067200000,
      description: "Test commit",
      parents: @[newJJRevId("parent1"), newJJRevId("parent2")]
    )
    check $rev.revId == "abc123"
    check $rev.changeId == "ch-001"
    check rev.author == "Test Author"
    check rev.timestamp == 1704067200000
    check rev.description == "Test commit"
    check rev.parents.len == 2

  test "JJRevision toJson":
    let rev = JJRevision(
      revId: newJJRevId("abc123"),
      changeId: newJJChangeId("ch-001"),
      author: "Test Author",
      timestamp: 1704067200000,
      description: "Test commit",
      parents: @[newJJRevId("parent1")]
    )
    let j = rev.toJson()
    check j["revId"].getStr() == "abc123"
    check j["changeId"].getStr() == "ch-001"
    check j["author"].getStr() == "Test Author"
    check j["timestamp"].getBiggestInt() == 1704067200000
    check j["description"].getStr() == "Test commit"
    check j["parents"].len == 1
    check j["parents"][0].getStr() == "parent1"

  test "JJRevision with empty parents":
    let rev = JJRevision(
      revId: newJJRevId("root"),
      changeId: newJJChangeId("ch-root"),
      author: "Root Author",
      timestamp: 1704067200000,
      description: "Root commit",
      parents: @[]
    )
    check rev.parents.len == 0
    let j = rev.toJson()
    check j["parents"].len == 0

suite "JJMergeBase":
  test "JJMergeBase creation":
    let mb = JJMergeBase(
      baseRev: newJJRevId("base"),
      headRev: newJJRevId("head"),
      mergeBaseRev: newJJRevId("common")
    )
    check $mb.baseRev == "base"
    check $mb.headRev == "head"
    check $mb.mergeBaseRev == "common"

suite "JJAncestryResult":
  test "JJAncestryResult is ancestor":
    let result = JJAncestryResult(
      baseRev: newJJRevId("base"),
      headRev: newJJRevId("head"),
      isAncestor: true
    )
    check result.isAncestor == true

  test "JJAncestryResult not ancestor":
    let result = JJAncestryResult(
      baseRev: newJJRevId("base"),
      headRev: newJJRevId("head"),
      isAncestor: false
    )
    check result.isAncestor == false

suite "JJConflictResult":
  test "JJConflictResult no conflict":
    let result = JJConflictResult(
      hasConflict: false,
      conflictingFiles: @[],
      detail: ""
    )
    check result.hasConflict == false
    check result.conflictingFiles.len == 0

  test "JJConflictResult with conflicts":
    let result = JJConflictResult(
      hasConflict: true,
      conflictingFiles: @["file1.txt", "file2.txt"],
      detail: "Merge conflict in files"
    )
    check result.hasConflict == true
    check result.conflictingFiles.len == 2
    check "file1.txt" in result.conflictingFiles

suite "JJMergeResult":
  test "JJMergeResult success":
    let result = JJMergeResult(
      success: true,
      mergedRev: some(newJJRevId("merged")),
      errorCode: none(string),
      errorMessage: none(string)
    )
    check result.success == true
    check result.mergedRev.isSome
    check $result.mergedRev.get == "merged"
    check result.errorCode.isNone

  test "JJMergeResult failure":
    let result = JJMergeResult(
      success: false,
      mergedRev: none(JJRevId),
      errorCode: some("ERR_CONFLICT"),
      errorMessage: some("Merge conflict detected")
    )
    check result.success == false
    check result.mergedRev.isNone
    check result.errorCode.get == "ERR_CONFLICT"
    check result.errorMessage.get == "Merge conflict detected"

  test "JJMergeResult toJson success":
    let result = JJMergeResult(
      success: true,
      mergedRev: some(newJJRevId("merged123")),
      errorCode: none(string),
      errorMessage: none(string)
    )
    let j = result.toJson()
    check j["success"].getBool() == true
    check j["mergedRev"].getStr() == "merged123"
    check not j.hasKey("errorCode")
    check not j.hasKey("errorMessage")

  test "JJMergeResult toJson failure":
    let result = JJMergeResult(
      success: false,
      mergedRev: none(JJRevId),
      errorCode: some("ERR_CONFLICT"),
      errorMessage: some("Conflict")
    )
    let j = result.toJson()
    check j["success"].getBool() == false
    check not j.hasKey("mergedRev")
    check j["errorCode"].getStr() == "ERR_CONFLICT"
    check j["errorMessage"].getStr() == "Conflict"

suite "JJError":
  test "JJError creation":
    let err = (ref JJError)(
      msg: "JJ command failed",
      exitCode: 1,
      stderr: "error: invalid revision"
    )
    check err.msg == "JJ command failed"
    check err.exitCode == 1
    check err.stderr == "error: invalid revision"

  test "JJError can be raised and caught":
    proc mayFail() =
      raise (ref JJError)(msg: "Test error", exitCode: 128, stderr: "fatal")

    expect JJError:
      mayFail()

suite "JJRewriteEntry":
  test "JJRewriteEntry creation":
    let entry = JJRewriteEntry(
      oldRev: newJJRevId("old"),
      newRev: newJJRevId("new"),
      changeId: newJJChangeId("ch-001"),
      rewrittenAt: 1704067200000
    )
    check $entry.oldRev == "old"
    check $entry.newRev == "new"
    check $entry.changeId == "ch-001"
    check entry.rewrittenAt == 1704067200000

suite "JJRewriteMap":
  test "JJRewriteMap creation":
    let map = JJRewriteMap(
      changeId: newJJChangeId("ch-001"),
      entries: @[]
    )
    check $map.changeId == "ch-001"
    check map.entries.len == 0

  test "JJRewriteMap with entries":
    let entry1 = JJRewriteEntry(
      oldRev: newJJRevId("v1"),
      newRev: newJJRevId("v2"),
      changeId: newJJChangeId("ch-001"),
      rewrittenAt: 1000
    )
    let entry2 = JJRewriteEntry(
      oldRev: newJJRevId("v2"),
      newRev: newJJRevId("v3"),
      changeId: newJJChangeId("ch-001"),
      rewrittenAt: 2000
    )
    let map = JJRewriteMap(
      changeId: newJJChangeId("ch-001"),
      entries: @[entry1, entry2]
    )
    check map.entries.len == 2
    check $map.entries[0].oldRev == "v1"
    check $map.entries[1].newRev == "v3"

echo "Running JJ Types tests..."
