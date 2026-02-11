# チェックポイント記録テンプレート

## チェックポイント情報
- **日時**: YYYY-MM-DD HH:MM:SS
- **チェックポイント番号**: NNN
- **作成理由**: [なぜこのタイミングで作成したか]
- **作成者**: Claude Code / Gemini / Codex / Cursor / Windsurf

## プロジェクト状態スナップショット

### 完了フェーズ
- ✅ Phase 0: [フェーズ名]
- ✅ Phase 1: [フェーズ名]
- 🔄 Phase 2: [フェーズ名]（進行中）

### コード状態
- **ビルド**: ✅ 成功 / ❌ 失敗
- **テスト**: ✅ 全パス / ⚠️ 一部失敗 / ❌ 失敗
- **リント**: ✅ エラー0件 / ⚠️ 警告あり / ❌ エラーあり
- **カバレッジ**: [XX]%

### Git情報
- **ブランチ**: [branch-name]
- **コミットハッシュ**: [hash]
- **コミット数**: [total-commits]
- **未コミット変更**: あり / なし

## 主要ファイル一覧
```
src/
├── core/           [XX files]
├── mocks/          [XX files]
├── spec-driven/    [XX files]
└── ...

.kiro/
├── specs/          [XX specs]
├── sessions/       [XX sessions]
└── ...
```

## 依存関係状態
- **Node.js**: [version]
- **TypeScript**: [version]
- **主要パッケージ**: [list]
- **脆弱性**: あり（[count]件） / なし

## 品質メトリクス
- **コード行数**: [total-lines]
- **テスト行数**: [test-lines]
- **複雑度**: [average-complexity]
- **技術的負債**: [debt-ratio]

## ロールバック情報

### このチェックポイントに戻す方法
```bash
# Git経由
git checkout [commit-hash]

# または
git reset --hard [commit-hash]
```

### 注意事項
- [ロールバック時の注意点1]
- [ロールバック時の注意点2]

## 次のマイルストーン
- **目標**: [次のマイルストーン名]
- **期限**: [予定日]
- **残タスク数**: [count]

## 備考
- [その他メモ]
