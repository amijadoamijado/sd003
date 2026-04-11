---
name: sessionread
description: Codex equivalent of the SD003 custom command `/sessionread`. Use when the user invokes `/sessionread`, `sessionread`, `session-read`.
---

# セッション読み込み（完全版）

この skill は Claude Code の `/sessionread` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# セッション読み込み（完全版）

セッション開始時に必要な全ファイルを読み込みます。

## 読み込み順序（必須）

| 順序 | ファイル | 目的 |
|------|---------|------|
| 1 | `D:\claudecode\CLAUDE.md` | グローバル設定（UTF-8制約等） |
| 2 | `./CLAUDE.md` | プロジェクト設定（SD003ルール） |
| 3 | `.sessions/session-current.md` | 現在のセッション（短期記憶） |
| 4 | `.sessions/TIMELINE.md` | プロジェクト履歴（長期記憶） |

## 実行手順

### Step 1: グローバル CLAUDE.md
```
Read: D:\claudecode\CLAUDE.md
```
- UTF-8境界エラー防止ルール
- 日本語ファイル操作制約
- セッション開始プロトコル

### Step 2: プロジェクト CLAUDE.md
```
Read: ./CLAUDE.md
```
- SD003フレームワーク設定
- 技術スタック
- AI協調ワークフロー

### Step 3: session-current.md
```
Read: .sessions/session-current.md
```
- 前回の作業状況
- 進行中タスク
- P0/P1/P2 優先タスク

### Step 4: TIMELINE.md
```
Read: .sessions/TIMELINE.md
```
- プロジェクト全体の履歴
- 過去セッションの概要
- 長期的なコンテキスト

## 表示フォーマット

全ファイル読み込み後、以下の形式で要約を表示:

```
📚 セッション読み込み完了

## 1. グローバル設定
✅ CLAUDE.md (グローバル) 読み込み完了
   - UTF-8制約ルール確認

## 2. プロジェクト設定
✅ CLAUDE.md (プロジェクト) 読み込み完了
   - SD003 v[バージョン]

## 3. 現在セッション
📅 前回: [日時]
🌿 ブランチ: [ブランチ名]
📝 コミット: [最新コミット]

### 作業状況
✅ 完了: [N]件
🔄 進行中: [N]件
🔴 未解決: [N]件

### 次回優先 (P0)
[P0タスクリスト]

## 4. プロジェクト履歴
📊 総セッション数: [N]
📆 期間: [開始日] ~ [最終日]
🔧 直近の作業: [概要]

---
🚀 セッション開始準備完了
```

## エラーハンドリング

| ファイル | 存在しない場合 |
|---------|---------------|
| グローバル CLAUDE.md | 警告表示、続行 |
| プロジェクト CLAUDE.md | 警告表示、続行 |
| session-current.md | 「新規セッション」として扱う |
| TIMELINE.md | 「履歴なし」として扱う |

## 関連コマンド

| コマンド | 目的 |
|---------|------|
| `/sessionwrite` | セッション保存（終了時） |
| `/sessionhistory` | 履歴のみ表示 |

---

## Step 5: セッションアーカイブ（バックグラウンド）

**4ファイル読み込みと並行して**、以下のAgentをバックグラウンドで起動する:

```
Agent(run_in_background=true):
  description: "archive old sessions"
  prompt: |
    古いClaude Codeセッションのアーカイブ状況を確認します。以下を実行してください:
    1. bash ~/.claude/scripts/archive-sessions.sh 7 preview でプレビュー
    2. 対象が0件なら「アーカイブ対象なし」と報告して終了
    3. 対象がある場合は件数とサイズを報告（実行はしない）
    4. 「/archive-sessions --execute で実行できます」と案内
```

**重要**: このAgentはバックグラウンドで実行し、メインの作業をブロックしない。
完了通知が届いたら結果を簡潔にユーザーに伝える。

---

## Step 6: NotebookLM知見取得（バックグラウンド、オプション）

`.sd/notebooklm-config.json` が存在し `memory.enabled: true` の場合のみ、
Step 5と並行してバックグラウンドAgentを起動する:

```
Agent(run_in_background=true):
  description: "fetch relevant knowledge from NotebookLM"
  prompt: |
    .sd/notebooklm-config.json を読み、memory.enabled が true なら:
    1. python -m notebooklm auth check で認証確認
    2. session-current.md の次回タスクを読む
    3. python -m notebooklm chat "前回のセッションで未解決だった課題と関連する過去の知見" -n <notebook_id>
    4. 結果があれば「関連する過去の知見」として報告
    configが存在しない or enabled=false なら「NLMメモリ無効」と報告して終了
```

詳細: `.claude/skills/notebooklm-memory/SKILL.md`

---

**実行開始**: 上記4ファイルを順番に読み込み（Step 1-4）、同時にStep 5-6のAgentをバックグラウンドで起動し、要約を表示してください。
