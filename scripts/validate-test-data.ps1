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

$ErrorActionPreference = "Stop"

$testDir = Join-Path $PSScriptRoot "..\tests\gas-fakes"

if (-not (Test-Path $testDir -PathType Container)) {
    Write-Host "[VTD] No tests/gas-fakes/ directory found - skipping validation"
    exit 0
}

$testFiles = Get-ChildItem -Path $testDir -File | Where-Object {
    $_.Name -match '\.(test|spec)\.ts$'
}

if ($testFiles.Count -eq 0) {
    Write-Host "[VTD] No test files found in tests/gas-fakes/ - skipping validation"
    exit 0
}

$errors = @()
$warnings = @()

foreach ($file in $testFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    $relativePath = $file.Name
    $inTestBlock = $false
    $braceDepth = 0
    $testBlockAssertions = @()
    $testBlockStart = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNum = $i + 1

        # Track test block boundaries (it( or test( )
        if ($line -match '^\s*(it|test)\s*\(') {
            $inTestBlock = $true
            $braceDepth = 0
            $testBlockAssertions = @()
            $testBlockStart = $lineNum
        }

        if ($inTestBlock) {
            # Count braces to track block depth
            $braceDepth += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
            $braceDepth -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count

            # VTD-001: Empty arrays in test data
            if ($line -match '(headers|rows|data|items|values|records|entries|results)\s*:\s*\[\s*\]') {
                $matched = $Matches[0]
                $errors += "[VTD-001] ${relativePath}:${lineNum} - Empty array in test data: $matched"
            }

            # VTD-002: All-empty/zero object values (detect objects where all values are empty/zero/null)
            if ($line -match '\{\s*((\w+)\s*:\s*(''''|""|0|null|undefined)\s*,?\s*){2,}\}') {
                $errors += "[VTD-002] ${relativePath}:${lineNum} - All-empty/zero values in test object"
            }

            # VTD-004: Tautology assertions
            if ($line -match 'expect\s*\(\s*true\s*\)\s*\.\s*toBe\s*\(\s*true\s*\)') {
                $errors += "[VTD-004] ${relativePath}:${lineNum} - Tautology assertion: expect(true).toBe(true)"
            }
            if ($line -match 'expect\s*\(\s*1\s*\)\s*\.\s*toBe\s*\(\s*1\s*\)') {
                $errors += "[VTD-004] ${relativePath}:${lineNum} - Tautology assertion: expect(1).toBe(1)"
            }
            if ($line -match 'expect\s*\(\s*false\s*\)\s*\.\s*toBe\s*\(\s*false\s*\)') {
                $errors += "[VTD-004] ${relativePath}:${lineNum} - Tautology assertion: expect(false).toBe(false)"
            }

            # Track assertions in this test block
            if ($line -match 'expect\s*\(') {
                if ($line -match '\.\s*toBeDefined\s*\(') {
                    $testBlockAssertions += "toBeDefined"
                } elseif ($line -match '\.\s*(toEqual|toBe|toContain|toHaveLength|toMatchObject|toStrictEqual|toThrow|toHaveBeenCalled)') {
                    $testBlockAssertions += "value-check"
                } else {
                    $testBlockAssertions += "other"
                }
            }

            # End of test block
            if ($braceDepth -le 0 -and $inTestBlock -and $lineNum -gt $testBlockStart) {
                # VTD-003: Only toBeDefined() assertions in this test block
                if ($testBlockAssertions.Count -gt 0) {
                    $uniqueAssertions = $testBlockAssertions | Sort-Object -Unique
                    if ($uniqueAssertions.Count -eq 1 -and $uniqueAssertions[0] -eq "toBeDefined") {
                        $warnings += "[VTD-003] ${relativePath}:${testBlockStart} - Only toBeDefined() assertions in test block"
                    }
                }
                $inTestBlock = $false
            }
        }
    }

    # VTD-005: No value-checking assertions in entire file
    $fileContent = Get-Content $file.FullName -Raw -Encoding UTF8
    $hasValueChecks = $fileContent -match '\.\s*(toEqual|toBe\s*\([^)]*[^truefalse1]|toContain|toHaveLength|toMatchObject|toStrictEqual)'
    $hasExpect = $fileContent -match 'expect\s*\('
    if ($hasExpect -and -not $hasValueChecks) {
        $warnings += "[VTD-005] ${relativePath} - No value-checking assertions (toEqual, toBe(value), toContain) in file"
    }
}

# Output results
$totalViolations = $errors.Count + $warnings.Count

if ($totalViolations -eq 0) {
    Write-Host "[VTD] All test files passed validation ($($testFiles.Count) files scanned)" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "=== SD003 Test Data Quality Validation ===" -ForegroundColor Cyan
Write-Host "Scanned: $($testFiles.Count) test files in tests/gas-fakes/" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -gt 0) {
    Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "  $e" -ForegroundColor Red
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  $w" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "Total: $($errors.Count) errors, $($warnings.Count) warnings" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Yellow" })

# Exit with error only if there are errors (not warnings)
if ($errors.Count -gt 0) {
    exit 1
}
exit 0
