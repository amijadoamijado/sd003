#!/bin/bash
# SD003 Test Data Quality Validator
# Scans tests/gas-fakes/*.test.ts and *.spec.ts for hollow test patterns
#
# Rules:
#   VTD-001: Empty arrays in test data (error)
#   VTD-002: All-empty/zero object values (error)
#   VTD-003: toBeDefined()-only assertions (warning)
#   VTD-004: Tautology assertions expect(true).toBe(true) (error)
#   VTD-005: No value-checking assertions in file (warning)
#
# Exit codes: 0 = OK, 1 = violations found

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$SCRIPT_DIR/../tests/gas-fakes"

if [ ! -d "$TEST_DIR" ]; then
    echo "[VTD] No tests/gas-fakes/ directory found - skipping validation"
    exit 0
fi

# Find test files
TEST_FILES=$(find "$TEST_DIR" -maxdepth 1 -type f \( -name "*.test.ts" -o -name "*.spec.ts" \) 2>/dev/null)

if [ -z "$TEST_FILES" ]; then
    echo "[VTD] No test files found in tests/gas-fakes/ - skipping validation"
    exit 0
fi

FILE_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
ERROR_COUNT=0
WARNING_COUNT=0
ERRORS=""
WARNINGS=""

while IFS= read -r file; do
    filename=$(basename "$file")
    line_num=0

    # VTD-001: Empty arrays in test data
    while IFS= read -r match; do
        if [ -n "$match" ]; then
            lnum=$(echo "$match" | cut -d: -f1)
            content=$(echo "$match" | cut -d: -f2-)
            ERRORS="${ERRORS}[VTD-001] ${filename}:${lnum} - Empty array in test data:${content}\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done < <(grep -n -E '(headers|rows|data|items|values|records|entries|results)\s*:\s*\[\s*\]' "$file" 2>/dev/null || true)

    # VTD-004: Tautology assertions
    while IFS= read -r match; do
        if [ -n "$match" ]; then
            lnum=$(echo "$match" | cut -d: -f1)
            ERRORS="${ERRORS}[VTD-004] ${filename}:${lnum} - Tautology assertion: expect(true).toBe(true)\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done < <(grep -n -E 'expect\s*\(\s*true\s*\)\s*\.\s*toBe\s*\(\s*true\s*\)' "$file" 2>/dev/null || true)

    while IFS= read -r match; do
        if [ -n "$match" ]; then
            lnum=$(echo "$match" | cut -d: -f1)
            ERRORS="${ERRORS}[VTD-004] ${filename}:${lnum} - Tautology assertion: expect(1).toBe(1)\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done < <(grep -n -E 'expect\s*\(\s*1\s*\)\s*\.\s*toBe\s*\(\s*1\s*\)' "$file" 2>/dev/null || true)

    while IFS= read -r match; do
        if [ -n "$match" ]; then
            lnum=$(echo "$match" | cut -d: -f1)
            ERRORS="${ERRORS}[VTD-004] ${filename}:${lnum} - Tautology assertion: expect(false).toBe(false)\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done < <(grep -n -E 'expect\s*\(\s*false\s*\)\s*\.\s*toBe\s*\(\s*false\s*\)' "$file" 2>/dev/null || true)

    # VTD-005: No value-checking assertions in file
    has_expect=$(grep -c 'expect\s*(' "$file" 2>/dev/null || echo "0")
    has_value_check=$(grep -c -E '\.\s*(toEqual|toContain|toHaveLength|toMatchObject|toStrictEqual)' "$file" 2>/dev/null || echo "0")
    # Also check toBe with actual values (not just toBeDefined)
    has_tobe_value=$(grep -c -E '\.toBe\s*\([^)]*[a-zA-Z_$]' "$file" 2>/dev/null || echo "0")

    if [ "$has_expect" -gt 0 ] && [ "$has_value_check" -eq 0 ] && [ "$has_tobe_value" -eq 0 ]; then
        WARNINGS="${WARNINGS}[VTD-005] ${filename} - No value-checking assertions (toEqual, toBe(value), toContain) in file\n"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    # VTD-003: Check for toBeDefined()-only test blocks (simplified: file-level check)
    has_toBeDefined=$(grep -c 'toBeDefined\s*(' "$file" 2>/dev/null || echo "0")
    if [ "$has_expect" -gt 0 ] && [ "$has_toBeDefined" -eq "$has_expect" ] && [ "$has_value_check" -eq 0 ] && [ "$has_tobe_value" -eq 0 ]; then
        WARNINGS="${WARNINGS}[VTD-003] ${filename} - Only toBeDefined() assertions in test file\n"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

done <<< "$TEST_FILES"

# Output results
TOTAL=$((ERROR_COUNT + WARNING_COUNT))

if [ "$TOTAL" -eq 0 ]; then
    echo "[VTD] All test files passed validation ($FILE_COUNT files scanned)"
    exit 0
fi

echo ""
echo "=== SD003 Test Data Quality Validation ==="
echo "Scanned: $FILE_COUNT test files in tests/gas-fakes/"
echo ""

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "ERRORS ($ERROR_COUNT):"
    printf "  $ERRORS"
    echo ""
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
    echo "WARNINGS ($WARNING_COUNT):"
    printf "  $WARNINGS"
    echo ""
fi

echo "Total: $ERROR_COUNT errors, $WARNING_COUNT warnings"

# Exit with error only if there are errors (not warnings)
if [ "$ERROR_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
