# DONE.md - 完了報告（2026-05-27）

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.sessions/session-20260527-104307.md` | セッション履歴新規作成 |
| `.sessions/session-current.md` | 最新版コピー |
| `.sessions/TIMELINE.md` | 05-27エントリ追加、統計更新 |
| `.handoff/DONE.md` | このファイル更新 |

**変更内容の要約**
SD003コード変更なし。AIツール頻繁クラッシュの根本診断と対処方針合意。OneDriveプロセス停止（580MB回復）と、SQL Server 3インスタンスの用途・現役性を実機調査。

---

## 確認結果

**実行したコマンド**
```powershell
# 診断
Get-CimInstance Win32_OperatingSystem  # メモリ使用率 77%
Get-Process | Sort WS -Desc            # SQL×3=2.3GB、OneDrive×3=580MB
Get-CimInstance Win32_Service | Where Name -like 'MSSQL*'  # 3インスタンス特定
Get-NetTCPConnection -State Established | Where { $sqlPids -contains $_.OwningProcess }  # SQL接続=0件
Get-ChildItem 'C:\Program Files (x86)\OBC' -Recurse -Filter '*.mdf'  # OBC=今朝書込み

# 実行（成功）
Stop-Process -Name OneDrive,OneDrive.Sync.Service -Force
```

**結果**
- OneDrive: 全プロセス停止確認（580MB回復）
- SQL$YAYOI: 不要確定（ユーザー証言+ESTABLISHED接続0）
- SQL$OBCINSTANCE4X: 現役確定（今朝書込み、停止禁止）
- SQLSERVER: ユーザー指示で残置

---

## 残っていること

**未完了タスク**（次セッション・ユーザー側）
- [ ] **P0**: 管理者pwshで `Stop-Service MSSQL$YAYOI` + `Set-Service ... -StartupType Manual`（約1GB回復）
- [ ] **P0**: ページファイルをF:に移動・拡大（初期16384/最大32768）+ Cの4GBを削除 → 再起動
- [ ] **P1**: タスクマネージャーでOneDrive自動起動を無効化
- [ ] **P2**: MSSQLSERVER用途確認 / メモリ32GB増設検討

**次の手順**
- 上記P0タスク2つを完了後、AIツール作業中のクラッシュが解消したか観察

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| AIツール軽量化 vs OS環境改善 | OS環境改善 | AIツール本体は20%しか食ってない |
| MSSQL$YAYOI停止 vs 残置 | 停止+手動化 | 弥生販売廃用確定+接続ゼロ |
| MSSQL$OBCINSTANCE4X停止 vs 残置 | 残置 | 今朝書込みあり、現役 |
| ページファイルCLI vs GUI | GUI | ブート不能リスク回避 |
| 直接実行 vs ユーザー手動 | ユーザー手動 | サービス停止は管理者権限必須 |

---

## 追加情報

- 「弥生会計スタンドアロンはSQL不使用、弥生販売はSQL使用」はユーザー証言。auto-memoryへの記録候補。
- DB現役性判定の手法（`.mdf` の LastWriteTime + ESTABLISHED接続数）は再現性あり、他環境でも応用可能。
