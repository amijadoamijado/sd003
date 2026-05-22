# DONE.md - 完了報告

---

## やったこと

**変更したファイル（4論理コミット）**
| ファイル群 | 変更内容 |
|---------|----------|
| `scripts/agent-{implement,pipeline,test}.sh`, `sync-cli-commands.py` | gemini → `agy --prompt ... --dangerously-skip-permissions` 化 |
| `antigravity.md`（`GEMINI.md`からrename）, `.antigravity/` | Antigravity設定 + 生成コマンド/スキルツリー新規 |
| `.claude/commands/workflow-{impl,request,review,status}.md`, `sessionwrite.md` | 実装デフォルトをGemini→Antigravity(agy)に書換 |
| `CLAUDE.md`, `AGENTS.md`, `README.md`, `ai-coordination.md`, `package.json` | AI協調モデル一覧をAntigravityに統一、`.gemini/`参照除去 |
| `.gemini/.cursor/.windsurf/.qwen/.agent/.agents/`（削除） | 廃止CLI統合の削除（git履歴に保持） |
| `.sd/commands/*`（untrack） | gitignore済みのtracked残骸を解消 |
| `.claude/hooks/*skill-read*.sh`, `registry.json`, 新規skill 2件, `.gitignore` | skill-readガードレール + ゴミ(cr001/worktrees)除外 |

**変更内容の要約**
SD003の実装/E2E連携先をGemini CLIからAntigravity CLI(agy)へ移行・一本化。別ツール報告(9件)と実態(465件)の乖離を検証し、4つの論理コミットに分割して安全に確定した。

---

## 確認結果

**実行したコマンド**
```bash
bash scripts/agent-implement.sh test-project 001 --dry-run
bash scripts/agent-pipeline.sh test-project 001 --dry-run
python scripts/sync-cli-commands.py --check
```

**結果**
```
agent-implement.sh → "Antigravity CLI Agent - Implementation"
agent-pipeline.sh  → "Antigravity(実装) → Codex(レビュー) → Antigravity(テスト)"
SYNC CHECK OK (36 commands)
committed .codex/.antigravity ドリフトなし
```

**動作確認**
- [x] dry-runでagy起動コマンドが組まれる
- [x] sync整合（.antigravity/.codex/.sd/commands）
- [x] 実行系のgemini呼び出しゼロ（残るは注記/履歴フッター/deployテンプレのみ）
- [ ] npm build/test は対象外（src/未変更のため柱3に基づき省略）

---

## 残っていること

**未完了タスク**
- [ ] claude-mem `CLAUDE.md` 自動スタブ9件の方針決定（gitignore or commit）
- [ ] deploy.ps1/sh の gemini.md 生成まわり整理（再デプロイ時）
- [ ] 配下プロジェクト（at002等）への再デプロイ（今回スコープ外）

**次の手順**
- 次のタスク: claude-memスタブ方針決定 → 必要なら再デプロイ
- 依存関係: なし（sd003正本は確定済み）

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 一括コミット vs 論理分割 | 論理分割(4コミット) | 報告と実態の乖離が大きく、レビュー可能性とrevert単位を確保 |
| `.sd/commands` をcommit vs untrack | untrack | .sdはgitignore済み、消失フットガンを恒久解消 |
| `.gemini` 残す vs 完全削除 | 完全削除 | 廃止方針に従い半壊状態を解消（git履歴で復元可） |
| workflow-impl.md inline agy vs script委譲 | script委譲 | agy起動を agent-implement.sh に一本化しドリフト防止 |

**採用しなかった案と理由**
- 全docのGemini参照一括掃除: スコープ膨張回避のため「全AIモデル共通」履歴フッターは残置
- 再デプロイ: ユーザー指示によりsd003正本のみ（別タスク）

---

## 追加情報

- `git rm` の落とし穴: 変更ありファイルを含む `git rm` は `-f`なしで全体abort。`--cached`（ディスク既削除時）使用で復旧。stderrを捨てない教訓
- `.sd/commands/specs` はランタイムrefreshでローカルキャッシュが消えることがある→ `python scripts/sync-cli-commands.py` で再生成

---
