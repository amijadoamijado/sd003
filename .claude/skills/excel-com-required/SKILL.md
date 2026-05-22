---
name: excel-com-required
description: Excel書式・罫線・列幅を保持する操作はExcel COM経由必須。xlsxライブラリ禁止。cf001再発防止。
applies_to:
  extensions: ["*.xlsx", "*.xls"]
  keywords: ["openpyxl", "XLSX.utils", "ExcelJS", "pandas.to_excel"]
severity: block
---

# excel-com-required

Excelファイルの書式（罫線・色・列幅・結合セル等）を保持しながら更新する操作は、**Excel COM (PowerShell + COM Automation) 必須**。openpyxl / xlsx-utils / ExcelJS / pandas.to_excel での書出は禁止。

## 背景

cf001プロジェクトで `consolidated_pl_update_skill.md` に「Excel COM必須・xlsxライブラリ禁止」と明記されていたが、AI が SKILL.md を未読のまま xlsx で書出し、書式・罫線・色・列幅が全破壊された事故。

## ルール

| 操作 | 許可 | 禁止 |
|------|------|------|
| 書式保持で更新 | PowerShell + Excel.Application COM | openpyxl, xlsx-utils, ExcelJS, pandas.to_excel |
| 値だけ読む | pandas.read_excel, openpyxl(read) | - |
| 新規作成（書式気にしない） | openpyxl 等 | - |

## 読んだら次にやること

1. **対象 .xlsx の用途を確認**: ユーザー提供の最終成果物か、AI生成の中間ファイルか
2. **ユーザー提供 / 最終成果物**: Excel COM 経由で更新。元ファイルは別名コピーしてから操作
3. **AI生成 / 中間ファイル**: 書式不要なら openpyxl 等で OK
4. **不明なら聞く**: 「このxlsxは書式保持必須ですか」をユーザーに確認

## 物理ガードレール

`enforce-skill-read.sh` がこのスキルIDをログ確認している。`*.xlsx` を含む Bash/Write/Edit はこのスタブを読まないと deny される。

## 関連

- cf001: `consolidated_pl_update_skill.md`（プロジェクト固有の詳細SKILL）
- 上書き禁止ルール: `.claude/rules/cleanup/file-organization.md`
