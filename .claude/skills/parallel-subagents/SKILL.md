---
name: parallel-subagents
description: Claude内部サブエージェント並列実行のパターンとガイドライン
optional: true
source: obra/superpowers (adapted)
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
---

# Parallel Subagents - Claude内部並列実行ガイド

## 概要

Claude Code内のAgent toolを使い、複数のサブエージェントを並列に起動して
独立したタスクを同時に処理するためのガイド。
SD003の「サブエージェント積極活用原則」を具体的なパターンで実装する。

## 外部AI並列 vs 内部並列の棲み分け

| 領域 | 仕組み | 使うもの |
|------|--------|---------|
| 外部AI並列 | Claude Code → Gemini/Codex/Antigravity | AI協調体制（`/workflow:*`） |
| **内部並列** | Claude Code → Agent tool × N | **本スキル** |

## 適用判断フロー

```
タスクが複数の独立した部分に分解できるか？
  ├── YES → 各部分が共有状態を持つか？
  │     ├── YES → 順次実行（並列化禁止）
  │     └── NO  → ★ 並列サブエージェント適用
  └── NO  → 単一タスクとして実行
```

## パターン1: 調査並列化

複数のファイル・ディレクトリを同時に調査する。

```
Agent("ファイルAの構造を調査", subagent_type="Explore")
Agent("ファイルBの構造を調査", subagent_type="Explore")
Agent("ファイルCの構造を調査", subagent_type="Explore")
→ 3つの結果を統合して分析
```

### SD003ユースケース

| コマンド | 並列タスク |
|---------|-----------|
| `/refactor:init` | Scope Agent + Pattern Agent + Risk Agent |
| `/bug-trace` | 多ファイル同時調査 |
| コードレビュー | 複数ファイルの同時読解 |

## パターン2: 実行並列化

独立した実装タスクを同時に行う。

```
Agent("テストファイルAを修正", isolation="worktree")
Agent("テストファイルBを修正", isolation="worktree")
→ 各worktreeの結果をマージ
```

### 注意: worktree分離が必要なケース

同じファイルを触る可能性がある場合、`isolation: "worktree"` を指定:

| ケース | isolation |
|--------|-----------|
| 異なるファイルを編集 | 不要 |
| 同じファイルを編集する可能性あり | `"worktree"` 必須 |
| 読み取り専用の調査 | 不要 |

## パターン3: 検証並列化

異なる観点からの検証を同時に行う。

```
Agent("型チェックを実行: npm run typecheck")
Agent("Lintを実行: npm run lint")
Agent("テストを実行: npm test")
→ 全結果を集約して報告
```

## ディスパッチの書き方

### 良い例（明確で独立したタスク）

```
# 1つのメッセージで複数のAgent呼び出しを並列実行
Agent(
  description="Scope分析",
  prompt="src/配下の全TypeScriptファイルの依存関係を調査し、変更影響範囲を報告して",
  subagent_type="Explore"
)
Agent(
  description="Pattern分析",
  prompt="src/配下で繰り返し出現するコードパターンを特定して報告して",
  subagent_type="Explore"
)
Agent(
  description="Risk分析",
  prompt="src/配下のテストカバレッジが低いファイルとリスクの高い変更箇所を報告して",
  subagent_type="Explore"
)
```

### 悪い例（禁止パターン）

```
# ❌ 共有状態がある（同じファイルを順に編集する必要がある）
Agent("ファイルAの1行目を修正")
Agent("ファイルAの修正結果を踏まえて2行目を修正")  # 依存関係あり！

# ❌ 曖昧な指示
Agent("なんかいい感じに調べて")

# ❌ 結果を使わない無駄な並列化
Agent("READMEを読んで")  # 自分で直接Read toolを使えばよい
```

## 結果統合のパターン

サブエージェントの結果が返ってきたら:

1. **集約**: 全結果を一覧にまとめる
2. **矛盾検出**: 結果間の矛盾がないか確認
3. **統合判断**: 矛盾がある場合はユーザーに判断を仰ぐ
4. **アクション**: 統合結果に基づいて次のステップを実行

## パフォーマンス指針

| エージェント数 | 推奨用途 |
|---------------|---------|
| 2-3 | 標準的な並列調査・検証 |
| 4-5 | 大規模リファクタリングの分析 |
| 6+ | 原則避ける（結果統合が複雑になる） |

## 禁止事項

| 禁止 | 理由 |
|------|------|
| 共有状態のあるタスクの並列化 | 競合・不整合が発生する |
| 曖昧な指示での委譲 | サブエージェントが迷走する |
| 単純な読み取りのためのAgent起動 | Read/Glob/Grepで十分 |
| メインで同じ調査を重複実行 | コンテキストの無駄遣い |
| 結果を確認せず次に進む | 品質低下 |
