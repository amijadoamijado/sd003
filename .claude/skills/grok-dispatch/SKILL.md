---
name: grok-dispatch
description: Claude Code等からGrok CLIへAssistディスパッチする正準スキル。Lead mode（直接起動）は対象外。grok-build・--output-format plain で最終回答とstderrを分離。
allowed-tools: Bash, Read, Write
---

# /grok-dispatch

`--permission-mode bypassPermissions` は非対話実行に必須（2026-07-12 E2E実測）。必ず隔離workspaceで使用する。

Claude Code 等の **Session Lead から** xAI 公式 Grok CLI にタスクを渡す **Assist mode** 用スキル。

> **Lead mode は本スキルの対象外。** ユーザーが Grok を直接起動する、または「Grok主導で」等と言った場合は
> Grok が Session Lead。Claude はディスパッチせず、必要なら handoff する。
> Lead 正本: `.grok/GROK_NATIVE.md` / 運用: `.sd/ai-coordination/workflow/GROK_GUIDE.md`

> ⚠️ **2026-06-28 実測で確定したこと（推測コマンドを正準化しない）**
> - `--output-format` の有効値は **`plain | json | streaming-json`**。**`text` は無効**（exit 2）。
> - **`--prompt-file <file>`** で長文プロンプトをファイル渡しできる（長文を引数で渡すより堅牢）。
> - 最終回答は **stdout（plain・clean）**、進捗・DEBUG・OpenTelemetry は **stderr**。`> out 2> progress.log` で分離する。
> - codex の `-o`（最終メッセージ専用ファイル化）**相当は無い**。stdout リダイレクトが正本。
> - 既定モデルの `grok -p` は**エージェント的にリポジトリを探索し始める**（実測 5分で timeout）。
>   レビュー・相談用途では「**探索禁止・提示テキストのみで回答**」をプロンプトに明示する。

## 正準コマンド（これだけ使う）

```powershell
# 環境（GROK_HOME 必須。exe は $GROK_HOME\bin\grok.exe）
$env:GROK_HOME = 'D:\grok'   # 例。実体は環境変数で持つ
$grok = Join-Path $env:GROK_HOME 'bin\grok.exe'

# 1) 長文プロンプトはファイルに書いてから渡す
Set-Content -Path prompt.txt -Value $prompt -Encoding UTF8

# 2) 実行（最終回答→out.txt / 進捗→progress.log）
& $grok --prompt-file prompt.txt -m grok-build --output-format plain > out.txt 2> progress.log
```

実行後は **`out.txt` だけ読む**。`progress.log` は原則読まない（巨大）。失敗診断時だけ `tail` する。

ラッパー（フラグを間違えない決定論入口・推奨）: `.claude/skills/grok-dispatch/grok-run.ps1`
```powershell
pwsh -File .claude/skills/grok-dispatch/grok-run.ps1 <repo> <out.txt> "<prompt>" [model]
# Bash tool から呼ぶ場合も pwsh -File で呼ぶ（Codex=bash / Grok=ps1 の非対称を吸収）
```

## 効いた設定（実測 2026-06-28）

| 目的 | フラグ/env | 根拠 |
|------|-----------|------|
| 最終回答だけ受け取る | `--output-format plain` + `> out.txt` | stdout=最終回答。`text`は無効、`plain`が正 |
| 進捗ログを context に入れない | `2> progress.log`（**`--debug-file`と二重化しない**） | 進捗・DEBUG・telemetryは stderr |
| 長文プロンプト | `--prompt-file <file>` | 引数渡しより堅牢 |
| コーディング特化モデル | `-m grok-build` | xAIの実装向けモデル（`grok build`はサブコマンドではない） |
| 機械可読 | `--output-format json`（必要時） | stdout が JSON。最終回答キーを抽出 |
| 探索抑制（相談用途） | プロンプトに「ツール不使用・探索禁止・即答」 | 既定はエージェント的に探索する |

> **出力正本マトリクス（1本化・二重化禁止）**: stdout=`--output-format plain > out`（最終回答）/ stderr=`2> progress.log`（進捗）/ debug=原則未使用（詳細診断時のみ `--debug-file`）。

## 着手前プリフライト（必須・OOM/詰まり防止）

1. **GROK_HOME**: 設定済みか。`$env:GROK_HOME` 未設定だと grok が `%USERPROFILE%\.grok` を再生成する。
2. **RAM 確認**: 空き < 5GB なら重い CLI 同時実行は OOM 危険。
   `pwsh -NoProfile -Command "[int]((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
3. **単一インスタンス / 排他**: 既存 grok/codex/agy が走っていないか（`Get-Process grok,codex,agy`）。
   **同一 repo への複数AI同時書き込みは禁止**（git 競合回避）。
4. RAM 逼迫 or 既存インスタンス有 → §「人手ハンドオフ」へ。

## 実行モード（フォアグラウンド vs 待機）

- 短時間（小タスク）: フォアグラウンドで `out.txt` を待つ。
- 長時間が読めない: `run_in_background` の Bash/PowerShell で実行し、`out.txt` 生成をポーリングで待つ。**foreground sleep は使わない**。

## 人手ハンドオフ（環境逼迫・反復失敗時）

CC が回すのが不安定（RAM<5GB・既存agy/codex稼働・2回連続失敗）なら、**依頼書を書いてユーザーに渡す**。
依頼書には §「正準コマンド」のコピペ＋プロンプト＋出力先を含める（例: `materials/text/GROK-REQUEST-*.md`）。

## 失敗時プロトコル（盲目リトライ禁止）

- **同型の失敗が2回続いたら、同じコマンドで再試行しない**（root-cause-first ルール）。
- `progress.log` の tail と公式情報で**原因を特定してから**直す。
- 実例: `--output-format text` は exit 2（有効値は `plain|json|streaming-json`）。エラーは progress.log に出る。

## 役割と使い分け（4AI協調）

| モード | 手段 | 地位 |
|--------|------|------|
| **Lead** | ユーザーが Grok 直接起動 / 「Grok主導で」 | Session Lead（本スキル不使用） |
| **Assist** | 本スキル `grok-dispatch` | 被呼び出し。呼び出し元が Lead |

- Assist での典型用途: 調査 / セカンドオピニオン / 並列検証 / 補助実装（`grok-build`）。
- 公式レビュー印は **Codex**、本番 E2E は **agy**。所有ドメインは `ai-coordination.md` に従う。
- ad-hoc → 本スキルで `--output-format plain`。正式（案件IDあり）のみ `.sd/ai-coordination/`。

## 注意事項

- `grok -p` / `--prompt-file` は非インタラクティブ（確認なしで進む。config.toml `permission_mode="always-approve"`）。
- 結果は CC 側でレビューしてから適用する。
- 顧客データの外部送信に注意（OCR等の外部送信はユーザー `!` 実行）。
- Windows/pwsh 前提。`grok.exe` は Windows ネイティブのため `.ps1` ラッパーを使う。

## 改訂履歴

| 版 | 日付 | 内容 |
|---|------|------|
| 0.1 | 2026-06-28 | 初版。実測で正準invocation確定（`--output-format plain`・`--prompt-file`・stdout/stderr分離・`-m grok-build`）。codex-dispatch をミラーし grok-run.ps1 を追加。Grok自身による計画レビューを反映 |
| 0.2 | 2026-07-12 | Lead mode 正式採用に合わせ Assist 専用と明記。Lead は GROK_NATIVE / GROK_GUIDE へ |
