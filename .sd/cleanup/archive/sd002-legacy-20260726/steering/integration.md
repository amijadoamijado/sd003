# SD002 Framework - 統合ガイド

## 概要

このガイドでは、SD001とGA001を統合したSD002フレームワークの使用方法について説明します。

## 1. SD001とGA001の統合ポイント

### 1.1 統合の目的

| SD001の強み | GA001の強み | SD002での統合 |
|------------|------------|--------------|
| 要件トレーサビリティ | GASローカル開発 | 仕様書駆動GAS開発 |
| ID管理システム | Env Interface Pattern | 完全な環境独立性 |
| 品質ゲート | モックサービス | 自動品質保証 |
| 仕様書同期 | テストフレームワーク | 統一ワークフロー |

### 1.2 統合アーキテクチャ

```
SD002 Framework
├── 仕様書駆動レイヤー (from SD001)
│   ├── .kiro/specs/           # 仕様書管理
│   ├── ID Registry            # ID管理
│   ├── Traceability Engine    # トレーサビリティ
│   └── Quality Gates          # 品質ゲート
│
├── GAS抽象化レイヤー (from GA001)
│   ├── src/env/               # 環境インターフェース
│   ├── src/mocks/             # モックサービス
│   └── src/logic/             # ビジネスロジック
│
└── 統合レイヤー (SD002 unique)
    ├── 統一CLI                # sd002コマンド
    ├── ワークフロー自動化      # 自動化スクリプト
    └── クロスレイヤー連携      # レイヤー間連携
```

## 2. セットアップ

### 2.1 初期セットアップ

```bash
# 1. プロジェクト作成
mkdir my-gas-project
cd my-gas-project

# 2. SD002インストール
npm init -y
npm install sd002-framework --save-dev

# 3. プロジェクト初期化
npx sd002 init

# 4. 依存関係インストール
npm install
```

### 2.2 プロジェクト構造の作成

初期化後、以下の構造が作成されます：

```
my-gas-project/
├── .kiro/
│   ├── specs/              # 仕様書
│   ├── settings/           # 設定
│   └── traceability/       # トレーサビリティ
├── src/
│   ├── env/
│   │   ├── IEnv.ts         # 環境インターフェース
│   │   ├── LocalEnv.ts     # ローカル環境
│   │   └── GasEnv.ts       # GAS環境
│   └── logic/
│       └── main.ts         # ビジネスロジック
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── package.json
├── tsconfig.json
└── ga001.config.ts
```

## 3. 開発ワークフロー

### 3.1 仕様書駆動開発（SD001）

#### Step 1: 仕様書作成

```bash
# 新規仕様書の作成
npx sd002 spec:create user-authentication

# 仕様書編集
# .kiro/specs/user-authentication/spec.json を編集
# .kiro/specs/user-authentication/requirements.md を編集
```

仕様書の構造：
```json
{
  "id": "SPEC-001",
  "name": "user-authentication",
  "version": "1.0.0",
  "requirements": [
    {
      "id": "REQ-001",
      "description": "ユーザー認証機能",
      "priority": "high"
    }
  ],
  "design": [
    {
      "id": "DES-001",
      "requirement_id": "REQ-001",
      "description": "認証サービスの設計"
    }
  ]
}
```

#### Step 2: 仕様書の検証

```bash
# 仕様書の妥当性検証
npx sd002 spec:validate

# トレーサビリティチェック
npx sd002 spec:trace
```

### 3.2 GASローカル開発（GA001）

#### Step 3: Env Interface実装

```typescript
// src/env/IEnv.ts
export interface IEnv {
  spreadsheet: ISpreadsheetService;
  logger: ILogger;
  properties: IPropertiesService;
}

// src/env/LocalEnv.ts
import { IEnv } from './IEnv';
import { MockSpreadsheetService, MockLogger, MockPropertiesService } from 'sd002-framework';

export class LocalEnv implements IEnv {
  spreadsheet = new MockSpreadsheetService();
  logger = new MockLogger();
  properties = new MockPropertiesService();
}

// src/env/GasEnv.ts
export class GasEnv implements IEnv {
  spreadsheet = SpreadsheetApp;
  logger = Logger;
  properties = PropertiesService;
}
```

