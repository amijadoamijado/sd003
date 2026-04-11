---
name: notebooklm-research
description: NotebookLMのRAGでゼロトークンリサーチ。大量ドキュメント分析をNotebookLMに委ね、Claude Codeはオーケストレーションのみ担当。
---

# NotebookLM Research（ゼロトークンリサーチ）

大量ドキュメント（税務講本、業務標準化資料等）をNotebookLMにアップロードし、RAGクエリで分析・要約を実行する。Claude Codeのトークン消費はゼロ。

## 前提条件チェック（実行前に必ず確認）

### 1. notebooklm-py

```bash
python -m notebooklm --version        # インストール確認
python -m notebooklm auth check       # 認証確認
```

未インストール時:
```bash
pip install notebooklm-py
```

認証切れ時（Playwright経由でCookie再取得）:
```python
from playwright.sync_api import sync_playwright
import json, time, os

profile_dir = r'D:\claudecode\er001\.notebooklm-profile'
with sync_playwright() as p:
    browser = p.chromium.launch_persistent_context(profile_dir, headless=False, channel='chrome')
    page = browser.pages[0] if browser.pages else browser.new_page()
    page.goto('https://notebooklm.google.com/', timeout=30000)
    page.wait_for_load_state('networkidle', timeout=30000)
    time.sleep(3)
    storage = browser.storage_state()
    out_dir = os.path.expanduser(r'~\.notebooklm')
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, 'storage_state.json'), 'w') as f:
        json.dump(storage, f)
    browser.close()
```

### 2. GitHubリポジトリ仕様変更チェック（必須）

```bash
# https://github.com/teng-lin/notebooklm-py/releases
# GoogleのRPCメソッドID変更で即座に壊れるため、最新版を確認
```

---

## ワークフロー

### Step 1: リサーチ目的の明確化

ユーザーに以下を確認:
- 分析対象ドキュメント（PDF/URL/テキスト）
- 分析の目的（要約、比較、質問応答、構造化抽出）
- 出力形式（Markdown、JSON、テーブル）
- 出力先（`materials/` or Obsidianボルト）

### Step 2: Notebook作成

```python
import subprocess, json

# 新規ノートブック作成
notebook_name = 'リサーチ名_YYYYMMDD'
r = subprocess.run(
    ['python', '-m', 'notebooklm', 'create', notebook_name, '--json'],
    capture_output=True, text=True
)
nb_data = json.loads(r.stdout)
nb_id = nb_data['notebook']['id']  # ← 正しいパス。data['id']ではない
print(f'Notebook ID: {nb_id}')
```

**既存ノートブックを使う場合**:
```bash
python -m notebooklm list --json   # 一覧からIDを確認
```

### Step 3: ソース追加

```python
sources = [
    {'type': 'file', 'path': r'D:\path\to\document.pdf'},
    {'type': 'url', 'url': 'https://example.com/article'},
    # ...
]

for src in sources:
    if src['type'] == 'file':
        cmd = ['python', '-m', 'notebooklm', 'source', 'add',
               src['path'], '--type', 'file', '-n', nb_id]
    elif src['type'] == 'url':
        cmd = ['python', '-m', 'notebooklm', 'source', 'add',
               src['url'], '-n', nb_id]
    subprocess.run(cmd, capture_output=True, text=True)

# ソース追加確認
r = subprocess.run(
    ['python', '-m', 'notebooklm', 'source', 'list', '--json', '-n', nb_id],
    capture_output=True, text=True
)
count = len(json.loads(r.stdout).get('sources', []))
print(f'Sources added: {count}')
assert count == len(sources), f'Expected {len(sources)}, got {count}'
```

### Step 4: RAGクエリ実行

```python
queries = [
    'この資料の主要な論点を5つ挙げてください',
    '実務上の注意点をまとめてください',
    # ユーザー指定のクエリ
]

results = []
for q in queries:
    r = subprocess.run(
        ['python', '-m', 'notebooklm', 'chat', q, '-n', nb_id],
        capture_output=True, text=True, timeout=120
    )
    results.append({'query': q, 'answer': r.stdout.strip()})
```

### Step 5: 結果出力

結果をMarkdownファイルとして保存する。

**出力先の決定**:
- `.sd/notebooklm-config.json` の `research.obsidian_vault_path` が設定済み → Obsidianボルト
- 未設定 → `materials/text/` に保存

**出力形式**:
```markdown
---
source: NotebookLM RAG
notebook_id: {nb_id}
date: YYYY-MM-DD
tags: [notebooklm, research]
---

# {リサーチテーマ}

## ソース
- {ソース1}
- {ソース2}

## Q&A

### Q: {クエリ1}
{回答1}

### Q: {クエリ2}
{回答2}
```

**ファイル名規則**: `YYYYMMDD_{テーマ}_NLMリサーチ.md`

---

## フォールバック（notebooklm-py故障時）

notebooklm-pyがエラーを返す場合（GoogleのRPC変更等）:

1. `references/fallback-guide.md` を参照
2. chrome-devtools MCP経由でNotebookLMをブラウザ操作
3. 手動でソース追加 → チャット → 結果コピー

詳細: `references/fallback-guide.md`

---

## 必須ルール

| ルール | 理由 |
|--------|------|
| `nb_data['notebook']['id']` を使う | `data['id']` は空文字を返す |
| 全操作で `-n <notebook_id>` を明示指定 | コンテキスト依存は事故の元 |
| GitHubチェックなしの実行禁止 | GoogleのRPC仕様変更で壊れるリスク |
| 認証チェックを毎回実行 | Cookie有効期限は数十分〜数時間 |

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| `Token fetch failed` | Cookie期限切れ | 認証再取得を実行 |
| `chat` が空文字を返す | ソース未追加 or ソース処理中 | source list確認、30秒待って再試行 |
| `create --json` のIDが空 | JSONパスの誤り | `nb_data['notebook']['id']` を確認 |
| ソースが別ノートブックに追加 | `-n` 未指定 | 全コマンドに `-n <id>` を付与 |
| `pip install` 失敗 | Python環境の問題 | `python --version` 確認、venv推奨 |

## 禁止事項

- **トークン節約のためにクエリ結果を要約しない**: NotebookLMの回答をそのまま保存する。Claude Codeでの再要約はトークン消費の本末転倒
- **認証情報のgit commit**: `storage_state.json` は `.gitignore` に追加済みであること
- **GitHubチェックなしの実行**: 壊れるリスクが常にある
