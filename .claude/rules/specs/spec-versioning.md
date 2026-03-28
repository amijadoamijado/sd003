---
description: 仕様書バージョン管理（.sd/specs/配下適用）
paths:
  - ".sd/specs/**/*"
---

# 仕様書バージョン管理

## 原則

> 最新版は常に単一ファイル。履歴は別フォルダで管理。

## フォルダ構造

```
.sd/specs/{feature}/
├── spec.json               # メタデータ（バージョン管理）
├── requirements.md         # 最新版（常に現在の要件）
├── design.md               # 最新版（常に現在の設計）
├── tasks.md                # 最新版（常に現在のタスク）
└── history/                # 履歴アーカイブ
    ├── requirements-20251026-100000.md
    ├── requirements-20241224-153000.md
    ├── design-20251026-100000.md
    └── ...
```

## 履歴ファイル命名規則

```
{type}-YYYYMMDD-HHMMSS.md
```

| 要素 | 説明 | 例 |
|------|------|-----|
| type | ファイル種別 | requirements, design, tasks |
| YYYYMMDD | 保存日 | 20251226 |
| HHMMSS | 保存時刻 | 143000 |

## 履歴保存タイミング

| タイミング | 説明 | コマンド |
|------------|------|----------|
| 仕様変更前 | 大きな変更を加える前 | `/spec:archive {feature} {file}` |
| マイルストーン完了 | フェーズ完了時 | `/spec:archive {feature}` |
| 手動トリガー | 明示的な保存 | `/spec:archive {feature}` |

## spec.json履歴セクション

```json
{
  "name": "feature-name",
  "version": "2.1.0",
  "updated": "2025-12-27T10:00:00+09:00",
  "history": [
    {
      "version": "2.0.0",
      "date": "2025-12-25",
      "file": "requirements-20251225-100000.md",
      "note": "照合ロジック変更"
    },
    {
      "version": "1.0.0",
      "date": "2025-10-26",
      "file": "requirements-20251026-100000.md",
      "note": "初版"
    }
  ]
}
```

## 運用ワークフロー

### 仕様変更時

```
1. /spec:archive {feature} requirements   # 変更前を保存
2. requirements.mdを直接編集              # 最新版を更新
3. spec.jsonのversionを更新               # バージョンアップ
```

### 試行錯誤フェーズ

```
1. プロトタイプで検証
2. 発見事項をrequirements.mdに「逆起こし」
3. 必要に応じて/spec:archiveで履歴化
```

## 禁止事項

| 禁止 | 理由 |
|------|------|
| `requirements-update-*.md`形式 | 履歴が分散し、最新状態が不明確になる |
| 本体ファイル外への更新追記 | 「逆起こし」漏れの原因 |
| history/以外への履歴保存 | 管理が煩雑になる |

## コマンド

| コマンド | 説明 |
|----------|------|
| `/spec:archive {feature} [file]` | 履歴保存（fileなしで全ファイル） |
| `/spec:history {feature}` | 履歴一覧表示 |

## 関連ルール

- `spec-driven.md`: 仕様書駆動開発フロー
