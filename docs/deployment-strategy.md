# デプロイ戦略

SD002フレームワークにおけるデプロイと手戻り防止の戦略。

## 手戻り防止戦略

### 戦略1: 疑似GAS環境の完全性
```typescript
// LocalEnvはGasEnvと100%互換
const localEnv = new LocalEnv();
const gasEnv = new GasEnv();

// 同じコードが両環境で動作
function myLogic(env: IEnv) {
  // 環境差異を意識しないビジネスロジック
}

myLogic(localEnv);  // ローカルテスト
myLogic(gasEnv);    // 本番実行
```

### 戦略2: デプロイ前完全テスト
- **必須**: 全E2Eテストがパス
- **必須**: カバレッジ80%以上
- **必須**: 疑似GAS環境での動作確認
- **推奨**: 手動テストによる最終確認

### 戦略3: 段階的デプロイ
1. **ステージング環境**: 疑似本番環境でのテスト
2. **カナリアデプロイ**: 一部ユーザーでの動作確認
3. **本番デプロイ**: 全ユーザーへの展開
4. **ロールバック準備**: 問題発生時の即座復旧

### 戦略4: デプロイ後モニタリング
- エラーログの即時確認
- 実行時間の監視
- ユーザーフィードバックの収集

## 必須設定

### Tool Search（MCP最適化）

SD002導入時に以下の設定を必ず追加する：

**`.claude/settings.local.json`**
```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

| 設定 | 効果 |
|------|------|
| `ENABLE_TOOL_SEARCH` | MCPツールの遅延読み込み。トークン消費を最大85%削減 |

**グローバル設定（オプション）**: `~/.claude/settings.json`にも追加可能。

## デプロイ前チェックリスト

```markdown
## Pre-Deploy Checklist

### Required Settings
- [ ] ENABLE_TOOL_SEARCH=true in settings.local.json

### Quality Gates
- [ ] Gate 1: Syntax - TypeScript compiled
- [ ] Gate 2: Type - No type errors
- [ ] Gate 3: Lint - 0 errors, 0 warnings
- [ ] Gate 4: Security - No vulnerabilities
- [ ] Gate 5: Test - Coverage ≥80%
- [ ] Gate 6: Performance - Under 6min limit
- [ ] Gate 7: Documentation - JSDoc complete
- [ ] Gate 8: Integration - E2E passed

### Final Checks
- [ ] All specs up to date
- [ ] Session recorded
- [ ] Rollback plan documented
- [ ] Stakeholders notified
```

## デプロイ手順

### 1. ビルド
```bash
npm run build
```

### 2. 品質ゲート全通過
```bash
npm run qa:all
```

### 3. デプロイリハーサル
```bash
npm run qa:deploy:safe
```

### 4. 本番デプロイ
```bash
npm run deploy
```

### 5. 検証
```bash
npm run verify:production
```

## ロールバック手順

### 即時ロールバック
問題を本番環境で修正しない。即座にロールバック。

```bash
# 前バージョンに戻す
npm run rollback

# 検証
npm run verify:production
```

### ロールバック後の対応
1. **原因分析**: なぜ疑似GAS環境で検出できなかったか
2. **テスト追加**: 同じバグを検出できるテストを追加
3. **再デプロイ**: 全品質ゲートを再度通過してからデプロイ

## デプロイ後の手戻りが発生した場合

```markdown
## Post-Deploy Issue Report

### Issue Summary
[問題の概要]

### Impact
- Severity: Critical/High/Medium/Low
- Users affected: X%
- Duration: X hours

### Root Cause
[なぜ疑似GAS環境で検出できなかったか]

### Resolution
1. Immediate: Rollback executed
2. Fix: [修正内容]
3. Prevention: [再発防止策]

### Tests Added
- [ ] Test case 1 for this issue
- [ ] Test case 2 for edge case
```

## 関連ドキュメント
- [品質ゲート](quality-gates.md)
- [GAS開発ガイド](gas-development-guide.md)

## Ralph Loop配置

SD002デプロイ時に自動配置されるRalph Loop関連ファイル：

### 配置ファイル
| ファイル | 用途 | 環境 |
|---------|------|------|
| `.claude/hooks/sd003-stop-hook.ps1` | 中盤用stop-hook | Windows |
| `.claude/hooks/sd003-stop-hook-endgame.ps1` | 終盤用 | Windows |
| `.claude/hooks/sd003-stop-hook.sh` | 中盤用stop-hook | Linux/Mac |
| `.claude/hooks/sd003-stop-hook-endgame.sh` | 終盤用 | Linux/Mac |
| `.claude/commands/sd002-loop-*.md` | ループコマンド | 全環境 |
| `.claude/rules/ralph-loop.md` | 運用ルール | 全環境 |

### 動作確認

#### Windows
```powershell
# hooks設定確認
Get-Content .claude/settings.json | ConvertFrom-Json | Select-Object -ExpandProperty hooks
```

#### Linux/Mac
```bash
# hooks設定確認
cat .claude/settings.json | jq '.hooks'
```

### フェーズ別適用
| Phase | Ralph Loop | Completion Condition |
|-------|------------|---------------------|
| Early (Phase 1) | Not used | - |
| Midpoint (Phase 2-3) | Active | All tests pass |
| Endgame (Phase 4-5) | Max 2 attempts | Same error 2x -> dialogue-resolution |

## Bug Trace v2.0配置（v2.6.0強化）

3エージェント並列調査 + Ultrathink統合分析 + ASCII図式化によるバグ原因分析機能。

### 配置ファイル
| ファイル | 用途 |
|---------|------|
| `.claude/commands/bug-trace.md` | 3エージェント並列バグ調査コマンド v2.0 |
| `docs/troubleshooting/BUG_TRACE_LOG.md` | 調査ログ |

### 使用方法
```
/bug-trace {エラーの概要}
```

### 3エージェント体制
| Agent | Role | Focus |
|-------|------|-------|
| Spec Agent | 仕様書調査 | 要件・設計書・期待動作 |
| Code Agent | コード調査 | 実装・データフロー・状態遷移 |
| Solution Agent | 解決策立案 | 仮説形成・修正戦略 |

### v2.0新機能
| 機能 | 説明 |
|------|------|
| Ultrathink Synthesis | 3エージェント報告の深層分析・クロスリファレンス |
| ASCII Flow Diagrams | エラーフローの視覚的図式化（入力→処理→エラー） |
| Reverse Trace Diagrams | エラー→根本原因の逆追跡図 |
| Divergence Analysis Box | 期待値 vs 実際の並列比較表示 |

### 出力例（ASCII図）
```
┌──────────────────┐
│   INPUT SOURCE   │
└────────┬─────────┘
         ▼
╔══════════════════╗
║   ⚠ DIVERGENCE   ║  ← 分岐点
╚════════┬═════════╝
         ▼
╔══════════════════╗
║   ❌ ERROR       ║
╚══════════════════╝
```
