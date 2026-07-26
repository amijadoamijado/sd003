# 成果物の保存場所（AppData隠しディレクトリ禁止）

## 原則

> AIが生成する成果物（レポート・文書・分析・データ）は、**ユーザーがディスク上から
> 直接開けるプロジェクト内の場所**に保存する。AppData等の隠しディレクトリに成果物の
> 唯一のコピーを置いてはならない。

## 背景（2026-07-05 agy成果物迷子事故）

agy（Antigravity CLI）は、会話ごとに `~/.gemini/antigravity-cli/brain/<会話ID>/`
という**AppData下の隠しディレクトリ（かつ会話専用のgitリポジトリ）**を作業場所として
持つ。agyのシステムには「生成物はこの brain/<会話ID>/ に保存する」という前提が
注入されている。

- **リッチなWeb UIを持つ環境**では、この隠しフォルダのファイルが画面上に
  ドキュメントビューアとして自動レンダリングされ、ユーザーはクリックで読める。
- **ターミナル（CLI）で Claude Code / agy を使う場合**、その表示画面が無いため、
  ただ「`C:\Users\...\.gemini\antigravity-cli\brain\<会話ID>\report.md` に保存した」
  という事実だけがログに残る。`~/.gemini/` は隠しフォルダで、人間からは
  「そんな場所は探せない」状態になる。

実例（この事故で迷子になった成果物）:
- `.../brain/1ed9a9aa.../agy_integration_analysis.md`（agy連携メタ分析）
- `.../brain/603a159f.../critique_report.md`（戦略提案批判レポート）

## 適用（全AI共通・agyは特に厳守）

### 保存先（`.claude/rules/cleanup/file-organization.md` / `.handoff/RULES.md` に準拠）

| 成果物の種別 | 保存先（プロジェクト内） |
|-------------|------------------------|
| ユーザー向けレポート・文書（.md/.html/.txt） | `materials/text/` または `materials/html/` |
| 表・データ（.csv/.xlsx） | `materials/csv/` / `materials/excel/` |
| 画像・PDF | `materials/images/` / `materials/pdf/` |
| AI協調の依頼書・報告書 | `.sd/ai-coordination/workflow/...` |
| フレームワーク・プロセス文書 | `docs/` |
| 仕様書 | `.sd/specs/{feature}/` |

**迷ったら `materials/`（ユーザーが見る成果物の既定置き場）に置く。**

### 禁止

| 禁止 | 理由 |
|------|------|
| `~/.gemini/antigravity-cli/brain/<会話ID>/` に成果物の**唯一のコピー**を残す | CLIユーザーが見つけられない |
| AppData / `%APPDATA%` / `~/.gemini/` 等の隠しディレクトリを成果物の最終保存先にする | 同上 |
| 「保存した」と報告するが、実体がプロジェクト外にしかない | 柱1 Output Primacy 違反（ユーザーに届いていない） |

### agy固有の指示（システム注入の既定を上書きする）

> agyのシステムには「brain/<会話ID>/ に保存」という既定が注入されているが、
> **SD003プロジェクトでは、この既定を上書きして、最終成果物を必ずプロジェクト内
> （`materials/` 等）にも書き出すこと。** brain/ 内にしか無い状態で完了報告をしない。
> 完了報告には、成果物のプロジェクト内フルパス（例:
> `D:\claudecode\{proj}\materials\text\report.md`）を明記する
> （`.claude/rules/global/fullpath-display.md`）。

## 強制（正直な限界と物理的バックストップ）

**agyはClaude CodeのPreToolUseフック系の外で動くため、Claude側のフックでagyの
書き込みを物理ブロックすることはできない。** よってagyに対しては本ルール（規範）＋
以下の**回収バックストップ**で担保する:

- **回収スクリプト**: `scripts/recover-agy-artifacts.sh`
  brain/ 内の最近の成果物ファイル（.git / .system_generated / transcript を除く）を
  プロジェクトの `materials/_agy-recovered/<日付>/` へ**コピー**（非破壊）で回収する。
  ```bash
  bash scripts/recover-agy-artifacts.sh            # 直近48時間ぶんを回収
  bash scripts/recover-agy-artifacts.sh --hours 6  # 直近6時間
  bash scripts/recover-agy-artifacts.sh --dry-run  # プレビューのみ
  ```
- **Claude側の振る舞い**: agyの出力を扱う際、成果物が brain/<会話ID>/ にしか
  存在しないと気づいたら、上記スクリプト（または `cp`）でプロジェクト内へ移送し、
  ユーザーにフルパスを提示する。

## 全AIモデル共通

このルールは Claude Code / Codex / Antigravity(agy) / Grok 全てに適用される。

## 関連

- `.claude/rules/cleanup/file-organization.md`（materials/ 構造）
- `.claude/rules/global/output-primacy.md`（柱1: 成果物がユーザーに届いて完了）
- `.claude/rules/global/fullpath-display.md`（保存先はフルパスで案内）
- `.handoff/RULES.md`（全AI共通ファイル配置ルール）
- `antigravity.md`（agy設定）
