#!/usr/bin/env bash
# setup-e2e.sh - GAS E2E テスト環境セットアップ
# Usage: bash .claude/skills/gas-e2e/scripts/setup-e2e.sh

set -euo pipefail

echo "=== GAS E2E Test Environment Setup ==="

# Step 1: Playwright Chromium インストール
echo ""
echo "[1/3] Installing Playwright Chromium browser..."
export PLAYWRIGHT_BROWSERS_PATH="D:/playwright-browsers"
npx playwright install chromium
echo "  Chromium installed to: D:/playwright-browsers"

# Step 2: OS依存ライブラリ
echo ""
echo "[2/3] Installing OS dependencies (may skip on Windows)..."
if npx playwright install-deps chromium 2>/dev/null; then
    echo "  OS dependencies installed."
else
    echo "  Skipped (not required on Windows)."
fi

# Step 3: 専用E2Eプロファイルディレクトリ作成
PROFILE_DIR="D:/playwright-browsers/gas-e2e-profile"
echo ""
echo "[3/3] Creating E2E profile directory..."
if [ ! -d "$PROFILE_DIR" ]; then
    mkdir -p "$PROFILE_DIR"
    echo "  Created: $PROFILE_DIR"
else
    echo "  Already exists: $PROFILE_DIR"
fi

# 完了メッセージ
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  Mode 1 (claude-in-chrome): Ready to use. No additional setup needed."
echo "  Mode 2 (connect_over_cdp):  Start Chrome with --remote-debugging-port=9222"
echo "  Mode 3 (persistent_context): Close Chrome, then run your test script."
echo "    First run requires manual Google login in the browser."
echo ""
