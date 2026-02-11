# Kiro Spec Init

新規仕様書を初期化します。

## 引数
- `$ARGUMENTS`: 仕様書の説明

## 作成ファイル
```
.kiro/specs/{feature}/
├── spec.json        # メタデータ
├── requirements.md  # 要件定義（空テンプレート）
├── design.md        # 技術設計（空テンプレート）
└── tasks.md         # 実装タスク（空テンプレート）
```

## 実行手順
1. 仕様書名を決定（kebab-case）
2. ディレクトリ構造を作成
3. テンプレートファイルを配置
4. spec.jsonにメタデータを記録

## Task Completion Report Required
```
## Task Completion Report
### Summary
仕様書 {feature} を初期化完了
### Changes Made
| File | Action | Description |
|------|--------|-------------|
| .kiro/specs/{feature}/ | Created | 仕様書ディレクトリ |
### Next Steps
- [ ] /prompts:kiro-spec-requirements {feature}
```
