---
name: ralph-wiggum-plan
description: Codex equivalent of the SD003 custom command `/ralph-wiggum:plan`. Use when the user invokes `/ralph-wiggum:plan`, `ralph-wiggum-plan`.
---

# /ralph-wiggum:plan - Weekly Planning

この skill は Claude Code の `/ralph-wiggum:plan` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Original Command Body
# /ralph-wiggum:plan - Weekly Planning

週次計画を作成する。

## Usage

```
/ralph-wiggum:plan [week]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `week` | 週番号（例: W02）。省略時は今週 |

## Process

1. **週次ディレクトリ作成**
   ```
   .sd/ralph/weekly/{YYYY-Www}/
   ├── plan.md
   ├── daily/
   │   ├── mon.md
   │   ├── tue.md
   │   ├── wed.md
   │   ├── thu.md
   │   └── fri.md
   └── review.md
   ```

2. **バックログ確認**
   - `.sd/ralph/backlog.md` から優先度順にタスクを選択
   - 仕様書参照を確認

3. **日別割り当て**
   - 各日の推定反復数を計算
   - 依存関係を考慮して配置

4. **リスク分析**
   - 複雑なタスクは週中に配置（リカバリー時間確保）
   - 金曜は低リスクタスク推奨

## Output

```markdown
# 週次計画 - 2026年第2週

## 期間
2026-01-06 (Mon) ~ 2026-01-10 (Fri)

## 週次目標
### 必達目標
1. PC002 月次処理完成
2. テストカバレッジ85%達成

### 努力目標
1. ドキュメント整備
2. 技術的負債削減

## リソース配分
| 曜日 | 日中（協調WF） | 夜間（ralph） |
|------|--------------|--------------|
| Mon | PC002設計レビュー | FW003実装 |
| Tue | PC002タスク精査 | PC002 #1-#6 |
...

## 日別キュー割り当て
### Monday
- nightly-queue: daily/mon.md
- 推定反復: 25
- 想定成果: FW003完成
- 仕様参照: .sd/specs/fw003/
```

## Best Practices

1. **月曜は軽めのタスク**
   - 週の始まりは成功体験を作る
   - 複雑なタスクは週中に配置

2. **依存関係を意識**
   - 前提タスクを先に配置
   - 並行実行可能なタスクを特定

3. **リスク分散**
   - 外部依存タスクは早めに
   - 金曜はリファクタ/Lint等の低リスクタスク

4. **仕様書との紐付け**
   - 各タスクに仕様参照を必須
   - 仕様なしの実装は禁止

## Related Commands

- `/ralph-wiggum:run` - 夜間キュー実行
- `/ralph-wiggum:status` - 実行状況確認

## Files

- `.sd/ralph/weekly/TEMPLATE/` - テンプレート
- `.sd/ralph/backlog.md` - バックログ

---

**Phase**: Daytime (Planning)
