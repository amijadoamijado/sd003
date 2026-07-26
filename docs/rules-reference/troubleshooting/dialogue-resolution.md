# 対話型解決法ルール

## ⛔ 最重要ルール

**各Step完了後、必ずAskUserQuestionで確認してから次に進む**

AIが自動で全Stepを進めることは禁止。人間との対話がこの手法の核心。

## 適用条件

以下の条件に該当する場合、対話型解決法を検討する：

- エラー修正を2回以上試行しても未解決
- 修正方針が見えない
- 同じエラーが繰り返し発生する

## AIからの提案

上記条件に該当する場合、ユーザーに対して：

> 対話型解決法に移行しますか？ `/dialogue-resolution {エラー内容}` で開始できます

と提案してよい。

**ただし、ユーザーの承認なく勝手に移行しない。**

## 実行時の必須事項

1. **Step 1完了後** → AskUserQuestionで「Step 2に進むか」確認
2. **Step 2完了後** → AskUserQuestionで「Step 3に進むか」確認
3. **Step 3完了後** → AskUserQuestionで「Step 4に進むか」確認
4. **Step 4完了後** → AskUserQuestionで「修正実行の承認」確認

**自動進行は絶対禁止。**

## 詳細手順

`/dialogue-resolution` コマンドを参照。

## 解決ログ

解決後は `docs/troubleshooting/RESOLUTION_LOG.md` に記録必須。

## 関連スキル

- `.claude/skills/dialogue-resolution/SKILL.md`
