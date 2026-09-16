---
name: codex-security
description: "OpenAI公式のCodex Security CLIで、リポジトリの脅威ベース脆弱性スキャン、保存結果の調査、候補の検証、修正、SARIF・JSON・CSV出力を行う。ユーザーがセキュリティ監査、脆弱性診断、攻撃経路の確認、セキュリティ所見の再現、修正を依頼した場合や、認証・認可・秘密情報・外部入力・コマンド実行など高リスク変更の検査を相談した場合に使う。npm audit警告の説明だけには使わない。"
---

# Codex Security

OpenAI公式の `@openai/codex-security` を、対象範囲・外部送信・費用・変更権限を明確にして使う。CLIは初期版で変更が速いため、記憶したフラグより実行時の `--help` を優先する。

## 実行境界

- ユーザーがスキャン、検証、修正を明示的に依頼している場合は、その範囲内で実行する。
- 高リスク変更を発見しただけでスキャン依頼がない場合は、適用理由と対象範囲を示して提案する。ライブスキャンは開始しない。
- `info`、`--help`、`scan --dry-run` などローカルの読取・入力検証は、診断に必要なら実行してよい。
- ライブスキャンはソースコードやリポジトリ情報をOpenAIサービスへ送信し、認証方式によっては費用が発生し得る。依頼から明らかでない場合は実行前に確認する。
- `patch` はコードを変更する。相談・診断・レビューだけの依頼では実行しない。
- `install-hook`、`login`、`logout`、`bulk-scan` は永続設定、資格情報、複数リポジトリへ影響するため、明示依頼なしに実行しない。
- SD003内では `codex-security skills add` を実行しない。不要なCLI別Skillディレクトリも生成するため、Skill同期はSD003の正本と同期スクリプトで管理する。

## プリフライト

1. `git status --short` と `git rev-parse --show-toplevel` で対象ルートと既存変更を確認する。
2. 既存の未コミット変更をユーザーまたは他AIの作業として保護する。スキャン準備のために戻したりstashしたりしない。
3. まずローカルにインストール済みの版を使う。

```powershell
npx --no-install @openai/codex-security info --format json
npx --no-install @openai/codex-security scan --help
```

4. `--no-install` が失敗した場合は、勝手に最新版を取得しない。`Get-Command codex-security` と親ディレクトリの `node_modules/.bin` を確認し、それでも無ければインストールまたは `npx @openai/codex-security@latest` 実行の許可を得る。
5. ライブスキャン前に同じ引数で `--dry-run` を実行し、対象、Git範囲、出力先、認証前提を確認する。

## スキャン範囲を選ぶ

最小の有効範囲を選ぶ。

| 目的 | 主な指定 |
|---|---|
| 現在の未コミット変更 | `--working-tree` |
| ブランチまたはコミット差分 | `--diff <base> --head <head>` |
| 特定機能だけ | `--path <path>` を必要数指定 |
| 初回ベースライン、全体監査 | リポジトリ全体 |

- 通常は `--mode standard` を使う。`--mode deep` は時間・費用が増えるため、明示依頼または合意がある場合だけ使う。
- モデルは原則として同梱版の既定値を使う。理由なく固定しない。
- API課金で上限が必要な場合は `--max-cost` を使う。金額は推測せずユーザーに確認する。
- 成果物はプロジェクト内の `materials/codex-security/<日時>/` を `--output-dir` に指定する。秘密情報を含み得るため、明示依頼なしにstage、commit、外部共有しない。

例:

```powershell
$out = "materials/codex-security/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
npx --no-install @openai/codex-security scan . `
  --working-tree `
  --mode standard `
  --output-dir $out `
  --dry-run
```

ユーザーがライブスキャンを依頼済みで、dry-run結果に問題がなければ、同じコマンドから `--dry-run` だけを外して実行する。

## 所見を扱う

1. `scans list` と `scans show` で保存結果と設定を確認する。
2. 各所見について、場所、攻撃者が制御できる入力、信頼境界、到達する影響、前提条件、再現・検証状態を分けて読む。
3. 未検証候補を事実として断定しない。重要な候補は `validate` で再現可能性を確認する。
4. 重大度だけでなく、到達可能性と実運用上の影響で優先順位を付ける。
5. 報告では、確認済み事実、推論、未検証事項を明確に分ける。

## 修正する

ユーザーが修正を依頼した場合だけ次へ進む。

1. 修正対象の所見を特定し、可能なら先に `validate` する。
2. `patch` 実行前の `git status --short` を保存する。
3. `patch` 実行後に差分を読み、既存変更との混在や対象外編集がないか確認する。
4. 関連テスト、型チェック、lint、再現手順を実行する。
5. 修正後に再検証し、所見が解消したことと回帰がないことを分けて報告する。
6. パッチを自動的に正しいものとして採用せず、通常のコードレビューを通す。

## 出力する

完了済みスキャンは必要に応じて出力する。

```powershell
npx --no-install @openai/codex-security export <scanDir> `
  --export-format sarif `
  --output <outputFile> `
  --source-root .
```

- GitHub Code Scanning等へ渡す場合はSARIF、人が加工する場合はCSV、機械処理する場合はJSONを選ぶ。
- 外部サービスへのアップロードやPR作成は、ユーザーが明示的に依頼した場合だけ行う。
