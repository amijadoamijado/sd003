# DONE.md - 完了報告

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/hooks/enforce-spec-location.sh` | B17: 裸パス `specs/foo/spec.md` 早期allow漏れ修正 |
| `.claude/hooks/track-skill-read.sh` | B18: python化＋read-skillsログをsession_id採番 |
| `.claude/hooks/enforce-skill-read.sh` | B18: log_path算出をpython内でsession_id採番化 |
| `.claude/hooks/session-skill-suggest.sh` | B18: stdin読込追加・session scope・PY_BIN前倒し |
| `.eslintrc.cjs` | 新設: qa:deploy:safe の Lint gate を実動作させる設定 |
| `.claude/rules/workflow/artifact-output-location.md` | 新設: 成果物のプロジェクト内保存ルール（全AI） |
| `scripts/recover-agy-artifacts.sh` | 新設: agy成果物の非破壊回収スクリプト |
| `antigravity.md` / `.handoff/RULES.md` / `CLAUDE.md` | agy成果物保存場所の明記 |
| `.gitignore` | `materials/_agy-recovered/` 除外 |

**変更内容の要約**
未解決P2課題3件（spec-location裸パス漏れ／eslint gate常時FAILED／skill-readのセッションscope）を実測検証付きで解消。加えてagyが成果物をAppData隠しフォルダに保存する問題をルール化＋回収スクリプトで対策し、迷子の実成果物4件を回収した。

## 確認結果

**実行したコマンド**
```bash
npm run build && npm run lint     # build OK / lint exit 0
node dist/cli/index.js qa:deploy:safe   # ✅ LintValidation passed
# skill-read E2E（隔離HOME・実フック10ケース）→ ALL PASS(10/10)
# spec-location 実JSON13ケース → 全一致
```

**結果**
```
build OK / lint 20file 0error / Syntax・Type・Test・Lint 全PASS
skill-read B18: 10/10 PASS（block→読込→allow・別session隔離・fallback・SessionStart再arm）
spec-location B17: 全ケース期待通り（裸specs/→DENY・.sd/specs/→ALLOW・docs/specs/→DENY）
```

## 残っていること

**未完了タスク**
- [ ] 配信先へ `/sd-upgrade` 反映（skill-read scope／spec-location／agy保存ルール）
- [ ] L1〜L4等の撤去要否ユーザー判断（本セッション推奨=維持）
- [ ] **【次タスク】SD003過剰設定の除去**（Ralph Loop/sd003-loop、context-autonomy、workflow-impl 7段階）→ ユーザー依頼受領・footprint調査から着手

**次の手順**
- 次タスク: 上記3機構の除去（footprint調査→アーカイブ→参照除去→検証）

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| eslint no-explicit-any: error vs GAS境界override | override | GAS境界層のanyはEnv Interface例外。業務ロジックは厳格維持 |
| skill-read: session採番 vs 固定パス維持 | session採番＋対称fallback | 並行session誤block/漏れ解消。fallbackでゼロ回帰 |
| agy物理ブロック vs 規範＋回収 | 規範＋回収 | agyはClaudeのフック外＝物理ブロック不可。回収で担保 |
| L1-L4撤去 vs 維持 | 維持 | mid-session wipe未検証・観測1日で不足・下振れ重大 |

## 追加情報
- 迷子agy成果物は `materials/_agy-recovered/20260705/`（gitignore・非commit）。`603a159f__critique_report.md` は別PJ由来の可能性。
- git-bash/WSL落とし穴: python subprocess['bash']はWSL(System32)を拾う→git-bash明示（メモリ化）。
- commit 294d35f を master へ push済（remote==local・.sd/59無傷）。
