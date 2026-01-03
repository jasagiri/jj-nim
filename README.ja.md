# jj-nim

[![Nim Version](https://img.shields.io/badge/nim-%3E%3D2.0.0-orange)](https://nim-lang.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-156%20passing-green)]()

[Jujutsu (JJ)](https://github.com/jj-vcs/jj) バージョン管理システム用のNimアダプタライブラリ

[English](README.md) | 日本語

## 特徴

- **型安全** - RevId、ChangeId、OperationId用のdistinct型
- **ポリモーフィック** - CLIとMock実装を持つ抽象アダプタインターフェース
- **完全機能** - JJの全コア機能をカバーする27操作
- **テスト容易** - 実際のJJなしでユニットテスト可能なMockアダプタ
- **監査対応** - 監査証跡のための操作ログサポート

## クイックスタート

```nim
import jj

# リポジトリ用のアダプタを作成
let adapter = newJJCliAdapter("/path/to/repo")

# 参照を解決
let mainRef = adapter.resolveRef("main")
if mainRef.isSome:
  echo "Main branch: ", mainRef.get.revId

# マージ前にコンフリクトをチェック
let conflicts = adapter.checkConflicts(baseRev, headRev, jjStrategyRebase)
if not conflicts.hasConflict:
  let result = adapter.performMerge(baseRev, headRev, jjStrategyRebase, "Merge feature")
  if result.success:
    echo "Merged: ", result.mergedRev.get
```

## インストール

### nimble使用（推奨）

```nim
# .nimbleファイルに追加
requires "jj >= 0.1.0"
```

### 手動インストール

```bash
# リポジトリをクローン
git clone https://github.com/your-org/jj-nim.git

# nim.cfgに追加
echo '--path:"/path/to/jj-nim/src/"' >> nim.cfg
```

### 必要条件

- Nim >= 2.0.0
- JJ CLI（JJCliAdapter用）- [JJのインストール](https://github.com/jj-vcs/jj#installation)

## ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| [APIリファレンス](docs/API.md) | 完全なAPIドキュメント |
| [使用例](docs/EXAMPLES.md) | 詳細な使用例 |
| [仕様書](specs/README.md) | Gherkin BDD仕様書 |

## 基本概念

### アダプタパターン

jj-nimはJJ操作を抽象化するアダプタパターンを使用：

```nim
# 抽象基底クラス - インターフェースを定義
type JJAdapter* = ref object of RootObj

# CLIアダプタ - 実際のjjコマンドをラップ
let cli = newJJCliAdapter("/path/to/repo")

# Mockアダプタ - テスト用
let mock = newJJMockAdapter()
```

### 型安全

distinct型により識別子の混同を防止：

```nim
type
  JJRevId* = distinct string    # コミットハッシュ
  JJChangeId* = distinct string # 不変の変更ID
  JJOperationId* = distinct string # 操作ID

# コンパイルエラー - 型安全！
# let rev: JJRevId = changeId  # エラー！
```

### マージ戦略

```nim
type JJMergeStrategy* = enum
  jjStrategyRebase = "rebase"  # コミットをリベース
  jjStrategySquash = "squash"  # 1つに統合
  jjStrategyMerge = "merge"    # マージコミット作成
```

## 操作一覧

### コア操作（13）

| 操作 | 説明 |
|------|------|
| `resolveRef` | 参照名をリビジョンに解決 |
| `getRevision` | リビジョンメタデータを取得 |
| `computeMergeBase` | 共通祖先を検索 |
| `isAncestor` | 祖先関係をチェック |
| `checkConflicts` | コンフリクトを検出（ドライラン） |
| `performMerge` | マージを実行 |
| `getChangeTip` | 変更の現在リビジョンを取得 |
| `observeRewrite` | リライトを記録 |
| `getRewriteHistory` | 進化履歴を取得 |
| `trackChangeEvolution` | 完全なリライトマップを構築 |
| `wasRewritten` | リライトされたかチェック |
| `getCurrentRevForChange` | 変更の最新リビジョンを取得 |
| `getChangedPaths` | リビジョンで変更されたファイルを取得 |

### ブックマーク操作（5）

| 操作 | 説明 |
|------|------|
| `listBookmarks` | 全ブックマークを一覧 |
| `createBookmark` | 新規ブックマークを作成 |
| `deleteBookmark` | ブックマークを削除 |
| `moveBookmark` | 新しいリビジョンに移動 |
| `getBookmark` | 特定のブックマークを取得 |

### 操作ログ（4）- 監査証跡

| 操作 | 説明 |
|------|------|
| `getOperationLog` | 操作履歴を取得 |
| `getOperation` | 特定の操作を取得 |
| `undoOperation` | 操作を取り消し |
| `restoreToOperation` | 状態を復元 |

### ワークスペース操作（3）

| 操作 | 説明 |
|------|------|
| `listWorkspaces` | 全ワークスペースを一覧 |
| `addWorkspace` | 新規ワークスペースを追加 |
| `forgetWorkspace` | ワークスペースを削除 |

### Git操作（3）

| 操作 | 説明 |
|------|------|
| `listGitRemotes` | リモートを一覧 |
| `gitFetch` | リモートからフェッチ |
| `gitPush` | リモートにプッシュ |

## アーキテクチャ

```
jj-nim/
├── src/
│   ├── jj.nim              # メインエントリーポイント
│   └── jj/
│       ├── types.nim       # 型定義
│       ├── adapter.nim     # 抽象インターフェース（27メソッド）
│       ├── cli.nim         # CLI実装
│       └── mock.nim        # テスト用Mock
├── tests/                  # テストコード（156テスト）
├── specs/                  # Gherkin仕様書
└── docs/                   # ドキュメント
```

## テスト

```bash
# 全テスト実行
nim c -r tests/test_all.nim

# JJ統合テスト付き（JJインストール必要）
JJ_TEST_REPO=/path/to/test/repo nim c -r tests/test_all.nim
```

**テストカバレッジ:** 156テストで全操作をカバー

## Mockアダプタでのテスト

```nim
import jj
import unittest

suite "マイ機能":
  test "マージ検出":
    let mock = newJJMockAdapter()

    # テストデータをセットアップ
    mock.addRef("main", newJJRevId("abc123"))
    mock.addRef("feature", newJJRevId("def456"))
    mock.addConflict(newJJRevId("abc123"), newJJRevId("def456"))

    # コンフリクト検出をテスト
    let result = mock.checkConflicts(
      newJJRevId("abc123"),
      newJJRevId("def456"),
      jjStrategyRebase
    )

    check result.hasConflict == true
```

## Nomikon統合

jj-nimは[Nomikon](https://github.com/your-org/nomikon)の制度・法制エンジンで使用されています：

- **Praxis** - PRライフサイクル管理にJJアダプタを使用
- **Aletheia** - 操作ログで監査証跡を提供
- **Synnomia** - マージポリシー評価にコンフリクト検出を使用

## ライセンス

Apache-2.0 - 詳細は[LICENSE](LICENSE)を参照

## 関連プロジェクト

- [Jujutsu (JJ)](https://github.com/jj-vcs/jj) - バージョン管理システム
- [Nomikon](https://github.com/your-org/nomikon) - jj-nimを使用するガバナンスエンジン
