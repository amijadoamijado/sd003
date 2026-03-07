# SD003 Framework Deployment Script v3.1.0 (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1 <target-project-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject
)

$ErrorActionPreference = "Stop"

# Configuration
$SD003_VERSION = "3.1.0"
$FRAMEWORK_VERSION = "2.13.0"
$SOURCE_DIR = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$DATE = Get-Date -Format "yyyy-MM-dd"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=== SD003 Framework Deployment v${SD003_VERSION} ===" -ForegroundColor Cyan
Write-Host "Framework: v${FRAMEWORK_VERSION}"
Write-Host "Source: $SOURCE_DIR"
Write-Host "Target: $TargetProject"
Write-Host ""

# ============================================================
# Phase 1: Validate
# ============================================================
if (-not (Test-Path $TargetProject -PathType Container)) {
    Write-Host "Error: Target project '$TargetProject' not found" -ForegroundColor Red
    exit 1
}
Write-Host "[Phase 1/7] Target validated" -ForegroundColor Green

# ============================================================
# Phase 2: Backup
# ============================================================
$BackupDir = Join-Path $TargetProject ".sd003-backup-$TIMESTAMP"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$backupTargets = @("CLAUDE.md", "gemini.md")
foreach ($f in $backupTargets) {
    $path = Join-Path $TargetProject $f
    if (Test-Path $path) {
        Copy-Item $path $BackupDir -Force
    }
}

$backupDirs = @(".claude", ".gemini", ".kiro", ".antigravity")
foreach ($d in $backupDirs) {
    $path = Join-Path $TargetProject $d
    if (Test-Path $path -PathType Container) {
        Copy-Item $path $BackupDir -Recurse -Force
    }
}
Write-Host "[Phase 2/7] Backup created: $BackupDir" -ForegroundColor Green

# ============================================================
# Phase 3: Create directory structure
# ============================================================
$directories = @(
    ".claude/commands/kiro",
    ".claude/rules",
    ".claude/skills",
    ".claude/hooks",
    ".gemini/commands",
    ".kiro/specs",
    ".kiro/steering",
    ".kiro/sessions",
    ".kiro/settings",
    ".kiro/ids",
    ".kiro/traceability",
    ".kiro/ai-coordination/workflow/templates",
    ".kiro/ai-coordination/workflow/spec",
    ".kiro/ai-coordination/workflow/review",
    ".kiro/ai-coordination/workflow/log",
    ".kiro/ai-coordination/handoff",
    ".antigravity",
    ".handoff",
    ".kiro/ralph",
    ".kiro/refactor",
    "docs/troubleshooting/bug-reports",
    "materials/csv",
    "materials/excel",
    "materials/pdf",
    "materials/images",
    "materials/text"
)

foreach ($dir in $directories) {
    $path = Join-Path $TargetProject $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}
Write-Host "[Phase 3/7] Directory structure created" -ForegroundColor Green

# ============================================================
# Phase 4: Dynamic copy (directory-based)
# ============================================================
$copyStats = @{}

# Helper function: copy directory tree
function Copy-DirTree {
    param(
        [string]$RelPath,
        [string]$Label,
        [string]$Filter = "*"
    )
    $src = Join-Path $SOURCE_DIR $RelPath
    $dst = Join-Path $TargetProject $RelPath
    $count = 0

    if (-not (Test-Path $src -PathType Container)) {
        Write-Host "  WARN: Source not found: $RelPath" -ForegroundColor Yellow
        $copyStats[$Label] = 0
        return
    }

    # Ensure destination exists
    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    # Copy entire tree preserving structure
    $items = Get-ChildItem -Path $src -Recurse -File -Filter $Filter
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($src.Length)
        $destPath = Join-Path $dst $relativePath
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $item.FullName $destPath -Force
        $count++
    }

    $copyStats[$Label] = $count
}

# Helper function: copy flat directory (*.ext only)
function Copy-FlatDir {
    param(
        [string]$RelPath,
        [string]$Label,
        [string]$Extension = ".md"
    )
    $src = Join-Path $SOURCE_DIR $RelPath
    $dst = Join-Path $TargetProject $RelPath
    $count = 0

    if (-not (Test-Path $src -PathType Container)) {
        Write-Host "  WARN: Source not found: $RelPath" -ForegroundColor Yellow
        $copyStats[$Label] = 0
        return
    }

    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    $items = Get-ChildItem -Path $src -File -Filter "*$Extension"
    foreach ($item in $items) {
        Copy-Item $item.FullName (Join-Path $dst $item.Name) -Force
        $count++
    }

    $copyStats[$Label] = $count
}

