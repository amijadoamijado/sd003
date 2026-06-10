# DONE.md - 完了報告（2026-06-10 16:40 セッション）

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `D:\claudecode\at002\`（コミット 8c57d7d） | /sd-upgrade展開: FW v3.2.0更新（266ファイル）。.sd003-keep新規（固有5ファイル保護）、.gitignoreにupgrade-backup除外追加 |
| `D:\claudecode\nm002\`（コミット 42e9b38, a56174c） | blatゴミ803個削除 → 06-07未コミット分＋今日のv3.2.0更新を統合コミット（383ファイル）＋verify-deployment.mjs追加 |
| `nm002/.claude/hooks/scan-utf8-replacement.sh` | バグ修正: stdin modeでallowlist完全バイパス → `--stdin-path <path>` モード追加 |
| `nm002/.git/hooks/pre-commit` | scanner呼び出しに `--stdin-path "$f"` を渡すよう修正（git管理外） |
| `nm002/.claude/hooks/utf8-replacement-allow.txt` | `scripts/verify-deployment.mjs` を許可登録（U+FFFDはC5文字化け検出プローブ＝意図的） |

**変更内容の要約**
前回P1の配信先展開を at002 / nm002 に絞って完遂。sd003本体のコード変更なし。
両ターゲットとも dry-run→keep仕分け→execute→verify-deployment.mjs（C1〜C6）全PASS。

---

## 確認結果

**実行したコマンド**
```bash
bash .claude/skills/sd-upgrade/upgrade.sh <target>            # dry-run
bash .claude/skills/sd-upgrade/upgrade.sh <target> --execute
node scripts/verify-deployment.mjs <target>
```

**結果**
- at002: ALL PASSED（430コピー+7生成、kept 5、C1〜C6全PASS、17 hooks配線健全）
- nm002: ALL PASSED（kept 1=CLAUDE.md、C1〜C6全PASS、.sd/ 592ファイル健在＝wipeなし）
- hookバグ修正: 単体テスト4ケース全PASS（許可通過/非許可ブロック/クリーン通過/旧モード互換）＋実コミット通過で実証

---

## 残っていること

**未完了タスク**
- [ ] **P0: C:ドライブ危機**（空き約1GB）。真因=Claude Desktop `vm_bundles` 12.5GB。F:退避はDesktop終了が必要（手順: auto-memory `project_c_drive_vm_bundles.md`）
- [ ] P1: 残り配信先（oc001/fw5yp/sb001/er001等）への /sd-upgrade（**C:空き確保後**）
- [ ] nm002のproduct差分3件（dist/tar.gz・docs 2件）はnm002側の業務判断待ちで未コミット
- [ ] P2: deploy共通化Stage1（generate-framework-files.mjs）/ メモリ逼迫恒久対策

**次の手順**
- 次のタスク: vm_bundles退避（ユーザー操作）→ 残り配信先展開
- 依存関係: 配信先展開はC:空き確保が前提（at002で「No space left on device」失敗実績）

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| at002固有化の扱い: keep-all vs 選択keep | 選択keep（5ファイル） | 差分行数で客観判定（CLAUDE.md 298行差=固有、rules 4-10行差=古いFW）。FW修正を確実に届けつつ06-10成果を温存 |
| nm002の順序: 即upgrade vs 掃除→過去分→今日分 | 掃除→統合コミット | 差分の混濁回避。blat汚染801個と06-07未コミット分の存在をgit statusで先に発見 |
| U+FFFDブロック対応: ファイル除外 vs hook修正 | hook修正（root-cause-first） | 除外は回避策（ユーザー拒否）。stdin modeのallowlistバイパスが真のバグ |

**採用しなかった案と理由**
- 全配信先一括展開: ユーザー指定でat002/nm002に限定。残りはC:空き確保後
- ごみ箱クリア: ユーザー未承認の不可逆削除のため見送り（permission denied妥当）

---

## 追加情報

- verify-deployment.mjs の `'�'` リテラル（281行目付近）は**意図的**（C5文字化け検出プローブ）。修正禁止。U+FFFDスキャナを持つ配信先ではallowlist登録が正解
- C:満杯（0GB）時は `head` 等の基本コマンドも失敗する。upgrade.shはD:対象でもC:のTEMP書き込みで死ぬ
- auto-memory 2件新規: `project_c_drive_vm_bundles.md` / `reference_verify_deployment_ufffd.md`

---
