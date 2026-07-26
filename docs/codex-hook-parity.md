# Claude Code / Codex hook差分

監査日: 2026-07-26

## 結論

Claude Codeは4イベント・複数hookを使う。Codexは`.codex/hooks.json`から`scripts/orchestrator-guard.js`をPreToolUseで1本だけ呼ぶ。完全互換ではないため、次の原則で分担する。

1. CLIをまたいで必須の決定論防御は共有Node guardまたはGit hookへ置く。
2. Claude Code固有のUX補助・警告はClaude hookに残す。
3. Codex側で機械強制できない重要事項だけを短く`AGENTS.md`へ残す。
4. hookが存在するだけで有効と判断せず、参照スクリプトの配布と実機probeを検証する。

## 機能差

| 防御・補助 | Claude Code | Codex | 判定・対応 |
|---|---|---|---|
| 危険なGit操作、広域stage、`.sd`破壊 | 共有guard＋Claude shell hook | 共有guardのshell経路 | 共有guardを正本化。AGENTSにも短文を残す |
| GAS deployment作成・削除 | 共有guard＋専用hook | 共有guard | ユーザー承認をhookだけでは判定できないためAGENTSにも残す |
| `.sd`へのWrite/Edit制限 | Claude専用hook | 専用hookなし | `.sd`変更後の早期commitをAGENTSに残す |
| `.sd`消失検知・復元 | PostToolUse watchdog＋Git hook | Git hookのみ | mid-session差を許容し、Git hookと早期commitを共通防御にする |
| protected dirへの一時物作成防止 | Claude専用hook | なし | Claude固有。再発時だけ共有化を検討 |
| commit前テスト | Claude専用hook | なし | 必須化するならGit hookまたはCIへ移す |
| 正式Workflow gate・state追跡 | Claude専用hook | なし | 案件ID routingをAGENTS/CODEX_NATIVEに保持 |
| spec配置 | Claude専用hook | なし | 保存先規則をAGENTS/CODEX_SPECに保持 |
| Skill必読・読取追跡 | Claude専用hook | Codex標準Skill trigger | 各SkillのdescriptionとSkill指示を正本にする |
| GAS編集後の反映状態追跡 | Claude PostToolUse/Stop | なし | GAS承認規則だけをAGENTSに保持 |
| deploy package更新忘れ | Claude reminder | なし | deployment verifierで検出する |
| 証拠のない原因断定 | Claude Stop warning | なし | 根拠と未検証事項を分ける原則をAGENTSに保持 |
| commit後の外部AIレビュー | Claude運用hook | 該当なし | CIまたは明示レビューへ分離 |

## 発見した配布不具合

`.codex/hooks.json`は`scripts/orchestrator-guard.js`を参照する。しかし従来のsd-deployは`.codex`を配布する一方、参照先Node scriptを配布対象に含めていなかった。

監査時点で複数の展開先に同じhooks設定だけが存在し、guard scriptが欠落していた。設定ファイルの存在確認だけでは防御成立の証拠にならない。

必要な修正:

- sd-deployで`scripts/orchestrator-guard.js`を単体配布する。
- deployment verifierで`.codex/hooks.json`と参照scriptの両方を検証する。
- 配布先で安全なdeny/allow probeを実行する。

## 共有guardの既知制約

- shell文字列の正規表現判定なので、禁止語を検索する読取コマンドを誤検知しうる。
- PowerShell、Gitのglobal option、別名引数など一部表記を見逃す。
- patch系toolはshell commandとpayload構造が異なり、`.sd`保護を同じ方法では保証できない。
- worktreeでproject hookが読まれない環境差を前提にし、hookだけへ依存しない。

改善は、tool名ごとにpayloadを構造化して判定し、読取専用検索を除外し、別表記の回帰ケースを追加する順で行う。

## AGENTSへ残す安全事項

1. 未コミット変更を戻さず、破壊的Git操作・広域stage・ユーザーファイル削除をしない。
2. GASの通常反映はpush操作だけとし、deployment変更はユーザー明示指示時だけ行う。
3. `.sd`を破壊せず、変更後は早めに明示パスでcommitする。
4. 正式spec・AI協調文書は規定ディレクトリへ置く。
5. 結論は検証根拠と未検証事項を区別する。

## 検証

```powershell
npx jest --runInBand tests/integration/orchestrator-guard.test.ts tests/deploy/verify-deployment.test.ts
python scripts/sync-cli-commands.py --check
```

Codex hookの実機probeでは、安全なテスト入力に対してdeny応答が返ることを確認する。配布先では参照scriptの実在確認も必須とする。
