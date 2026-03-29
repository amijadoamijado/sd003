# SD003 Framework Deployment Script v3.1.0 (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1 <target-project-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,
    [switch]$IncludeOptional
)

$ErrorActionPreference = "Stop"

# Configuration
$SD003_VERSION = "3.1.0"
$FRAMEWORK_VERSION = "2.14.0"
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

$backupDirs = @(".claude", ".gemini", ".sd", ".antigravity")
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
    ".claude/commands/sd",
    ".claude/rules",
    ".claude/skills",
    ".claude/hooks",
    ".gemini/commands",
    ".sd/specs",
    ".sd/steering",
    ".sessions",
    ".sd/settings",
    ".sd/ids",
    ".sd/traceability",
    ".sd/ai-coordination/workflow/templates",
    ".sd/ai-coordination/workflow/spec",
    ".sd/ai-coordination/workflow/review",
    ".sd/ai-coordination/workflow/log",
    ".sd/ai-coordination/handoff",
    ".antigravity",
    ".handoff",
    ".sd\design",
    ".sd/ralph",
    ".sd/refactor",
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
        [string]$Filter = "*",
        [string[]]$Exclude = @()
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
        # Exclude check
        $skip = $false
        foreach ($ex in $Exclude) {
            if ($item.FullName -like "*\$ex\*") { $skip = $true; break }
        }
        if ($skip) { continue }

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

# 4-2: .claude/commands/sd/*.md
Copy-FlatDir -RelPath ".claude\commands\sd" -Label "Commands/sd" -Extension ".md"

# 4-3: .claude/rules/ (tree)
Copy-DirTree -RelPath ".claude\rules" -Label "Rules" -Filter "*.md"

# 4-4: .claude/skills/ (tree) - optional skills excluded by default
$optionalSkills = @()
$optCfg = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\optional-skills.json"
if ((Test-Path $optCfg) -and (-not $IncludeOptional)) {
    $optionalSkills = (Get-Content $optCfg | ConvertFrom-Json).optional_skills
    Write-Host "  Optional skills excluded: $($optionalSkills -join ', ')" -ForegroundColor DarkGray
}
Copy-DirTree -RelPath ".claude\skills" -Label "Skills" -Exclude $optionalSkills

# 4-5: .claude/hooks/ (tree)
Copy-DirTree -RelPath ".claude\hooks" -Label "Hooks"

# 4-6: .gemini/commands/ (flat, .toml)
Copy-FlatDir -RelPath ".gemini\commands" -Label "Gemini Commands" -Extension ".toml"

# 4-7: .antigravity/ (tree)
Copy-DirTree -RelPath ".antigravity" -Label "Antigravity"

# 4-8: .sd/settings/ (tree)
Copy-DirTree -RelPath ".sd\settings" -Label "SD Settings"

# 4-9: .sessions/templates/ (template files for new projects)
$sessionTemplatesSrc = Join-Path $SOURCE_DIR ".sessions\templates"
if (Test-Path $sessionTemplatesSrc) {
    $targetTemplatesDir = Join-Path $TargetProject ".sessions\templates"
    if (!(Test-Path $targetTemplatesDir)) { New-Item -ItemType Directory -Path $targetTemplatesDir -Force | Out-Null }
    Copy-Item "$sessionTemplatesSrc\*" $targetTemplatesDir -Force
    $templateCount = (Get-ChildItem $targetTemplatesDir -File).Count
    $copyStats["Session Templates"] = $templateCount
} else {
    Write-Host "  WARN: .sessions/templates/ not found" -ForegroundColor Yellow
    $copyStats["Session Templates"] = 0
}

# 4-10a: .sd/design/ (tree)
Copy-DirTree -RelPath ".sd\design" -Label "Design Tokens"

# 4-10b: .sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}
$workflowSrc = Join-Path $SOURCE_DIR ".sd\ai-coordination\workflow"
$workflowDst = Join-Path $TargetProject ".sd\ai-coordination\workflow"
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

# 4-15a: scripts/validate-test-data.ps1 (single file)
$vtdPs1Src = Join-Path $SOURCE_DIR "scripts\validate-test-data.ps1"
if (Test-Path $vtdPs1Src) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item $vtdPs1Src (Join-Path $scriptsDst "validate-test-data.ps1") -Force
    $copyStats["Validate Test Data (ps1)"] = 1
} else {
    $copyStats["Validate Test Data (ps1)"] = 0
}

# 4-15b: scripts/validate-test-data.sh (single file)
$vtdShSrc = Join-Path $SOURCE_DIR "scripts\validate-test-data.sh"
if (Test-Path $vtdShSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item $vtdShSrc (Join-Path $scriptsDst "validate-test-data.sh") -Force
    $copyStats["Validate Test Data (sh)"] = 1
} else {
    $copyStats["Validate Test Data (sh)"] = 0
}

