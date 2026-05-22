---
name: notebooklm-memory
description: セッション知見をNotebookLMに蓄積し、次回セッションで関連知見を取得する永続メモリシステム。
---

# NotebookLM Memory（永続メモリ）

セッション終了時の知見をNotebookLMノートブックに蓄積し、次回セッション開始時に関連知見をRAGで取得する。Claude Codeのセッション間記憶喪失を補完する。

## 前提条件

1. notebooklm-pyインストール済み（`python -m notebooklm --version`）
2. 認証済み（`python -m notebooklm auth check`）
3. `.sd/notebooklm-config.json` が存在し `memory.enabled: true`

認証手順は `notebooklm-research` スキルまたは `notebooklm-slide-pipeline` スキルを参照。

## 設定ファイル

`.sd/notebooklm-config.json`:
```json
{
  "memory": {
    "enabled": true,
    "notebook_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "notebook_name": "SD003-知見ストア"
  }
}
```

### 初期セットアップ

知見ストア用ノートブックを1回だけ作成する:

```python
import subprocess, json

r = subprocess.run(
    ['python', '-m', 'notebooklm', 'create', 'SD003-知見ストア', '--json'],
    capture_output=True, text=True
)
nb_id = json.loads(r.stdout)['notebook']['id']
print(f'notebook_id: {nb_id}')
# → .sd/notebooklm-config.json の memory.notebook_id に設定
```

---

## ワークフロー

### 蓄積（sessionwrite後）

sessionwrite完了後、以下をオプショナルで実行:

1. `session-current.md` から「完了」「未解決」「備考」セクションを抽出
2. テキストソースとしてNotebookLMに追加

```python
import subprocess, json, os
from datetime import datetime

# 設定読込
with open('.sd/notebooklm-config.json', 'r') as f:
    config = json.load(f)

if not config.get('memory', {}).get('enabled'):
    print('NotebookLM memory is disabled. Skipping.')
    exit(0)

nb_id = config['memory']['notebook_id']

# セッション記録を読み込み
with open('.sessions/session-current.md', 'r', encoding='utf-8') as f:
    content = f.read()

# テキストソースとして追加（NotebookLMにインデックスされる）
# notebooklm-py の source add はテキストファイルを受け付ける
tmp_path = f'.sd/tmp_session_{datetime.now().strftime("%Y%m%d_%H%M%S")}.md'
with open(tmp_path, 'w', encoding='utf-8') as f:
    f.write(content)

subprocess.run([
    'python', '-m', 'notebooklm', 'source', 'add',
    tmp_path, '--type', 'file', '-n', nb_id
], capture_output=True, text=True)

os.remove(tmp_path)  # 一時ファイル削除
print(f'Session knowledge stored to NotebookLM notebook {nb_id}')
```

### 取得（sessionread時）

sessionread完了後、バックグラウンドで以下を実行:

```python
import subprocess, json

with open('.sd/notebooklm-config.json', 'r') as f:
    config = json.load(f)

if not config.get('memory', {}).get('enabled'):
    exit(0)

nb_id = config['memory']['notebook_id']

# 前回の次回タスクを読み込み
with open('.sessions/session-current.md', 'r', encoding='utf-8') as f:
    content = f.read()

# 「次回タスク」セクションからクエリを生成
# 簡易的に session-current.md の内容をクエリとして投げる
query = '前回のセッションで未解決だった課題と、関連する過去の知見を教えてください'

r = subprocess.run(
    ['python', '-m', 'notebooklm', 'chat', query, '-n', nb_id],
    capture_output=True, text=True, timeout=60
)

if r.stdout.strip():
    print('--- NotebookLM 関連知見 ---')
    print(r.stdout.strip())
    print('--- ここまで ---')
else:
    print('NotebookLM: 関連知見なし')
```

---

## sessionwrite/sessionread への統合

### sessionwrite Step 8（オプション）

`sessionwrite.md` に追加するステップ:

```
## Step 8: NotebookLM知見蓄積（オプション）

`.sd/notebooklm-config.json` が存在し `memory.enabled: true` の場合のみ実行。
失敗してもセッション保存自体はブロックしない（warn and continue）。
```

### sessionread Step 6（バックグラウンド、オプション）

`sessionread.md` に追加するステップ:

```
## Step 6: NotebookLM知見取得（バックグラウンド、オプション）

`.sd/notebooklm-config.json` が存在し `memory.enabled: true` の場合のみ。
Agent(run_in_background=true) で関連知見を取得し、結果を表示。
```

---

## 設計原則

| 原則 | 理由 |
|------|------|
| 完全オプショナル | config未設定なら一切動作しない。既存フローを壊さない |
| 失敗非致命的 | NLM蓄積/取得の失敗はwarnのみ。session保存はブロックしない |
| 1プロジェクト1ノートブック | 知見の混在を防ぐ |
| セッション記録そのままを蓄積 | 要約・加工はしない。NotebookLMのRAGに任せる |

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| `memory.enabled: true` なのに動かない | notebook_id が空 | 初期セットアップを実行 |
| `Token fetch failed` | Cookie期限切れ | 認証再取得 |
| 蓄積は成功するが取得が空 | ソースのインデックス処理中 | 数分待って再試行 |
| config読込エラー | JSONフォーマットエラー | `.sd/notebooklm-config.json` を確認 |
