# Silent Interior（内部は黙って動け）

## 原則

> 内部実装（adapter / core / interface / types）は**動けばよい**。
> 内部設計の優雅さを議論しない。内部の議論は output を阻害する時のみ許可。

## 背景

プロジェクト開始時に adapter-core 分離、Env Interface Pattern、Result型を導入しようとして、
動くものができる前に型定義と interface の設計に時間を溶かす失敗が繰り返されてきた。
「内部を綺麗に作れば結果も良くなる」は幻想。動くものが先。

## 適用

### 開発順序（厳守）

```
1. 画面スケルトンを作る（HTML/CSS ベタ書きでいい）
2. 実データまたはコピーで動かす
3. 動く状態で内部を整える
4. 3回以上同じコードが出たら抽象化を検討する
```

**逆順は禁止**:
```
❌ 型定義 → interface → adapter → core → UI → 動かない
```

### 議論の制限

内部設計の議論は以下の条件でのみ許可:
- **output を阻害している**時のみ
- 修正が output の成立期限より短い時のみ

以下の議論は**打ち切り対象**:
- 「もっと綺麗なインターフェース設計」
- 「再利用性のための抽象化」
- 「将来の拡張性」
- 「型の美しさ」（`any` 禁止は守るが、それ以上の追求は不要）
- 「adapter と core の責任分離の厳密化」

### パターン適用の順序

| パターン | いつ適用するか |
|---------|--------------|
| Adapter-Core分離 | output が安定し、データ源が2つ以上になった時 |
| Env Interface Pattern | GAS と Local 両方で動かす必要が出た時 |
| Result型 | エラー処理が3箇所以上で複雑化した時 |
| 型定義の厳密化 | `any` が消せなくなった時に部分導入 |

**最初から全パターンを導入しない。** 動くものが先。

### コードレビューでの扱い

Codex レビューで内部設計に関する Request Changes を出す場合:
- **output が破綻していない** → コメントのみ（承認ブロックしない）
- **output に影響がある** → Request Changes 可
- 「もっと良い設計」提案は別タスク化（今の PR を止めない）

## 禁止事項

| 禁止 | 理由 |
|------|------|
| 動いていないものに型定義・interface を書く | 柱3違反（real data first） |
| 最初から Adapter-Core を導入する | 動くものが先 |
| 「綺麗さ」で Request Changes を出す | 柱1違反（output 優先） |
| interface-first / types-first 開発 | 柱4違反（段取り逆転） |
| 未使用の将来拡張コード | YAGNI |

## 品質基準との関係

`.claude/rules/global/quality-standards.md` の基準は「内部が黙って動くための最低ライン」。
以下は守る（Silent Interior の「黙って動く」の条件）:
- TypeScript strict
- `any` 禁止（`unknown` + 型ガードで代替）
- `@ts-nocheck` / `@ts-ignore` 禁止
- ESLint エラー 0件

これらは「品質追求」ではなく「動かすための最低条件」。
これを超えた「美しさ」への投資は柱2違反。

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。

## 関連

- ドクトリン: `docs/core-doctrine.md` 柱2
- 品質基準: `.claude/rules/global/quality-standards.md`
- Adapter-Core: `.claude/rules/architecture/adapter-core-pattern.md`（動いた後に適用）
