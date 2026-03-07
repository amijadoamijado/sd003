# SD003 Framework Deployment Script v3.0.0 (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1 <target-project-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject
)

$ErrorActionPreference = "Stop"

# Configuration
$SD003_VERSION = "3.0.0"
$FRAMEWORK_VERSION = "2.11.0"
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
Write-Host "  2. Review CLAUDE.md"
Write-Host "  3. Run /sessionread to verify"
Write-Host "  4. Start with /kiro:spec-init {feature}"
Write-Host ""
Write-Host "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!" -ForegroundColor Green
