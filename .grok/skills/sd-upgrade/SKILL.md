---
name: sd-upgrade
description: |
  既存プロジェクトの古いSD003を最新フレームワークへ安全に置き換える（廃止物の削除＋最新配備）。
  プロジェクトのコード・データ（src/, .sd/specs/, .sessions/履歴, materials/ 等）は壊さない。
  Use when: ユーザーが「SD003アップグレード」「フレームワーク置き換え」「古いsd003を最新に」
  「廃止物を削除して最新化」「sd-upgrade」と言及した場合。
---

# SD003 安全アップグレードスキル v1.0.0

## 目的

`/sd-deploy` は「最新フレームワークの上書き配備＋データ保護＋バックアップ」を行うが、
**古いinstallに残る廃止物（旧CLI設定など）を削除しない**。本スキルはその穴を埋め、
**プロジェクト資産を壊さずに**古いSD003を最新へ「置き換える」。

`/sd-deploy`（新規配備）と `/sd-upgrade`（既存の置き換え＝廃止物削除＋再配備）は役割が異なる。

## 使い方

```
/sd-upgrade <target-project-path>          # まず dry-run（何が削除/配備/保護されるか提示。無変更）
/sd-upgrade <target-project-path> --execute # 確認後に実行
```

スクリプト直接実行:
```powershell
# Windows（推奨）。-Execute なしは dry-run
powershell -ExecutionPolicy Bypass -File .claude/skills/sd-upgrade/upgrade.ps1 <target> [-Execute] [-IncludeOptional]
```
```bash
# Linux/Mac。--execute なしは dry-run
bash .claude/skills/sd-upgrade/upgrade.sh <target> [--execute] [--include-optional]
```

## フロー（5 Phase）

| Phase | 内容 |
|-------|------|
| 1 Detect | target の SD003 version と廃止物の有無を検出して報告 |
| 2 Dry-run（既定） | 「削除予定（廃止物）」＋ deploy 委譲で「**上書きで失われる固有化（divergence）**」「`.sd003-keep` で保護される物」を一覧提示。**無変更** |
| 3 Backup | `.sd003-upgrade-backup-YYYYMMDD_HHMMSS/` に削除対象を**移動退避**（archive-then-remove。hard rm しない） |
| 4 Deploy | `sd-deploy` の deploy スクリプトを呼び最新FWを配備（上書き＝FW、skip＝データ） |
| 5 Verify | `.agents/skills` 配備・廃止物消失を確認して報告 |

**実行は必ず `--execute`/`-Execute` 明示時のみ。** 既定は dry-run。

## 削除対象（廃止物・DELETE list）

| 種別 | 対象 | 廃止理由 |
|------|------|---------|
| dir | `.gemini` `.cursor` `.windsurf` `.qwen` `.agent`(旧単数) | 廃止CLI |
| dir | `.kiro` | `.sd` にrename済み（旧構造） |
| dir | `.codex/prompts` | Custom Prompts廃止（skillsへ） |
| dir | `.antigravity/commands` `.antigravity/skills` | agyはここを読まない（→`.agents/skills`） |
| file | `GEMINI.md` `gemini.md` | Gemini廃止（→`antigravity.md`/`AGENTS.md`） |
| file | `scripts/sync-gemini-features.js` `scripts/migrate-kiro-to-sd.ps1` | 廃止/一回限り |
| file | `.antigravity/rules.md` | agy非読・stale（→`antigravity.md`） |
| file | `<claude-mem-context>` を含む nested `CLAUDE.md` | claude-mem(非公式)の自動スタブ |

> **⚠️ `.agents/skills/` は削除しない。** 旧「廃止」扱いから復活し、現在は agy の正規スキルパス。

## 保護対象（PROTECT・絶対に削除/上書きしない）

`src/`、`tests/`（FW管理の `tests/gas-fakes/setup.ts` を除く）、`.sd/specs/`、`.sd/ai-coordination/`、
`.sessions/session-*.md` と `TIMELINE.md`、`materials/`、`.clasp.json`、`.git/`、`node_modules/`、
`dist/`、`.env*`、その他ユーザーファイル。

> **⚠️ フレームワークファイルは PROTECT ではない。** CLAUDE.md / antigravity.md / settings.json /
> `.claude/rules/` / `.claude/skills/`（registry.json含む）/ `.claude/hooks/` / `package.json` 等は
> deploy が**最新版で上書きする**。プロジェクトが**意図的に固有化**したこれらのファイルは、
> そのままでは upgrade で消える（過去 at002 でこれが起きた）。保護するには `.sd003-keep` に列挙する（下記）。

## .sd003-keep（固有化ファイルの保護・必須確認）

固有化したプロジェクトを upgrade する前に、守るべきフレームワークファイルを宣言する。

- 配置: `<target>/.sd003-keep`（1行1パス、`#`コメント可、`*`/`?`グロブ・ディレクトリ接頭辞対応）
- `.sd003-keep` が無ければ全ガードは no-op（従来挙動と同一）

```
# 例: 会計事務所スキル等を固有化したプロジェクト
CLAUDE.md
.claude/skills/registry.json
.claude/hooks/
.claude/rules/
package.json
```

### dry-run が正直になった（誤報の根絶）

dry-run は deploy に委譲し、**上書きで失われる固有化ファイルを必ず一覧表示する**:
- `WILL OVERWRITE - LOCAL CUSTOMIZATION WILL BE LOST`（内容差分あり＝消える）
- `KEPT via .sd003-keep`（保護される）

固有化プロジェクトの正しい手順:
```
1. /sd-upgrade <target>            # dry-run。"WILL OVERWRITE ... LOST" を確認
2. 失いたくないものを <target>/.sd003-keep に追記
3. /sd-upgrade <target> --execute  # 保護したものは残り、廃止物は削除、残りは最新化
```
execute 後は「OVERWROTE local divergence（バックアップ済み）」が報告される。
**もはや "UPGRADE OK / 全部無傷" とは誤報しない。**

## 安全装置

- **dry-run 既定**：`--execute` なしは一切変更しない
- **divergence 可視化（正直化）**：dry-run が「上書きで失われる固有化ファイル」を一覧。execute 後も上書きした divergence を報告。**"全部無傷" と誤報しない**
- **オプトアウト保護**：`.sd003-keep` 記載の FW ファイルは上書きしない（バックアップに頼らず最初から守る）
- **全バックアップ**：削除対象は消す前に `.sd003-upgrade-backup-*/` へ移動（元のパス構造を保持＝復元可能）。deploy 側の上書き分は `.sd003-backup-*/`
- **明示的DELETE list**：全走査での削除はしない。既知の廃止物のみ。`.agent`≠`.agents` を厳密に区別
- **冪等**：再実行しても廃止物が無ければ削除0件、deployは上書き
- **非git警告**：target が git 管理下でない場合は警告（ロールバック安全性のため `git init` 推奨）

## 復元（万一の場合）

`.sd003-upgrade-backup-YYYYMMDD_HHMMSS/` に削除物が元のパス構造で残る。必要なファイル/フォルダを
そこから元の位置へ戻すだけ。deploy による上書き分は `.sd003-backup-*/`（deploy側のバックアップ）にある。

## 注意

- 1プロジェクトずつ明示実行する（複数PJの一括処理はしない。dry-run→確認→execute を各PJで）
- 実行後は target で `npm install`、agy を再起動して `/skills` でコマンド表示を確認する
- claude-mem スタブは、claude-mem 本体（非公式・global導入）が有効な間はローカルで再生成され得る。
  恒久停止は target 側でも claude-mem のアンインストールが必要（環境横断のためユーザー判断）
