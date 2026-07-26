# Codex lean alignment 要件定義書

作成日: 2026-07-26

## 1. 背景

Claude Code側のlean化は完了したが、Codexは`AGENTS.md`、Agent Skills、Codex hooksを別経路で利用する。そのため、Skillの最大3重露出と常時指示の矛盾がCodex側に残っている。

## 2. 現状と前提

### 2.1 現状

- `.claude/commands/**/*.md`がコマンドのauthoring source。
- `.agents/skills`はagy向け生成先だが、Codex公式のrepo Skill探索先でもある。
- `.codex/skills`と`~/.codex/skills`が同じSkillを重複配布している。
- `AGENTS.md`は7,042 bytesあり、Fast Reviewと正式報告などに重複・矛盾がある。
- Codexは共有guardを使うが、Claude固有hook群とは適用範囲が異なる。

### 2.2 技術環境と制約

- Windows 11 / PowerShell / UTF-8。
- 未コミットの他AI作業を保護する。
- 生成物を直接手編集せず、authoring sourceと同期アダプタを修正する。
- 自動削除は管理マーカー付き生成物に限定し、手作りSkillを保護する。
- 危険なGAS deployment操作は行わない。

### 2.3 スコープ

実施する:

- `.agents/skills`をCodex・agy共通のrepo Skill正規位置にする。
- `.codex/skills`生成とCodex homeへの重複配布を廃止する。
- `AGENTS.md`をlean化する。
- Claude/Codex hook差分を文書化する。
- 同期スクリプト、manifest、README、配布・upgrade経路、検証を整合させる。

実施しない:

- Claude固有hookの一括移植。
- agy・Grokの探索先変更。
- SD003由来と確認できないグローバルSkillの削除。

### 2.4 AIへの注意事項

- 文字数削減より、正規位置の一本化と矛盾除去を優先する。
- 同名未管理Skillは上書きしない。
- ユーザーSkillは削除せず、復元可能な場所へ退避する。

## 3. ゴール

Codexとagyが同じ`.agents/skills`を安全に共有し、Skillの重複露出がなく、短いAGENTS、物理guard、必要時参照に役割分担されている。

## 4. アウトプット定義

### 4.1 成果物

- 更新された同期・配布・upgradeスクリプト
- 共通`.agents/skills`とmanifest v2
- 廃止された`.codex/skills`
- lean版`AGENTS.md`
- 更新されたCodex仕様・README
- hook差分表
- 回帰検証
- 人間向け要件定義HTML

### 4.2 完成条件

- 重複生成経路がない。
- 廃止オプションが安全に移行案内を返す。
- hook差分ごとの扱いが記録される。
- sync check、build、test、lintが成功する。

### 4.3 利用者と利用場面

SD003をClaude Code、Codex、agy、Grokで運用する開発者が、Codexセッション開始時とSkill実行時に利用する。

## 5. 要件

### 5.1 機能要件

1. `.agents/skills`をCodex・agy共通出力として生成する。
2. manifestは共通Agent Skillを一度だけ記録する。
3. `.codex/skills`を再生成しない。
4. 旧Codex専用オプションは重複を再発させず移行案内を返す。
5. 同名未管理Skillとの衝突時は、書込み前に同期を中止する。
6. `AGENTS.md`は常時必要な入口情報だけを保持する。
7. hook差分表は適用面と代替策を示す。

### 5.2 非機能要件

- 同期は冪等。
- 生成物はUTF-8。
- 既存CLIを壊さない。
- 整理対象は復元可能にする。

## 6. 検証観点

- [ ] `.agents/skills`だけでCodex・agy用SD003 Skillが揃う。
- [ ] repoとCodex homeの重複が解消される。
- [ ] 同名未管理Skillが保護される。
- [ ] `AGENTS.md`のFast/Formal routingに矛盾がない。
- [ ] hook差分と文章維持判断が追跡できる。
- [ ] sync、build、test、lintが成功する。

## 7. Known Unknowns

- Codexでの`disable-model-invocation`の扱いは公開仕様で明示されていないため、共通Skillは明示呼出しを主契約とする。
- Codex homeの同名Skillは内容が現行生成物と異なるため、自動削除せず隔離して復元可能にする。
