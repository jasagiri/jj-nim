# jj-nim Specifications

Gherkin形式の仕様書です。

## Feature Files

| File | Description | Scenarios |
|------|-------------|-----------|
| [types.feature](types.feature) | Type system specifications | 型、コンストラクタ、JSON変換 |
| [adapter.feature](adapter.feature) | Adapter interface specifications | 抽象インターフェース、ポリモーフィズム |
| [mock.feature](mock.feature) | Mock adapter specifications | テスト用モック、全メソッド |
| [cli.feature](cli.feature) | CLI adapter specifications | CLIラッパー、エラー処理 |
| [bookmarks.feature](bookmarks.feature) | Bookmark operations | ブックマーク作成・削除・移動 |
| [operations.feature](operations.feature) | Operation log (audit) | 操作ログ、Undo、監査証跡 |
| [workspaces.feature](workspaces.feature) | Workspace operations | ワークスペース管理 |
| [git.feature](git.feature) | Git integration | Git fetch/push/remote |

## Overview

### types.feature

JJ型システムの仕様:

- **JJRevId** - リビジョン識別子（コミットハッシュ）
- **JJChangeId** - 変更識別子（JJの不変追跡ID）
- **JJTimestamp** - ミリ秒タイムスタンプ
- **JJMergeStrategy** - マージ戦略（rebase/squash/merge）
- **JJRef** - 解決された参照
- **JJRevision** - リビジョンメタデータ
- **JJMergeBase** - マージベース結果
- **JJConflictResult** - コンフリクト検出結果
- **JJMergeResult** - マージ実行結果
- **JJError** - エラー型
- **JJRewriteEntry/Map** - リライト追跡

### adapter.feature

抽象アダプターインターフェースの仕様:

- 基本クラス作成と継承
- 全13メソッドのインターフェース契約
- ベースメソッドは未実装例外を投げる
- ポリモーフィズムとメソッドディスパッチ

### mock.feature

テスト用モックアダプターの仕様:

- セットアップメソッド（addRef, addRevision, addConflict, addAncestry）
- 全13メソッドのモック実装
- 設定可能な動作（コンフリクト、祖先関係）
- ポリモーフィズム対応

### cli.feature

CLIアダプターの仕様:

- jjコマンドのラッパー
- 無効リポジトリの処理
- 無効バイナリの処理
- マージ戦略の実装
- エラーコード検出
- 統合テスト（@requires-jj タグ）

### bookmarks.feature

ブックマーク（名前付き参照）の仕様:

- **JJBookmark** - ブックマークオブジェクト
- **JJBookmarkState** - local/tracking/conflict
- **listBookmarks** - ブックマーク一覧
- **createBookmark** - ブックマーク作成
- **deleteBookmark** - ブックマーク削除
- **moveBookmark** - ブックマーク移動
- **getBookmark** - ブックマーク取得

### operations.feature

操作ログ（監査証跡）の仕様:

- **JJOperationId** - 操作識別子
- **JJOperationType** - 操作タイプ（commit, rebase, etc.）
- **JJOperation** - 操作オブジェクト
- **getOperationLog** - 操作ログ取得
- **getOperation** - 特定操作取得
- **undoOperation** - 操作取り消し
- **restoreToOperation** - 操作状態復元

### workspaces.feature

ワークスペースの仕様:

- **JJWorkspace** - ワークスペースオブジェクト
- **listWorkspaces** - ワークスペース一覧
- **addWorkspace** - ワークスペース追加
- **forgetWorkspace** - ワークスペース削除

### git.feature

Git連携の仕様:

- **JJGitRemote** - リモートオブジェクト
- **JJGitFetchResult** - フェッチ結果
- **JJGitPushResult** - プッシュ結果
- **listGitRemotes** - リモート一覧
- **gitFetch** - リモートからフェッチ
- **gitPush** - リモートへプッシュ

## Tags

| Tag | Description |
|-----|-------------|
| `@requires-jj` | 実際のJJインストールが必要 |

## Running Specifications

これらの仕様書は設計ドキュメントとして機能し、
テストコード（`tests/`）の期待動作を記述しています。

```bash
# テストを実行して仕様を検証
cd /path/to/jj-nim
nimble test
```
