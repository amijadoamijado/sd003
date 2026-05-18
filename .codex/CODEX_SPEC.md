# SD003 Codex Specification

この文書は、SD003をCodex CLIで動かすための追加仕様です。
Claude Codeの仕様を置き換えず、`.claude/commands/**/*.md` を引き続きauthoring sourceとして扱います。

## 位置づけ

| 項目 | 方針 |
|------|------|
| Claude Code正本 | `.claude/commands/**/*.md` |
| 共通正規化仕様 | `.sd/commands/specs/*.md` |
| CodexプロジェクトSkill | `.codex/skills/*/SKILL.md` |
| CodexユーザーSkill配布先 | `~/.codex/skills/*/SKILL.md` |
| 旧Codex Skillパス | `.agents/skills/*/SKILL.md` はlegacy扱い |

Codex向けの生成物は `python scripts/sync-cli-commands.py` で作成します。
生成済みSkillを直接手編集せず、Claude側の正本または同期スクリプトのCodex adapterを変更してください。

## Codex実行ルール

1. 人間向けの回答、レビュー報告、質問、完了報告は日本語で書く。
2. Claude CodeのスラッシュコマンドはCodexで直接実行しない。生成Skill内のOriginal Command Bodyは意図の正本として読み、Codexの通常操作に翻訳する。
3. Codex内で `/codex:review`、`/codex:rescue`、`/codex:adversarial-review` を再帰的に呼ばない。必要な差分確認、実装、検証、報告をCodex自身で行う。
4. Windows 11 / PowerShell環境ではPowerShellで実行できるコマンドを優先する。bash例はWSLまたはGit Bashが利用可能な場合だけ使う。
5. 未コミット変更はユーザーまたは他AIの作業として扱い、明示指示なしに戻さない。
6. GASデプロイでは `clasp push` のみ許可する。`clasp deploy` と `clasp undeploy` はユーザーの明示指示なしに実行しない。
7. `.sd/ai-coordination/` へ依頼書・報告書を書く場合は案件ID配下に限定し、プロジェクトルートへ作成しない。

## Codexレビュー仕様

Codexがレビュー担当として呼ばれた場合は、次を最小セットとして実施します。

1. `.handoff/AGENTS.md` が存在する場合はレビュー手順として読む。
2. 対象の `WORK_ORDER.md`、`IMPLEMENT_REQUEST_*.md`、`REVIEW_REQUEST_*.md` があれば読む。
3. `git status --short`、`git diff --stat`、必要に応じて `git diff` または `git show` で差分を確認する。
4. 実行可能な範囲で `npm run build`、`npm test`、`npm run lint` を確認する。失敗または未実行の場合はレビュー結果に明記する。
5. 指摘は重大度、場所、影響、修正案を含める。
6. 結果は `.sd/ai-coordination/workflow/review/{案件ID}/` に保存する。案件IDが不明な場合はユーザーへ確認する。

## Codex実装仕様

Codexが実装担当として呼ばれた場合は、次を最小セットとして実施します。

1. 実装前に `git status --short` を確認し、既存の未コミット変更を把握する。
2. `IMPLEMENT_REQUEST_*.md` の変更可能ファイル、Acceptance Criteria、検証手順を守る。
3. 編集は対象スコープに限定する。
4. 検証コマンドを実行し、失敗した場合は原因と残作業を報告する。
5. `.sd/` 設定系やClaude Code hookを壊す変更をしない。

## 同期検証

以下が通る状態をCodex仕様の正常状態とする。

```powershell
python scripts/sync-cli-commands.py --check
```

`--check` は、Claude commandから生成される `.sd/commands/specs`、`.gemini/commands`、`.codex/skills`、およびこの `CODEX_SPEC.md` の存在を確認する。
