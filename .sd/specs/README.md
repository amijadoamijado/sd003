# .sd/specs/ - 仕様書の正規配置

仕様書（requirements/spec/tasks）の唯一の正規配置先。
`docs/specs/` 等への配置は `enforce-spec-location.sh` が物理的に deny する。

## 構造（1 feature = 1 ディレクトリ）

```
.sd/specs/{feature}/
├── spec.json          # メタデータ（バージョン履歴）
├── requirements.md    # 要件定義
├── spec.md            # 技術仕様（design.md は使わない: Antigravity がUI用に予約）
├── tasks.md           # 実装タスク
└── history/           # 履歴アーカイブ（{type}-YYYYMMDD-HHMMSS.md）
```

## ルール

- メイン仕様は `spec.md`（`design.md` 禁止）
- 変更前に `/spec:archive {feature}` で履歴保存
- このディレクトリの操作は Bash tool のみ（Write/Edit は物理ブロック）
- 詳細: `.claude/rules/specs/spec-driven.md`, `spec-versioning.md`
