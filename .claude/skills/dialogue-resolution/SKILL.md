---
name: dialogue-resolution
description: |
  AIの迷走時に仕様・実装との差異を段階的に検出する対話型解決法。
  Use when: ユーザーが /dialogue-resolution を実行した時、
  または dialogue-trigger スキルで提案が承認された場合。
allowed-tools: Read, Glob, Grep, AskUserQuestion
---

# 対話型解決法スキル（Dialogue Resolution Skill）

## 目的

終盤の統合・テストフェーズでエラーが発生し、AIが迷走する場合に適用する問題解決手法。
AIの「思い込み」を可視化し、仕様・実装との差異を段階的に検出して収束させる。

## 関連コマンド

- **コマンド**: `/dialogue-resolution`
- **トリガー**: `/dialogue-trigger` スキル

## 4ステップ構造

| Step | 内容 | 重要ポイント |
|------|------|-------------|
| 1 | 認識の言語化 | ファイル検索禁止、現在の知識のみで回答 |
| 2 | 仕様との照合 | 差異をテーブル形式で報告 |
| 3 | 実装との照合 | コード確認し仕様との差異を検出 |
| 4 | 修正計画策定 | 優先順位付き修正計画を提示 |

## 厳守事項

1. **各Step完了後は必ずAskUserQuestionで確認**
2. **ユーザー承認なく次Stepに進まない**
3. **Step 1ではファイル検索・コード読み込み禁止**
4. **差異はテーブル形式で報告**

## 実行フロー

```
dialogue-trigger（提案）
    |
    v
ユーザー承認
    |
    v
dialogue-resolution（実行）
    |
    v
Step 1 → 確認 → Step 2 → 確認 → Step 3 → 確認 → Step 4 → 修正実行
```

## ログ記録

解決後は `docs/troubleshooting/RESOLUTION_LOG.md` に記録する。
