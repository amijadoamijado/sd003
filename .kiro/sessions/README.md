# セッション管理ガイド

## 概要
このディレクトリはSD002プロジェクト全体のセッション管理を行います。

## ディレクトリ構造
```
.kiro/sessions/
├── current-session.md    # 現在進行中のセッション状態
├── history/              # 過去のセッション履歴（時系列）
│   ├── 2025-11-16-session-001.md
│   └── ...
├── checkpoints/          # チェックポイント記録
│   ├── 2025-11-16-checkpoint-001.md
│   └── ...
└── README.md             # このファイル
```

## 使用方法

### セッション記録コマンド
ユーザーが「**継続記録**」と指示した場合：
1. `current-session.md` を現在の状態で更新
2. タイムスタンプと作業内容を記録
3. 次回の作業予定を明記

### セッション読み込みコマンド
ユーザーが「**継続記録 読んで**」と指示した場合：
1. `current-session.md` を読み込み
2. 最新の作業状況を把握
3. 次回作業予定を確認

### セッション終了時
セッション完了時：
1. `current-session.md` を `history/YYYY-MM-DD-session-NNN.md` として保存
2. 新しい `current-session.md` を作成（次回セッション用）

### チェックポイント作成
重要なポイントで：
1. 現在の状態を `checkpoints/YYYY-MM-DD-checkpoint-NNN.md` として保存
2. ロールバックポイントとして活用

## ファイル命名規則
- セッション履歴: `YYYY-MM-DD-session-NNN.md`（NNN = 連番001, 002...）
- チェックポイント: `YYYY-MM-DD-checkpoint-NNN.md`（NNN = 連番001, 002...）

## 自動化
- Claude Code: `CLAUDE.md` に記録されたルールに従い自動実行
- Gemini/Codex/Cursor/Windsurf: 各AIツールも同様のルールを適用
