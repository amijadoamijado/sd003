---
name: codex-dispatch
description: Claude CodeからCodex CLI (codex exec) にタスクをディスパッチする正準スキル。2>&1|tee 禁止・-oで最終回答受領・effort制御。
disable-model-invocation: true
---

# /codex-dispatch

Claude Code から Codex CLI (`codex exec`) にタスクを渡す正準スキル。

> ⚠️ **2026-05-26 事故対策（必読・二度と同じ間違いをしないため）**
> 旧版（user-global の codex-dispatch）は `codex exec "..." 2>&1 | tee` を教えていた。これが**全失敗の原因**:
> codex は **進捗・テレメトリを stderr に、最終回答だけを stdout に**出す。
> `2>&1` で stderr を混ぜると DEBUG/OpenTelemetry ログが数MB〜10MB流入し最終回答が埋もれる（実測9.2MB）。
> さらに `config.toml` の `model_reasoning_effort=xhigh` が既定だと **遅すぎてタイムアウト**（RAM逼迫時は確実に落ちる）。
> → 下記「正準コマンド」を**必ず**使う。素の `codex exec ... 2>&1 | tee` は禁止。

## 正準コマンド（これだけ使う）

```bash
# レビュー・調査など「読むだけ」タスク（推奨デフォルト）
RUST_LOG=error codex exec "<prompt>" \
  --cd <repo> \
  -c model_reasoning_effort="medium" \
  --ignore-user-config \
  --sandbox read-only \
  -o <out.md> \
  2> <progress.log>
# 最終回答 → <out.md>（clean） / 進捗・ログ → <progress.log>（context に載せない）

# codex に編集させるタスク
RUST_LOG=error codex exec "<prompt>" \
  --cd <repo> \
  -c model_reasoning_effort="medium" \
  --ignore-user-config \
  --sandbox workspace-write \
  -o <out.md> \
  2> <progress.log>
```

実行後は **`<out.md>` だけ読む**。`<progress.log>` は原則読まない（巨大）。失敗診断時だけ `tail` する。

ラッパー（フラグを間違えない決定論入口・推奨）: `.claude/skills/codex-dispatch/codex-run.sh`
```bash
bash .claude/skills/codex-dispatch/codex-run.sh <repo> <out.md> read-only "<prompt>"
# user-global にも同等品がある場合あり: ~/.claude/skills/codex-dispatch/codex-run.sh
```

## 効いた設定（公式根拠 2026-05-26 確認）

| 目的 | フラグ/env | 根拠 |
|------|-----------|------|
| 最終回答だけ受け取る | `-o, --output-last-message <file>` | stdout=最終回答のみ。`-o`でファイル化 |
| 進捗ログを context に入れない | `2> progress.log`（**`2>&1`禁止**） | 進捗・telemetryは stderr |
| ログ抑制 | `RUST_LOG=error` | 既定infoでも reqwest/otel が出る |
| 速度（タイムアウト回避） | `-c model_reasoning_effort="medium"` ＋ `--ignore-user-config` | config.toml の xhigh を無視し medium に固定。`-c reasoning_effort=medium` が必要な版もある |
| 安全（レビューは読むだけ） | `--sandbox read-only` | 既定 read-only。編集時のみ workspace-write |
| 機械可読 | `--json`（必要時） | stdout が JSONL |
| 設定非依存の決定論実行 | `--ignore-user-config` / `--ignore-rules` | CI 向け |

## 着手前プリフライト（必須・OOM/詰まり防止）

1. **RAM 確認**: 空き < 5GB なら重い CLI 同時実行は OOM 危険（過去事例: 重CLI同時実行でOOMクラッシュ）。
   `pwsh -NoProfile -Command "[int]((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
2. **単一インスタンス**: 既存 codex/agy が走っていないか。`Get-Process codex,agy`。**codex と agy を同時に回さない**（OOM）。
3. **並走禁止**: Claude Code が重い処理中に codex をバックグラウンド並走させない（過去 OOM クラッシュ実績）。
4. RAM 逼迫 or 既存インスタンス有 → **CC で回さず §「人手ハンドオフ」へ**。

## 実行モード（フォアグラウンド vs 待機）

- 短時間（medium・小タスク）: フォアグラウンドで `-o` を待つ。
- 長時間が読めない: `run_in_background` の Bash で正準コマンドを実行し、`until [ -s <out.md> ]; do sleep 5; done`（＋wall-clock deadline）で完了を待つ。**foreground sleep は使わない**。

## 人手ハンドオフ（環境逼迫・反復失敗時）

CC が回すのが不安定（RAM<5GB・既存agy稼働・2回連続失敗）なら、**依頼書を書いてユーザーに渡す**。
依頼書には §「正準コマンド」のコピペ＋プロンプト＋出力先を含める（例: `materials/text/CODEX-REVIEW-REQUEST-*.md`）。
ユーザーが手元で実行→出力ファイルを CC が読む。

## 失敗時プロトコル（盲目リトライ禁止）

- **同型の失敗が2回続いたら、同じコマンドで再試行しない**（[[feedback_bash_caution]] / root-cause-first ルール）。
- 進捗ログ(`progress.log`)の tail と公式ドキュメント（WebSearch/WebFetch）で**原因を特定してから**直す。
- 原因が環境（RAM/インスタンス）なら人手ハンドオフへ切替。

## AGENTS.md / handoff 連携

対象プロジェクトの `AGENTS.md` / `.handoff/RULES.md` を codex が読む。設計書を渡す:
```bash
RUST_LOG=error codex exec "$(cat .handoff/IMPLEMENT_REQUEST_001.md)" --cd . -c model_reasoning_effort="medium" --ignore-user-config --sandbox workspace-write -o out.md 2> progress.log
```

## 公式プラグインとの使い分け

- ad-hoc な相談・レビュー（「codexにレビューさせて」等）→ 公式プラグイン `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`（CLAUDE.md 参照）。
- プログラム的な並列ディスパッチ・依頼書ベースの実行 → 本スキル（codex exec の正準invocation）。

## 注意事項

- `codex exec` は非インタラクティブ（確認なしで進む）。
- 結果は CC 側でレビューしてから適用する。
- 顧客データの外部送信は分類器がブロックする。OCR等の外部送信はユーザー `!` 実行。

## 改訂履歴

| 版 | 日付 | 内容 |
|---|------|------|
| 0.3 | 2026-05-26 | sd003 framework に正準化して取り込み（sd003のミス＝正準レシピ不在を是正）。project-local ラッパー参照・OOM事例汎用化 |
| 0.2 | 2026-05-26 | 事故対策。`2>&1 \| tee` 禁止→stderr分離+`-o`、xhigh→medium+`--ignore-user-config`、read-onlyサンドボックス、RAM/単一インスタンスのプリフライト、人手ハンドオフ、盲目リトライ禁止、ラッパー codex-run.sh を追加 |
| 0.1 | (初版・user-global) | 並列ディスパッチ（誤: 2>&1\|tee・effort未制御） |
