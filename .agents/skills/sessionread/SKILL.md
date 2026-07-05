---
name: sessionread
description: "最新のセッション継続記録を読み込み表示"
disable-model-invocation: true
---

# セッション読み込み（完全版）

SD003 custom command `/sessionread` を Antigravity (agy) skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Antigravity Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、agy の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

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
   - 🔄 SD003アップデートあり: v[ローカル] → v[現行]（該当時のみ表示。Step 6参照）

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
| SD003アップデートチェック（Step 6） | 作業ディレクトリが `D:\claudecode\sd003` 自身、または `./CLAUDE.md` に `SD003 v` 表記なし → スキップ（無音） |

## 関連コマンド

| コマンド | 目的 |
|---------|------|
| `/sessionwrite` | セッション保存（終了時） |
| `/sessionhistory` | 履歴のみ表示 |
| `/sd-upgrade` | SD003フレームワークの安全アップグレード（Step 6から誘導） |

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

## Step 6: SD003アップデートチェック（デプロイ先プロジェクトのみ）

Step 2（プロジェクト CLAUDE.md）読み込み後、非ブロッキングで以下を確認する。
**このプロジェクトが SD003 本体（`D:\claudecode\sd003`）自身の場合は完全にスキップする**（無音）。

### 6-1: バージョン検出

1. `Grep pattern:"SD003 v[0-9.]+" path:"./CLAUDE.md"` でローカルバージョンを取得。
   マッチしなければ「このプロジェクトはSD003未デプロイ」としてスキップ（無音・以降の手順は実行しない）。
2. `Grep pattern:"FRAMEWORK_VERSION = " path:"D:/claudecode/sd003/.claude/skills/sd-deploy/deploy.ps1"`
   で現行バージョン（`$FRAMEWORK_VERSION`）を取得する。
   - 注意: SD003本体の `CLAUDE.md` 末尾表記（例: `SD003 v3.4.0`）とはズレがあり得る
     （deployスクリプト自体のバージョンと、実際にデプロイ先へ書き込まれるテンプレートの
     バージョンが別管理のため）。**比較には必ず `deploy.ps1` の `$FRAMEWORK_VERSION` を使う**
     （それが実際にプロジェクトへ配布される値だから）。
3. ドット区切りで数値比較（例: `2.15.0` vs `2.16.0` → 各セグメントを左から数値比較）。
   ローカル < 現行 の場合のみ「アップデートあり」。同じかローカルの方が新しければ何もしない（無音）。

### 6-2: 非ブロッキング通知

「アップデートあり」の場合のみ、表示フォーマットの「## 2. プロジェクト設定」の下に
`🔄 SD003アップデートあり: v[ローカル] → v[現行]` の1行を追記する（表示フォーマット節を参照）。
ここまでは通常の要約表示の一部であり、ユーザーへの質問は発生しない。

### 6-3: 確認ゲート（アップデートありの場合のみ、1回だけ）

4ファイルの要約表示が終わった最後に、`AskUserQuestion` で一度だけ確認する:

> SD003アップデートがあります（v[ローカル] → v[現行]）。今すぐ更新しますか？

選択肢:
- **dry-run確認→実行（推奨）**
- 後で（`/sd-upgrade .` で自分で実行できることを案内して終了）
- 今回はスキップ

### 6-4: 「dry-run確認→実行」選択時の実行手順

1. dry-run:
   ```
   pwsh -File "D:\claudecode\sd003\.claude\skills\sd-upgrade\upgrade.ps1" "<このプロジェクトの絶対パス>"
   ```
   - 必ずSD003本体側の絶対パスのスクリプトを呼ぶこと（`$PSScriptRoot`基準でsourceを解決するため、
     デプロイ先にコピーされた同名スクリプトをそのcwdで実行すると誤動作する）
   - CP932文字化け回避のため `powershell` ではなく `pwsh` を使う（グローバルCLAUDE.md既存ルール）
2. dry-run結果（`WILL OVERWRITE - LOCAL CUSTOMIZATION WILL BE LOST` 等）をユーザーに提示する。
   固有化ファイルが上書き対象に含まれ、かつ `<target>/.sd003-keep` が無い/不十分な場合は
   追記を促す（`.claude/skills/sd-upgrade/SKILL.md` の `.sd003-keep` 節を参照）。
3. 再度 `AskUserQuestion` で `--execute` で実行してよいか確認する（2段目のゲート。
   破壊的操作のため dry-run結果を見せずに実行しない）。
4. 承認後のみ実行:
   ```
   pwsh -File "D:\claudecode\sd003\.claude\skills\sd-upgrade\upgrade.ps1" "<このプロジェクトの絶対パス>" -Execute
   ```
5. 完了後、`npm install` の実行と（agy利用時は）agy再起動を推奨する旨を案内する
   （`.claude/skills/sd-upgrade/SKILL.md` の「注意」節に準拠）。

---

**実行開始**: 上記4ファイルを順番に読み込み（Step 1-4）、同時にStep 5のAgentをバックグラウンドで起動し、
Step 6のSD003アップデートチェックを非ブロッキングで実行した上で、要約を表示してください。
