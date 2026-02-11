# リカバリー戦略定義

> Ralph Wiggum v1.1 - 7パターン自動リカバリー

## 失敗パターンと対応

### Pattern 1: ビルドエラー

**検知条件**:
- `npm run build` の exit code != 0
- TypeScript compilation error

**リカバリー手順**:
1. エラーメッセージを解析
2. 該当ファイルの型エラーを修正
3. 再ビルド試行（最大3回）
4. 3回失敗 → チェックポイント保存 → 次タスクへ

**自動修正パターン**:
- "Property X does not exist" → 型定義追加
- "Cannot find module" → import文修正
- "Type X is not assignable" → 型キャスト検討

---

### Pattern 2: テスト失敗

**検知条件**:
- `npm test` の exit code != 0
- Jest/Vitest failure output

**リカバリー手順**:
1. 失敗テストを特定
2. 実装コードとテストコードを比較
3. 実装側の修正を試行
4. テスト側の期待値が誤りの可能性を検討
5. 3回失敗 → テストをskip markして次へ

**優先順位**:
- 実装修正 > テスト修正 > テストskip

---

### Pattern 3: Lintエラー

**検知条件**:
- `npm run lint` の exit code != 0

**リカバリー手順**:
1. `npm run lint --fix` 実行
2. 自動修正不可のエラーを手動修正
3. 特殊ルールは eslint-disable コメント追加

**自動修正可能**:
- インデント、セミコロン、クォート
- import順序
- 未使用変数（削除）

**手動対応必要**:
- any型の使用
- 複雑度超過
- 命名規則違反

---

### Pattern 4: 無限ループ検知（Adaptive）

**検知条件**:
- 編集距離 + ファイル重複の適応的検知
- 同一エラーシグネチャの繰り返し

**リカバリー手順**:
1. 現在の状態をチェックポイント保存
2. 問題タスクをBLOCKEDとしてマーク
3. ブロック理由を詳細記録
4. 次のタスクへスキップ

**検知ロジック**:
```
if (editPattern.totalEdits > calculateThreshold(editPattern)) {
  // 適応的閾値: ファイルが繰り返されるほど閾値を下げる
  return INFINITE_LOOP_DETECTED;
}
```

---

### Pattern 5: 外部依存エラー（Circuit Breaker）

**検知条件**:
- ネットワークエラー
- API制限到達（HTTP 429）
- 認証エラー

**リカバリー手順**:
1. サーキットブレーカー状態確認
2. CLOSED: 指数バックオフでリトライ
3. OPEN: 即座にモック化
4. HALF_OPEN: 1回試行して判定

**状態遷移**:
- CLOSED → 3回失敗 → OPEN
- OPEN → 30秒待機 → HALF_OPEN
- HALF_OPEN → 成功 → CLOSED / 失敗 → OPEN

---

### Pattern 6: 想定外エラー（Resumable）

**検知条件**:
- 上記パターンに該当しない
- 未知のエラーメッセージ

**リカバリー手順**:
1. エラー全文をログに記録
2. スタックトレースを保存
3. 現在のgit diffを保存
4. graceful-exit実行（再開可能）

**graceful-exit仕様**:
```json
{
  "reason": "Unexpected error",
  "recoveryPoint": { /* checkpoint */ },
  "canResume": true,
  "suggestedAction": "手動確認後 /ralph-wiggum:run --resume で再開"
}
```

---

### Pattern 7: リカバリー試行過多（v1.1 NEW）

**検知条件**:
- 同一タスクで3回以上リカバリー失敗
- パターン1-5のいずれかが3回連続失敗

**リカバリー手順**:
1. タスクをスキップ
2. エスカレーションフラグを設定
3. 朝のレビュー用にレポート生成
4. 次のタスクへ進む

**エスカレーション出力**:
```json
{
  "escalate": true,
  "task_id": "TASK_X",
  "patterns_tried": [1, 2, 1],
  "suggestedAction": "手動調査が必要"
}
```

---

## チェックポイント仕様

### 保存タイミング
- 各タスク完了時
- エラー発生時
- 10反復ごと

### 保存先
```
.kiro/ralph/recovery/checkpoints/
├── latest.json           # 最新（シンボリックリンク）
├── 20260104-023000.json  # タイムスタンプ付き
└── ...
```

### 破損検知
- checksumフィールドで整合性検証
- 破損時は直前のチェックポイントを使用

---

## フォールバックプロンプト

### retry-single.md
単一タスクの再試行用プロンプト

### skip-and-continue.md
タスクスキップ時のプロンプト

### graceful-exit.md
安全終了時のプロンプト

---

Version: 1.1.0 | Updated: 2026-01-04
