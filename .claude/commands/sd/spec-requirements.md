@req

---
description: Generate requirements document for a specification
allowed-tools: Read, Task
argument-hint: <feature-name>
---

# Requirements Generation

## Parse Arguments
- Feature name: `$1`

## Validate
Check that spec has been initialized:
- Verify `.sd/specs/$1/` exists
- Verify `.sd/specs/$1/spec.json` exists

If validation fails, inform user to run `/sd:spec-init` first.

## Invoke SubAgent

Delegate requirements generation to spec-requirements-agent:

Use the Task tool to invoke the SubAgent with file path patterns:

```
Task(
  subagent_type="general-purpose",
  description="Generate requirements document",
  prompt="""
Feature: $1
Spec directory: .sd/specs/$1/

File patterns to read:
- .sd/specs/$1/spec.json
- .sd/specs/$1/requirements.md
- .sessions/templates/requirements.md.template
- .sessions/templates/requirements-example.md

## Output Format

Use the template at `.sessions/templates/requirements.md.template` as the structure.
Refer to `.sessions/templates/requirements-example.md` for a concrete example.

## Writing Rules

### Structure (must follow this order)
1. **サマリー**: 課題・解決・効果・対象ユーザーを表形式で10行以内
2. **機能一覧**: F-NNN番号付き、各1-2行で全体像を先に見せる
3. **機能詳細**: 各機能について以下の4項目
   - ストーリー（1行、「〜が〜できる」形式）
   - ルール（箇条書き、平易な日本語）
   - データ（入力→出力の表）
   - 制約（やらないこと）
4. **用語集**: ドメイン固有の用語のみ
5. **テスト仕様への参照**: テスト条件は別ファイル `test-spec.md` に分離

### 禁止事項
- WHEN/THEN/SHALL 形式は使わない（平易な日本語ルールで書く）
- As a...I want...so that 形式は使わない（1行ストーリーで書く）
- Acceptance Criteria セクションは作らない（ルール + テスト仕様書に分離）
- 英語のサービス名（例: Client Management Service）は使わない（日本語で書く）
- テスト条件を要件定義書に混ぜない

### 品質基準
- 経営者が読んでも全体像がわかるサマリー
- AIが「次に何を実装すべきか」を判断できる機能一覧と詳細
- 人間が「全体像→詳細」の順で読める構造

Mode: generate
"""
)
```

## Display Result

Show SubAgent summary to user, then provide next step guidance:

### Next Phase: Design Generation

**If Requirements Approved**:
- Review generated requirements at `.sd/specs/$1/requirements.md`
- **Optional Gap Analysis** (for existing codebases):
  - Run `/sd:validate-gap $1` to analyze implementation gap with current code
  - Identifies existing components, integration points, and implementation strategy
  - Recommended for brownfield projects; skip for greenfield
- Then `/sd:spec-design $1 [-y]` to proceed to design phase

**If Modifications Needed**:
- Provide feedback and re-run `/sd:spec-requirements $1`

**Note**: Approval is mandatory before proceeding to design phase.
---
@req: REQ-SUBAGENTS-002
