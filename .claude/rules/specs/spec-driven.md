---
description: 仕様書駆動開発（常時適用 / paths制約なし）
---

# 仕様書駆動開発

> **このルールは常時読み込まれる**（paths制約なし）。
> 仕様書配置の鶏卵問題（at001-v1事故 2026-05-07）の再発防止のため、
> 「.sd/specs/配下にあるときだけ発火」させない設計に変更済み。

## 配置の絶対ルール

| 項目 | 規約 | 補足 |
|------|------|------|
| 配置先 | `.sd/specs/{feature}/` | 他のディレクトリ（`docs/specs/` 等）禁止 |
| 物理ガードレール | `.claude/hooks/enforce-spec-location.sh`（PreToolUse） | 違反箇所への書き込みを deny |
| 命名（メイン仕様） | `spec.md` | **`design.md` は使わない**（Google Antigravity がUI設計用に予約） |

## 開発フロー
Requirements → Spec → Tasks → Implementation

## 仕様書構造
```
.sd/specs/{feature}/
├── spec.json          # メタデータ
├── requirements.md    # 要件定義
├── spec.md            # 技術仕様（旧 design.md）
├── tasks.md           # 実装タスク
└── history/           # 履歴アーカイブ
```

### design.md 廃止理由
Google Antigravity は `design.md` を UI 設計ファイル名として予約済み。
SD003 内部仕様書と衝突するため、SD003 側は `spec.md` に統一する。
既存の `design.md` は順次 `spec.md` にリネーム（git mv で履歴保持）。

## バージョン管理
詳細: `spec-versioning.md`

- 最新版は常に単一ファイル（requirements.md / spec.md 等）
- 履歴はhistory/フォルダに保存
- `/spec:archive {feature}` で履歴保存
- `/spec:history {feature}` で履歴確認

## ルール
- 仕様書なしの実装禁止
- 仕様書の無断変更禁止
- 変更時は影響分析必須
- **`docs/specs/` への配置禁止**（at001-v1事故の再発防止）

## 検証コマンド
```bash
/sd:spec-status {feature}
/sd:validate-gap {feature}
/sd:validate-spec {feature}
```

## トレーサビリティ
- 全要件にID付与
- 要件→仕様→実装の追跡可能

## 関連事故
- `docs/troubleshooting/RESOLUTION_LOG.md`「2026-05-07 SD003仕様書配置ルール違反（at001-v1事故）」
