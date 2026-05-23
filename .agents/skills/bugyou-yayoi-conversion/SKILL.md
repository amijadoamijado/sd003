---
name: bugyou-yayoi-conversion
description: 勘定奉行 → 弥生会計 仕訳CSV変換に関する基本ガードレール。業務ルール本体はプロジェクト固有のSKILL.mdに委譲。
applies_to:
  extensions: ["*.csv"]
  keywords: ["奉行", "弥生", "仕訳", "サクセス", "山一", "siwakebugyou", "yayoi"]
  paths: ["サクセス/", "山一/"]
severity: block
disable-model-invocation: true
---

# bugyou-yayoi-conversion

このスキルは sd003 フレームワーク側のガードレール登録用スタブ。
**業務ルール本体（複合仕訳の構造、列マッピング、摘要充実、〃同上扱い等）は各案件プロジェクト側の SKILL.md / 仕様書で管理する。**

## このスタブの役割

- 中央レジストリ `.claude/skills/registry.json` から参照される登録エントリ
- 該当ファイル（`*.csv` で奉行/弥生/サクセス/山一 を含む等）に対して PreToolUse hook を発火
- AI が「該当案件の業務 SKILL.md を未読のまま CSV を Write/Edit/操作する」のを物理ブロック

## 読んだら次にやること

1. **どのプロジェクトの変換タスクか特定する**
   - サクセス XX期 → at001 など案件プロジェクトを特定
   - 該当プロジェクトの `.claude/skills/` または仕様書に変換ルールがあるか確認
2. **業務ルールが定義されている SKILL.md を Read する**
   - 列マッピング、エンコーディング、複合仕訳ルール、摘要処理、特殊文字（〃 等）の扱い
3. **業務ルールが見つからなかったら、ユーザーに確認する**
   - 「どのプロジェクトの SKILL.md / 仕様書を参照すべきか」を聞く
   - **推論で進めるな**。前回自分で書いたテストCSVを「正解」として参照しないこと

## 物理ガードレール

`enforce-skill-read.sh` がこのスキルの ID をログ確認している。このファイルが Read されると `~/.claude/state/sd003/read-skills.log` に `bugyou-yayoi-conversion` が追加され、以降のブロックが解除される。

ただし**このスタブを読んだだけで業務ルールを把握したことにはならない**。ユーザーに業務側 SKILL.md の所在を確認するのが正しい流れ。

## 関連事故

- cf001: SKILL.md 未読で xlsx ライブラリ使用 → Excel書式破壊
- サクセス変換: SKILL.md 未読で複合仕訳バグ（自分が作ったテストCSVを「正解」と誤認）

両方とも「ルール宣言だけで物理強制なし」が根本原因。本ガードレールはその再発防止。
