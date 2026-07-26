---
description: 仕様書駆動開発（常時適用 / paths制約なし）
---

# 仕様書駆動開発（要点）

| 項目 | 規約 |
|------|------|
| 配置先 | `.sd/specs/{feature}/` のみ。違反書き込みは hook `enforce-spec-location.sh` が物理 deny |
| メイン仕様 | `spec.md`（**`design.md` 禁止** — Google Antigravity が UI 設計用に予約済み） |
| 構成 | spec.json / requirements.md / spec.md / tasks.md / implementation-notes.md（逸脱発生時のみ）/ history/ |
| tasks.md | 変わりやすい判断（データモデル・型・ユーザー可視部分）を先頭に並べる |
| バージョン | 最新は単一ファイル。履歴は `/spec:archive {feature}` で history/ へ |

- 仕様書なしの実装・仕様書の無断変更は禁止。変更時は影響分析必須
- implementation-notes.md は Unknown-Undetected の事後回収先を兼ねる
- 検証: `/sd:spec-status` `/sd:validate-gap` `/sd:validate-spec`

詳細・経緯（at001-v1事故 2026-05-07）: `docs/rules-reference/specs/spec-driven-full.md`
