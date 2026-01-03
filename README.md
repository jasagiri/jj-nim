# jj-nim

[![Nim Version](https://img.shields.io/badge/nim-%3E%3D2.0.0-orange)](https://nim-lang.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-156%20passing-green)]()

Nim adapter library for [Jujutsu (JJ)](https://github.com/jj-vcs/jj) version control system.

## Features

- **Type-safe** - Distinct types for RevId, ChangeId, OperationId
- **Polymorphic** - Abstract adapter interface with CLI and Mock implementations
- **Complete** - 27 operations covering all core JJ functionality
- **Testable** - Mock adapter for unit testing without real JJ
- **Auditable** - Operation log support for audit trails

## Quick Start

```nim
import jj

# Create adapter for a repository
let adapter = newJJCliAdapter("/path/to/repo")

# Resolve a reference
let mainRef = adapter.resolveRef("main")
if mainRef.isSome:
  echo "Main branch: ", mainRef.get.revId

# Check for conflicts before merging
let conflicts = adapter.checkConflicts(baseRev, headRev, jjStrategyRebase)
if not conflicts.hasConflict:
  let result = adapter.performMerge(baseRev, headRev, jjStrategyRebase, "Merge feature")
  if result.success:
    echo "Merged: ", result.mergedRev.get
```

## Installation

### Using nimble (recommended)

```nim
# In your .nimble file
requires "jj >= 0.1.0"
```

### Manual installation

```bash
# Clone the repository
git clone https://github.com/your-org/jj-nim.git

# Add to your nim.cfg
echo '--path:"/path/to/jj-nim/src/"' >> nim.cfg
```

### Requirements

- Nim >= 2.0.0
- JJ CLI (for JJCliAdapter) - [Install JJ](https://github.com/jj-vcs/jj#installation)

## Documentation

| Document | Description |
|----------|-------------|
| [API Reference](docs/API.md) | Complete API documentation |
| [Examples](docs/EXAMPLES.md) | Detailed usage examples |
| [Specifications](specs/README.md) | Gherkin BDD specifications |
| [日本語ドキュメント](README.ja.md) | Japanese documentation |

## Core Concepts

### Adapters

jj-nim uses an adapter pattern to abstract JJ operations:

```nim
# Abstract base - defines the interface
type JJAdapter* = ref object of RootObj

# CLI adapter - wraps real jj command
let cli = newJJCliAdapter("/path/to/repo")

# Mock adapter - for testing
let mock = newJJMockAdapter()
```

### Type Safety

Distinct types prevent mixing up identifiers:

```nim
type
  JJRevId* = distinct string    # Commit hash
  JJChangeId* = distinct string # Immutable change ID
  JJOperationId* = distinct string # Operation ID

# These won't compile - type safety!
# let rev: JJRevId = changeId  # Error!
```

### Merge Strategies

```nim
type JJMergeStrategy* = enum
  jjStrategyRebase = "rebase"  # Rebase commits
  jjStrategySquash = "squash"  # Squash into one
  jjStrategyMerge = "merge"    # Create merge commit
```

## Operations Overview

### Core Operations (13)
| Operation | Description |
|-----------|-------------|
| `resolveRef` | Resolve reference name to revision |
| `getRevision` | Get revision metadata |
| `computeMergeBase` | Find common ancestor |
| `isAncestor` | Check ancestry relationship |
| `checkConflicts` | Detect conflicts (dry-run) |
| `performMerge` | Execute merge |
| `getChangeTip` | Get current revision for change |
| `observeRewrite` | Record a rewrite |
| `getRewriteHistory` | Get evolution history |
| `trackChangeEvolution` | Build complete rewrite map |
| `wasRewritten` | Check if revision was rewritten |
| `getCurrentRevForChange` | Get latest revision for change |
| `getChangedPaths` | Get files changed in revision |

### Bookmark Operations (5)
| Operation | Description |
|-----------|-------------|
| `listBookmarks` | List all bookmarks |
| `createBookmark` | Create new bookmark |
| `deleteBookmark` | Delete bookmark |
| `moveBookmark` | Move to new revision |
| `getBookmark` | Get specific bookmark |

### Operation Log (4) - Audit Trail
| Operation | Description |
|-----------|-------------|
| `getOperationLog` | Get operation history |
| `getOperation` | Get specific operation |
| `undoOperation` | Undo an operation |
| `restoreToOperation` | Restore to state |

### Workspace Operations (3)
| Operation | Description |
|-----------|-------------|
| `listWorkspaces` | List all workspaces |
| `addWorkspace` | Add new workspace |
| `forgetWorkspace` | Remove workspace |

### Git Operations (3)
| Operation | Description |
|-----------|-------------|
| `listGitRemotes` | List remotes |
| `gitFetch` | Fetch from remote |
| `gitPush` | Push to remote |

## Architecture

```
jj-nim/
├── src/
│   ├── jj.nim              # Main entry point (exports all)
│   └── jj/
│       ├── types.nim       # Type definitions
│       ├── adapter.nim     # Abstract interface
│       ├── cli.nim         # CLI implementation
│       └── mock.nim        # Mock for testing
├── tests/
│   ├── test_all.nim        # Test runner
│   ├── test_types.nim      # Type tests
│   ├── test_adapter.nim    # Interface tests
│   ├── test_mock.nim       # Mock adapter tests
│   └── test_cli.nim        # CLI adapter tests
├── specs/                  # Gherkin specifications
│   ├── types.feature
│   ├── adapter.feature
│   ├── mock.feature
│   ├── cli.feature
│   ├── bookmarks.feature
│   ├── operations.feature
│   ├── workspaces.feature
│   └── git.feature
└── docs/
    ├── API.md              # API reference
    └── EXAMPLES.md         # Usage examples
```

## Testing

```bash
# Run all tests
nim c -r tests/test_all.nim

# Run with JJ integration tests (requires JJ installed)
JJ_TEST_REPO=/path/to/test/repo nim c -r tests/test_all.nim
```

**Test Coverage:** 156 tests covering all operations

## Usage with Testing

The mock adapter makes unit testing easy:

```nim
import jj
import unittest

suite "My Feature":
  test "merge detection":
    let mock = newJJMockAdapter()

    # Setup test data
    mock.addRef("main", newJJRevId("abc123"))
    mock.addRef("feature", newJJRevId("def456"))
    mock.addConflict(newJJRevId("abc123"), newJJRevId("def456"))

    # Test conflict detection
    let result = mock.checkConflicts(
      newJJRevId("abc123"),
      newJJRevId("def456"),
      jjStrategyRebase
    )

    check result.hasConflict == true
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

Apache-2.0 - See [LICENSE](LICENSE) for details.

## Related Projects

- [Jujutsu (JJ)](https://github.com/jj-vcs/jj) - The version control system
- [Nomikon](https://github.com/your-org/nomikon) - Governance engine using jj-nim
