---
slug: sessionwrite
source: .claude/commands/sessionwrite.md
description: Save session handoff and update timeline
claude_command: /sessionwrite
agent_skill: sessionwrite/SKILL.md
aliases: session-write
allowed_tools: Bash, Write, Read
---

# セッション保存

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Codex/Antigravity共通Agent SkillとGrok Skillはこのファイルから生成します。

## Original Body
# セッション保存

セッション引き継ぎ記録を保存し、プロジェクトタイムラインを更新する。

## ファイル

| ファイル | 用途 |
|---------|------|
| `.sessions/session-YYYYMMDD-HHMMSS.md` | 履歴（タイムスタンプ付き） |
| `.sessions/session-current.md` | 最新版 |
| `.sessions/TIMELINE.md` | プロジェクト履歴 |

## 実行手順

1. `.sessions/` ディレクトリ作成（なければ）
2. タイムスタンプ生成（例: `20251123-143052`）
3. git状態取得（ブランチ、最新コミット、作業ツリーと既存のstage）。更新先に既存の変更があれば内容を読み、保持して追記する。
4. 履歴ファイル `.sessions/session-YYYYMMDD-HHMMSS.md` 作成
5. `.sessions/session-current.md` にコピー
6. **TIMELINE.md 更新**（新エントリ追加）
7. `.handoff/DONE.md` を更新し、以下のGitコミット手順で保存する
8. 完了メッセージ表示（保存先、コミット結果、pushの実施有無、未解決事項）

## 言語ルール（必須）

**セッション記録は全て日本語で書くこと。** 英語禁止。
- 見出し: 日本語
- 完了事項: 日本語
- 次回タスク: 日本語
- 備考: 日本語
- コミットメッセージのみ英語OK

## セッション記録フォーマット

```markdown
# セッション記録

## セッション情報
- **日時**: [YYYY-MM-DD HH:MM:SS]
- **プロジェクト**: [パス]
- **ブランチ**: [git branch]
- **最新コミット**: [hash + message]

## 作業サマリー

### 完了
[番号付きリスト・日本語]

### 進行中
[番号付きリスト・日本語]

### 未解決
[課題と試した対策・日本語]

### 作成・変更ファイル
[カテゴリ別リスト]

### 使用した外部ファイル（⚠️ 必須・省略禁止）

**「これを書かなければ次の自分は知らない」基準で記録する。**

プロジェクト外のファイル（デスクトップ、他プロジェクト、ダウンロード等）を
入力元・参照元として使用した場合、全てのフルパスを記録する。

```markdown
### 使用した外部ファイル
- `C:\Users\a-odajima\Desktop\サクセス\22sakusesusiwakebugyou.csv`（勘定奉行CSV、CP932、78列）
- `D:\claudecode\他プロジェクト\src\参考.ts`（〇〇の実装参考）
- なし
```

**禁止**: 「覚えている」を理由に記録しないこと。
AIには持続的記憶がない。書いてあるものだけが次セッションの記憶になる。

### 次回タスク

#### P0（緊急）
[即対応が必要]

#### P1（重要）
[緊急ではないが重要]

#### P2（通常）
[時間があれば]

### 備考
[引き継ぎ事項・日本語]

### 学習ナッジ（修正が2回以上ある場合のみ記載）
- 修正N回検出
- 修正内容:
  1. [修正の要約: 何を→何に修正したか]
  2. [修正の要約: 何を→何に修正したか]
- 永続化提案: [ルール追加 / auto-memory feedback記録 / スキル作成] を検討
```

## TIMELINE.md 更新

セッション保存後、TIMELINE.mdを更新する:

1. 現在のTIMELINE.mdを読む
2. 主な作業内容を1行で要約
3. 当月テーブルの先頭に新エントリ追加:

```markdown
| MM-DD | [Main Work] | [Commit Hash] | [Details](session-YYYYMMDD-HHMMSS.md) |
```

4. 統計のTotal Sessions数をインクリメント
5. Latest Session日付を更新

## ユーザー入力
$ARGUMENTS

## 学習評価（Step 4内で自動実行・非ブロッキング）

履歴ファイル作成時（Step 4）に、以下を備考セクションに反映する:

1. セッション中にユーザーから受けた修正を振り返る
2. 修正が2回以上あれば「学習ナッジ」セクションを備考に追加
3. 完了メッセージ（Step 8）の末尾に1行で提案を追記

**ルール**: 非対話・非ブロッキング。AskUserQuestion禁止。保存フローを中断しない。
**詳細**: `docs/rules-reference/skills/learning-nudge.md`

## Codex Handoff（並行保存）

セッション記録と同時に、Codex向けの引き継ぎファイルも更新する:

```bash
# .handoff/DONE.md を生成（Codex/Antigravity向け引き継ぎ）
```

内容は session record の要約版:
- 完了事項（箇条書き）
- 未完了事項
- 次のステップ
- 関連ファイルパス

**DONE.md は `.handoff/DONE.template.md` をベースに作成する。**

## Gitコミット

セッション保存の依頼は、今回の引継ぎファイルのローカルコミットを含む。pushはユーザーの明示依頼がある場合だけ実行する。

1. `git status --short`、`git diff --cached --name-only`、対象ファイルの差分を確認する。今回作成・更新した引継ぎファイルだけを対象にし、ディレクトリ単位のstageや `git add -A` は使わない。
2. コミット前に `git config --get core.hooksPath`（未設定ならGit既定のhooks配置先）と実際に動くhook・呼出先を確認する。自動push等の外部変更や対象外ファイルの自動stageがある場合、既存の一時的な抑止方法が確認できればそれを使う。未承認の外部変更・対象外ファイルの混入を抑止できなければ、ファイル保存まで完了し、コミットは保留して具体的な理由を報告する。hookを一括無効化したり、恒久設定を無断変更したりしない。
3. 対象外の既存stageを巻き込まないよう、コミットにも対象パスを明示する。対象ファイル自体に他の作業の変更が混在していて分離できない場合は、その変更を保護し、保存済み・コミット保留として報告する。

以下は4ファイルすべてを今回更新した場合の例。日時は実際の履歴ファイル名に置き換え、更新していないファイルは両コマンドから除く。

```bash
git add -- .sessions/session-YYYYMMDD-HHMMSS.md .sessions/session-current.md .sessions/TIMELINE.md .handoff/DONE.md
git commit --only -m "session: [1行サマリー]" -- .sessions/session-YYYYMMDD-HHMMSS.md .sessions/session-current.md .sessions/TIMELINE.md .handoff/DONE.md
```

特定のAIやモデルの署名を固定で付けない。コミット後はコミットIDと対象ファイルを確認し、対象外のstageが保持されていることを確認する。コミット成功とpush成功を混同せず、pushを依頼されて実行した場合はその結果も確認する。

---

**実行**: 今回の引継ぎファイルを保存し、上記手順で対象を限定してローカルコミットする。保留事項があれば記録し、保存・コミット・pushそれぞれの実施結果を報告する。
