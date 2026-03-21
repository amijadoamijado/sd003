# 原因追及ファースト（Root Cause First）

## 絶対ルール

> 原因が特定されていない問題に対策を打つな。
> 原因不明のまま対策を実装するのは問題の隠蔽であり、対策ではない。

## 背景（2026-03-21事故）

.kiro/ディレクトリが繰り返し消失。AIは原因追及せずにフック作成（対策）に飛び、
途中で「Windowsアンチウイルスのせい」「OneDriveのせい」と外部転嫁を試みた。
ユーザーに5回指摘されて初めて自分のプロセスを調査。
実際はbrowser-useテストのChromiumゾンビプロセスが原因だった。

## 強制プロトコル

異常発生時、以下の順序を**絶対に**守る:

```
1. 症状を正確に記述する
2. 自分が直前にやったことを全てリストアップする
3. 自分の行動が原因である仮説を最初に立てる（外部要因は最後）
4. 仮説を検証する（プロセス確認、ログ確認、再現テスト）
5. 原因が確定してから対策を実装する
6. 対策は登録・コミット・パッケージ化まで一気にやる
```

## 禁止事項

| 禁止 | 理由 |
|------|------|
| 原因不明のまま対策コードを書く | 問題の隠蔽 |
| 外部環境（OS、アンチウイルス、OneDrive等）を最初に疑う | 自分の行動が原因である確率が圧倒的に高い |
| 「気をつける」を対策として提示する | 決定論的でない対策は対策ではない |
| フックを書いただけで完了とする | 登録・コミット・パッケージ化・動作確認まで一気にやる |
| 対策の後にパッケージ化を忘れる | deploy-package-reminder.sh が警告するが、警告を無視するな |

## 仮説の優先順位（必ずこの順で疑う）

```
1. 自分が起動したプロセス（ゾンビプロセス含む）
2. 自分が実行したコマンドの副作用
3. 自分が作成・変更したファイルの影響
4. 自分が登録したフック・設定の影響
5. git操作の副作用
6. ---ここまで自分の責任---
7. 他のツール・プロセス
8. OS・環境要因
```

## 検証コマンドテンプレート

```bash
# プロセス確認（最初にやること）
powershell -Command "Get-Process | Where-Object { \$_.StartTime -gt (Get-Date).AddHours(-2) } | Select-Object Id, ProcessName, StartTime | Sort-Object StartTime"

# ファイル監視（削除イベント検知）
powershell -Command "
\$w = New-Object System.IO.FileSystemWatcher
\$w.Path = 'D:\claudecode\sd003'
\$w.IncludeSubdirectories = \$true
\$w.EnableRaisingEvents = \$true
Register-ObjectEvent \$w 'Deleted' -Action { Write-Host \"DELETED: \$(\$Event.SourceEventArgs.FullPath)\" }
Start-Sleep -Seconds 60
"
```
