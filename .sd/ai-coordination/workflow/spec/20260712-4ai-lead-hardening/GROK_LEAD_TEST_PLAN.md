# Grok Lead実測計画

実測自体はユーザー参加が必要なため本実装では行わない。

1. 隔離worktreeのrepo直下でGrok TUIを起動する。
2. 冒頭質問で `grok.md` が自動読込済みか確認する。
3. `.grok/GROK_NATIVE.md` のセッション開始チェック遵守を確認する。
4. 結果を `.sessions/TIMELINE.md` に1行記録する。
5. 自動読込されない場合、`GROK_GUIDE.md` のLead開始へ「起動後まずgrok.mdを読ませる」を追記する。
