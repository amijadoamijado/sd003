# IMPLEMENT_REQUEST: Grok正本・共有入口のlean整合（20260726-grok-doc-alignment）

- 発行: Claude Code（全体構成把握者・指示書作成）
- 実装: **Grok Lead**
- 発端: Grok自身のレビュー（2026-07-26・APPROVE with REQUEST_CHANGES）のP0/P1/P2
- 分担意図: 発見者=Grok → 指示書=Claude → 実装=Grok → 完了報告をClaude/ユーザーが確認

## 1. 背景

2026-07-26のlean化（FRAMEWORK 2.18.0・全12PJ適用済み）で、Grok正本（.grok/）と共有入口（AGENTS.md）の整合が一段遅れた。Grokレビューで3点が確定（Claudeが実物照合で全件裏取り済み）。

## 2. ゴール（ユーザーが見る画面・受け取るもの）

1. `.grok/GROK_SPEC.md` / `.grok/GROK_NATIVE.md` から死んだ `grok-build` の正準指定が消え、`grok-run.ps1` と同一方針（省略=CLI既定）になった状態
2. `AGENTS.md` 冒頭にLead分岐表があり、タイトルがCodex専用に見えない状態
3. `.sessions/session-current.md` / `TIMELINE.md` がHEAD（befd8c7以降）まで反映された状態
4. 上記が commit + push 済みで、完了報告（変更行の要約＋検証結果）が返ること

## 3. 実装内容

### P0: モデル既定の整合（.grok/GROK_SPEC.md / .grok/GROK_NATIVE.md）

正とする方針（`grok-run.ps1` 実装と一致させる）:
> モデル名は固定しない。**省略=CLI既定**。指定が必要なときのみ `-m <model>`、使用前に `grok models` で実在IDを確認する。

- `GROK_SPEC.md` L69-70: 表の `-m grok-build` / `grok-build` 指定 → 「省略（CLI既定）」へ
- `GROK_SPEC.md` L75: 正準invocation例から `-m grok-build` を除去
- `GROK_SPEC.md` L80: 「コーディング特化モデルは `-m grok-build`」→ 「モデル指定は任意。指定時は `grok models` で実在確認（`grok-build` は2026-07-12に unknown model id 化した前例あり）」
- `GROK_NATIVE.md` L87: 同方針で書き換え
- **歴史注記は1箇所だけ残す**（grok-build死亡の教訓＝再発防止知識。全消しすると同じ轍を踏む）

### P1: AGENTS.md の中立化（最小差分・+10行以内）

AGENTS.mdは本日Codexがlean化した成果物（−213行）。**膨らませない・再構成しない**。

1. タイトル `# AGENTS.md — SD003 Codex Entry Point` → `# AGENTS.md — SD003 Shared Entry Point`
2. 冒頭にLead分岐表を1個追加（これが最小の「注入マップ」を兼ねる）:

```markdown
> このファイルは Codex と Grok の両方に常時注入される共有入口。あなたの正本は以下:
>
> | Session Lead | 正本 |
> |---|---|
> | Codex | `.codex/CODEX_NATIVE.md` |
> | Grok | `.grok/GROK_NATIVE.md` |
> | agy (Antigravity) | `antigravity.md` |
> | Claude Code | `CLAUDE.md` |
```

3. 本文の「Codexで常時適用する最小ルール」の文はCodexの意図なので**残す**（言い換え不要）

### P2: セッション記録の鮮度回復

- `.sessions/session-current.md`: Codex保存時点（ac1589e）以降の作業を追記反映:
  lean配布伝播v2.18.0・12/12PJ適用（at002は決定論分離維持で適用）・deploy BOM修正（38bf5b7）・SD002遺物退役（678b267）・verify C2b/C7 keep-aware化（befd8c7）・Grokレビュー対応（本件）
- `.sessions/TIMELINE.md`: 本日分を1〜2行追記
- 既存記載は消さない（追記・更新のみ）。書式は `.sessions/session-template.md` 準拠

## 4. 触ってはいけないもの（違反=即中止）

| 対象 | 理由 |
|------|------|
| `grok-run.ps1` / `.claude/skills/grok-dispatch/` | こちらが「正」。文書側を合わせる方向のみ |
| `deploy.ps1` / `deploy.sh` / `upgrade.*` / `verify-deployment.mjs` | 本日確定・全PJ検証済み。ps1のUTF-8 BOMを剥がさないこと |
| `.claude/hooks/` / `.claude/settings.json` / registry類 | 決定論層 |
| `docs/rules-reference/` / `.claude/rules/` | lean構造の本体 |
| 配布先12プロジェクト（oc001〜at002） | 本指示書はsd003本体のみ。伝播は次回upgradeで自然に届く |
| AGENTS.mdの大規模改稿 | Codexのlean成果を尊重。差分は+10行以内 |

## 5. 検証（実装後にGrok自身が実行・結果を報告に含める）

```bash
grep -rn "grok-build" .grok/          # → 歴史注記の1箇所のみになること
grep -c "Codex Entry Point" AGENTS.md # → 0
python scripts/sync-cli-commands.py --check   # → OK
npm test                              # → 全緑（96+）
```

- commit規約: master直接・短い1行メッセージ・`.sd/`変更（本ファイル配下含む）は早めにcommit
- セッション終了時は `git pull --rebase && git push` まで（Beads運用）

## 6. 完了報告

本ディレクトリに `IMPLEMENTATION_REPORT.md` を作成（変更ファイル・行数・検証4項の結果・逸脱があれば理由）。