# 4-1: .claude/commands/*.md
Copy-FlatDir -RelPath ".claude\commands" -Label "Commands" -Extension ".md"

# 4-2: .claude/commands/kiro/*.md
Copy-FlatDir -RelPath ".claude\commands\kiro" -Label "Commands/kiro" -Extension ".md"

# 4-3: .claude/rules/ (tree)
Copy-DirTree -RelPath ".claude\rules" -Label "Rules" -Filter "*.md"

# 4-4: .claude/skills/ (tree)
Copy-DirTree -RelPath ".claude\skills" -Label "Skills"

# 4-5: .claude/hooks/ (tree)
Copy-DirTree -RelPath ".claude\hooks" -Label "Hooks"

# 4-6: .gemini/commands/ (flat, .toml)
Copy-FlatDir -RelPath ".gemini\commands" -Label "Gemini Commands" -Extension ".toml"

# 4-7: .antigravity/ (tree)
Copy-DirTree -RelPath ".antigravity" -Label "Antigravity"

# 4-8: .kiro/settings/ (tree)
Copy-DirTree -RelPath ".kiro\settings" -Label "Kiro Settings"

# 4-9: .kiro/sessions/session-template.md (single file)
$sessionTemplateSrc = Join-Path $SOURCE_DIR ".kiro\sessions\session-template.md"
if (Test-Path $sessionTemplateSrc) {
    Copy-Item $sessionTemplateSrc (Join-Path $TargetProject ".kiro\sessions\session-template.md") -Force
    $copyStats["Session Template"] = 1
} else {
    Write-Host "  WARN: session-template.md not found" -ForegroundColor Yellow
    $copyStats["Session Template"] = 0
}

# 4-10: .kiro/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}
$workflowSrc = Join-Path $SOURCE_DIR ".kiro\ai-coordination\workflow"
$workflowDst = Join-Path $TargetProject ".kiro\ai-coordination\workflow"
$wfCount = 0

foreach ($f in @("README.md", "CODEX_GUIDE.md")) {
    $src = Join-Path $workflowSrc $f
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $workflowDst $f) -Force
        $wfCount++
    }
}

$templatesSrc = Join-Path $workflowSrc "templates"
$templatesDst = Join-Path $workflowDst "templates"
if (Test-Path $templatesSrc -PathType Container) {
    $items = Get-ChildItem -Path $templatesSrc -File
    foreach ($item in $items) {
        Copy-Item $item.FullName (Join-Path $templatesDst $item.Name) -Force
        $wfCount++
    }
}
$copyStats["AI Coordination"] = $wfCount

# 4-11: docs/troubleshooting/
Copy-DirTree -RelPath "docs\troubleshooting" -Label "Docs/Troubleshooting"

# 4-12: docs/quality-gates.md
$qgSrc = Join-Path $SOURCE_DIR "docs\quality-gates.md"
if (Test-Path $qgSrc) {
    Copy-Item $qgSrc (Join-Path $TargetProject "docs\quality-gates.md") -Force
    $copyStats["Docs/QualityGates"] = 1
} else {
    $copyStats["Docs/QualityGates"] = 0
}

# 4-13: .handoff/ (tree)
Copy-DirTree -RelPath ".handoff" -Label "Handoff"

# 4-14: scripts/sync-codex-prompts.js (single file)
$syncCodexSrc = Join-Path $SOURCE_DIR "scripts\sync-codex-prompts.js"
if (Test-Path $syncCodexSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item $syncCodexSrc (Join-Path $scriptsDst "sync-codex-prompts.js") -Force
    $copyStats["Sync Codex"] = 1
} else {
    $copyStats["Sync Codex"] = 0
}

# 4-15: scripts/sync-gemini-features.js (single file)
$syncGeminiSrc = Join-Path $SOURCE_DIR "scripts\sync-gemini-features.js"
if (Test-Path $syncGeminiSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item $syncGeminiSrc (Join-Path $scriptsDst "sync-gemini-features.js") -Force
    $copyStats["Sync Gemini"] = 1
} else {
    $copyStats["Sync Gemini"] = 0
}

# 4-16: AGENTS.md (single file)
$agentsSrc = Join-Path $SOURCE_DIR "AGENTS.md"
if (Test-Path $agentsSrc) {
    Copy-Item $agentsSrc (Join-Path $TargetProject "AGENTS.md") -Force
    $copyStats["AGENTS.md"] = 1
} else {
    $copyStats["AGENTS.md"] = 0
}