#### Step 4: ビジネスロジック実装

```typescript
// src/logic/authentication.ts
import { IEnv } from '../env/IEnv';

/**
 * ユーザー認証を行う
 * @param env - 環境インターフェース
 * @param username - ユーザー名
 * @param password - パスワード
 * @returns 認証成功の場合true
 */
export function authenticateUser(
  env: IEnv,
  username: string,
  password: string
): boolean {
  env.logger.log(`認証試行: ${username}`);

  const storedPassword = env.properties.getProperty(`password_${username}`);

  if (!storedPassword) {
    env.logger.log(`ユーザー未登録: ${username}`);
    return false;
  }

  const isValid = storedPassword === password;
  env.logger.log(`認証結果: ${isValid ? '成功' : '失敗'}`);

  return isValid;
}
```

#### Step 5: ローカルテスト

```typescript
// tests/unit/authentication.test.ts
import { authenticateUser } from '../../src/logic/authentication';
import { LocalEnv } from '../../src/env/LocalEnv';

describe('authenticateUser', () => {
  let env: LocalEnv;

  beforeEach(() => {
    env = new LocalEnv();
    // テストデータのセットアップ
    env.properties.setProperty('password_testuser', 'testpass123');
  });

  test('正しい認証情報で成功', () => {
    const result = authenticateUser(env, 'testuser', 'testpass123');
    expect(result).toBe(true);
  });

  test('誤ったパスワードで失敗', () => {
    const result = authenticateUser(env, 'testuser', 'wrongpass');
    expect(result).toBe(false);
  });

  test('未登録ユーザーで失敗', () => {
    const result = authenticateUser(env, 'unknown', 'anypass');
    expect(result).toBe(false);
  });
});
```

```bash
# テスト実行
npm test
```

### 3.3 統合ワークフロー（SD002）

#### Step 6: 開発サーバー起動

```bash
# GASモック環境で開発サーバー起動
npm run dev:server
```

開発サーバーはLocalEnvを使用し、ブラウザでGAS環境をシミュレートします。

#### Step 7: 品質ゲート実行

```bash
# 8段階品質ゲートの実行
npx sd002 qa:test
```

品質ゲートの内容：
1. 構文検証（TypeScript）
2. 型検証（tsc --noEmit）
3. リント検証（ESLint）
4. セキュリティ検証（npm audit）
5. テスト検証（Jest）
6. パフォーマンス検証（ベンチマーク）
7. ドキュメント検証（JSDoc）
8. 統合検証（E2E）

#### Step 8: 仕様書同期

```bash
# 実装と仕様書の同期
npx sd002 spec:sync

# トレーサビリティマトリクス更新
npx sd002 spec:trace
```

### 3.4 デプロイ

#### Step 9: デプロイ前検証

```bash
# デプロイ前の総合検証
npm run qa:deploy:safe
```

これにより以下が実行されます：
- 全テストの実行
- 品質ゲートの実行
- デプロイガード（危険コードチェック）
- 仕様書との整合性確認

#### Step 10: GASデプロイ

```bash
# GAS環境へのデプロイ
npm run gas:deploy
```

## 4. 実践的な例

### 4.1 スプレッドシート操作

