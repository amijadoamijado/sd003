# .claude/rules/

SD003フレームワークの開発ルール集。Claude Codeが自動読込する。

## ルール一覧

### グローバル（全ファイル適用）
| ファイル | 内容 |
|---------|------|
| `global/work-first.md` | **まず動かす原則（最上位・全ルールに優先）** |
| `global/quality-standards.md` | 品質基準（TypeScript/テスト/コード品質） |
| `global/fullpath-display.md` | ファイル保存先のフルパス表示 |

### ドメイン別

#### アーキテクチャ
| ファイル | 内容 |
|---------|------|
| `architecture/adapter-core-pattern.md` | Adapter-Core分離パターン |

#### GAS開発
| ファイル | 内容 |
|---------|------|
| `gas/env-interface.md` | Env Interface Pattern |
| `gas/gas-constraints.md` | GAS環境制約（禁止API等） |

#### UIデザイン
| ファイル | 内容 |
|---------|------|
| `ui/web-design-principles.md` | Web UIデザイン原則（8原則+禁止事項） |
| `ui/visual-review-checklist.md` | 視覚的評価チェックリスト（7項目スコアリング） |

#### ファイル管理
| ファイル | 内容 |
|---------|------|
| `cleanup/file-organization.md` | ファイル整理・materials・Cleanup Tool |

#### スキル管理
| ファイル | 内容 |
|---------|------|
| `skills/skill-trust-policy.md` | スキル信頼ポリシー（Trusted/Caution） |
| `skills/skill-check-before-action.md` | ファイル操作前のスキル確認必須ルール |

### フェーズ別

#### 仕様書駆動
| ファイル | 内容 |
|---------|------|
| `specs/spec-driven.md` | 仕様書駆動開発フロー |

#### テスト
| ファイル | 内容 |
|---------|------|
| `testing/testing-standards.md` | テスト基準・カバレッジ要件 |
| `testing/production-data-tdd.md` | 変則TDD（本番データ駆動） |

#### セッション
| ファイル | 内容 |
|---------|------|
| `session/session-management.md` | セッション管理 |

### システム別

#### リファクタリング
| ファイル | 内容 |
|---------|------|
| `refactoring/refactoring-system.md` | リファクタリングワークフロー |
| `ralph-loop.md` | Ralph Loop（エラー修正ループ） |

#### AI協調
| ファイル | 内容 |
|---------|------|
| `workflow/ai-coordination.md` | AI協調体制・ワークフロー |

#### 問題解決（3階層デバッグ）
| ファイル | 内容 |
|---------|------|
| `troubleshooting/bug-quick.md` | Bug QUICK（処理フロー照合、5-15分） |
| `troubleshooting/dialogue-resolution.md` | 対話型解決法（AI思い込み検出） |

## 使い方

### 自動読込
`.claude/rules/`配下の全`.md`ファイルはClaude Codeが自動で読み込む。

### パス限定ルール（オプション）
YAMLフロントマターで特定ファイルにのみ適用:

```markdown
---
paths: src/**/*.ts
---

# このルールはsrc/配下のTypeScriptファイルにのみ適用
```

### CLAUDE.mdからの参照
CLAUDE.mdでは短文で方針を示し、詳細はrulesを参照:

```markdown
## ファイル整理
詳細: `.claude/rules/cleanup/file-organization.md`
```

## ディレクトリ構造

```
.claude/rules/
├── README.md                    # このファイル
├── architecture/
│   └── adapter-core-pattern.md  # Adapter-Core分離
├── cleanup/
│   └── file-organization.md     # ファイル整理
├── gas/
│   ├── env-interface.md         # Env Interface
│   └── gas-constraints.md       # GAS制約
├── global/
│   ├── quality-standards.md     # 品質基準
│   └── fullpath-display.md      # フルパス表示
├── refactoring/
│   └── refactoring-system.md    # リファクタリング
├── session/
│   └── session-management.md    # セッション
├── skills/
│   ├── skill-trust-policy.md    # スキル信頼ポリシー
│   └── skill-check-before-action.md  # スキル確認必須
├── specs/
│   └── spec-driven.md           # 仕様書駆動
├── testing/
│   ├── testing-standards.md     # テスト
│   └── production-data-tdd.md   # 変則TDD
├── troubleshooting/
│   ├── bug-quick.md             # Bug QUICK
│   └── dialogue-resolution.md   # 対話型解決法
├── ui/
│   ├── web-design-principles.md # Web UIデザイン原則
│   └── visual-review-checklist.md # 視覚的評価チェックリスト
├── workflow/
│   └── ai-coordination.md       # AI協調
└── ralph-loop.md                # Ralph Loop
```
