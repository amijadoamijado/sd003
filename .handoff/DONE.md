# DONE.md - claude-gpt GPT-6 Sol／Luna対応（2026-09-23）

## やったこと

| ファイル | 変更内容 |
|---|---|
| C:\Users\a-odajima\Documents\Codex\Tools\claude-gpt\launcher.json | プロキシv0.1.42、主モデル6 Sol、軽量モデル6 Lunaへ変更 |
| C:\Users\a-odajima\Documents\Codex\Tools\claude-gpt\versions\v0.1.42\ | SHA-256照合済みのプロキシを配置 |
| .sessions/session-20260923-193835.md | 今回の引継ぎ記録 |
| .sessions/session-current.md、.sessions/TIMELINE.md、.handoff/DONE.md | 最新の引継ぎと履歴を更新 |

更新前の設定は C:\Users\a-odajima\Documents\Codex\Tools\claude-gpt\launcher.json.pre-gpt6-sol-luna-20260923.bak に保存した。Sonnet／Fableの割当てと通常のclaudeは変更していない。

---

## 確認結果

- プロキシv0.1.42のモデル一覧にgpt-6-solとgpt-6-lunaが登録されている。
- 配布アーカイブのSHA-256はrelease.jsonと一致した。
- claude-gpt --doctorは最終設定（Sol主モデル、Luna軽量モデル）で成功した。
- claude-gpt --smoke-testはSolとLunaでそれぞれ CLAUDE_GPT_OK を返した。Luna試験後は最終設定へバイト単位で復元した。
- SD003の既存のscripts/ai-usage-monitor.pyの未コミット変更には触れていない。

---

## 残っていること

- 長時間の実作業セッションと業務用Skills・Hooks・MCPの連続動作は未検証。
- 前回引継ぎのclaudecode-fyxとpm002の課題は今回現況未確認。詳細は .sessions/session-20260923-093059.md と .sessions/session-20260923-092033.md を参照。

---

## 判断したこと

- 設定変更はversion、model、smallModelの3項目に限定した。
- 新しいclaude-gptセッションから設定を反映する。
- 引継ぎはローカルコミットのみとし、pushは行わない。

---

## 追加情報

- 配布元: https://github.com/raine/claude-code-proxy/releases/tag/v0.1.42
- 詳細記録: .sessions/session-20260923-193835.md
