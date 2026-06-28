# DONE — 引き継ぎ（Codex/Antigravity/Grok 向け）

## このセッションでやったこと（2026-06-28）

1. **Grok CLI を C→D 移行**（`D:\grok`、`GROK_HOME=D:\grok`、`grok 0.2.72`）。Move-Item失敗の真因=ReadOnly/Hidden属性→robocopy /MOVE。
2. **SD003 に Grok を4AI目（汎用）としてフル統合**（commit 7160f0f）。
   - grok-dispatch スキル + `grok-run.ps1`（非対話正準: `--prompt-file ... -m grok-build --output-format plain > out 2> progress`。`text`は無効）
   - ai-coordination 4AI化（Claude/Codex/agy/Grok）+役割分岐+排他
   - sync-cli-commands.py に `.grok/skills` 生成（DISPATCH_EXCLUDE再帰除外 + frontmatter whitelist正規化）
   - `.grok/GROK_SPEC.md`・`grok.md`、全AI共通列挙から Gemini CLI撤去（agy置換済み）+Grok追加、deploy対応
3. **at002 へ /sd-upgrade**（未コミット保留）。固有データ（registry.json会計82件等）hash一致で保全。C1 FAILは既知良性。
4. **agy 非対話ハングの onboarding を antigravity.md に文書化**（commit e768170/d15d725）。原因=排他ロック競合+認証待ち。対処=直列化+事前OAuth/GEMINI_API_KEY。

## 未完了 / 次のステップ
- at002 アップグレードのコミット判断（ユーザー保留中）。
- 他PJへの Grok統合展開（`/sd-upgrade <target>`）は任意。
- `npm run lint` の eslint設定不在は既存問題（別タスク）。

## 重要ルール（全AI共通）
- 一人運用ファースト: master 直接、ブランチ/PR はユーザー指示時のみ。
- agy 非対話: 二重起動回避＋OAuth完了 or GEMINI_API_KEY が前提（`antigravity.md`）。
- Grok 非対話: `GROK_HOME` 必須、`--prompt-file`+`--output-format plain`、stdout=回答/stderr=進捗（`grok.md`/`.grok/GROK_SPEC.md`）。
- 成果物（計画・実装）は最終化前に別AI（Grok/Codex/agy）の独立レビューを通す運用。

## 関連ファイル
- `.claude/skills/grok-dispatch/`、`.grok/GROK_SPEC.md`、`grok.md`、`scripts/sync-cli-commands.py`
- `.claude/rules/workflow/ai-coordination.md`、`antigravity.md`