# 4-17: .kiro/ralph/ (tree)
Copy-DirTree -RelPath ".kiro\ralph" -Label "Ralph"

# 4-18: .kiro/steering/ (tree)
Copy-DirTree -RelPath ".kiro\steering" -Label "Steering"

# 4-19: .kiro/refactor/config.json (single file)
$refactorCfgSrc = Join-Path $SOURCE_DIR ".kiro\refactor\config.json"
if (Test-Path $refactorCfgSrc) {
    $refactorDst = Join-Path $TargetProject ".kiro\refactor"
    if (-not (Test-Path $refactorDst)) { New-Item -ItemType Directory -Path $refactorDst -Force | Out-Null }
    Copy-Item $refactorCfgSrc (Join-Path $refactorDst "config.json") -Force
    $copyStats["Refactor Config"] = 1
} else {
    $copyStats["Refactor Config"] = 0
}

# 4-20: tests/gas-fakes/setup.ts (single file)
$gasFakesSrc = Join-Path $SOURCE_DIR "tests\gas-fakes\setup.ts"
if (Test-Path $gasFakesSrc) {
    $gasFakesDst = Join-Path $TargetProject "tests\gas-fakes"
    if (-not (Test-Path $gasFakesDst)) { New-Item -ItemType Directory -Path $gasFakesDst -Force | Out-Null }
    Copy-Item $gasFakesSrc (Join-Path $gasFakesDst "setup.ts") -Force
    $copyStats["Gas Fakes Setup"] = 1
} else {
    Write-Host "  WARN: tests/gas-fakes/setup.ts not found" -ForegroundColor Yellow
    $copyStats["Gas Fakes Setup"] = 0
}

Write-Host "[Phase 4/7] Dynamic copy completed" -ForegroundColor Green
foreach ($key in $copyStats.Keys | Sort-Object) {
    Write-Host "  $key : $($copyStats[$key]) files"
}

# ============================================================
# Phase 5: Generate files
# ============================================================
$ProjectName = Split-Path $TargetProject -Leaf

# 5-1: CLAUDE.md from template
$claudeTemplate = Join-Path $SOURCE_DIR ".claude\skills\kiro-deploy\templates\CLAUDE.md.template"
if (Test-Path $claudeTemplate) {
    $content = Get-Content $claudeTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'v2\.3\.0', "v$FRAMEWORK_VERSION"
    Set-Content -Path (Join-Path $TargetProject "CLAUDE.md") -Value $content -Encoding UTF8
} else {
    Write-Host "  WARN: CLAUDE.md.template not found, skipping" -ForegroundColor Yellow
}

# 5-2: gemini.md from template
$geminiTemplate = Join-Path $SOURCE_DIR ".claude\skills\kiro-deploy\templates\gemini.md.template"
if (Test-Path $geminiTemplate) {
    $content = Get-Content $geminiTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'v2\.3\.0', "v$FRAMEWORK_VERSION"
    Set-Content -Path (Join-Path $TargetProject "gemini.md") -Value $content -Encoding UTF8
} else {
    Write-Host "  WARN: gemini.md.template not found, skipping" -ForegroundColor Yellow
}

# 5-3: session-current.md (new)
$sessionCurrentContent = @"
# Session Record

## Session Info
- **Date**: $DATE
- **Project**: $ProjectName
- **Branch**: main
- **Latest Commit**: (initialized)

## Progress Summary

### Completed
- SD003 Framework v${FRAMEWORK_VERSION} deployed

### In Progress
- (none)

### Next Session Tasks
- P1 (Important): Run /sessionread to verify

### Notes
Initialized with SD003 v${FRAMEWORK_VERSION}.
"@
Set-Content -Path (Join-Path $TargetProject ".kiro\sessions\session-current.md") -Value $sessionCurrentContent -Encoding UTF8

# 5-4: TIMELINE.md (new)
$timelineContent = @"
# $ProjectName - Project Timeline

## Overview
- **Project**: $ProjectName
- **Created**: $DATE
- **Framework**: SD003 v${FRAMEWORK_VERSION}

---

## Timeline

### $DATE - Project Initialized
- SD003 Framework v${FRAMEWORK_VERSION} deployed
"@
Set-Content -Path (Join-Path $TargetProject ".kiro\sessions\TIMELINE.md") -Value $timelineContent -Encoding UTF8

