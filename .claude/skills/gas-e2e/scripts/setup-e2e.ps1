# setup-e2e.ps1 - GAS E2E テスト環境セットアップ
# Usage: powershell -ExecutionPolicy Bypass -File .claude/skills/gas-e2e/scripts/setup-e2e.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== GAS E2E Test Environment Setup ===" -ForegroundColor Cyan

# Step 1: Playwright Chromium インストール
Write-Host "`n[1/3] Installing Playwright Chromium browser..." -ForegroundColor Yellow
$env:PLAYWRIGHT_BROWSERS_PATH = "F:\playwright-browsers"
npx playwright install chromium
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Playwright Chromium install failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Chromium installed to: F:\playwright-browsers" -ForegroundColor Green

# Step 2: OS依存ライブラリ（Windowsでは通常不要だが念のため試行）
Write-Host "`n[2/3] Installing OS dependencies (may skip on Windows)..." -ForegroundColor Yellow
try {
    npx playwright install-deps chromium 2>$null
    Write-Host "  OS dependencies installed." -ForegroundColor Green
} catch {
    Write-Host "  Skipped (not required on Windows)." -ForegroundColor DarkGray
}

# Step 3: 専用E2Eプロファイルディレクトリ作成
$profileDir = "F:\playwright-browsers\gas-e2e-profile"
Write-Host "`n[3/3] Creating E2E profile directory..." -ForegroundColor Yellow
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "  Created: $profileDir" -ForegroundColor Green
} else {
    Write-Host "  Already exists: $profileDir" -ForegroundColor DarkGray
}

# 完了メッセージ
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  Mode 1 (claude-in-chrome): Ready to use. No additional setup needed."
Write-Host "  Mode 2 (connect_over_cdp):  Start Chrome with --remote-debugging-port=9222"
Write-Host "  Mode 3 (persistent_context): Close Chrome, then run your test script."
Write-Host "    First run requires manual Google login in the browser."
Write-Host ""
