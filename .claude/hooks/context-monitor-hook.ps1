<#
.SYNOPSIS
    Context Monitor Hook for SD003 Refactoring System

.DESCRIPTION
    Monitors context usage and triggers autonomous actions:
    - 70%: sessionwrite + compact
    - 85%: sessionwrite + clear + sessionread

    Also detects refactoring completion markers and triggers session-autosave.

.NOTES
    Hook Type: Stop
    Exit Codes:
    - 0: Approve (with optional system message)

    This hook runs at the end of each turn to check state.
#>

$ErrorActionPreference = "Stop"

# Read input from stdin (JSON with transcript field)
$inputText = [Console]::In.ReadToEnd()

try {
    $json = $inputText | ConvertFrom-Json
    $transcript = $json.transcript
} catch {
    # No valid input, approve and continue
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Configuration
$configPath = Join-Path $env:CLAUDE_PROJECT_DIR ".kiro\refactor\config.json"
$config = @{
    context_autonomy = @{
        enabled = $true
        compact_threshold = 0.70
        clear_threshold = 0.85
    }
    session_autosave = @{
        enabled = $true
    }
}

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        # Use defaults
    }
}

# Skip if disabled
if (-not $config.context_autonomy.enabled) {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# ====================
# Context Estimation
# ====================

# Estimate context usage from transcript length
# Rough mapping: 800K chars ~ 100% of 200K tokens
$transcriptLength = $transcript.Length
$estimatedUsage = [math]::Min(1.0, $transcriptLength / 800000)
$usagePercent = [math]::Round($estimatedUsage * 100, 1)

# ====================
# Marker Detection
# ====================

# Session autosave markers
$autosaveMarkers = @(
    "REFACTOR_BATCH_\d+_COMPLETE",
    "ALL_TESTS_PASS",
    "LINT_CLEAN",
    "TYPE_CHECK_PASS",
    "REFACTOR_SESSION_INIT",
    "CHECKPOINT_CREATED"
)

$shouldAutosave = $false
foreach ($marker in $autosaveMarkers) {
    if ($transcript -match $marker) {
        $shouldAutosave = $true
        break
    }
}

# ====================
# Decision Logic
# ====================

$systemMessage = $null
$reason = "Normal operation"

# Check for critical threshold (85%)
if ($estimatedUsage -ge 0.85) {
    $systemMessage = @"
[CONTEXT-AUTONOMY] Context at ~$usagePercent%. CRITICAL threshold reached.
Executing autonomous clear cycle:
1. /sessionwrite - Preserving session state
2. /clear - Clearing context
3. /sessionread - Restoring session

This is automatic. Session data is preserved.
"@
    $reason = "Context critical - auto clear cycle"
}
# Check for compact threshold (70%)
elseif ($estimatedUsage -ge 0.70) {
    $systemMessage = @"
[CONTEXT-AUTONOMY] Context at ~$usagePercent%. Compact threshold reached.
Executing autonomous compact cycle:
1. /sessionwrite - Preserving session state
2. /compact - Compressing history

This is automatic. Session data is preserved.
"@
    $reason = "Context high - auto compact cycle"
}
# Check for session autosave trigger
elseif ($shouldAutosave -and $config.session_autosave.enabled) {
    $systemMessage = @"
[SESSION-AUTOSAVE] Completion marker detected.
Executing: /sessionwrite
Session state preserved automatically.
"@
    $reason = "Autosave triggered by completion marker"
}
# Check for 50% status log
elseif ($estimatedUsage -ge 0.50) {
    # Silent log, no action needed
    $reason = "Context at $usagePercent% - monitoring"
}

# ====================
# Output
# ====================

$output = @{
    decision = "approve"
    reason = $reason
}

if ($systemMessage) {
    $output.systemMessage = $systemMessage
}

$output | ConvertTo-Json -Compress
exit 0
