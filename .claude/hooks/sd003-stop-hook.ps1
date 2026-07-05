# SD003 Stop Hook - Midpoint Phase (Windows PowerShell)
# Purpose: Loop until all tests pass (max 20 iterations)
#
# Exit codes:
#   0 = Success (stop approved)
#   2 = Block (continue looping)
#
# 2026-07-05 B2 fix: the Stop-hook stdin JSON has no `transcript` field -- only
# `transcript_path` (a path to the JSONL transcript file). This hook used to read
# $json.transcript, which is always $null (wrong field name) -> permanent no-op.
# Now it dot-sources lib-transcript.ps1 to resolve transcript_path and extract the
# transcript's plain text from the JSONL file.

$ErrorActionPreference = "Stop"

# Read JSON input from stdin
$input_text = [Console]::In.ReadToEnd()

try {
    $json = $input_text | ConvertFrom-Json
} catch {
    $json = $null
}

. (Join-Path $PSScriptRoot "lib-transcript.ps1")
$transcript = Get-TranscriptTextFromStdinJson -JsonObj $json
if (-not $transcript) { $transcript = "" }

# Check for test success markers
if ($transcript -match "(All tests pass|Tests:.*passing|0 failing|ALL_TESTS_PASS)") {
    # Validate test data quality before approving
    $vtdScript = Join-Path $PSScriptRoot "..\..\scripts\validate-test-data.ps1"
    if (Test-Path $vtdScript) {
        $vtdResult = & powershell -ExecutionPolicy Bypass -File $vtdScript 2>&1
        if ($LASTEXITCODE -ne 0) {
            $vtdOutput = $vtdResult -join "`n"
            Write-Output "{`"decision`": `"block`", `"reason`": `"Tests pass but test data quality validation failed. Fix VTD violations before proceeding.`"}"
            exit 0
        }
    }
    Write-Output '{"decision": "approve", "reason": "All tests passed - stopping loop"}'
    exit 0
}

# Check for explicit completion markers
if ($transcript -match "(BUILD SUCCESS|Compilation successful|No errors)") {
    Write-Output '{"decision": "approve", "reason": "Build/compilation successful"}'
    exit 0
}

# Check for test failures - continue looping
if ($transcript -match "(FAIL|failing|failed|Error:|error:)") {
    Write-Output '{"decision": "block", "reason": "Tests still failing - continue loop"}'
    exit 0
}

# Default: approve stopping (no clear test context)
Write-Output '{"decision": "approve", "reason": "No test context detected"}'
exit 0
