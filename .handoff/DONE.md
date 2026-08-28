# DONE.md - 完了報告

- **日時**: 2026-08-28 21:54:33
- **プロジェクト**: D:\claudecode\sd003
- **ブランチ**: master
- **セッション記録**: `D:\claudecode\sd003\.sessions\session-20260828-215433.md`

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `C:\Users\a-odajima\.codex\config.toml` | `model` を `gpt-5.6-sol` → `gpt-5.6-luna`、`model_reasoning_effort` を `low` → `max` |
| `C:\Users\a-odajima\.codex\config.toml.bak-20260828-luna` | 変更前バックアップを新規作成（7,060 bytes） |
| `.sessions/session-20260828-215433.md` | セッション記録を新規作成 |
| `.sessions/session-current.md` / `.sessions/TIMELINE.md` | 最新版へ更新（2026-08 セクション新設・総124セッション） |
| `.handoff/DONE.md` | 本ファイル |

**変更内容の要約**
Claude Code × OpenAI公式Codexプラグイン × GPT-5.6 の構成が**すでに 2026-03-31 から稼働済み**であることを実測で確定し、
ユーザー指示により Codex の既定モデルを `gpt-5.6-luna` / reasoning effort `max` へ変更した。sd003本体のコード変更はなし。

---

## 確認結果

**実行したコマンド**
```bash
codex --version
codex exec --sandbox read-only -o <out> "Reply with exactly the string OK and nothing else."
```

**結果**
```
codex-cli 0.150.1
rc=0 / 回答: OK
実行ログ内: gpt-5.6-luna x143 件, effort=max x49 件
```

**動作確認**
- [x] 変更後の設定で `codex exec` が rc=0 で完走する
- [x] 実行ログ上で実際に `gpt-5.6-luna` / `effort=max` が使われている
- [x] 認証は ChatGPT アカウント（`auth.json`: `OPENAI_API_KEY = null` + トークン一式）＝API課金なし
- [x] プラグイン `codex@openai-codex` v1.0.6 が user scope に導入済み（2026-03-31）

---

## 残っていること

**未完了タスク**
- [ ] `codex-security` スキル3ミラー（`.claude/skills/` `.agents/skills/` `.grok/skills/`）が未コミット・出所不明 → 中身確認して commit か退避かを判断（P1）
- [ ] セッションアーカイブ 61件 / 13MB 未実行（`/archive-sessions --execute`）
- [ ] 持ち越し: td001 GitHubリモート未設定 / bd登録3件 / at002提案2件のユーザー判断 / `/context` 実測

**次の手順**
- 次のタスク: `codex-security` 3ミラーの素性確認
- 依存関係: なし

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| effort `max` vs `ultra` | `max` | ユーザー明示指示。`ultra` の存在は備考として記録 |
| 既定を変更 vs 呼び出し側で都度指定 | 既定を変更 | ユーザー指示が「初期値」。用途別に落としたい場合は呼び出し側で上書き可 |
| 設定変更前にバックアップ | 取得する | ユーザー領域の設定ファイルのため（上書き禁止ルールの趣旨） |
| sd003 を `trust_level = trusted` へ追加 | 見送り | read-only sandbox で完走したため現時点で不要。書き込み系で詰まったら判断 |

**採用しなかった案と理由**
- SD003側の `codex-dispatch` 既定を同時に変更: 指示は Codex 側の初期値のみ。波及の周知に留めた

---

## 追加情報

- **グローバル既定のため波及範囲が広い**: `/codex:review` `/codex:adversarial-review` `/codex:rescue` および SD003 の `codex-dispatch`（`codex-run.ps1` / `codex-run.sh`）も luna/max で走る。SD003 の正準レシピは「medium effort を明示」なので、重い一括レビューでは時間とCodex利用枠の消費が増える
- **`codex.exe` から抽出した有効値**: モデル `gpt-5.6-luna` / `-terra` / `-sol` / `-pro`、effort `minimal / low / medium / high / xhigh / max / ultra`
- **外部情報の扱い**: 起点はChatGPT回答の転記。内容は概ね正しかったが「これから組む」前提だけが実態とズレていた。`installed_plugins.json` / `auth.json` / `config.toml` のディスク実測で確定させる手順が有効
