# AI協調ワークフロー（軽量ディスパッチ版）

Session Lead は **入口 CLI に紐づく**（常に Claude 固定ではない）。
Claude Code / Codex（レビュー） / Antigravity（実装・E2E） / Grok（Lead 候補・探索実装・独立検証）の
4AI協調の運用ディレクトリ。
正本ルール: `.claude/rules/workflow/ai-coordination.md`

> **2026-07-05 変更**: 旧「7段階ワークフロー」（WORK_ORDER→IMPLEMENT_REQUEST→REVIEW_REPORT→TEST_REQUEST
> の自動連鎖・6テンプレート）は過剰設計として撤去した。現在は各AIへ軽量CLIディスパッチで直接依頼する
> （書面受け渡しの儀式は不要）。旧テンプレート本体は `_archive/removed-overengineering-20260705/` へ
> 保存済み。`templates/` 配下は廃止notice付きファイルのみ残置（.sd/はmv/rmがハードブロックのため）。
>
> **2026-07-12 変更**: Grok **Lead mode** 正式採用。運用は `GROK_GUIDE.md`、実行は `.grok/GROK_NATIVE.md`。

## 構造

| パス | 用途 |
|------|------|
| `spec/{案件ID}/` | 正式依頼書（案件IDが明示された時のみ・自由形式） |
| `review/{案件ID}/` | 正式報告書（案件IDが明示された時のみ・自由形式） |
| `CODEX_GUIDE.md` | Codex レビュー運用 |
| `GROK_GUIDE.md` | Grok Lead / Assist 運用 |
| `../handoff/handoff-log.json` | AI間引き継ぎログ（記録必須） |
| `../sessions/{ai}/` | AI別セッション記録（antigravity / claude-code / codex / grok） |

## 依頼のかけ方

アドホックな相談・レビュー・実装は会話内で完結する（書面依頼は不要）。

- Codex: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`（公式プラグイン）
- Grok **Lead**: ユーザーが Grok を直接起動（`.grok/GROK_NATIVE.md`）
- Grok **Assist**: `grok-dispatch`（`grok-run.ps1`・非対話・`grok-build`）
- agy: `antigravity.md` の非対話呼び出し

案件IDが明示された正式な依頼・報告のときだけ、上記 `spec/{案件ID}/` `review/{案件ID}/` に保存する。
テンプレートは不要（廃止済み）。内容は案件に応じて自由記述でよい。

## 注意（.sd/ 操作）

このディレクトリ配下のファイル作成・編集は **Bash tool のみ**（Write/Edit はhookで物理ブロック）。
作成したら早めに commit する。詳細: `.claude/rules/git/sd-safe-commit.md`
