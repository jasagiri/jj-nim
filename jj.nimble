# Package

version       = "0.0.8"
author        = "GodsGolemInc"
description   = "Nim adapter for Jujutsu (JJ) version control system"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 2.0.0"

# Tasks

task test, "Run all tests":
  exec "nim c -r tests/test_all.nim"

task test_types, "Run type tests":
  exec "nim c -r tests/test_types.nim"

task test_adapter, "Run adapter tests":
  exec "nim c -r tests/test_adapter.nim"

task test_mock, "Run mock adapter tests":
  exec "nim c -r tests/test_mock.nim"

task test_cli, "Run CLI adapter tests":
  exec "nim c -r tests/test_cli.nim"
