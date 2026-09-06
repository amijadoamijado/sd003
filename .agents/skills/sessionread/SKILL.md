---
name: sessionread
description: "最新の引継ぎと現在のGit状態を確認する"
disable-model-invocation: true
---

# セッション読み込み

SD003 custom command `/sessionread` をCodex/agy共通Agent Skillとして再現します。

User-provided arguments (if any): $ARGUMENTS

## Runtime Adaptation Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、実行中CLIの通常手順（ファイル読取・編集・検証・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは再帰実行しない。必要な作業は現在のCLIが直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。
- Codex固有の実行優先順位は `.codex/CODEX_NATIVE.md` に従う。

## Original Command Body
# セッション読み込み

最新の引継ぎと現在の状態を照合し、次の作業に必要な情報を短く報告する。読み込みだけの依頼では、残タスクの実装や設定変更を開始しない。

## 読み込み

1. 対象プロジェクトの絶対パスを固定する。シェルのプロファイルによる作業ディレクトリ変更を避け、Windowsでは`pwsh -NoProfile`と明示した作業ディレクトリを使う。
2. 実行中CLIの入口設定を確認する。Codexは`AGENTS.md`と`.codex/CODEX_NATIVE.md`、Grokは`.grok/GROK_NATIVE.md`、agyは`antigravity.md`、Claude Codeは`CLAUDE.md`に従う。すでに読んだ設定は再読しない。
3. `.sessions/session-current.md`、`git status --short`、現在のブランチ、直近コミットを確認する。
4. `.handoff/DONE.md`が存在し、session-currentより新しい場合は併読する。
5. 過去の経緯が必要な場合だけ`.sessions/TIMELINE.md`をキーワード検索し、関連する記録を読む。他CLIのグローバル設定や全履歴の読み込みは不要。

記録内のモデル・設定・未解決事項は過去時点の情報として扱う。今回確認できた状態と異なる場合は、その差を示す。設定内容や認証情報を確認する際は秘密の値を出力しない。

## 起動時の点検（読み取りのみ）

このセッションでまだ実施していなければ、次の2点を確認する。どちらも読み取りだけで、ファイルの更新も移動も行わない。差がなければ何も報告せず先へ進む。

**SD003の版**: `.codex/check-framework-version.py`があれば`python .codex/check-framework-version.py`で更新元と比較する（更新元の指定は`--source <絶対パス>`または`SD003_SOURCE`）。スクリプトが無い旧い導入先では、導入先と更新元の`.claude/skills/sd-deploy/deploy.ps1`から`$FRAMEWORK_VERSION`を読んで直接比較する（`CLAUDE.md`末尾の版表記は別管理でズレるため比較に使わない）。更新があれば導入版・更新元版と、`/sd-upgrade .`で更新できることを1行で伝える。参照不能は未確認として扱う。

**会話ログの退避候補**: `~/.claude/scripts/archive-sessions.sh`があれば`bash ~/.claude/scripts/archive-sessions.sh 7 preview`で候補を数える。previewは数えるだけで移動しない。候補があれば件数・容量と、`bash ~/.claude/scripts/archive-sessions.sh 7 execute`で退避できることを1行で伝える。0件なら報告しない。

## 報告

- 前回日時と主な完了事項
- 現在のブランチ・コミット・未コミット変更
- 次の優先事項と未検証事項
- 引継ぎと現状の差（ある場合）
- 起動時の点検で差が出た場合のみ、その1行（SD003更新あり／ログ退避候補あり）

ファイルがない場合は「引継ぎ記録なし」「履歴なし」等と伝え、確認できる範囲を報告する。読み取りのみなら「変更なし」と明記する。

## 保守作業

起動時の点検は状態を見るだけで、実際の退避・更新適用・モデル変更は読み込みのたびに行わない。報告を見たユーザーが指示した時点で実行する。SD003更新を依頼された場合は`sd-upgrade`の手順に従う。