# 4-16: scripts/sync-gemini-features.js (single file)
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

# 4-17: .sd/ralph/ (tree)
Copy-DirTree -RelPath ".sd\ralph" -Label "Ralph"

# 4-18: .sd/steering/ (tree)
Copy-DirTree -RelPath ".sd\steering" -Label "Steering"

# 4-19: .sd/refactor/config.json (single file)
$refactorCfgSrc = Join-Path $SOURCE_DIR ".sd\refactor\config.json"
if (Test-Path $refactorCfgSrc) {
    $refactorDst = Join-Path $TargetProject ".sd\refactor"
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

# 5-1: CLAUDE.md from template (ALWAYS overwrite - rules must be latest)
$claudeMdPath = Join-Path $TargetProject "CLAUDE.md"
$claudeTemplate = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\CLAUDE.md.template"
if (Test-Path $claudeTemplate) {
    $content = Get-Content $claudeTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'v2\.3\.0', "v$FRAMEWORK_VERSION"
    Set-Content -Path $claudeMdPath -Value $content -Encoding UTF8
    if (Test-Path $claudeMdPath) { Write-Host "  UPDATE: CLAUDE.md (latest rules applied)" -ForegroundColor Green }
} else {
    Write-Host "  WARN: CLAUDE.md.template not found, skipping" -ForegroundColor Yellow
}

# 5-2: gemini.md from template (ALWAYS overwrite - rules must be latest)
$geminiMdPath = Join-Path $TargetProject "gemini.md"
$geminiTemplate = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\gemini.md.template"
if (Test-Path $geminiTemplate) {
    $content = Get-Content $geminiTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'v2\.3\.0', "v$FRAMEWORK_VERSION"
    Set-Content -Path $geminiMdPath -Value $content -Encoding UTF8
    if (Test-Path $geminiMdPath) { Write-Host "  UPDATE: gemini.md (latest rules applied)" -ForegroundColor Green }
} else {
    Write-Host "  WARN: gemini.md.template not found, skipping" -ForegroundColor Yellow
}

# 5-3: session-current.md (skip if exists, use template from .sessions/templates/)
$sessionCurrentPath = Join-Path $TargetProject ".sessions\session-current.md"
if (Test-Path $sessionCurrentPath) {
    Write-Host "  SKIP: session-current.md already exists (preserving existing session)" -ForegroundColor Cyan
} else {
    $templatePath = Join-Path $SOURCE_DIR ".sessions\templates\session-current.md.template"
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw -Encoding UTF8
        $content = $content -replace '\{\{DATE\}\}', $DATE
        $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
        $content = $content -replace '\{\{FRAMEWORK_VERSION\}\}', $FRAMEWORK_VERSION
        Set-Content -Path $sessionCurrentPath -Value $content -Encoding UTF8
    } else {
        Write-Host "  WARN: session-current.md.template not found, skipping" -ForegroundColor Yellow
    }
}

# 5-4: TIMELINE.md (skip if exists, use template from .sessions/templates/)
$timelinePath = Join-Path $TargetProject ".sessions\TIMELINE.md"
if (Test-Path $timelinePath) {
    Write-Host "  SKIP: TIMELINE.md already exists (preserving existing timeline)" -ForegroundColor Cyan
} else {
    $templatePath = Join-Path $SOURCE_DIR ".sessions\templates\TIMELINE.md.template"
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw -Encoding UTF8
        $content = $content -replace '\{\{DATE\}\}', $DATE
        $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
        $content = $content -replace '\{\{FRAMEWORK_VERSION\}\}', $FRAMEWORK_VERSION
        Set-Content -Path $timelinePath -Value $content -Encoding UTF8
    } else {
        Write-Host "  WARN: TIMELINE.md.template not found, skipping" -ForegroundColor Yellow
    }
}

# 5-5: .claude/settings.json (ALWAYS overwrite - hooks must be latest)
$settingsPath = Join-Path $TargetProject ".claude\settings.json"
$templatePath = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\settings.json.template"
if (Test-Path $templatePath) {
    Copy-Item $templatePath $settingsPath -Force
    Write-Host "  UPDATE: .claude/settings.json (latest hooks applied)" -ForegroundColor Green
} else {
    Write-Host "  WARN: settings.json.template not found, skipping" -ForegroundColor Yellow
}

# 5-5b: Ensure .claude/settings.json is in .gitignore (prevents .sd/ disappearance bug)
# Ref: anthropics/claude-code#34330 - Claude Code runtime refreshes working tree on settings.json git changes
$gitignorePath = Join-Path $TargetProject ".gitignore"
$settingsIgnoreLine = ".claude/settings.json"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw -Encoding UTF8
    if ($gitignoreContent -notmatch [regex]::Escape($settingsIgnoreLine)) {
        Add-Content -Path $gitignorePath -Value "`n# Claude Code settings (must not be git-tracked, causes .sd/ disappearance)`n$settingsIgnoreLine"
        Write-Host "  [Phase 5-5b] Added .claude/settings.json to .gitignore"
    }
} else {
    Set-Content -Path $gitignorePath -Value "# Claude Code settings (must not be git-tracked)`n$settingsIgnoreLine`n" -Encoding UTF8
    Write-Host "  [Phase 5-5b] Created .gitignore with .claude/settings.json exclusion"
}