```typescript
// src/logic/spreadsheet-ops.ts
import { IEnv } from '../env/IEnv';

export function writeToSheet(
  env: IEnv,
  data: string[][]
): void {
  const sheet = env.spreadsheet.getActiveSheet();

  data.forEach(row => {
    sheet.appendRow(row);
  });

  env.logger.log(`${data.length}行を書き込みました`);
}

// ローカルテスト
// tests/unit/spreadsheet-ops.test.ts
import { writeToSheet } from '../../src/logic/spreadsheet-ops';
import { LocalEnv } from '../../src/env/LocalEnv';

test('データ書き込み', () => {
  const env = new LocalEnv();
  const testData = [
    ['名前', '年齢'],
    ['太郎', '25'],
    ['花子', '30']
  ];

  writeToSheet(env, testData);

  const sheet = env.spreadsheet.getActiveSheet();
  expect(sheet.getLastRow()).toBe(3);
});

// GAS環境での実行
// src/gas/main.ts
import { GasEnv } from '../env/GasEnv';
import { writeToSheet } from '../logic/spreadsheet-ops';

function onOpen() {
  const env = new GasEnv();
  const data = [['Test', '123']];
  writeToSheet(env, data);
}
```

### 4.2 HTTP API呼び出し

```typescript
// src/logic/api-client.ts
import { IEnv } from '../env/IEnv';

export function fetchUserData(
  env: IEnv,
  userId: string
): any {
  const apiKey = env.properties.getProperty('API_KEY');
  const url = `https://api.example.com/users/${userId}`;

  const response = env.urlFetch.fetch(url, {
    headers: {
      'Authorization': `Bearer ${apiKey}`
    }
  });

  env.logger.log(`API呼び出し完了: ${response.getResponseCode()}`);

  return JSON.parse(response.getContentText());
}

// ローカルテスト（モックAPI）
test('ユーザーデータ取得', () => {
  const env = new LocalEnv();

  // モックレスポンス設定
  env.urlFetch.mockResponse({
    responseCode: 200,
    content: JSON.stringify({ id: '123', name: 'Test User' })
  });

  const result = fetchUserData(env, '123');

  expect(result.name).toBe('Test User');
});
```

## 5. トラブルシューティング

### 5.1 仕様書同期エラー

```bash
# エラー: 仕様書とコードが不整合

# 解決策1: 仕様書を強制同期
npx sd002 spec:sync --force

# 解決策2: トレーサビリティを再構築
npx sd002 spec:trace --rebuild
```

### 5.2 品質ゲート失敗

```bash
# 各ゲートの詳細確認
npx sd002 qa:test --verbose

# 特定ゲートのみ実行
npx sd002 qa:test --gate=5  # テスト検証のみ
```

### 5.3 Env実装の問題

```typescript
// LocalEnvとGasEnvの動作を比較
import { LocalEnv } from './env/LocalEnv';
import { GasEnv } from './env/GasEnv';

function debugEnv() {
  const local = new LocalEnv();
  const gas = new GasEnv();

  console.log('LocalEnv:', local.spreadsheet.getActiveSheet());
  console.log('GasEnv:', gas.spreadsheet.getActiveSheet());
}
```

## 6. ベストプラクティス

### 6.1 仕様書管理

- 仕様書は小さく分割する
- IDは自動生成に任せる
- 定期的に同期を実行する

### 6.2 Env実装

- ビジネスロジックはIEnvのみに依存
- LocalEnvで完全にテスト可能にする
- GAS固有のコードは最小限に

### 6.3 テスト戦略

- ユニットテスト: LocalEnv使用
- 統合テスト: LocalEnv + モックデータ
- E2Eテスト: Playwright + 実環境

### 6.4 品質保証

- すべての品質ゲートを通過させる
- テストカバレッジ80%以上を維持
- デプロイ前検証を必ず実行

## 7. 次のステップ

- [API リファレンス](api-reference.md)
- [アーキテクチャ設計](architecture.md)
- [要件定義書](../01_requirements/01_requirements.md)
- [セッション継続管理](../05_management/01_session_continuity.md)

---

**統合フレームワーク・仕様書駆動・GAS独立・品質保証**

最終更新: 2025-11-15
バージョン: 1.0.0
