---
description: 仕様書駆動開発（.kiro/specs/配下適用）
paths:
  - ".kiro/specs/**/*"
  - ".kiro/steering/**/*"
---

# 仕様書駆動開発

## 開発フロー
Requirements → Design → Tasks → Implementation

## 仕様書構造
```
.kiro/specs/{feature}/
├── spec.json        # メタデータ
├── requirements.md  # 要件定義
├── design.md        # 技術設計
├── tasks.md         # 実装タスク
└── history/         # 履歴アーカイブ
```

## バージョン管理
詳細: `spec-versioning.md`

- 最新版は常に単一ファイル（requirements.md等）
- 履歴はhistory/フォルダに保存
- `/spec:archive {feature}` で履歴保存
- `/spec:history {feature}` で履歴確認

## ルール
- 仕様書なしの実装禁止
- 仕様書の無断変更禁止
- 変更時は影響分析必須

## 検証コマンド
```bash
/kiro:spec-status {feature}
/kiro:validate-gap {feature}
/kiro:validate-design {feature}
```

## トレーサビリティ
- 全要件にID付与
- 要件→設計→実装の追跡可能
