# AGENTS.md — SD003 Shared Entry Point

> このファイルは Codex と Grok の両方に常時注入される共有入口。あなたの正本は以下:
>
> | Session Lead | 正本 |
> |---|---|
> | Codex | `.codex/CODEX_NATIVE.md` |
> | Grok | `.grok/GROK_NATIVE.md` |
> | agy (Antigravity) | `antigravity.md` |
> | Claude Code | `CLAUDE.md` |
>
> **agy必須上書き**（2026-07-26実測: agyが自動で読むのは本ファイルのみ、かつsystem promptは
> `brain/<会話ID>/` への保存を強制する）: SD003では成果物を**必ずプロジェクト内**へ保存する —
> ユーザー向け=`materials/`、AI協調文書=`.sd/ai-coordination/`。brain/ にしか無い状態で完了報告
> しない。詳細: `antigravity.md`。注入マップ: `docs/context-injection-map.md`

## 目的

Codexで常時適用する最小ルールと、詳細仕様への入口を定義する。Claude Code固有の操作を複製せず、Codexの通常操作へ変換する。

| 対象 | 必要時に読む正本 |
|---|---|
| Codexの実行モード・引継ぎ・Lead | `.codex/CODEX_NATIVE.md` |
| Skill生成・同期・配置 | `.codex/CODEX_SPEC.md` |
| 正式コードレビュー | `.handoff/AGENTS.md` |
| 成果物配置・共通安全 | `.handoff/RULES.md` |
| 正式AI協調 | `.claude/rules/workflow/ai-coordination.md` |
| GAS固有制約 | `.claude/rules/gas/` |

## 常時適用

- ユーザー向け回答、質問、レビュー、報告は日本語で書く。
- 相談・診断だけの依頼では、明示されていない編集や外部変更を行わない。実装依頼では対象範囲を限定して完了まで進める。
- 編集前に`git status --short`を確認する。既存の未コミット変更はユーザーまたは他AIの作業として保護し、明示指示なしに戻さない。
- 破壊的Git操作、広域stage、ユーザーファイルの削除・上書きを行わない。
- `.sd/`を破壊しない。変更時は`.claude/rules/git/sd-safe-commit.md`を読み、早めに明示パスでcommitする。
- WindowsではPowerShellで実行できる手順を優先する。
- Claude Code用スラッシュコマンド、`Agent(...)`、`AskUserQuestion`を文字通り再帰実行せず、意図をCodexの読取・編集・検証へ変換する。
- hookが完全に保護すると仮定しない。結論は検証根拠と未検証事項を分ける。

## タスク振り分け

- 案件IDや正式依頼書のないレビュー・チェックはFast Reviewとする。差分と関連コードを確認し、重大度順に会話内で報告する。`.sd/ai-coordination/`へ報告書を作らない。
- 案件IDと正式なレビュー対象が明示された場合だけWorkflow Reviewとし、依頼文書を読んで`.sd/ai-coordination/workflow/review/{案件ID}/`へ保存する。
- 実装を依頼された場合は、対象範囲を限定して編集し、関連する検証を行う。
- Codexが直接起動されたセッションのLead手順、引継ぎ、lock取得は`.codex/CODEX_NATIVE.md`に従う。
- Codexでは`.codex/CODEX_NATIVE.md`を実行手順の正本とする。共通文書や生成Skillに残る他CLI向けの固定担当・確認回数・画面必須・クイズ必須の手順より優先する。データ保護、保存先、公開・デプロイの承認条件は維持する。

## 作業方針

- 複雑な作業は着手前に短い計画を示し、進行に合わせて更新する。Plan mode自体は必須としない。
- Codexは、独立した調査・実装・検証の並列化が有益なら、利用可能なサブエージェントを使ってよい。編集を並列化するときは担当ファイルを分け、必要ならworktreeで隔離する。既存ブランチの切替、公開、マージは別途その操作の許可範囲に従う。他CLIの並列運用は各Native仕様に従う。
- 依頼範囲内の通常の実装判断・修正・検証は完了まで進める。質問は、結果を左右する未確定事項や、未承認の外部変更に必要な場合に限る。確認のためだけの確認を挟まない。
- 現在の依頼範囲を超える恒久設定変更が必要なら、根拠と影響を示して確認する。明示承認済みの変更を重ねて確認しない。
- 変更理由を説明できる範囲だけ編集し、関連するテスト・型チェック・lint・実動作確認を選んで実行する。
- 検証失敗や未実行を理由にレビューを拒否せず、確認できた事実と未確認事項を報告する。

## GAS・テスト制約

- GASランタイムコードではEnv Interface Patternを使い、`fs`、`path`、`process`などNode.js専用APIを使わない。同期スクリプトやローカル開発ツールまで禁止しない。
- 既存テストは必要に応じて実行する。新規テストは本番バグの再現・固定または実データ検証に必要な最小範囲とし、カバレッジ目標やモック中心のテストを増やさない。
- GAS反映は`clasp push`だけを通常許可する。固定deploymentを作成・削除・更新する操作は、ユーザーの明示指示なしに行わない。

## 生成物

- `.claude/commands/**/*.md`をコマンドのauthoring sourceとする。
- 生成Skillを直接編集せず、正本または同期アダプタを変更して`python scripts/sync-cli-commands.py`で再生成する。
- Codex・agy共通のrepo Skill正規位置は`.agents/skills/*/SKILL.md`。配置詳細は`.codex/CODEX_SPEC.md`に一本化し、このファイルに静的Skill一覧を持たない。
- 正式なAI協調文書だけを案件ID配下へ保存し、プロジェクトルートへ依頼書・報告書を作らない。

## 完了報告

完了時は、結果、変更ファイルと目的、検証結果、未解決事項を簡潔に報告する。読み取りのみの場合は「変更なし」と明記する。
