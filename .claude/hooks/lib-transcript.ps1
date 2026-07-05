<#
.SYNOPSIS
    Shared helper for sd003 PowerShell Stop hooks (B2 fix).

.DESCRIPTION
    The Claude Code Stop-hook stdin JSON does NOT contain a `transcript` field
    with the conversation text -- it only contains `transcript_path`, a path to a
    JSONL transcript file (see .claude/hooks/claim_evidence_detect.py for the
    Python reference pattern already used elsewhere in this repo). The ps1 Stop
    hooks used to read `$json.transcript`, which is always $null (wrong field
    name) -> the hooks were permanent no-ops. This dot-sourced helper reads
    `transcript_path` and extracts the plain-text content of the JSONL transcript
    (assistant/user message text + tool_result text), which is what the hooks
    pattern-match against (e.g. "All tests pass", "FAIL", "Error:").

.NOTES
    Dot-source this file, then call Get-TranscriptTextFromStdinJson with the
    already-parsed stdin JSON object (or $null if parsing failed).
#>

function Get-TranscriptTextFromPath {
    param([string]$Path)

    if (-not $Path) { return "" }
    if (-not (Test-Path -LiteralPath $Path)) { return "" }

    $parts = New-Object System.Collections.Generic.List[string]

    Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction SilentlyContinue | ForEach-Object {
        $line = $_.Trim()
        if (-not $line) { return }

        try { $obj = $line | ConvertFrom-Json -ErrorAction Stop } catch { return }

        if ($obj.type -ne "assistant" -and $obj.type -ne "user") { return }

        $content = $obj.message.content
        if ($null -eq $content) { return }

        if ($content -is [string]) {
            if ($content) { $parts.Add($content) }
            return
        }

        foreach ($block in @($content)) {
            if ($null -eq $block) { continue }
            if ($block.type -eq "text") {
                if ($null -ne $block.text) { $parts.Add([string]$block.text) }
            }
            elseif ($block.type -eq "tool_result") {
                # tool_result content can itself be a string or a list of blocks
                # (e.g. bash/test output is where "All tests pass" / "FAIL" appear).
                $inner = $block.content
                if ($inner -is [string]) {
                    if ($inner) { $parts.Add($inner) }
                }
                elseif ($null -ne $inner) {
                    foreach ($iblock in @($inner)) {
                        if ($null -ne $iblock -and $iblock.type -eq "text" -and $null -ne $iblock.text) {
                            $parts.Add([string]$iblock.text)
                        }
                    }
                }
            }
        }
    }

    return ($parts -join "`n")
}

function Get-TranscriptTextFromStdinJson {
    param($JsonObj)

    if ($null -eq $JsonObj) { return "" }
    $path = $null
    if ($JsonObj.PSObject -and ($JsonObj.PSObject.Properties.Name -contains 'transcript_path')) {
        $path = $JsonObj.transcript_path
    }
    return Get-TranscriptTextFromPath -Path $path
}
