# DONE.md - 完了報告（2026-05-26）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/skills/sd-deploy/{deploy.ps1,deploy.sh,SKILL.md}` | `.sd003-keep` オプトアウト＋`-DryRun`/`--dry-run` divergence スキャン＋execute時の上書き報告 |
| `.claude/skills/sd-upgrade/{upgrade.ps1,upgrade.sh,SKILL.md}` | dry-run を deploy 委譲で正直化、判定文言を UPGRADE COMPLETE に、`.sd003-keep` ドキュメント化 |
| `.claude/skills/codex-dispatch/{SKILL.md,codex-run.sh}` | 新規。codex exec 正準レシピ＋決定論ラッパー |
| `.agents/skills/{sd-deploy,sd-upgrade,codex-dispatch}/*` | sync ミラー |

**変更内容の要約**
deploy/upgrade が固有化FWファイルを黙って上書きし「UPGRADE OK」と誤報する欠陥を、`.sd003-keep`（オプトアウト）＋ dry-run の divergence 可視化で構造的に修正。あわせて codex exec の正準invocation（`2>&1|tee` 禁止・`-o`・medium effort）を sd003 framework スキル codex-dispatch として取り込んだ。

---

## 確認結果

**実行したコマンド**
```bash
# PowerShell / bash の構文チェック
[Parser]::ParseFile(deploy.ps1/upgrade.ps1) ; bash -n deploy.sh/upgrade.sh/codex-run.sh
# throwaway での end-to-end 検証（ps1 + bash 両方）
upgrade.ps1 <throwaway> (-DryRun) ; upgrade.ps1 <throwaway> -Execute
python scripts/sync-cli-commands.py --check
```

**結果**
```
全 .ps1/.sh パースOK
dry-run: WILL OVERWRITE(diverged) / KEPT(.sd003-keep) を正しく一覧
execute: kept は固有化内容保持 / 非kept は上書き＋バックアップ＋報告（復元可）
SYNC CHECK OK (35 commands)
```

**動作確認**
- [x] `.sd003-keep` 記載ファイルが上書きされない（CLAUDE.md/rules を保護できた）
- [x] 非kept の divergence は上書きされバックアップに退避・報告される
- [x] PowerShell と bash で同一挙動
- [x] codex-dispatch が `.agents/skills` に同期（agy frontmatter付与）

---

## 残っていること

**未完了タスク**
- [ ] workflow-impl / agent-review.sh の codex 呼び出しを正準レシピに整合（P1・auto-chainに触れるため未着手）
- [ ] gemini-dispatch の sd003 反映検討（P1・未調査）
- [ ] at002 本体の復旧（別セッション管轄）。復旧後 `.sd003-keep` を配置すると再発防止

**次の手順**
- 次タスク: 上記 P1（workflow-impl 整合 / gemini-dispatch 反映）はユーザー承認後
- 依存関係: なし

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 正直化＋オプトアウト vs 最小正直化のみ vs オプトアウトのみ | 正直化＋オプトアウト | 再発を構造的に防ぐ（dry-run可視化＋.sd003-keep保護） |
| deploy に -DryRun を全mutation guard vs 早期exitスキャン | 早期exitスキャン | 実deployパスに手を入れず低リスク |
| codex-dispatch を rule化 vs skill化 | skill化（+ラッパー） | guardrails over rules。決定論入口を1点に集約 |

**採用しなかった案と理由**
- `git checkout HEAD -- .` での at002 一括復旧: 取り消し困難で「事故」化リスク。本セッションでは at002 に触れず（別セッション管轄）

---

## 追加情報
- 2コミット: 14230fd（sd-upgrade）, 93a6224（codex-dispatch）。両 commit 後 post-commit hook が `.sd/` を HEAD から自動復元（既知ランタイムバグ・hook機能）
- 設計規律: 貼付報告を鵜呑みにせず実機（コード/disk）確認してから着手（root-cause-first）
