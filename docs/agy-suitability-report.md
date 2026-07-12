# SD003 Framework - Antigravity CLI (agy) 適合性検証・改善提案報告書

## 1. エグゼクティブサマリー

SD003フレームワークは本来 Claude Code を司令塔として設計されたものですが、自動同期スクリプトやカスタムスキル定義（`SKILL.md`）によって **Antigravity CLI (agy) に対しても高いレベルで統合・適合されています。**

しかし、agy固有の挙動（成果物の隠しディレクトリ出力）や、動作時のハング（ロック競合・認証切れ）、OS（Windows/PowerShell）との親和性の面で、**SD003のコア原則である「Work First (動くもの優先)」および「Output Primacy (成果物第一主義)」と衝突するいくつかの摩擦点（痛み）**が存在します。

本報告書では、agyにおけるSD003の現状を検証し、自動化・堅牢性をさらに高めるための具体的な改善案を提案します。

---

## 2. 適合性評価 (Suitability Analysis)

### 2.1. 適合している点 (メリット)
1. **スキル・コマンドのシームレスな同期**:
   - `scripts/sync-cli-commands.py` により、`.claude/commands/` の markdown 仕様から agy が解釈可能な形式（`.agents/skills/{slug}/SKILL.md` + フロントマター `disable-model-invocation: true`）へ自動変換する機構が確立されています。
2. **実行ルールの自動翻訳**:
   - 同期時に "Antigravity Runtime Rules" が自動注入され、Claude Code 固有の `Agent(...)` や `/workflow:*` などの構文を agy 向けに「翻訳して解釈する」指示が与えられているため、定義の二重管理を防止できています。
3. **非対話実装への適応**:
   - `scripts/agent-implement.sh` で `agy --prompt` および `--dangerously-skip-permissions` を用いて、非インタラクティブに実装依頼を流し込むパイプライン設計が美しく動作します。

### 2.2. 摩擦が生じている点 (課題・ボトルネック)
1. **成果物の「迷子」問題 (Output Primacy とのミスマッチ)**:
   - agyは成果物（レポート、データ等）をデフォルトで `~/.gemini/antigravity-cli/brain/<conversationID>/` というユーザーから見えない隠しディレクトリ（かつ会話ごとの使い捨て領域）に書き出します。
   - これは「完了＝ユーザーが見える場所に成果物があること」とする **Output Primacy（柱1）** に反します。
   - 現状は `scripts/recover-agy-artifacts.sh` による後追いの手動回収で対処していますが、パイプラインの自動実行フローにこれが統合されていません。
2. **非対話実行におけるハング（フリーズ）リスク**:
   - agy は同一 `~/.gemini` ディレクトリを共有する他のインスタンスと二重起動された際の「排他ロック競合」、または「OAuthトークン期限切れ」時に、対話入力を待ってバックグラウンドで無期限にフリーズします。
   - パイプライン実行（`agent-pipeline.sh`）でこれが起きると、呼び出し元の Claude Code 自体がハングする原因になります。
3. **Windows (PowerShell) 環境との親和性不足**:
   - SD003 の自動化スクリプトや回収スクリプト（`recover-agy-artifacts.sh`）の多くが Bash (`.sh`) 前提です。
   - 本開発環境は Windows 11 であり、ユーザーがネイティブな PowerShell 環境から成果物を回収したり、検証を行ったりする際のツールチェインが不足しています（`clasp-guard.ps1` や `validate-test-data.ps1` はありますが、回収スクリプトの PowerShell 版がありません）。

---

## 3. 改善提案 (Proposals)

### 提案1: 成果物自動回収処理のパイプラインへの統合
**【内容】**  
`agent-implement.sh` および `agent-pipeline.sh` の実装・テスト完了時に、自動的に成果物回収スクリプトを実行する処理を追加します。  
**【期待効果】**  
実装が完了した時点で、agy が brain フォルダに書き残した成果物が自動的にプロジェクトの `materials/_agy-recovered/` に即座にコピーされ、ユーザーが手動で回収スクリプトを走らせる手間を省きます。

### 提案2: PowerShell版 回収スクリプト (`recover-agy-artifacts.ps1`) の新規実装
**【内容】**  
Windows ネイティブの PowerShell から直接 agy の脳フォルダから成果物を救出できるスクリプトを作成します。  
**【期待効果】**  
Git Bash や WSL を介さずに、Windows コマンドラインからネイティブかつ高速に成果物の回収が可能になります。

### 提案3: タイムアウト処理とロック競合ガードの導入
**【内容】**  
`scripts/agent-implement.sh` 内で `agy` を呼び出す際、タイムアウト設定を設けるか、事前に `~/.gemini/antigravity-cli/` 配下のロックファイル（存在する場合）をチェックして警告を出す仕組みを追加します。  
**【期待効果】**  
OAuth 認証切れや多重起動によるハングを早期に検知し、ハングによる開発プロセスのスタックを防ぎます。

### 提案4: プロンプト側でのプロジェクト内直接保存の強化
**【内容】**  
`agent-implement.sh` の `PROMPT` をチューニングし、agy に対し「成果物は `materials/` ディレクトリに直接書き出すこと」をより強い制約として指示します。  
**【期待効果】**  
そもそも `brain/` に成果物を書き残さず、最初からプロジェクトツリー内に正しく生成する成功率を向上させます。

---

## 4. 改善案のプロトタイプ実装プラン

本検証を基に、以下の改善用コンポーネントを実装することを推奨します。

1. **`scripts/recover-agy-artifacts.ps1`**: PowerShell 版成果物回収スクリプト
2. **`scripts/agent-implement.sh` の改修**: `recover-agy-artifacts.sh` の自動呼び出し追加およびタイムアウト考慮

---
SD003 Framework Suitability Report | Created: 2026-07-12
