# SD003 Grok Specification

この文書は、SD003 を Grok CLI（xAI 公式）で動かすための追加仕様です。
Claude Code の仕様を置き換えず、`.claude/commands/**/*.md` を引き続き authoring source として扱います。

## 位置づけ

| 項目 | 方針 |
|------|------|
| Claude Code 正本 | `.claude/commands/**/*.md` |
| 共通正規化仕様 | `.sd/commands/specs/*.md` |
| Grok プロジェクト Skill | `.grok/skills/*/SKILL.md` |
| Grok ユーザー Skill | `~/.grok/skills/*/SKILL.md` |
| Grok Native（Lead） | `.grok/GROK_NATIVE.md` |
| 運用ガイド | `.sd/ai-coordination/workflow/GROK_GUIDE.md` |

Grok 向けの生成物は `python scripts/sync-cli-commands.py` で作成します。
生成済み Skill を直接手編集せず、Claude 側の正本または同期スクリプトの Grok adapter を変更してください。

## セットアップ・認証（他マシン・再デプロイ時の必須確認）

Grok CLI はデータホームを環境変数 `GROK_HOME` で決めます（このマシンの既定: `D:\grok`）。

```powershell
# 1) GROK_HOME（未設定だと grok が %USERPROFILE%\.grok を再生成する）
$env:GROK_HOME = 'D:\grok'          # 恒久化は [Environment]::SetEnvironmentVariable('GROK_HOME','D:\grok','User')

# 2) 実行ファイル
$grok = Join-Path $env:GROK_HOME 'bin\grok.exe'

# 3) 疎通確認
& $grok --version                    # grok 0.x が出れば OK

# 4) 未認証なら（auth.json が無い等）
& $grok login                        # もしくは xAI の API キー設定
```

- 認証情報は `$GROK_HOME\auth.json`。再ログインを求められたら `grok login`。
- PATH に `$GROK_HOME\bin` を通す（ディスパッチは絶対パス `$GROK_HOME\bin\grok.exe` を使うので必須ではない）。

## Grok 実行ルール

1. 人間向けの回答、レビュー報告、質問、完了報告は日本語で書く。
2. Claude Code のスラッシュコマンドを Grok で直接実行しない。生成 Skill 内の Original Command Body は意図の正本として読み、Grok の通常操作に翻訳する。
3. `/workflow:*`、`/codex:*` など他 CLI のスラッシュコマンドを再帰的に呼ばない。必要な差分確認・実装・検証・報告を Grok 自身で行う。
4. Windows / PowerShell 環境では PowerShell で実行できるコマンドを優先する。bash 例は WSL または Git Bash が利用可能な場合だけ使う。
5. 未コミット変更はユーザーまたは他 AI の作業として扱い、明示指示なしに戻さない。
6. GAS デプロイでは `clasp push` のみ許可する。`clasp deploy` と `clasp undeploy` はユーザーの明示指示なしに実行しない。
7. `.sd/ai-coordination/` へ依頼書・報告書を書く場合は案件 ID 配下に限定し、プロジェクトルートへ作成しない。
8. **同一 repo への複数 AI 同時書き込みは排他**（agy/codex/grok の並行編集禁止＝git 競合回避）。Lead が repo lock を持つ。

## Grok の役割（4AI協調）

| 項目 | 方針 |
|------|------|
| 役割 | **Lead 候補** / 探索実装 / 独立検証 / 調査主導。Assist 時はセカンドパス・補助実装 |
| Lead mode | ユーザーが Grok を直接起動、または「Grok主導で」等。Session Lead として自己完結（`.grok/GROK_NATIVE.md`） |
| Assist mode | Claude 等から `grok-dispatch` で呼ばれたとき。呼び出し元が Lead |
| 主担当との関係 | 公式レビュー印=Codex / 本番 E2E=agy。衝突時はドメイン表（ai-coordination.md）に従う |
| 起動 | Lead=直接起動 / Assist=`grok-dispatch`（`.claude/skills/grok-dispatch/`） |

詳細な役割分岐は `.claude/rules/workflow/ai-coordination.md` の「司令塔ルール」「役割分岐」に従う。

## モデル使い分け

| 用途 | モデル / 形態 |
|------|----------------|
| Lead 対話・方針・調査 | 対話 TUI（Session Lead） |
| 実装・リファクタ・バグ修正（非対話含む） | `-m grok-build` |
| Assist 非対話ディスパッチ | `grok-build` + `--output-format plain`（既定） |

## 非対話ディスパッチの正準形（Assist・実測 2026-06-28）

```powershell
& $grok --prompt-file <in.txt> -m grok-build --output-format plain > <out.txt> 2> <progress.log>
```

- `--output-format` の有効値は `plain | json | streaming-json`（`text` は無効）。
- 最終回答は stdout（plain）、進捗・DEBUG は stderr。`> out 2> progress.log` で分離。
- `grok build` はサブコマンドではない。コーディング特化モデルは `-m grok-build`。
- ラッパー: `pwsh -File .claude/skills/grok-dispatch/grok-run.ps1 <repo> <out> "<prompt>" [model]`

## 同期検証

以下が通る状態を Grok 仕様の正常状態とする。

```powershell
python scripts/sync-cli-commands.py --check
```

`--check` は、Claude command から生成される `.sd/commands/specs`、`.agents/skills`（agy）、`.codex/skills`、`.grok/skills`（Grok）、および `CODEX_SPEC.md` / `GROK_SPEC.md` / `GROK_NATIVE.md` の存在を確認する。dispatch 系スキル（`DISPATCH_EXCLUDE`）は Grok 生成対象外なので検証もスキップされる。