# 5-6: .sd/ids/registry.json (skip if exists, use template)
$registryPath = Join-Path $TargetProject ".sd\ids\registry.json"
if (Test-Path $registryPath) {
    Write-Host "  SKIP: registry.json already exists (preserving existing IDs)" -ForegroundColor Cyan
} else {
    $templatePath = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\registry.json.template"
    if (Test-Path $templatePath) {
        $isoDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
        $content = Get-Content $templatePath -Raw -Encoding UTF8
        $content = $content -replace '\{\{ISO_DATE\}\}', $isoDate
        $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
        Set-Content -Path $registryPath -Value $content -Encoding UTF8
    } else {
        Write-Host "  WARN: registry.json.template not found, skipping" -ForegroundColor Yellow
    }
}

# 5-7: handoff-log.json (skip if exists, use template)
$handoffPath = Join-Path $TargetProject ".sd\ai-coordination\handoff\handoff-log.json"
if (Test-Path $handoffPath) {
    Write-Host "  SKIP: handoff-log.json already exists (preserving existing logs)" -ForegroundColor Cyan
} else {
    $templatePath = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\handoff-log.json.template"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath $handoffPath -Force
    } else {
        Write-Host "  WARN: handoff-log.json.template not found, skipping" -ForegroundColor Yellow
    }
}

# 5b: Inject gas-fakes into target package.json (create if not exists)
$targetPkg = Join-Path $TargetProject "package.json"
if (-not (Test-Path $targetPkg)) {
    # Auto-create minimal package.json
    $newPkgContent = @"
{
  "name": "$($ProjectName.ToLower() -replace '[^a-z0-9\-]', '-')",
  "version": "0.1.0",
  "private": true,
  "scripts": {},
  "devDependencies": {}
}
"@
    Set-Content -Path $targetPkg -Value $newPkgContent -Encoding UTF8
    Write-Host "  [Phase 5b] package.json created" -ForegroundColor Green
}

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

if (-not $pkgContent.scripts.'test:validate-data') {
    $pkgContent.scripts | Add-Member -NotePropertyName "test:validate-data" -NotePropertyValue "powershell -ExecutionPolicy Bypass -File scripts/validate-test-data.ps1" -Force
    $needsUpdate = $true
}

if ($needsUpdate) {
    $pkgContent | ConvertTo-Json -Depth 10 | Set-Content $targetPkg -Encoding UTF8
    Write-Host "  [Phase 5b] gas-fakes injected into package.json" -ForegroundColor Green
} else {
    Write-Host "  [Phase 5b] gas-fakes already present in package.json, skipping" -ForegroundColor Yellow
}

# 5-8: User-level CLAUDE.md (initial setup for ~/.claude/CLAUDE.md)
$userClaudeTemplate = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\user-claude.md.template"
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
$verifyResults += Verify-Category -Label "Commands/sd" -SourceRelPath ".claude\commands\sd" -Filter "*.md"
$verifyResults += Verify-Category -Label "Rules" -SourceRelPath ".claude\rules" -Filter "*.md" -Recurse
$verifyResults += Verify-Category -Label "Skills" -SourceRelPath ".claude\skills" -Recurse
$verifyResults += Verify-Category -Label "Hooks" -SourceRelPath ".claude\hooks" -Recurse
$verifyResults += Verify-Category -Label "Gemini Commands" -SourceRelPath ".gemini\commands" -Filter "*.toml"
$verifyResults += Verify-Category -Label "Antigravity" -SourceRelPath ".antigravity" -Recurse
$verifyResults += Verify-Category -Label "SD Settings" -SourceRelPath ".sd\settings" -Recurse
$verifyResults += Verify-Category -Label "Handoff" -SourceRelPath ".handoff" -Recurse
$verifyResults += Verify-Category -Label "Design" -SourceRelPath ".sd\design" -Recurse
$verifyResults += Verify-Category -Label "Ralph" -SourceRelPath ".sd\ralph" -Recurse
$verifyResults += Verify-Category -Label "Steering" -SourceRelPath ".sd\steering" -Recurse
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
    ".sessions\session-current.md",
    ".sessions\TIMELINE.md",
    ".claude\settings.json",
    ".sd\ids\registry.json",
    ".sd\ai-coordination\handoff\handoff-log.json"
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
Write-Host "  5. Start with /sd:spec-init {feature}"
Write-Host ""
Write-Host "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!" -ForegroundColor Green