# 5-5: .claude/settings.json (OS-aware)
$settingsContent = @"
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"`$CLAUDE_PROJECT_DIR\\.claude\\hooks\\sd003-stop-hook.ps1\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
"@
Set-Content -Path (Join-Path $TargetProject ".claude\settings.json") -Value $settingsContent -Encoding UTF8

# 5-6: .kiro/ids/registry.json (new)
$isoDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$registryContent = @"
{
  "version": "1.0.0",
  "created": "$isoDate",
  "project": "$ProjectName",
  "requirements": {},
  "specifications": {},
  "last_updated": "$isoDate"
}
"@
Set-Content -Path (Join-Path $TargetProject ".kiro\ids\registry.json") -Value $registryContent -Encoding UTF8

# 5-7: handoff-log.json (new)
$handoffContent = @"
{
  "version": "2.0.0",
  "entries": []
}
"@
Set-Content -Path (Join-Path $TargetProject ".kiro\ai-coordination\handoff\handoff-log.json") -Value $handoffContent -Encoding UTF8

# 5b: Inject gas-fakes into target package.json (if it exists)
$targetPkg = Join-Path $TargetProject "package.json"
if (Test-Path $targetPkg) {
    $pkgContent = Get-Content $targetPkg -Raw -Encoding UTF8 | ConvertFrom-Json
    $needsUpdate = $false

    if (-not $pkgContent.devDependencies) {
        $pkgContent | Add-Member -NotePropertyName "devDependencies" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    if (-not $pkgContent.devDependencies.'@mcpher/gas-fakes') {
        $pkgContent.devDependencies | Add-Member -NotePropertyName "@mcpher/gas-fakes" -NotePropertyValue "^1.2.0" -Force
        $needsUpdate = $true
    }

    if (-not $pkgContent.scripts) {
        $pkgContent | Add-Member -NotePropertyName "scripts" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    if (-not $pkgContent.scripts.'test:gas-fakes') {
        $pkgContent.scripts | Add-Member -NotePropertyName "test:gas-fakes" -NotePropertyValue "jest --testPathPatterns=tests/gas-fakes/ --setupFiles=./tests/gas-fakes/setup.ts --passWithNoTests" -Force
        $needsUpdate = $true
    }

    if ($needsUpdate) {
        $pkgContent | ConvertTo-Json -Depth 10 | Set-Content $targetPkg -Encoding UTF8
        Write-Host "  [Phase 5b] gas-fakes injected into package.json" -ForegroundColor Green
    } else {
        Write-Host "  [Phase 5b] gas-fakes already present in package.json, skipping" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [Phase 5b] No package.json found, skipping gas-fakes injection" -ForegroundColor Yellow
}

# 5-8: User-level CLAUDE.md (initial setup for ~/.claude/CLAUDE.md)
$userClaudeTemplate = Join-Path $SOURCE_DIR ".claude\skills\kiro-deploy\templates\user-claude.md.template"
$userClaudeDir = Join-Path $env:USERPROFILE ".claude"
$userClaudeFile = Join-Path $userClaudeDir "CLAUDE.md"
if (Test-Path $userClaudeTemplate) {
    if (-not (Test-Path $userClaudeFile)) {
        if (-not (Test-Path $userClaudeDir)) { New-Item -ItemType Directory -Path $userClaudeDir -Force | Out-Null }
        Copy-Item $userClaudeTemplate $userClaudeFile
        Write-Host "  [Phase 5-8] User CLAUDE.md created: $userClaudeFile" -ForegroundColor Green
    } else {
        Write-Host "  [Phase 5-8] User CLAUDE.md already exists, skipping: $userClaudeFile" -ForegroundColor Yellow
    }
} else {
    Write-Host "  WARN: user-claude.md.template not found, skipping" -ForegroundColor Yellow
}

Write-Host "[Phase 5/7] Generated files created" -ForegroundColor Green

# ============================================================
# Phase 6: Verification (source vs target file count)
# ============================================================
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan

$verifyResults = @()
$allPassed = $true

function Verify-Category {
    param(
        [string]$Label,
        [string]$SourceRelPath,
        [string]$TargetRelPath = $SourceRelPath,
        [string]$Filter = "*",
        [switch]$Recurse
    )

    $srcPath = Join-Path $SOURCE_DIR $SourceRelPath
    $dstPath = Join-Path $TargetProject $TargetRelPath

    if ($Recurse) {
        $srcCount = (Get-ChildItem -Path $srcPath -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
        $dstCount = (Get-ChildItem -Path $dstPath -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
    } else {
        $srcCount = (Get-ChildItem -Path $srcPath -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
        $dstCount = (Get-ChildItem -Path $dstPath -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    $status = if ($dstCount -ge $srcCount) { "PASS" } else { "FAIL" }
    if ($status -eq "FAIL") { $script:allPassed = $false }

    return [PSCustomObject]@{
        Category = $Label
        Source = $srcCount
        Target = $dstCount
        Status = $status
    }
}

$verifyResults += Verify-Category -Label "Commands" -SourceRelPath ".claude\commands" -Filter "*.md"
$verifyResults += Verify-Category -Label "Commands/kiro" -SourceRelPath ".claude\commands\kiro" -Filter "*.md"
$verifyResults += Verify-Category -Label "Rules" -SourceRelPath ".claude\rules" -Filter "*.md" -Recurse
$verifyResults += Verify-Category -Label "Skills" -SourceRelPath ".claude\skills" -Recurse
$verifyResults += Verify-Category -Label "Hooks" -SourceRelPath ".claude\hooks" -Recurse
$verifyResults += Verify-Category -Label "Gemini Commands" -SourceRelPath ".gemini\commands" -Filter "*.toml"
$verifyResults += Verify-Category -Label "Antigravity" -SourceRelPath ".antigravity" -Recurse
$verifyResults += Verify-Category -Label "Kiro Settings" -SourceRelPath ".kiro\settings" -Recurse
$verifyResults += Verify-Category -Label "Handoff" -SourceRelPath ".handoff" -Recurse
$verifyResults += Verify-Category -Label "Ralph" -SourceRelPath ".kiro\ralph" -Recurse
$verifyResults += Verify-Category -Label "Steering" -SourceRelPath ".kiro\steering" -Recurse
# Gas Fakes: only verify setup.ts exists (we deploy 1 file, not the whole directory)
$gasFakesTarget = Join-Path $TargetProject "tests\gas-fakes\setup.ts"
$gasFakesStatus = if (Test-Path $gasFakesTarget) { "PASS" } else { "FAIL" }
if ($gasFakesStatus -eq "FAIL") { $allPassed = $false }
$verifyResults += [PSCustomObject]@{ Category = "Gas Fakes (setup.ts)"; Source = 1; Target = $(if (Test-Path $gasFakesTarget) { 1 } else { 0 }); Status = $gasFakesStatus }

# Display results
foreach ($r in $verifyResults) {
    $icon = if ($r.Status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
    $color = if ($r.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $icon $($r.Category): $($r.Target)/$($r.Source)" -ForegroundColor $color
}

# Verify generated files
$generatedFiles = @(
    "CLAUDE.md",
    "gemini.md",
    ".kiro\sessions\session-current.md",
    ".kiro\sessions\TIMELINE.md",
    ".claude\settings.json",
    ".kiro\ids\registry.json",
    ".kiro\ai-coordination\handoff\handoff-log.json"
)

Write-Host ""
Write-Host "  Generated files:" -ForegroundColor Cyan
foreach ($f in $generatedFiles) {
    $path = Join-Path $TargetProject $f
    if (Test-Path $path) {
        Write-Host "    [PASS] $f" -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] $f" -ForegroundColor Red
        $allPassed = $false
    }
}

Write-Host "[Phase 6/7] Verification completed" -ForegroundColor Green

# ============================================================
# Phase 7: Report
# ============================================================
Write-Host ""
Write-Host "=== SD003 Framework Deployment Report ===" -ForegroundColor Cyan
Write-Host ""

$totalCopied = ($copyStats.Values | Measure-Object -Sum).Sum
Write-Host "  Files copied: $totalCopied"
Write-Host "  Files generated: $($generatedFiles.Count)"
Write-Host "  Backup: $BackupDir"
Write-Host ""

if ($allPassed) {
    Write-Host "  Result: ALL PASSED" -ForegroundColor Green
} else {
    Write-Host "  Result: SOME FAILURES - check above" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. cd $TargetProject"
Write-Host "  2. npm install  (to install @mcpher/gas-fakes and other dependencies)"
Write-Host "  3. Review CLAUDE.md"
Write-Host "  4. Run /sessionread to verify"
Write-Host "  5. Start with /kiro:spec-init {feature}"
Write-Host ""
Write-Host "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!" -ForegroundColor Green
