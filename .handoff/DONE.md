# DONE.md - 完了報告（2026-10-03 10:16 Claude Code セッション）

## やったこと

**変更したもの**
| 対象 | 変更内容 |
|------|----------|
| `C:\Users\a-odajima\Desktop\at002` | `F:\Desktop\at002` へ移しジャンクション化（5.9GB・13,559件） |
| `C:\Users\a-odajima\Documents\Yayoi\弥生会計26データフォルダ\Backup` | `F:\Documents\...\Backup` へ移しジャンクション化（4.1GB・869件） |
| `C:\Users\a-odajima\Documents\Hayawaza\早業8バックアップフォルダ` | `F:\Documents\Hayawaza\...` へ移しジャンクション化（1.2GB・11件） |
| `C:\Users\a-odajima\.codex\sessions` | `F:\codex\sessions` へ移しジャンクション化（3.4GB・2,319件） |
| Google ドライブ | トレイから終了→再起動で WAL 約1.1GB を縮小（C: 側 2.2→1.2GB） |
| `...\Claude_実レジストリ修復_20261002\00_原因と修復の記録.txt` | 再起動後の起動・会社回線の送信とも問題なしと追記 |

**変更内容の要約**
C: の空きを 3.6GB から 18GB に増やした。移動は全件 SHA1 照合後にジャンクション化し、ユーザー承認後に元を削除。sd003 のコードは変更していない。

## 確認結果
- 4か所とも C: 側パスからジャンクション経由で全件見えることを確認。
- アプリでの動作（at002 スクリプト・弥生/早業のバックアップ保存・Codex の過去会話）は未確認。

## 未完了
- `C:\Windows\SoftwareDistribution.old`（2.7GB）: ユーザーが管理者ターミナルで削除中。
- `pagefile.sys`（9.3GB）: C: のまま 2GB 固定を推奨、未実行。
- C: の空きの数値が揺れる原因は未調査。

## 次のステップ
1. `SoftwareDistribution.old` の消去と C: の空きを確認。
2. ページファイルの扱いを確定。
3. 移した4か所の動作確認。

## 注意
- **F: は USB 外付け SSD**。外すと上記4か所・Drive キャッシュ・Outlook の PST が見えなくなる。
- 日本語パスの robocopy は Bash からだと文字化けする。pwsh 経由で実行すること。

## 関連ファイル
- `D:\claudecode\sd003\.sessions\session-20261003-101645.md`
