# Context Injection Map（実測・2026-07-26確定）

どの入口文書がどのCLIに**自動注入**されるかの実測表。
「自動注入されない文書のルールは、注入される文書からの明示ポインタか呼び出し側の指示でしか届かない」——
入口文書（特に AGENTS.md）を書き換えるときは本表で影響範囲を評価してから触る
（2026-07-26 Grokレビュー軽2「注入マップ不在」の恒久対応）。

| CLI | 自動注入されるもの（実測） | 実測日・方法 | 信頼度 |
|-----|--------------------------|-------------|--------|
| Claude Code | ユーザー/親ディレクトリ/プロジェクトの CLAUDE.md 連鎖 + `.claude/rules/*.md`（`paths:`無し=常時全文・有り=条件）+ auto-memory MEMORY.md + スキルmetadata | 2026-07-26 lean化作業で実測（121KB→31KB） | GREEN |
| Grok | AGENTS.md + CLAUDE.md + `.claude/rules/README.md`（grok.md / GROK_NATIVE 全文は自動読込されない） | 2026-07-12 Grok実測（TIMELINE記録） | GREEN |
| agy (Antigravity) | **AGENTS.md のみ**（`<user_rules>` としてシステムレベルで全文注入）+ スキルmetadata（name/description のみ）。CLAUDE.md / antigravity.md / rules README は**注入されない**。加えて system prompt が `brain/<会話ID>/` への成果物保存を強制 | 2026-07-26 ツール使用禁止プロトコルで実測（冒頭行引用を実ファイルと突合済み） | GREEN |
| Codex | **AGENTS.md のみ**（CLAUDE.md / antigravity.md / rules README は注入されない）。保存先の強制既定なし | 2026-07-26 ツール禁止プロトコルで実測（`codex exec` read-only・冒頭行引用を実ファイルと突合済み） | GREEN |

## 含意（設計原則）

1. **AGENTS.md は全CLIに届く唯一の共有面**。CLI固有の最重要上書き（agyのbrain保存禁止等）は
   ポインタではなく**本文1行**でここに置く。ただし肥大化させない（lean原則・現在66行前後）
2. antigravity.md / GROK_NATIVE.md / CODEX_NATIVE.md は「読みに行かせる正本」。
   その導線は AGENTS.md 冒頭の Lead 分岐表
3. Claude Code の hooks（決定論ガードレール）は他CLIには効かない。他CLIを守るのは
   git hooks・回収スクリプト・呼び出し側指示・そして本表に基づく入口文書設計
4. Codex / agy とも自動注入は AGENTS.md 1枚のみ＝**AGENTS.md が非Claude系CLIへの実質唯一の常時チャネル**。
   CLAUDE.md の Conditional Context（IMPORTANT行）は Claude Code と Grok にしか届かない
   （Codex行は exec mode での実測。対話TUIでの差異が疑われたら同プロトコルで再計測）
