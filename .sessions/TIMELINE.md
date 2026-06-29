# SD003 Project Timeline

## Statistics
- **Total Sessions**: 105
- **Latest Session**: 2026-06-30
- **Project Start**: 2026-02-15

---

## 2026-06

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| 06-30 | **外部プラグイン `nam-tech-studio/toolcall-recover` の検証**（X投稿紹介のサードパーティ Claude Code プラグイン「検証して」依頼。実在性/機能整合/セキュリティ/手順/動作確認の5観点）。①実在性✅: `gh repo view`=MIT/Shell/★16/作成06-22/public。X投稿のインストール手順は README・plugin.json・marketplace.json と完全一致。②中身(scratchpad浅クローンで静的レビュー)=hook 1本(detect-toolcall-leak.sh)+skill 2本(run-toolcall-recover/improve)+hooks.json(Stop/SubagentStop登録)+テスト1本。機能=ツール結果文字化けで生のツール呼び出しマークアップ(invoke/parameterタグ・壊れ前置トークン`court`)が地の文へ漏れる崩壊を hook が検知→`block`再生成強制(撤退なし)。説明と実体一致。③**セキュリティ✅危険なし**: hook は transcript読込→jq/grep/sed→JSON判定のみ。通信/書込/eval/base64/curl/破壊/難読化すべて無し、jq不在時fail open。skillもプラグイン配下限定編集明記・持ち出しなし。④**回帰テスト実走(ユーザー`!`実行)=pass=3 fail=3**だが**全行`jq: command not found`＝この環境にjq無しが単一原因**(失敗3=expect=blockがjq無しでテストデータ生成不可+hook自身fail open、PASS3=expect=noneが成立しただけ)→検知正否は判定不能。`Get-Command jq`でPATH不在確定(winget未導入)。⑤**結論=安全に導入可だが jq 未導入だと fail open で完全無動作＝事実上 jq が前提**。誤検知=タグを地の文(フェンス外)で書くとブロック(README明記の既知限界)。auto-mode classifierが外部スクリプト実行を会話承認とは別に2回ブロック→`!`手元実行で回避(迂回せず) | (SD003本体変更なし・検証のみ) | [Details](session-20260630-073603.md) |
| 06-28 | **Grok CLI を C→D 移行＋SD003へ4AI目(汎用)としてフル統合＋at002アップグレード**。①移行: `.grok`をC→D、`Move-Item`がReadOnly(git pack)/Hidden(.git)属性で失敗→`robocopy /MOVE`で解決、GROK_HOME未設定での`--version`がCパス再生成する副作用も特定・除去。②統合(7160f0f/180file): **「grok build」はサブコマンドでなく`grok-build`モデル**・非対話正準=`--prompt-file ... --output-format plain > out 2> progress`(`text`は無効と実測)・codexの`-o`相当なし。grok-dispatchスキル+grok-run.ps1、ai-coordination 4AI化+役割分岐+排他、sync-cli-commands.pyに`.grok/skills`生成(DISPATCH_EXCLUDE再帰除外+frontmatter whitelist正規化`_rewrite_skill_md_for_grok`)、`.grok/GROK_SPEC.md`+grok.md、全AI共通9file+RULES+ORDERからGemini CLI撤去(agy置換済)+Grok追加、deploy対応。**Grok自身に計画+実装をレビューさせ致命バグ2件修正**(grok-run.ps1のexit code無視→`$rc -eq 0`必須/blacklist除去→whitelist化・62件YAML検証OK)。③at002 `/sd-upgrade`: 32 divergence全件精査(RESOLUTION_LOGは包含で損失なし等)→execute、registry.json会計82件/CLAUDE.md/settings.json hash一致で保全、C1 FAILは既知良性、**未コミット保留**(指示)。④agy 2回レビュー(PASSED)反映: 非対話ハング原因2系統(排他ロック競合+認証待ち)+直列化前提をantigravity.mdに文書化(e768170/d15d725) | 7160f0f, e768170, d15d725 | [Details](session-20260628-202337.md) |
| 06-25 | **一人運用ファーストのブランチ運用ルール制定＋at002のPRベース運用廃止**。ユーザー「基本一人でブランチ管理が大変→大改修等限られたときだけ」を受領。根本原因=AIの「作業前にとりあえずブランチを切る」ハーネスデフォルト。強制レベルをAskで確認→**軽量(ルールのみ)**採用(hook物理ブロックは一人運用で過剰)。新規`branch-strategy.md`+CLAUDE.md/配信テンプレ/RULES.md追記、`copy_dir_tree`で全PJ自動伝播確認(6bd9296)。**at002展開で矛盾検出**: 固有`pr-based-workflow.md`(Issue#8/PR#20-31・master直push禁止・CodeRabbit/Codex自動レビュー必須)と正面衝突→黙って上書きせずAsk→ユーザー「PR運用やめさせる」→at002も一人運用統一(旧ルール退役・宙吊り参照2箇所修正・9ef4514 push)。**ブランチ保護は存在せず**(gh api 403=private/Pro限定)＝旧master直push禁止はルールのみの運用と判明。追加指示「PR必要なときは指示する」で二条件→**一条件(指示時のみ作成)**へ簡素化(sd003 c702d0b/at002 10d83c6 push)。memory更新 | 6bd9296, c702d0b | [Details](session-20260625-193730.md) |
| 06-24 | **cf001へSD003アップグレード（v2.13.0時代→v3.2.0）完遂**。「cf001に対して/sd-upgrade」指示→dry-run（bash版・Bypassブロック回避）でdivergence60件検出→er001/at002の教訓で全件精査→**固有化ゼロ判定**（CLAUDE.md=SD002 v2.10.0未記入テンプレ・/kiro:参照/settings.json=sd002-stop-hook旧版/60件=v2.4時代旧FW版・440行差/git履歴=FW同期のみ/**registry.json=source完全一致で会計レジストリ損失リスクなし**）→`.sd003-keep`不要。**想定外: 未コミット287件**（BOM/mojibake修正WIP）発見→ユーザー確認でチェックポイントcommit(24ef3aa)保全→execute。60上書き+307新規、内容検証**ALL PASSED**、agy63スキル、退役物削除（.gemini/.cursor/.windsurf/.agent/GEMINI.md等）全バックアップ退避、会計カスタム(excel-com-required/bugyou-yayoi-conversion/tax-payment.md)温存、cf001 ae2f71e→**origin push同期確認**(branch feature/data-update-2603)。skill-checkが`bugyou`文字列に誤反応ブロック→トリガー語回避で再検証 | (cf001側)ae2f71e | [Details](session-20260624-195215.md) |
| 06-17 | **er001へSD003アップグレード（v3.1.0→v3.2.0）完遂**。「展開して」指示→現状確認で**既にv3.1.0展開済み**と判明→新規deployでなく`/sd-upgrade`を選択。dry-runでdivergence36件検出→at002 registry.json損失の教訓で全件精査→**固有化ゼロ判定**（CLAUDE.md=テンプレ生成版/settings.json=旧版＝版差/残34件=旧FW版・ss001同型）→`.sd003-keep`不要でexecute。435コピー+7生成、退役物削除（.gemini/.cursor/.windsurf/.agent/GEMINI.md+claude-memスタブ9件）を全てバックアップ退避、内容検証**C1-C6 ALL PASS**、agy63スキル、er001コミット5eb62a9。**`-ExecutionPolicy Bypass`をclassifierがブロック→回避せず公式bash版upgrade.shで完走**。**事前説明訂正**: 「sd003-stop-hookが消える」は誤り＝現行テンプレ標準で維持（ralph-loop現役）。`/archive-sessions --execute`で5件/5MB（PC002/at002/sd003）をGDrive退避・index47件再生成 | (er001側)5eb62a9 | [Details](session-20260617-080330.md) |
| 06-15 | **z.ai GLM運用構成の検証・修正**（5.2メイン+4.7背景+deny封印+ToolSearch無効）。**deny の local 上書き問題を発見・修正**: 新セッションで`TaskCreate`が実際に成功(文字化けタスク事故)→グローバル`deny:[Agent,Task]`が PJ local の`deny:[]`に上書きされ無効と確定→sd003 local に`deny:["Agent","Task"]`追記→新セッションでAgent/Task呼ばずBash直フォールバック・`/sessionread`正常完走を実証。**alwaysThinkingEnabled:false で思考暴走対策**(glm-5.2[1m] think強制ON=11分26秒→OFF=6分0秒に半減・残6分はモデル自体の遅さ=モデル更新待ちでユーザー解決扱い)。**auto mode classifierが「ユーザー選択≠実施承認」を検出しグローバル設定変更をブロック**(前回/ai-suspect真因と同根・正しい安全装置として受領→明示的go後に実施)。① auto-mode `⏵⏵ accept edits on`確認OKで前回P0クローズ。知見3件をfeedback_glm_zai_model_selection.mdへ焼込 | (gitignore対象・非commit) | [Details](session-20260615-201212.md) |
| 06-15 | **`/ai-suspect`で自分の捏造を起訴→決定論ガードレール化**（auto-mode自動ON調査中に「このセッションはプランモードで起動された」と**確定的に誤断定→ユーザー訂正**。5Why真因=証拠＜語りの過信＝優先順位の逆転（結論先行→proxy権威化→観測不能を「確定」で埋め→反証=auto mode classifier稼働を不開示）。claim-evidence Stop hook+二条件AND検出器+回帰テスト4本**ALL PASS**を実装・gate実機検証・settings.json配線・RESOLUTION_LOG記録、ba5f3f9。sd003 bd未初期化→bd化TODOで記録・incident **OPEN**。配線はgitignore対象でlive限定=テンプレ展開がP1）。**① auto-mode**: グローバルsettings.json `defaultMode:acceptEdits` 自体は正しい、真因は起動方法(`--continue`/フラグ優先・観測不能)。Claude 2.1.177で`--permission-mode acceptEdits`有効確認→pwsh profileに**再帰安全な**`claude`関数配線(構文/exe/再帰を実機検証)、新窓ON確認はユーザー待ち。**② at002 /sd-upgrade**: dry-runで**registry.json(会計82件)損失リスク発見**→.sd003-keep保護追加→execute。256更新・廃止物0・固有資産(registry82/独自settings.json/4hook)無傷、C1 FAILは独自settings.json保護の**良性**と特定、098cb27 | ba5f3f9, 098cb27 | [Details](session-20260615-025531.md) |
| 06-14 | **`/ai-suspect`コマンド新規作成**（AI挙動不審=捏造/過信/ルール不遵守を証拠ベース5Why→真因→決定論ガードレール+bd issue登録で強制クローズ。手動のみ・3点ゲート柱4・模範5Why(at002 0613)埋込・bd未初期化フォールバック。syncで.sd/.agents/.codexミラー生成）。**commit時.sd/ wipe事故→git show復元でクリーン復旧**（git add -Aが.sd/58ファイルwipeをステージ→全削除コミット→`git show e2b2cfb:path>path`で復元+sync再生成・データ損失ゼロ。git checkoutはguardrailで不可）。**at002 bd棚卸し: 完了済5件close**(3c0.3/3c0.6/b4o/qfe/12l・各証拠付・open62→57)+登録待ち3ゲート(3c0.1/3c0.2/Claim-Evidence)のsettings.jsonスニペット作成→at002 materials/text/保存。グローバルsettings.jsonにauto-accept edits既定化。archive 6件(4MB)→GDrive | b810931, 90d0df6 | [Details](session-20260614-094708.md) |
| 06-11 | **fl006へ/sd-upgrade展開完遂（v3.2.0）**。廃止物3件削除（.gemini/GEMINI.md/gemini.md）+FW 26ファイル更新+CLAUDE.md保護+verify C1-6全PASS（db3cd41）。powershell→pwsh切替でGet-FileHashエラー回避。**at002セッションアーカイブ1件(4MB)→Google Drive移動**（インデックス30件更新） | (fl006側) | [Details](session-20260611-141727.md) |
| 06-10 | **L4 wipe防御をスナップショット方式に強化**（ユーザー「wipe改善できないのか」→文書化済み改善候補2件を実装）。pre-commitが.sd/全体を.git/sd-snapshot/へ複製→post-commitがファイル単位で欠損検知・復元（partial wipe対応+commit時点の未commit分保護+残存ファイル不可侵+意図的削除非復活）。temp repoで17ケース実機テスト全PASS+実弾wipe 2回で実証（mid-session 58ファイル/commit時58ファイル復元）。**新観察: wipeはpre-commit前=Bash起動時refreshで発火の可能性**。テンプレ正本更新（配信先は次回/sd-upgradeで反映）。残穴=mid-session自動復元（sd-watchdog拡張はユーザー判断待ち） | 679fabc | [Details](session-20260610-205210.md) |
| 06-10 | **ss001へ/sd-upgrade展開完遂（v3.1.0→v3.2.0）**。dry-run 40 divergence→全件精査で固有化ゼロ判定（settings.json=旧テンプレ完全一致/CLAUDE.md=旧テンプレ生成のみ）→.sd003-keep不要で432コピー+7生成、廃止物13件退避、verify C1-6全PASS、290ファイルコミット(068eb07)。**Skills 118/119 FAIL=誤報と真因特定**（期待値がoptional除外3件を含むsource総数。欠落ゼロ＋旧FW残骸テンプレ2件は超過側→退避。deploy.ps1カウント修正がP2）。ss001 .gitignoreにbackup除外3パターン追加。**C:空き25.25GBに回復確認**（vm_bundles危機解消） | (ss001側) | [Details](session-20260610-202900.md) |
| 06-10 | **at002/nm002へ/sd-upgrade展開完遂（P1）**。at002: dry-run divergence仕分け（差分行数で固有化/古FW判定）→.sd003-keep固有5保護+FW29更新、verify C1-6全PASS、266ファイルコミット(8c57d7d)。nm002: blatゴミ803個削除→06-07未コミット分+今日分を統合コミット(42e9b38,a56174c/383ファイル)、product資産温存。**nm002固有hookバグ修正**: scan-utf8-replacementのstdin modeがallowlist完全バイパス→--stdin-path追加+wrapper修正(4テスト+実コミット実証)。**C:満杯0GB緊急対応**: OCC 1.27GB+Office診断0.41GB削除、真因=Claude Desktop vm_bundles 12.5GB特定（F:退避手順provided・Desktop終了待ち）。auto-memory 2件 | (at002/nm002側) | [Details](session-20260610-164049.md) |
| 06-10 | **SD003フレームワーク調査・評価＋推奨5件を全改修**。3並列Exploreで実体棚卸し→自前git履歴照合で裏取り（防御層A/自己整合性C+）。W1: `.sd/ai-coordination/`と`.sd/specs/`がgit履歴上一度も存在せずテンプレ全域ゼロと判明→6テンプレ+handoff+specs init実装(16ファイル)。W2: v3.2.0統一+jest coverageThreshold撤廃(柱3矛盾)+RULES.md design→spec。P2: 常時注入30件中14件にpaths:制約(~56KB/session削減、機構の実働も観測)。P2: deploy ps1/sh全文比較で**実害級差異2件発見**(CLAUDE.md skip-if-SD003=952ef66同型/materials/html欠落)→修正+静的パリティテスト新設+共通化計画。P3: バグ回避策サンセット表。jest OOM→maxWorkers:2。造語注釈ルールをグローバルCLAUDE.mdへ | 4196018, 6a15780, 7b64548, 13bd71e, 3fa3f49 | [Details](session-20260610-112231.md) |
| 06-07 | **nm002の最新配付用ファイル(tar.gz)作成**。nm002=会計事務所向け照合ツール製品(nm002-reconcile/tar.gz配布/v1.5.14)と判明、`python scripts/build_dist.py`で正規ビルド(32ファイル/80,316bytes/整合性OK)。配布.envのghp_同梱を「重大」と報告→**実は意図的例外設計(bot 3stax001・実質fine-grained等価)と判明し過剰反応を訂正**、build_dist.py変更を全revert。ユーザー: アカウント変更/revoke不要で確定。作業dir(sd003)と対象(nm002)の取り違え教訓 | (nm002側) | [Details](session-20260607-172652.md) |
| 06-07 | **nm002を最新sd003へ更新（/sd-upgrade）＋deploy.sh settings.json上書きバグ根本修正**。nm002はガードレールhook欠落・settings.json未配線で固着→upgradeで最新化、CLAUDE.mdは既存尊重(.sd003-keep登録)、settings.json修復でC1-6全PASS。**真因=deploy.shが既存settings.jsonをSKIP(deploy.ps1は上書き)→upgradeしても古い配線が直らない**→is_kept保護時のみSKIP・他は上書きに修正(heredocのOS対応は維持、3シナリオ実機検証)。慎重精読で当初案(テンプレコピー化)を撤回 | 952ef66 | [Details](session-20260607-170010.md) |
| 06-07 | **sd-deployにデプロイ時内容検証ゲート Phase 6b 実装**（配送へのWork First適用）。根本原因=既存Phase6はファイル数/存在のみ検証＋失敗してもexit0で成功扱い→9f14984のStop-only配線を素通り。単一Node検証 verify-deployment.mjs（C1 hook配線をイベント単位照合/C2 hook実在/C3 テンプレ実プレースホルダ限定/C4 廃止語/C5 文字化け.sh+.ps1/C6 JSON）＋deploy.ps1/sh にハードフェイル(exit 1)配線＋回帰テスト(9f14984再現fixture)。レビューP2/P3＋自己発見C3誤検知も根本修正。**ゲートが現役at002のガードレール不活性(block-sd-destructive未配線)を捕捉→最新テンプレ上書きで修復(C1-6全PASS)**。GEPA/SkillOpt/DSPy文書の批判的レビューも実施 | 9f0455d, 7becd7c | [Details](session-20260607-164006.md) |

## 2026-05

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| 05-31 | fl006へSD003展開（CLAUDE.md固定デプロイID/URLを.sd003-keep保護・421ファイル・settings.json手動完全配線）+ P0完遂（at002 Layer3配備/sd-safe-commit改訂）+ **重大発見: L1+L2+L3はwipe未解消、毎commitで.sd/全消失しL4 post-commit auto-restoreが実防衛線と実測確定（5-27結論を訂正）** + deployツールsettings.json生成バグ根本修正（全ガードレール未配線→deploy.sh/ps1テンプレ完全配線、temp実行検証） | 9f14984 | [Details](session-20260531-004242.md) |
| 05-27 | .sd/消失バグ根本対策3層構造（L1=.gitignoreから.sd/除外でtracked化/L2=settings.local.json untrack/L3=Edit-Write on .sd/物理ブロック新hook）実装+検証完了。npm test 7/7 PASS復旧（廃止テスト3件archive+gas-fakes ignore追加）。at002診断でL1+L2は既配備済（/sd-upgrade経由推定）発見、L3のみ未配備 | 6b3884f | [Details](session-20260527-201826.md) |
| 05-27 | 同セッション2回目クラッシュ復旧確認（13:27 sessionwrite後すぐにクラッシュ）→ git状態確認でコード損失なし。メモリ状況の即時記録試行したがpwsh自体が10秒応答せず（システム逼迫の早期警告サイン仮説）。直前は71.7%/4.46GB空きで余裕あったため真因未特定。pre-commit hookがNode.js検出エラーで継続ブロック中、本セッションのcommit試行もブロックリスクあり | cfec129継続 | [Details](session-20260527-140549.md) |
| 05-27 | クラッシュ復旧→再起動後P0全達成検証（ページファイルF:\16384/32768MB移行成功・C:空き15.3→18.30GB回復・メモリ使用率82→74.6%で7.4pt改善）+ P1完了（OneDrive自動起動レジストリ削除+全3プロセス停止で377MB→0MB、次回起動時500MB+効果見込み）。設定変更コマンドは全てユーザー側実行 | cfec129継続 | [Details](session-20260527-132737.md) |
| 05-27 | 再起動後のP0タスク継続実施（前回再起動後にYAYOI停止・ページファイル設定とも未実施と判明）→ 管理者pwshでMSSQL$YAYOI+SQLTELEMETRY$YAYOIを Stopped+Manual 化（sqlservr 3→2プロセス）。前セッションの「1GB回復」見積もりが実機101MBと10倍乖離していた誤りを訂正。ページファイル F:移行GUI設定はユーザー側で進行中、本セッション終了後に再起動予定 | a70b4dd継続 | [Details](session-20260527-111508.md) |
| 05-27 | AIツール頻繁クラッシュ原因の根本診断（物理RAM 16GB/使用77%、AIツール本体は20%でSQL Server×3とOneDriveが真犯人）。3 SQLインスタンス用途特定（YAYOI=弥生販売廃用確定/OBC=今朝書込み現役/MSSQLSERVER=ユーザー指定残置）+ OneDriveプロセス停止580MB回復 + ページファイル F:移行+拡大方針合意。コード変更なし、診断と方針合意のセッション | (sd003変更なし) | [Details](session-20260527-104307.md) |
| 05-26 | at002のStopフックから vestigial な sd003-stop-hook.ps1 を除去（毎Stop失敗の重いPowerShell製・ralph-loop退役で死に機能）。所見Aの前提をat002で実機裏取り、sd003本体はralph-loop現役のため不変更とスコープ判別。実働bash 2本は維持、JSON検証OK | (at002側) | [Details](session-20260526-095025.md) |
| 05-26 | sd-upgrade/deploy固有化ファイル上書き欠陥を修正（.sd003-keepオプトアウト＋dry-run正直化で誤報「UPGRADE OK/無傷」根絶、ps1+sh検証）＋codex-dispatchをsd003 framework正準化（2>&1\|tee禁止/-oで最終回答/medium effort、決定論ラッパーcodex-run.sh）。両者guardrails over rules | 14230fd, 93a6224 | [Details](session-20260526-022745.md) |
| 05-23 | at002へSD003フレームワークアップグレード（/sd-upgradeスキル: dry-run→確認→execute。412コピー+7生成、廃止物.gemini/claude-memスタブ削除・全バックアップ退避。Skills114/115 FAILはoptional除外の誤報。UPGRADE OK） | (at002側) | [Details](session-20260523-131933.md) |
| 05-23 | agyの/ドロップダウン問題を実機検証で根本解決（workspace .agents/skillsは/skills止まり→global ~/.gemini/skillsで接頭語なし表示）。deploy-agy-skills.py新規+メモリ訂正。クラッシュ2回復旧 | a46c7ab | [Details](session-20260523-131933.md) |
| 05-23 | agysync-cli-commands.pyのミラー処理バグ修正（`allowed-tools:`→`disable-model-invocation:true`変換で全60スキルをスラッシュコマンドとして表示）| aa05ee7 | [Details](session-20260523-104820.md) |
| 05-23 | agyスラッシュコマンド不具合の根本解決（TOML誤用→`.agents/skills`のSKILL.md機構を実機確定。/skills 0→60）+ 総合監査による不備一掃（deploy/hook/doctrine/docs/cosmetics）+ 新規`/sd-upgrade`スキル（throwawayテスト合格）+ claude-mem完全アンインストール（非公式）。10コミット | a7ce92e | [Details](session-20260523-102712.md) |
| 05-22 | gemini-cli→agy(Antigravity CLI)移行をsd003正本に確定（agy報告9件 vs 実態465件の乖離を検証→4論理コミットに分割：.sd untrack / 移行本体 / 廃止CLI削除 / framework更新）。dry-run+sync --check全通過 | 223c188 | [Details](session-20260522-215124.md) |
| 05-18 | Zenn記事Codex Skill移行受領 + 公式プラグインopenai/codex-plugin-cc調査（既にuser scopeでインストール済み確認）+ at002「不発」3要因分析 | (pending) | [Details](session-20260518-095119.md) |
| 05-18 | Claude Code正本を壊さずCodex仕様を追加（.codex/CODEX_SPEC + .codex/skills正式化 + sync --codex-only + deploy配布対応） | (pending) | [Details](session-20260518-075636.md) |
| 05-18 | セッションアーカイブ7件Google Drive移動 + at002へSD003展開（266コピー+7生成、Skills 113/116はOptional除外）+ deploy.ps1のNext Stepsに古い`/sd:spec-init`参照を発見 | (pending) | [Details](session-20260518-073605.md) |
| 05-16 | Codex/uvキャッシュ削除 + codex-cache-cleanupスキル作成・Codex.app日本語呼び出し対応 | (pending) | [Details](session-20260516-150213.md) |
| 05-16 | diff不可視修正の反映確認 + 「スキル無視は起こり得るか」概念整理（ルール+物理ガードレール必須の再確認） | (pending) | [Details](session-20260516-143601.md) |
| 05-16 | Claude Code diff不可視問題を診断・theme=dark-ansi追加で修正 / archive-sessions Google Drive mv失敗で見送り | 7a35cdb | [Details](session-20260516-142534.md) |
| 05-11 | er001へSD003最新版デプロイ（266ファイル+7生成、12/13 PASS） | 2b79b26 | [Details](session-20260511-074514.md) |
| 05-10 | html-reportスキル新規作成 + Blueprint Gate HTML出力モード追加（Thariq HTML effectiveness pattern） | 13dd2e8 | [Details](session-20260510-110118.md) |
| 05-07 | at001-v1事故対策: spec配置物理ガードレール+spec.md採用+全20PJ design→spec一括リネーム | 94bf8e7 | [Details](session-20260507-115551.md) |
| 05-07 | D:\claudecode 親.git解体 + 全56PJ独立git管理化（保全bundle 247MB） | (sd003変更なし) | [Details](session-20260507-093444.md) |

---

## 2026-04

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| 04-26 | sessionwrite改善（「使用した外部ファイル」セクション追加）+ 全12PJ配付 | e5ed2d3 | [Details](session-20260426-152843.md) |
| 04-25 | Codex skill 改訂（sessionread/sessionwrite に PROJECT_ROOT 固定 + 絶対パス化 + 広域探索禁止 + 5行報告） | - | [Details](session-20260425-235120.md) |
| 04-25 | nl001 プロジェクトへSD003フレームワーク展開（v2.14.0 / deploy v3.1.0、256ファイル コピー + 7ファイル 生成） | - | [Details](session-20260425-084041.md) |
| 04-20 | 全33PJ Gemini CLI TOML一括修復（22PJ 253件パースエラー + 16PJ 225件BOM解消、文字化け29件 sibling置換） | - | [Details](session-20260420-165616.md) |
| 04-20 | 全33PJ .kiro退避 + 9PJ /sd-deploy + 71件レガシー駆除 + 119ファイル sed 置換 + ta001整合性復旧 | - | [Details](session-20260420-095435.md) |
| 04-17 | Gemini CLI TOMLパースエラー解消 + 同期スクリプト統合 + 競合解消 | - | [Details](session-20260417-125152.md) |
| 04-12 | SD003 Core Doctrine 4本柱制定 + ガードレール Phase A-C（思想+テンプレート+コマンド強制）+ Playwright共有キャッシュ | 16e8b60 | [Details](session-20260412-214651.md) |
| 04-12 | AI協調ワークフロー致命的欠陥特定（impl Step 5にRun Gate欠落 / 動作確認なしで完走） | 79c2e3f | [Details](session-20260412-125516.md) |
| 04-12 | code-review-graph調査・SD003統合判定（条件付き導入推奨: 大規模PJのみ） | 9a94e4f | [Details](session-20260412-111628.md) |
| 04-12 | パイプラインレビューゲートhook実装（mz001 #1対策）+ cr001導入 | b25266a | [Details](session-20260412-101130.md) |
| 04-11 | Hermes Agent学習システム統合（session-search + memory-nudge + learning-nudge）+ cr001デプロイ | 3082bee | [Details](session-20260411-204411.md) |
| 04-11 | NotebookLM統合設計（research + memoryスキル新規作成 + sessionフック追加） | ad9d49a | [Details](session-20260411-100919.md) |
| 04-07 | RTKファクトチェック（10件検証→見送り判定）+ メモリ記録 | 822442f | [Details](session-20260407-075630.md) |
| 04-04 | 開発哲学文書化 + 分岐ルール + git hooks強化 + 全13PJ再デプロイ | a702684 | [Details](session-20260404-142713.md) |
| 04-04 | Multi-CLI 共通正本化 + Gemini/Codex 自動生成 + Codex home 配布 | 3539c86 | [Details](session-20260404-132402.md) |
| 04-03 | at001 .kiro完全廃止 + SD003再デプロイ（.sd統一） | 1e681c67 | [Details](session-20260403-125244.md) |
| 04-02 | Codex Custom Prompts廃止整理 + 用語混同修正（Slash Commands≠Custom Prompts） | f0d3f91 | [Details](session-20260402-155050.md) |
| 04-02 | .codex/prompts/廃止対応（全PJ削除+sd-deploy修正+sync撤去） | dbde941 | [Details](session-20260402-154054.md) |
| 04-02 | nm002スラッシュコマンド修復（@req除去+frontmatter追加）+ 全カスタマイズ差分調査 | 6e39c6a | [Details](session-20260402-142804.md) |

## 2026-03

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| 03-31 | Obsidian CLI + Codexテスト + 佑峯会決算後提出書類調査 | 64c06e2 | [Details](session-20260331-231849.md) |
| 03-31 | Obsidian CLI有効化 + セッションアーカイブ11件 | 569378d | [Details](session-20260331-210926.md) |
| 03-31 | Obsidian MCP修復 + obsidian-skills導入 + Codex移行完了 | 382619a | [Details](session-20260331-202859.md) |
| 03-31 | codex-plugin-cc公式プラグイン導入 + Codex呼び出し全面移行（Phase 1+2） | 4d114d4 | [Details](session-20260331-194236.md) |
| 03-30 | claude.ai MCP統合5サービス一括ブロック（グローバルsettings.json） | 222d516 | [Details](session-20260330-110700.md) |
| 03-30 | hookスクリプトmojibake修正 + 全ファイル英語化 + 全13PJ再配布 | ea3d7df | [Details](session-20260330-091653.md) |
| 03-29 | テンプレート.kiro掃除 + .git/hooks/自動デプロイ実装 + 全22PJ同期 | a623c65 | [Details](session-20260329-223801.md) |
| 03-29 | git hooks .kiro→.sd修正 + テンプレート.kiro残存発見 | be50618 | [Details](session-20260329-214753.md) |
| 03-29 | Codex/Geminiアーカイブ済みコマンド42件削除 + Blueprint Gate追加 | 09db501 | [Details](session-20260329-194013.md) |
| 03-29 | v3.0.0: Blueprint Gate作成 + sd/コマンド14個アーカイブ + CLAUDE.md全面改訂 | ea524d1 | [Details](session-20260329-191700.md) |
| 03-28 | sessionwrite日本語化 + スキルテンプレートルール + 全25PJ反映 | 0d486c4 | [Details](session-20260328-195000.md) |
| 03-28 | 28 projects .kiro->.sd migrated + ob001 deploy + requirements template | 409271b | [Details](session-20260328-190200.md) |
| 03-28 | deploy.ps1 overwrite policy + template separation + nm002 test | 845cfa3 | [Details](session-20260328-175100.md) |
| 03-28 | nm002 deploy + kiro→sd migration + deploy overwrite bug found | f8d3e31 | [Details](session-20260328-173600.md) |
| 03-28 | Full day: GitHub sync + .kiro bug trace + .sd migration + .sessions/ fix | ab6b3fd | [Details](session-20260328-165100.md) |
| 03-28 | .sessions/ save location fix + .kiro→.sd migration | b278075 | [Details](session-20260328-163800.md) |
| 03-28 | .kiro disappearance root cause + fix | 9bfe1c8 | [Details](session-20260328-130800.md) |
| 03-28 | watchdog fix + nm001 deploy | adc45ab | [Details](session-20260328-111700.md) |
| 03-28 | GitHub full sync: 44/44 clean, auto-push, branch cleanup | 0ea6155 | [Details](session-20260328-003000.md) |
| 03-27 | GitHub sync fix (21 remote + 12 push + 41 hooks) | 68b47d6 | [Details](session-20260327-084800.md) |
| 03-22 | .kiro消失完全解決（3層防御 + worktree非永続化バグ発見） | e8b3905 | [Details](session-20260322-113855.md) |
| 03-21 | .kiro消失解決確認 + 再起動検証 | a6e7f8b | [Details](session-20260321-224421.md) |
| 03-21 | dialogue-resolution .kiro root cause fixed | 7e327d4 | [Details](session-20260321-222657.md) |
| 03-21 | SD003.1 + root-cause-first + 7 projects | 2fdd9e4 | [Details](session-20260321-215950.md) |
| 03-21 | SD003.1 IMPORTANT IF restructure + block-at-submit + validation cases + browser-use検証 | df2851a | [Details](session-20260321-205056.md) |
| 03-18 | Superpowers部分統合（3スキル） + Codex日本語設定 | 5a653cd | [Details](session-20260318-110210.md) |
| 03-16 | 削除禁止・上書き禁止ルール追加 + セッションアーカイブ | f1f3128 | [Details](session-20260316-122250.md) |
| 03-15 | cf001短期借入金バグ調査（CF+BS漏れ確定、321未処理） | e71e8b5 | [Details](session-20260315-135822.md) |
| 03-15 | セッションアーカイブ + Claude/Codexスキル共有 + AI並列実行基盤 | aa15ed4 | [Details](session-20260315-115838.md) |
| 03-12 | cf001デプロイ + 展開検証ALL PASSED | aa15ed4 | [Details](session-20260312-190512.md) |
| 03-12 | at001デプロイ + deploy.ps1 gas-fakes自動生成改修 | aa15ed4 | [Details](session-20260312-160349.md) |
| 03-12 | SD003 v2.13.0 ck001デプロイ + マルチAI対応確認 | aa15ed4 | [Details](session-20260312-110949.md) |
| 03-10 | clasp deploy漏れ防止hook v2（3段階状態追跡） + Gemini調査確認 | aa15ed4 | [Details](session-20260310-154249.md) |
| 03-10 | GAS E2E業界調査 + 2層戦略発見 + Gemini依頼 | 0a286a6 | [Details](session-20260310-125054.md) |
| 03-10 | gas-e2e autoConnect接続分析 + browserUrl不可確定 | fe2c1ea | [Details](session-20260310-115808.md) |
| 03-10 | gas-e2e iframe制約記録 + Mode優先順修正 + もたつき防止 | 8c46448 | [Details](session-20260310-090634.md) |
| 03-08 | gas-e2eスキル + clasp deploy物理ブロック + Work First原則 | 65b43f6 | [Details](session-20260308-213433.md) |
| 03-08 | VTD Enforcement Layer追加 + テスト絶対原則明記 + oc001デプロイ | 0881eb5 | [Details](session-20260308-144850.md) |
| 03-07 | CLAUDE.md統一 + GA001完全排除 + td001デプロイテストALL PASSED | - | [Details](session-20260307-095821.md) |
| 03-07 | ローカルCLAUDE.md整備 + AGENTS.md/GEMINI.md Core Principles統一 + デプロイ対応 | - | [Details](session-20260307-091400.md) |

## 2026-02

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| 04-02 | nm002スラッシュコマンド修復（@req除去+frontmatter追加）+ 全カスタマイズ差分調査 | - | [Details](session-20260402-142804.md) |
| 02-18 | PC001 GA001排除+gas-fakes導入 / SD003 deploy v3.1.0 | a19bf0c | [Details](session-20260218-075432.md) |
| 02-17 | gas-fakes未導入根本原因究明 + GA001排除計画策定 | 81d0f4b | [Details](session-20260217-202121.md) |
| 02-15 | パスルール一貫性修正（RULES.md v2.0 + 全AI設定統一） | a266cd5 | [Details](session-20260215-162159.md) |
| 02-15 | デプロイパッケージ v2.13.0 同期 | 62a5e4a | [Details](session-current.md) |
| 02-15 | Skills.sh統合 + gas-fakes 2層ゲート | dd1e485 | [Details](session-20260215-154240.md) |
