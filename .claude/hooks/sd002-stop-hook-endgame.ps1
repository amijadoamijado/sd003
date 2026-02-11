# SD002 Stop Hook - Endgame Phase (Windows PowerShell)
# Purpose: Track error patterns, escalate to /dialogue-resolution after 2nd occurrence
#
# Exit codes:
#   0 = Success (with JSON output)
#   2 = Block (escalate to dialogue-resolution)

$ErrorActionPreference = "Stop"

# Error tracking file
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$errorLog = Join-Path $projectDir ".claude\hooks\.error-patterns.log"

# Read JSON input from stdin
$input_text = [Console]::In.ReadToEnd()

# Extract transcript from JSON
try {
    $json = $input_text | ConvertFrom-Json
    $transcript = $json.transcript
} catch {
    $transcript = ""
}

if (-not $transcript) { $transcript = "" }

# Check for test success - approve stopping
if ($transcript -match "(All tests pass|Tests:.*passing|0 failing|ALL_TESTS_PASS)") {
    # Clear error log on success
    if (Test-Path $errorLog) { Remove-Item $errorLog -Force -ErrorAction SilentlyContinue }
    Write-Output '{"decision": "approve", "reason": "All tests passed"}'
    exit 0
}

# Extract error signature (first error line)
$errorSig = ""
if ($transcript -match "(Error:.*|FAIL.*|TypeError.*|ReferenceError.*)") {
    $errorSig = $Matches[0].Substring(0, [Math]::Min(100, $Matches[0].Length))
}

if (-not $errorSig) {
    Write-Output '{"decision": "approve", "reason": "No error pattern detected"}'
    exit 0
}

# Create error log if not exists
$logDir = Split-Path $errorLog -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
if (-not (Test-Path $errorLog)) { New-Item -ItemType File -Path $errorLog -Force | Out-Null }

# Count occurrences of this error pattern
$errorCount = 0
if (Test-Path $errorLog) {
    $content = Get-Content $errorLog -ErrorAction SilentlyContinue
    if ($content) {
        $errorCount = ($content | Where-Object { $_ -eq $errorSig }).Count
    }
}

# Log this occurrence
Add-Content -Path $errorLog -Value $errorSig

if ($errorCount -ge 1) {
    # 2nd occurrence - escalate
    Write-Error "Same error pattern detected $errorCount times. Escalating to /dialogue-resolution"
    $response = @{
        decision = "block"
        reason = "Same error pattern repeated. Escalate to /dialogue-resolution for structured problem solving."
        systemMessage = "ESCALATION: Same error occurred 2+ times. Use /dialogue-resolution to diagnose the root cause through structured dialogue."
    } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
} else {
    # 1st occurrence - allow one more attempt
    $response = @{
        decision = "block"
        reason = "Error detected (1st occurrence). One more auto-fix attempt allowed."
        systemMessage = "Error pattern logged. If this error repeats, will escalate to /dialogue-resolution."
    } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
}
