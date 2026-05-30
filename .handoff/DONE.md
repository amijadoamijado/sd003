# DONE.md - 2026-05-31 00:42 セッション完了報告

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `D:\claudecode\fl006\` | SD003 展開（421コピー+7生成、CLAUDE.md を .sd003-keep 保護、settings.json 手動完全配線） |
| `D:\claudecode\at002\.claude\hooks\block-edit-write-on-sd.sh` | Layer 3 hook 配備（commit未・ディスク上アクティブ） |
| `D:\claudecode\at002\.claude\settings.json` | Layer 3 ブロック追記（gitignore・ディスク上アクティブ） |
| `.claude\rules\git\sd-safe-commit.md` | L4 実態反映に訂正（9ae3274→956b898） |
| `.claude\skills\sd-deploy\deploy.sh` | settings.json 完全配線生成（9f14984） |
| `.claude\skills\sd-deploy\templates\settings.json.template` | 完全版（9f14984） |

**変更内容の要約**
fl006 へ SD003 を展開（固定デプロイID/URL を保護）。P0 2件（at002 Layer3 配備 / sd-safe-commit 改訂）を完遂。改訂中に「L1+L2+L3 は .sd/ wipe を根絶しておらず、毎 commit で全消失し L4 post-commit auto-restore が実際の防衛線」と実測確定（5-27 結論を訂正）。deploy ツールの settings.json 生成バグ（全ガードレール未配線）を deploy.sh / deploy.ps1 テンプレ両方で根本修正。

---

## 確認結果

**実行したコマンド**
```bash
# deploy.sh 生成ロジックを temp dir で抽出実行 → node 検証
# template と sd003本体 settings.json の hooks 構造 diff
# at002 settings.json JSON 検証
```

**結果**
```
deploy.sh 生成: Stop2 / Pre5 / Post5 / SessionStart1 / Layer3=true / $CLAUDE_PROJECT_DIR リテラル保持
template vs 本体: hooks構造 完全一致
at002: Pre5 / Layer3=true / evaluator・det-runs・enforce-* 全保持 / JSON valid
fl006: settings.json 完全配線、参照15hook 全存在
sd003 .sd/: 42ファイル安定（毎commit wipe → L4復元を確認）
```

**動作確認**
- [x] fl006 deploy ALL PASSED（CLAUDE.md 保護）
- [x] at002 Layer3 ディスク上アクティブ
- [x] deploy.sh / template 完全配線を実行検証
- [x] .sd/ 消失→L4自動復元を実測

---

## 残っていること

**未完了タスク**
- [ ] at002 hook の commit（at002 セッションで `git add .claude/hooks/block-edit-write-on-sd.sh`）
- [ ] fl006 後続（`npm install` + 別リポジトリ commit）
- [ ] 既存デプロイ済みPJ（oc001/at001/er001 等）の settings.json 配線監査
- [ ] deploy.sh(SKIP) vs deploy.ps1(上書き) ポリシー統一
- [ ] L4 post-commit の partial wipe 検知追加

**次の手順**
- 次のタスク: 既存PJ監査 or fl006 後続
- 依存関係: なし

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| fl006 CLAUDE.md 上書き vs 保護 | 保護(.sd003-keep) | 固定デプロイID/URL消失=GAS新URL生成事故リスク |
| at002 settings.json 上書き vs 追記 | 追記 | at002固有 evaluator/det-runs hook を保持 |
| at002 hook commit する vs しない | しない | 作業中変更多数＋自動push設定への巻き込み回避 |
| sd-safe-commit「儀式撤廃」vs「早めcommit維持」 | 維持 | L4はHEAD復元、未commitの.sd/は失われる実測 |

**採用しなかった案と理由**
- deploy で fl006 CLAUDE.md テンプレ再生成: 固定デプロイID損失のため不採用
- 既存全PJ監査の同時実施: ユーザーが「ツール修正のみ」を選択

---

## 追加情報

- **重大発見**: 5-27 の「L1+L2+L3 で .sd/ 消失を構造解決」は誤り。毎 commit で `.sd/` 全消失 → L4（post-commit auto-restore）が HEAD から復元。これが実際の防衛線。memory 訂正済み
- auto-mode classifier はワーキングディレクトリ外（at002）書き込みをユーザー明示承認後に許可
- deploy.ps1 は `Copy-Item -Force` でテンプレ配布のため、テンプレ修正＝完全修正
