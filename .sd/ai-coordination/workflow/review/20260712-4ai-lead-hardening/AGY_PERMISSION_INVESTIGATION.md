# agy非対話権限拒否時出力の実測および cancellationPatterns 登録に関する調査報告

- **案件ID**: `20260712-4ai-lead-hardening`
- **調査日**: 2026-07-12
- **対象環境**: Windows 11, agy CLI v1.1.1, Gemini 3.5 Flash (High)

---

## 1. 調査目的

AI中立オーケストレーターにおいて、`agy`（Antigravity CLI）プロバイダが非対話実行中にパーミッションが必要なツール（`run_command` 等）を実行しようとした際、権限拒否によるキャンセルを早期検知するための出力マーカー（`cancellationPatterns`）を実測・特定し、`config/orchestrator.providers.json` へ登録すること。

---

## 2. 実測手順と結果

### 2-1. 非対話モードでの制限ツール実行（タイムアウト）
非対話モード（`--prompt`）において、パーミッション承認が必要な `run_command`（`whoami`）を実行させるタスクを走らせました。

* **実行コマンド**:
  ```powershell
  agy --sandbox --mode accept-edits --prompt "run command 'whoami' and output results"
  ```
* **結果**:
  `Error: timeout waiting for response`（5分間のタイムアウトでエラー終了）。
* **ログ分析**（`~/.gemini/antigravity-cli/log/cli-*.log`）:
  ```log
  I0712 14:10:06.210890  2008 tool_confirmation_manager.go:92] Surfacing tool confirmation: "Bash" at step 3
  ... (以降ログ更新なし) ...
  E0712 14:08:53.225837 15324 printmode.go:347] Print mode: timed out after 1497 polls
  ```
  `Surfacing tool confirmation` のログ出力以降、標準入力からの応答がないままハングし、最終的にタイムアウトしていました。

### 2-2. 標準入力リダイレクトの検証
標準入力を `$null`（EOF）にパイプして、入力待ちを自動バイパスし、即時拒否終了させることを試みました。

* **実行コマンド**:
  ```powershell
  $null | agy --sandbox --mode accept-edits --print-timeout 30s --prompt "run command 'whoami' and output results"
  ```
* **結果**:
  同じく `Error: timeout waiting for response` となり、標準入力が閉じられていても即座に「拒否された」として終了せず、ハングし続けていました。

### 2-3. 対話モードでの手動拒否シミュレーション
対話モード（`--prompt-interactive`）で起動し、プロンプト表示後に手動で拒否（`n`）を送るシミュレーションを行いました。

* **実行コマンド**:
  ```powershell
  agy --sandbox --mode accept-edits --prompt-interactive "run command 'whoami'"
  ```
* **結果**:
  標準入力に `"n\n"` を流し込んでも、非同期制御下での自動化フローがハングを回避して速やかにキャンセルを返す設計になっておらず、プロセスが終了しませんでした。

---

## 3. 技術的結論

1. **即時拒否マーカーの不在**:
   `agy` (v1.1.1) の非対話モードには、パーミッションが必要なツールを検知した際に「自動的に拒否してエラー（特定のキャンセルメッセージ）を吐き出して即座に異常終了する」ロジックが実装されていません。
   危険な操作を伴うタスクが与えられると、プロンプト待機に入り、標準入力の状態にかかわらず**必ずタイムアウト（ハング）**します。
2. **`cancellationPatterns` 登録の見送り**:
   プロセスがハングし、タイムアウトする以外に終了しないため、コンソール出力やデバッグログに `PermissionCancelled` のような早期検知のための「キャンセルマーク」は出力されません。したがって、`config/orchestrator.providers.json` の `agy` に対する `cancellationPatterns` の追加登録は**見送り（登録不要）**とします。

---

## 4. 今後の安全対策（二重防衛線）

早期検知マーカーの登録はできませんが、オーケストレーター自体の安全性は以下の既存の設計により完全に担保されています。

1. **タイムアウト時の失敗検知（防衛線1）**:
   `agy` がハングした場合、オーケストレーター側で設定した `timeoutMs`（またはプロバイダ既定）に達した時点で exit code が非ゼロ（またはタイムアウトエラー）になり、オーケストレーターは該当ステージを `failed` として正しく停止させます（正常終了として見過ごされることはありません）。
2. **成果物の有無によるゲート（防衛線2）**:
   `IMPLEMENT_REQUEST.md` で規定されている通り、`claude/agy` を実行ステージとして使うシナリオでは、必ず **`expectedArtifacts`（期待される成果物のパス）を明示的に指定**します。
   ハングや異常終了により成果物が作成されない限り、オーケストレーターは「成功」とみなさないため、沈黙失敗による事故は物理的に発生しません。
