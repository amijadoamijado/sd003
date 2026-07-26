# Tasks: lean-deploy-propagation

先頭=変わりやすい判断（ユーザー可視・データモデル）、末尾=差し替え容易。

1. [x] .sd003-profile 形式の確定（D6: key=value プレーンテキスト）
2. [ ] CLAUDE.md.template v2（ユーザー可視の最上位・dangling修正）
3. [ ] deploy.ps1: version bump + scanDirs + rules-reference コピー
4. [ ] deploy.sh: 同上
5. [ ] upgrade.ps1: keep parse + profile parse + lean migration（detect/dry-run/execute）
6. [ ] upgrade.sh: 同上
7. [ ] verify-deployment.mjs: C8 追加
8. [ ] SKILL.md 更新（sd-deploy / sd-upgrade）
9. [ ] 構文検査（PS parser / bash -n / node --check）
10. [ ] ミラー同期（python scripts/sync-cli-commands.py）
11. [ ] 実機 dry-run: deploy→oc001 / upgrade→oc001 / upgrade→at002（keep動作確認）
12. [ ] commit + 結果提示（Artifact）+ ユーザー承認ゲート（--execute は承認後）
