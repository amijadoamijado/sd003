# AI中立オーケストレーター 要件定義書

作成日: 2026-07-12

## 1. 背景

SD003はClaude Codeを司令塔として成長したが、Codex、Antigravity、Grokも計画・実装・レビュー・検証を担当できる。製品名に固定した役割、Claude固有hook、Bash専用パイプラインを残したままでは、別AIを司令塔にした際に安全性と完了判定が変わる。

## 2. 現状と前提

### 2.1 現状

- Codex向けAGENTS、Skill、Native実行仕様は存在する。
- 中核パイプラインはClaude司令塔・Bash実行・旧Workflow文書を前提としている。
- build、lint、既存テスト65件は成功している。

### 2.2 技術環境と制約

- Windows 11 / PowerShellを第一級環境とする。
- 既存のClaude、Codex、agy、Grok固有設定を一度に削除しない。
- 既存の未コミット変更を自動stage・commitしない。
- 外部AIの認証や応答品質に依存せず、ハーネス自体を決定論的に検証できること。

### 2.3 スコープ

やること:
- AI中立の契約、役割、状態、終了条件を定義する。
- OS非依存のTypeScriptランナーとガードを実装する。
- run manifestと成果物manifestを生成する。
- Codexを司令塔にした隔離E2Eを実行する。

やらないこと:
- 各AIサービスの認証情報を保存する。
- 外部AIの応答内容そのものを品質保証する。
- 既存CLI固有アダプターを即時削除する。

### 2.4 AIへの注意事項

- 「Codex対応」と「Codexが同等安全な司令塔」は同義ではない。
- AI名で処理順を固定せず、orchestrator / implementer / reviewer / testerの能力で割り当てる。
- provider失敗を成功へ縮退させない。

## 3. ゴール

Claude、Codex、agy、Grokの誰が起動しても、同じ状態モデル、同じ安全装置、同じ完了条件でタスクを進められる。

## 4. アウトプット定義

### 4.1 成果物

- AI中立オーケストレーター契約
- provider/role設定スキーマ
- TypeScript共通ランナーとCLI
- dirty tree、成果物、終了コードの共通ガード
- Codex司令塔E2Eシナリオと証跡

### 4.2 完成条件

- role割当を設定だけで交換できる。
- 各段階の失敗が非0終了とfailed状態になる。
- 実行ごとにrun ID、状態履歴、成果物、検証結果が保存される。
- 隔離された実案件E2EがCodex司令塔で成功する。
- build、lint、全テスト、同期チェックが成功する。

### 4.3 利用者と利用場面

SD003を利用する人と、Claude Code、Codex、agy、Grokの各実行エージェントが、計画・実装・レビュー・テストを引き継ぐ際に使用する。

## 5. 要件

### 5.1 機能要件

1. JSONシナリオからtask、workspace、role、provider、期待成果物を読み込める。
2. orchestratorを含む役割をproviderへ割り当てられる。
3. providerをshell文字列ではなく実行ファイルと引数配列で起動する。
4. 各段階をpending/running/succeeded/failed/skippedで記録する。
5. 期待成果物の存在を検証し、不足時は失敗する。
6. run manifestを常に出力する。
7. dry-runと実行を同じ契約で扱う。

### 5.2 非機能要件

- Windows、macOS、LinuxでNode.jsから同じ動作をする。
- 既存差分をstage、commit、削除しない。
- コマンドインジェクションを避けるためshellを介さない。
- テストは隔離ディレクトリで再現可能にする。

## 6. 検証観点

- [ ] Codexをorchestratorに設定したE2Eが完了する。
- [ ] provider異常終了がrun全体の失敗になる。
- [ ] 期待成果物不足が検出される。
- [ ] role/provider交換がコード変更なしで可能である。
- [ ] 実行証跡にrun ID、状態履歴、成果物が残る。
- [ ] build、lint、test、sync checkが成功する。

## 7. Known Unknowns（要確認・YELLOW）

- [x] 外部AI認証・料金・応答揺らぎをE2E必須条件にするか → ハーネスE2Eから分離し、決定論的providerで契約を検証する。
- [ ] 各外部CLIの最新版引数差異 → provider設定として局所化し、実運用接続時に個別検証する。
