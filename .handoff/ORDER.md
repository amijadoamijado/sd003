# ORDER.md - SD003 Handoff Pack Standardization Plan

この指示書は、SD003でモデル非依存の引き継ぎ運用を確立するための実行計画です。

---

## タスク概要

**何をするか**
`.handoff/` 配下に共通ルールとテンプレートを整備し、`CLAUDE.md` から参照可能な状態に統一する。

**優先順位**
- [x] High

**担当モデル**
- [x] Codex
- [ ] Claude Code
- [ ] Gemini CLI
- [ ] Antigravity

---

## 作業範囲

**対象ファイル/ディレクトリ**
```
.handoff/
CLAUDE.md
```

**新規作成するもの**
- [x] `.handoff/RULES.md`
- [x] `.handoff/ORDER.template.md`
- [x] `.handoff/DONE.template.md`
- [x] `.handoff/AGENTS.md`
- [x] `.handoff/ORDER.md`（このファイル）

**既存の変更禁止リスト**
- [x] `src/` は変更しない
- [x] `.sd/specs/` は変更しない
- [x] 既存の業務ロジックは変更しない

---

## 実施ステップ

1. 現在のテンプレート整備状況を確認する
2. `CLAUDE.md` に `.handoff/RULES.md` 参照と DONE 出力ルールを反映する
3. `.handoff/AGENTS.md` の4段階レビュー観点を確認する
4. 運用検証を実施する（存在確認・参照確認・差分確認）
5. 必要なら文言を微修正し、最終状態を確定する

---

## 完了条件

**必須条件**
- [x] `.handoff/` 配下に4ファイル（RULES/ORDER.template/DONE.template/AGENTS）が存在する
- [x] `CLAUDE.md` が `.handoff/RULES.md` を参照している
- [x] `CLAUDE.md` に「作業終了時は DONE.md を出力」の指示がある
- [x] 変更点が `git status` / `git diff` で追跡可能

**受け入れテスト**
```bash
# 存在確認
ls .handoff

# 参照確認
rg "\.handoff/RULES\.md" CLAUDE.md
rg "DONE\.md" CLAUDE.md

# 差分確認
git status --short
git diff -- CLAUDE.md
```

---

## 参照情報

**関連仕様書**
- `.handoff/RULES.md`
- `.handoff/ORDER.template.md`
- `.handoff/DONE.template.md`
- `.handoff/AGENTS.md`

**関連ファイル**
- `CLAUDE.md`
- `AGENTS.md`

---

## やってはいけないこと

- [x] プロジェクトルート直下に新規ファイルを作成しない
- [x] `.sd/specs/` の仕様書を無断変更しない
- [x] 実装コード変更をこのタスクに混在させない
- [x] DONE報告なしで作業を終えない

---

## 追加コンテキスト

- 本タスクは「モデル依存の個別指示」ではなく「共通運用基盤」の整備を目的とする。
- 運用開始後は、各モデルの指示ファイルで `.handoff/RULES.md` を一次参照に統一する。
- `AGENTS.md` と `.handoff/AGENTS.md` の役割差分は後続タスクで整理対象とする。

---
