# DONE.md - 完了報告（2026-06-14〜15 セッション）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/hooks/claim_evidence_detect.py` | 新規・決定論検出器（因果確信語 present かつ 証拠 absent → warn） |
| `.claude/hooks/claim-evidence-stop.sh` | 新規・Stop hook wrapper（fail-open） |
| `tests/hooks/claim-evidence-detect.test.sh` | 新規・回帰テスト4本（ALL PASS） |
| `.claude/settings.json` | Stop に配線（**gitignore対象＝非commit・live限定**） |
| `docs/troubleshooting/RESOLUTION_LOG.md` | /ai-suspect 結果を追記 |
| `D:\claudecode\at002\*`（別repo・098cb27） | /sd-upgrade で256ファイル最新化＋`.sd003-keep`に registry.json 追加保護 |
| `C:\Users\a-odajima\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | `claude` 関数追記（`--permission-mode acceptEdits` 強制・再帰安全） |

**変更内容の要約**
auto-mode 起動時ON 調査中に「プランモード起動が原因」と確定的に誤断定→ユーザー訂正。これを `/ai-suspect` で起訴し、真因=「証拠＜語りの過信」を5Whyで特定、決定論ガードレール（claim-evidence Stop hook＋検出器＋回帰テスト）を実装・実機検証・commit（ba5f3f9）。並行して at002 へ最新SD003を /sd-upgrade（registry.json 会計82件を保護して無傷・098cb27）。① は pwsh profile に起動フラグ強制の `claude` 関数を配線（最終ON確認はユーザー待ち）。

---

## 確認結果

**実行したコマンド**
```bash
bash tests/hooks/claim-evidence-detect.test.sh   # 回帰4本 ALL PASS
# gate経路を合成transcript(Windowsパス)で実機検証 → 陽性=systemMessage警告 / 陰性=plain approve
claude --version    # 2.1.177 / --permission-mode に acceptEdits 実在を確認
& upgrade.ps1 D:/claudecode/at002 -Execute        # at002最新化
```

**結果**
- claim-evidence: 回帰4本 ALL PASS、gate実機OK、settings.json VALID・Stop 3本配線
- ① auto-mode: グローバル `defaultMode:acceptEdits` は正しい／上書き設定なし／pwsh profile 関数=構文OK・exe実在・再帰安全
- ② at002: working tree CLEAN・.sd/ 116ファイル・registry 会計82件 無傷、C1 FAIL は良性
- commit時 .sd/ wipe発火 → post-commit L4 が59ファイル自動復元（データ損失ゼロ）

**動作確認**
- [x] 回帰テスト ALL PASS／gate 陽性・陰性 実機確認
- [x] at002 upgrade 後 registry 82件・独自hook 生存を実測
- [ ] ① auto-mode の新ウィンドウ起動でのON表示（**ユーザー確認待ち**）

---

## 残っていること

**未完了タスク**
- [ ] ① auto-mode: ユーザーが新 PowerShell で `⏵⏵ accept edits on` を確認（P0）
- [ ] sd003 `bd init` → bd化TODO を正式 issue 化し /ai-suspect incident を close（P1・現状 OPEN）
- [ ] claim-evidence ガードレールを deploy テンプレ `settings.json.template` へ展開（P1・他PJ propagation）
- [ ] Windows PowerShell 5.1 も使う場合は 5.1 profile にも `claude` 関数追記（P2）

**次の手順**
- 次のタスク: ①の確認結果を受けて（NGなら起動方法を再診断）→ bd init とテンプレ展開
- 依存関係: ①確認は新ターミナル起動が必要

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| ① の恒久固定策 | pwsh profile の起動フラグ強制 | 真因（起動方法）が観測不能でも確実に効く |
| ガードレール機構 | Stop hook（fail-open warn）＋回帰テスト | 経路上・決定論AND・低FP。block は重ゲート自壊(0526)回避 |
| at002 registry.json | `.sd003-keep` で保護してから execute | 会計82件の登録消失を防ぐ（データ損失ゼロ） |
| at002 C1 FAIL | 直さない | 独自settings.json保護の良性結果。直す=証拠追跡破壊 |

**採用しなかった案と理由**
- at002 settings.json を FW標準で上書き（C1を通す）: at002 の証拠追跡hook を破壊するため不採用
- claim-evidence を at002版から流用: 別設計（構造化CLAIM_EVIDENCEブロック）と判明→sd003独自実装

---

## 追加情報
- **前セッションDONE.mdの「auto modeは次回起動から全PJ有効」は誤り**だった。グローバル `defaultMode:acceptEdits` は新規セッションのシード値で、`--continue`/起動フラグに上書きされ起動時に効かない。→ pwsh profile の `--permission-mode acceptEdits` 強制で対処。
- sd003 `.claude/settings.json` は `.gitignore:62` 対象。Stop hook 配線は live のみ（commit/deploy に乗らない）。
- 自己適用: 本セッションの主張は回帰テスト出力・実機ログ・`settings.json:8` 等の証拠付き。観測不能な「起動方法」は推測のまま据え置き。

---
