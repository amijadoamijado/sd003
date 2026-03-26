---
description: ファイル保存先を表示する際のフルパス表示ルール
---

# フルパス表示ルール

## 原則

> ファイルの保存先・作成先をユーザーに案内する際は、必ず**絶対パス（フルパス）**で表示する。
> 相対パスだけではユーザーがすぐにファイルを開けない。

## 対象

ユーザーが開く可能性のあるファイルパスを表示する**全ての場面**:

| 場面 | 良い例 | 悪い例 |
|------|--------|--------|
| 成果物の保存先 | `D:\claudecode\sd003\materials\csv\report.csv` | `materials/csv/report.csv` |
| セッション保存 | `D:\claudecode\sd003\.kiro\sessions\session-current.md` | `.kiro/sessions/session-current.md` |
| ログ出力先 | `D:\claudecode\sd003\logs\debug.log` | `logs/debug.log` |
| アーカイブ先 | `G:\マイドライブ\claude-sessions-archive\...` | `claude-sessions-archive/...` |

## 例外（相対パスのままでよい）

- コード内のimport/require文
- ルール説明文中のパス参照（例: 「詳細: `.claude/rules/...`」）
- CLAUDE.md内の設定参照
- git diff / git status の出力

## 理由

相対パス（例: `.kiro/sessions/session-current.md`）はプロジェクトルートからの位置を示すだけで、
ユーザーがエクスプローラーやエディタで直接開くにはプロジェクトパスを自分で補完する必要がある。
フルパスならそのままコピーして即座にアクセスできる。
