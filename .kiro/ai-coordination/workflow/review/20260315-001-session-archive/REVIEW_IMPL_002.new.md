# REVIEW_IMPL_002

## Findings

1. High: [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L72](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L72) and [C:\Users\a-odajima\shared-skills\gemini-dispatch\SKILL.md#L51](/C:/Users/a-odajima/shared-skills/gemini-dispatch/SKILL.md#L51) instruct `git checkout -- .kiro/` unconditionally after AI execution. Step 2 only warns on dirty state, but Step 4/`.kiro/` recovery will discard any pre-existing uncommitted spec, review, or session notes under `.kiro/`. Because the same `workflow-impl.md` hash is deployed to `sd003/oc001/at001/td001/ta001/cf001/ck001`, this destructive behavior is replicated across all seven projects. Recovery needs to be diff-based or stash/restore-based, not blanket checkout.

2. Medium: [C:\Users\a-odajima\shared-skills\sync-skills.ps1#L82](/C:/Users/a-odajima/shared-skills/sync-skills.ps1#L82) creates Junctions, but stale cleanup at [C:\Users\a-odajima\shared-skills\sync-skills.ps1#L117](/C:/Users/a-odajima/shared-skills/sync-skills.ps1#L117) removes only `SymbolicLink`. When a shared skill is deleted from `~/shared-skills`, the old Junction remains in `~/.claude/skills` and `~/.codex/skills`, so the sync result becomes inaccurate over time.

3. Medium: [D:\claudecode\sd003\.git\hooks\post-commit#L19](/D:/claudecode/sd003/.git/hooks/post-commit#L19) pushes every successful commit to `origin/$BRANCH` with no branch allowlist, no opt-out switch, and no pre-push review gate. That makes accidental secret commits or WIP commits leave the machine immediately. The same hook hash is deployed to `sd003`, `oc001`, and `cf001`, so the blast radius is three repositories.

4. Medium: [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L31](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L31) documents only file existence as a precondition, but Step 3 directly calls `gemini` or `codex` without checking CLI availability. Likewise [D:\claudecode\sd003\.claude\commands\sessionread.md#L116](/D:/claudecode/sd003/.claude/commands/sessionread.md#L116) always starts a background `bash ~/.claude/scripts/archive-sessions.sh 7 preview`. In environments where `codex`, `gemini`, or `bash` are absent, the workflow fails late and noisily instead of falling back or emitting a guided error.

5. Low: [C:\Users\a-odajima\.claude\scripts\archive-sessions.sh#L9](/C:/Users/a-odajima/.claude/scripts/archive-sessions.sh#L9) hard-codes `G:/マイドライブ/claude-sessions-archive`. This is workable for one machine, but it breaks portability for the shared skill and makes testing on another account or Drive mount layout unnecessarily brittle.

## 前提確認

- `.handoff/AGENTS.md` が要求する `npm run build` / `npm test` / `npm run lint` の成功記録は提示されていない。
- 今回の対象は主にシェル、PowerShell、Markdown 定義であり、実行系の品質ゲートは未確認のままレビューした。
- 対象ファイルは全件読了した。展開済みコピーはハッシュで整合性を確認した。
  - `sessionread.md`: `sd003/oc001/at001/td001/ta001/cf001/ck001` で同一
  - `workflow-impl.md`: `sd003/oc001/at001/td001/ta001/cf001/ck001` で同一
  - `post-commit`: `sd003/oc001/cf001` で同一

## 段1: 仕様整合性

### 逸脱の可能性

- High: [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L72](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L72) の `.kiro/` 一括復元は、「AIが壊した `.kiro/` を戻す」という目的は満たす一方で、既存の未コミット作業まで破棄する。AI協調ワークフローの監査証跡を守る設計と衝突している。
- Medium: [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L31](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L31) の前提条件が `IMPLEMENT_REQUEST` 存在確認のみで、レビュー観点に明示された「CLI未導入環境」の扱いが仕様に落ちていない。
- Low: [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L121](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L121) の完了報告テンプレートが `--codex` 実行時でも「Gemini実装 → Codexレビュー完了」と固定されており、`--codex` 拡張の設計意図と表示が一致していない。

### 破壊的変更

- ある
- [D:\claudecode\sd003\.claude\commands\workflow-impl.md#L76](/D:/claudecode/sd003/.claude/commands/workflow-impl.md#L76): `git checkout -- .kiro/` により、実装前から存在した未コミットの `.kiro/` 変更も失われる。
- [D:\claudecode\sd003\.git\hooks\post-commit#L20](/D:/claudecode/sd003/.git/hooks/post-commit#L20): すべてのコミットが即 push 対象になるため、従来の「commit と push を分ける」運用は破壊される。

### 読むべき関連ファイル

- [D:\claudecode\sd003\.kiro\ai-coordination\workflow\spec\20260315-001-session-archive\IMPLEMENT_REQUEST_001.md](/D:/claudecode/sd003/.kiro/ai-coordination/workflow/spec/20260315-001-session-archive/IMPLEMENT_REQUEST_001.md): レビュー観点と展開範囲
- [C:\Users\a-odajima\shared-skills\codex-dispatch\SKILL.md#L63](/C:/Users/a-odajima/shared-skills/codex-dispatch/SKILL.md#L63): Codex 連携の既存導線
- [C:\Users\a-odajima\shared-skills\gemini-dispatch\SKILL.md#L51](/C:/Users/a-odajima/shared-skills/gemini-dispatch/SKILL.md#L51): `.kiro/` 復元方針

### 追加で必要な情報

- `post-commit` 自動 push を全員強制にしたいのか、個人 opt-in にしたいのか
- `.kiro/` に手動作業が残っている状態で `/workflow:impl` を走らせる運用を許容するか

## 段2: 正しさと境界条件

### バグ候補

| 重大度 | 場所 | 問題 | 再現手順 |
|--------|------|------|----------|
| High | `workflow-impl.md:72-77`, `gemini-dispatch/SKILL.md:51-57` | `.kiro/` 復元が未コミット変更まで巻き戻す。 | `.kiro/` 配下を手修正したまま `/workflow:impl ...` または Gemini dispatch を実行する。 |
| Medium | `sync-skills.ps1:112-125` | stale skill cleanup が Junction を削除しない。 | `~/shared-skills` から任意スキルを削除して `sync-skills.ps1` を実行し、`~/.claude/skills` の古い Junction が残ることを確認する。 |
| Medium | `workflow-impl.md:53-69`, `sessionread.md:116-120` | `codex` / `gemini` / `bash` 未導入時の前提チェックがなく、失敗が後段まで遅延する。 | CLI 未導入環境で `/workflow:impl ... --codex` または `/sessionread` を実行する。 |
| Low | `archive-sessions.sh:9` | アーカイブ先が固定値で、別端末・別アカウントでそのまま使えない。 | Drive 文字やフォルダ名が異なる環境で `archive-sessions.sh` を実行する。 |

### 修正案

- `workflow-impl.md` / `gemini-dispatch`:
  - 実行前に `git diff --name-only -- .kiro/` を保存し、AI実行後は AI が触ったファイルだけ戻す。
  - もしくは `.kiro/` だけ別 stash を作成して、実行後に `git stash pop` で戻す。
- `sync-skills.ps1`:
  - cleanup 条件を `SymbolicLink` と `Junction` の両方に広げる。
  - 可能なら stale link 削除前に target が `SharedRoot` 配下かも確認する。
- `workflow-impl.md` / `sessionread.md`:
  - Step 0 で `command -v gemini`, `command -v codex`, `command -v bash` を確認し、未導入なら代替案と導入手順を返す。
- `archive-sessions.sh`:
  - `DEST="${CLAUDE_SESSION_ARCHIVE_DEST:-...}"` のように環境変数で上書き可能にする。

## 段3: セキュリティと運用

### 危険箇所

| 重大度 | 場所 | 問題 | 軽減策 |
|--------|------|------|--------|
| High | `workflow-impl.md:76`, `gemini-dispatch/SKILL.md:56` | `.kiro/` 監査証跡をまとめて巻き戻せる。 | `git checkout -- .kiro/` を禁止し、差分限定復元に変更する。 |
| Medium | `post-commit:19-27` | レビュー前・秘密情報確認前に自動 push される。 | `AUTO_PUSH=1` のときだけ有効化、または protected branch/denylist を追加する。 |
| Medium | `archive-sessions.sh:9` | Google Drive パスがユーザー環境に固定されている。 | 環境変数・設定ファイル化し、存在と書き込み権限を事前検証する。 |
| Medium | `workflow-impl.md:55-65`, `codex-dispatch/SKILL.md:25-27` | 非対話実行を前提とするが、実行前の承認や dry-run 入口が弱い。 | 実行前に対象ファイル一覧と dirty state を明示し、`--force` 相当でのみ進める。 |

### ログ・権限の観点

- `handoff-log.json` 連携先は定義されているが、`workflow-impl.md` 自体には「失敗時」ログの規約がない。成功時だけでなく失敗時も記録しないと運用上の追跡が欠ける。
- `post-commit` は push 失敗を表示するだけで、次回 commit まで再試行されない。ネットワーク断時にローカルだけ進んでいる状態を見落としやすい。
- `sessionread` のバックグラウンド preview は UX 上有効だが、毎回実行されるためエラー常態化時に通知ノイズ源になる。

## 段4: 品質

### リファクタ提案

- `codex-dispatch` と `gemini-dispatch` は「単一タスク実行」「IMPLEMENT_REQUEST 実行」「結果回収」の骨格がほぼ同じ。共通 front matter と共通実行テンプレートを持つ `ai-dispatch` に寄せ、AI 固有差分だけを分岐させると保守コストが下がる。
- `/workflow:impl` の AI 選択は手動フラグだけでなく、`IMPLEMENT_REQUEST` の規模や変更ファイル数を見て推奨 AI を表示すると運用ミスが減る。
- shared-skills は `SKILL.md` の front matter 妥当性、リンク整合性、stale Junction cleanup を検証する小さな CI もしくはローカル自己診断コマンドを持たせるべき。

### 追加テスト案

- `sync-skills.ps1`: 削除済みスキルの Junction が cleanup されること
- `workflow-impl`: `.kiro/` に未コミット変更がある状態で安全に実行・復元できること
- `workflow-impl`: `codex` 未導入時に明示的なエラーと代替案を返すこと
- `workflow-impl`: `gemini` 未導入時に `--codex` 推奨へフォールバックすること
- `post-commit`: `AUTO_PUSH=0` などの抑止スイッチが効くこと
- `archive-sessions.sh`: `CLAUDE_SESSION_ARCHIVE_DEST` 上書き時に指定先へ書き込まれること

## レビューまとめ

| 重大度 | 件数 |
|--------|------|
| Critical | 0 |
| High | 1 |
| Medium | 3 |
| Low | 1 |

## 推奨アクション

- [ ] `git checkout -- .kiro/` を差し替えるまで `workflow-impl` / `gemini-dispatch` の運用を限定する
- [ ] `sync-skills.ps1` の stale Junction cleanup を修正する
- [ ] `post-commit` を opt-in 化するか、少なくとも branch/secret ガードを追加する
- [ ] `codex` / `gemini` / `bash` の前提チェックを追加する

## 追加テスト案

- `.kiro/` 変更保持テスト
- stale Junction cleanup テスト
- CLI 未導入時のエラーハンドリングテスト
- 自動 push 抑止条件テスト

## Task Completion Report

### Summary
セッション管理、共有スキル、AI協調ワークフロー、展開済みコピーを含めてレビューした。最大の問題は `.kiro/` の一括 `git checkout` により既存の運用記録を消し得る点で、これが 7 プロジェクトへ横展開されている。ほかに stale Junction cleanup 不備、自動 push の安全弁不足、CLI 未導入時の前提チェック不足を確認した。

### Changes Made
| File | Action | Description |
|------|--------|-------------|
| `.kiro/ai-coordination/workflow/review/20260315-001-session-archive/REVIEW_IMPL_002.md` | Update | 本日の全作業レビュー結果を記録 |
| `.kiro/ai-coordination/handoff/handoff-log.json` | Update | REVIEW_IMPL_002 の完了ログを追記 |

### Verification Commands
`Get-Content -Raw <target file>`
`Get-FileHash -Algorithm SHA256 <deployed copies>`

### Next Steps
- [ ] `.kiro/` 復元方式を差分限定または stash ベースに置換
- [ ] `sync-skills.ps1` の stale Junction cleanup を修正
- [ ] 自動 push の opt-in / branch guard を設計
