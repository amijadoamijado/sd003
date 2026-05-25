# SD003 Framework Deployment Script v3.1.0 (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1 <target-project-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,
    [switch]$IncludeOptional,
    [switch]$DryRun
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
# Opt-out manifest (.sd003-keep): framework files this project has
# INTENTIONALLY customized. deploy/upgrade must NOT overwrite them.
# Format: one relative path per line. Supports exact paths, directory
# prefixes (skip everything beneath), and * / ? globs. '#' starts a comment.
# When no .sd003-keep exists, every guard below is a no-op (zero behavior change).
# ============================================================
$KeepPatterns = @()
$keepFile = Join-Path $TargetProject ".sd003-keep"
if (Test-Path $keepFile) {
    $KeepPatterns = @(Get-Content $keepFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        ForEach-Object { ($_ -replace '\\', '/').TrimEnd('/') })
    if ($KeepPatterns.Count -gt 0) {
        Write-Host "[.sd003-keep] $($KeepPatterns.Count) protected pattern(s) loaded - these framework files are preserved" -ForegroundColor Magenta
    }
}

function Test-Kept {
    param([string]$RelPath)
    if ($KeepPatterns.Count -eq 0) { return $false }
    $rel = ($RelPath -replace '\\', '/').TrimStart('/')
    foreach ($pat in $KeepPatterns) {
        if ($rel -eq $pat) { return $true }                              # exact file
        if ($rel -like "$pat/*") { return $true }                        # directory prefix
        if (($pat -match '[\*\?]') -and ($rel -like $pat)) { return $true } # glob
    }
    return $false
}

# Honest-reporting trackers (populated by the real copy path below)
$script:keptFiles = @()
$script:divergedOverwrites = @()

# Optional skills are excluded from deployment (and from the dry-run scan)
$optionalSkills = @()
$optCfg = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\optional-skills.json"
if ((Test-Path $optCfg) -and (-not $IncludeOptional)) {
    $optionalSkills = (Get-Content $optCfg | ConvertFrom-Json).optional_skills
}
function Test-OptionalExcluded {
    param([string]$RelPath)
    foreach ($ex in $optionalSkills) {
        if (($RelPath -replace '\\', '/') -like "*/$ex/*") { return $true }
    }
    return $false
}

# ============================================================
# DRY-RUN: report what a real deploy WOULD overwrite, then exit (no changes).
# Honesty fix: surfaces framework files whose local content diverges (= bespoke
# customization that would be silently lost), plus files preserved by .sd003-keep.
# ============================================================
function Invoke-DeployDryRun {
    Write-Host ""
    Write-Host "=== DRY-RUN: what a real deploy would write (no changes made) ===" -ForegroundColor Cyan
    Write-Host ""

    $diverged = @(); $kept = @(); $newCount = 0; $sameCount = 0

    $scanDirs = @(
        ".claude\commands", ".claude\rules", ".claude\skills", ".claude\hooks",
        ".agents\skills", ".codex", ".sd\settings", ".sd\design", ".sd\ralph",
        ".sd\steering", ".handoff", "docs\troubleshooting"
    )
    foreach ($d in $scanDirs) {
        $srcRoot = Join-Path $SOURCE_DIR $d
        if (-not (Test-Path $srcRoot -PathType Container)) { continue }
        Get-ChildItem -Path $srcRoot -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $projRel = $_.FullName.Substring($SOURCE_DIR.Length).TrimStart('\')
            if (Test-OptionalExcluded $projRel) { return }
            if (Test-Kept $projRel) { $kept += ($projRel -replace '\\', '/'); return }
            $tgt = Join-Path $TargetProject $projRel
            if (-not (Test-Path $tgt)) { $newCount++; return }
            if ((Get-FileHash $_.FullName).Hash -ne (Get-FileHash $tgt).Hash) {
                $diverged += ($projRel -replace '\\', '/')
            } else { $sameCount++ }
        }
    }

    # Direct-copy framework files (hash-comparable)
    $scanFiles = @(
        "antigravity.md", "AGENTS.md", ".claude\settings.json",
        "docs\quality-gates.md", "scripts\validate-test-data.ps1",
        "scripts\validate-test-data.sh", "scripts\sync-cli-commands.py",
        "tests\gas-fakes\setup.ts"
    )
    foreach ($f in $scanFiles) {
        if (Test-Kept $f) { $kept += ($f -replace '\\', '/'); continue }
        $src = Join-Path $SOURCE_DIR $f; $tgt = Join-Path $TargetProject $f
        if (-not (Test-Path $src)) { continue }
        if (-not (Test-Path $tgt)) { $newCount++; continue }
        if ((Get-FileHash $src).Hash -ne (Get-FileHash $tgt).Hash) { $diverged += ($f -replace '\\', '/') } else { $sameCount++ }
    }

    $claudeKept = Test-Kept "CLAUDE.md"
    if ($claudeKept) { $kept += "CLAUDE.md" }

    if ($diverged.Count -gt 0) {
        Write-Host "WILL OVERWRITE - LOCAL CUSTOMIZATION WILL BE LOST ($($diverged.Count)):" -ForegroundColor Red
        Write-Host "  (target content differs from framework source. Add to .sd003-keep to preserve.)" -ForegroundColor DarkYellow
        foreach ($p in ($diverged | Sort-Object -Unique)) { Write-Host "  ! $p" -ForegroundColor Red }
        Write-Host ""
    }
    if (-not $claudeKept) {
        Write-Host "WILL OVERWRITE - regenerated from template:" -ForegroundColor Yellow
        Write-Host "  ~ CLAUDE.md  (add 'CLAUDE.md' to .sd003-keep to preserve a bespoke version)" -ForegroundColor Yellow
        Write-Host ""
    }
    if ($kept.Count -gt 0) {
        Write-Host "KEPT via .sd003-keep ($($kept.Count)) - preserved, not overwritten:" -ForegroundColor Green
        foreach ($p in ($kept | Sort-Object -Unique)) { Write-Host "  = $p" -ForegroundColor Green }
        Write-Host ""
    }
    Write-Host "Summary: $($diverged.Count) diverged, $(($kept | Sort-Object -Unique).Count) kept, $newCount new, $sameCount unchanged" -ForegroundColor Cyan
    if ($diverged.Count -gt 0) {
        Write-Host ""
        Write-Host "WARNING: $($diverged.Count) file(s) with local changes will be overwritten on a real run." -ForegroundColor Red
        Write-Host "         A backup is taken, but to KEEP them, list them in <target>/.sd003-keep first." -ForegroundColor Red
    }
}

if ($DryRun) {
    Invoke-DeployDryRun
    Write-Host ""
    Write-Host "[DRY-RUN] No changes made. Re-run without -DryRun to apply." -ForegroundColor Yellow
    exit 0
}

# ============================================================
# Phase 2: Backup
# ============================================================
$BackupDir = Join-Path $TargetProject ".sd003-backup-$TIMESTAMP"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$backupTargets = @("CLAUDE.md", "AGENTS.md", "antigravity.md")
foreach ($f in $backupTargets) {
    $path = Join-Path $TargetProject $f
    if (Test-Path $path) {
        Copy-Item $path $BackupDir -Force
    }
}

$backupDirs = @(".claude", ".codex", ".agents", ".sd")
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
    ".codex/skills",
    ".agents/skills",
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
    ".handoff",
    ".sd\design",
    ".sd/ralph",
    ".sd/refactor",
    "docs/troubleshooting/bug-reports",
    "materials/csv",
    "materials/excel",
    "materials/html",
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
        $projRel = (Join-Path $RelPath $relativePath.TrimStart('\'))
        if (Test-Kept $projRel) { $script:keptFiles += ($projRel -replace '\\', '/'); continue }
        $destPath = Join-Path $dst $relativePath
        if ((Test-Path $destPath) -and ((Get-FileHash $item.FullName).Hash -ne (Get-FileHash $destPath).Hash)) {
            $script:divergedOverwrites += ($projRel -replace '\\', '/')
        }
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
        $projRel = (Join-Path $RelPath $item.Name)
        if (Test-Kept $projRel) { $script:keptFiles += ($projRel -replace '\\', '/'); continue }
        $destPath = Join-Path $dst $item.Name
        if ((Test-Path $destPath) -and ((Get-FileHash $item.FullName).Hash -ne (Get-FileHash $destPath).Hash)) {
            $script:divergedOverwrites += ($projRel -replace '\\', '/')
        }
        Copy-Item $item.FullName $destPath -Force
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

# 4-4: .claude/skills/ (tree) - optional skills excluded by default (loaded in Phase 1)
if ($optionalSkills.Count -gt 0) {
    Write-Host "  Optional skills excluded: $($optionalSkills -join ', ')" -ForegroundColor DarkGray
}
Copy-DirTree -RelPath ".claude\skills" -Label "Skills" -Exclude $optionalSkills

# 4-5: .claude/hooks/ (tree)
Copy-DirTree -RelPath ".claude\hooks" -Label "Hooks"

# 4-6: .agents/skills/ (tree) - Antigravity CLI (agy) reads slash commands here as SKILL.md
Copy-DirTree -RelPath ".agents\skills" -Label "Agents Skills (agy)"

# 4-7: .codex/ (tree)
Copy-DirTree -RelPath ".codex" -Label "Codex"

# 4-9: .sd/settings/ (tree)
Copy-DirTree -RelPath ".sd\settings" -Label "SD Settings"

# 4-10: .sessions/templates/ (template files for new projects)
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

# 4-11a: .sd/design/ (tree)
Copy-DirTree -RelPath ".sd\design" -Label "Design Tokens"

# 4-11b: .sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}
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

# 4-16: scripts/sync-cli-commands.py (single file - the agy/codex skill generator)
$syncCliSrc = Join-Path $SOURCE_DIR "scripts\sync-cli-commands.py"
if (Test-Path $syncCliSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item $syncCliSrc (Join-Path $scriptsDst "sync-cli-commands.py") -Force
    $copyStats["Sync CLI"] = 1
} else {
    $copyStats["Sync CLI"] = 0
}

# 4-16: AGENTS.md (single file - overwrite unless protected by .sd003-keep)
$agentsSrc = Join-Path $SOURCE_DIR "AGENTS.md"
if (Test-Kept "AGENTS.md") {
    Write-Host "  KEEP: AGENTS.md preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "AGENTS.md"
    $copyStats["AGENTS.md"] = 0
} elseif (Test-Path $agentsSrc) {
    $agentsDst2 = Join-Path $TargetProject "AGENTS.md"
    if ((Test-Path $agentsDst2) -and ((Get-FileHash $agentsSrc).Hash -ne (Get-FileHash $agentsDst2).Hash)) { $script:divergedOverwrites += "AGENTS.md" }
    Copy-Item $agentsSrc $agentsDst2 -Force
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

# 4-21: .git/hooks/ (from templates/git-hooks/)
$gitHooksSrc = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\git-hooks"
$gitHooksDst = Join-Path $TargetProject ".git\hooks"
$hookCount = 0
if (Test-Path $gitHooksSrc -PathType Container) {
    if (-not (Test-Path $gitHooksDst)) { New-Item -ItemType Directory -Path $gitHooksDst -Force | Out-Null }
    $hookFiles = Get-ChildItem -Path $gitHooksSrc -File
    foreach ($hook in $hookFiles) {
        $targetHook = Join-Path $gitHooksDst $hook.Name
        # 上書き: 既存hookがあっても最新版で上書き（sd003と同一動作を保証）
        Copy-Item $hook.FullName $targetHook -Force
        $hookCount++
    }
    Write-Host "  Git Hooks: $hookCount file(s) installed" -ForegroundColor Cyan
} else {
    Write-Host "  WARN: templates/git-hooks/ not found" -ForegroundColor Yellow
}
$copyStats["Git Hooks"] = $hookCount

Write-Host "[Phase 4/7] Dynamic copy completed" -ForegroundColor Green
foreach ($key in $copyStats.Keys | Sort-Object) {
    Write-Host "  $key : $($copyStats[$key]) files"
}

# ============================================================
# Phase 5: Generate files
# ============================================================
$ProjectName = Split-Path $TargetProject -Leaf

# 5-1: CLAUDE.md from template (overwrite unless protected by .sd003-keep)
$claudeMdPath = Join-Path $TargetProject "CLAUDE.md"
$claudeTemplate = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\CLAUDE.md.template"
if (Test-Kept "CLAUDE.md") {
    Write-Host "  KEEP: CLAUDE.md preserved via .sd003-keep (bespoke version kept)" -ForegroundColor Magenta
    $script:keptFiles += "CLAUDE.md"
} elseif (Test-Path $claudeTemplate) {
    $content = Get-Content $claudeTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'v2\.3\.0', "v$FRAMEWORK_VERSION"
    Set-Content -Path $claudeMdPath -Value $content -Encoding UTF8
    if (Test-Path $claudeMdPath) { Write-Host "  UPDATE: CLAUDE.md (latest rules applied)" -ForegroundColor Green }
} else {
    Write-Host "  WARN: CLAUDE.md.template not found, skipping" -ForegroundColor Yellow
}

# 5-2: antigravity.md (agy root config - overwrite unless protected by .sd003-keep)
$antigravitySrc = Join-Path $SOURCE_DIR "antigravity.md"
$antigravityDst = Join-Path $TargetProject "antigravity.md"
if (Test-Kept "antigravity.md") {
    Write-Host "  KEEP: antigravity.md preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "antigravity.md"
} elseif (Test-Path $antigravitySrc) {
    if ((Test-Path $antigravityDst) -and ((Get-FileHash $antigravitySrc).Hash -ne (Get-FileHash $antigravityDst).Hash)) { $script:divergedOverwrites += "antigravity.md" }
    Copy-Item $antigravitySrc $antigravityDst -Force
    Write-Host "  UPDATE: antigravity.md (latest agy rules applied)" -ForegroundColor Green
} else {
    Write-Host "  WARN: antigravity.md not found in source, skipping" -ForegroundColor Yellow
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

# 5-5: .claude/settings.json (overwrite unless protected by .sd003-keep)
$settingsPath = Join-Path $TargetProject ".claude\settings.json"
$templatePath = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\settings.json.template"
if (Test-Kept ".claude/settings.json") {
    Write-Host "  KEEP: .claude/settings.json preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += ".claude/settings.json"
} elseif (Test-Path $templatePath) {
    if ((Test-Path $settingsPath) -and ((Get-FileHash $templatePath).Hash -ne (Get-FileHash $settingsPath).Hash)) { $script:divergedOverwrites += ".claude/settings.json" }
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

# 5b: Inject gas-fakes into target package.json (skip if protected by .sd003-keep)
# NOTE: ConvertTo-Json reformats the whole file; a hand-formatted package.json
# should be listed in .sd003-keep to avoid reformatting.
$targetPkg = Join-Path $TargetProject "package.json"
if (Test-Kept "package.json") {
    Write-Host "  KEEP: package.json preserved via .sd003-keep (gas-fakes injection skipped)" -ForegroundColor Magenta
    $script:keptFiles += "package.json"
} else {
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
}  # end .sd003-keep guard for package.json

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
$verifyResults += Verify-Category -Label "Agents Skills (agy)" -SourceRelPath ".agents\skills" -Recurse
$verifyResults += Verify-Category -Label "Codex" -SourceRelPath ".codex" -Recurse
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
    "antigravity.md",
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

# Honest reporting: kept (opt-out) and overwritten-divergence (potential data loss)
$kf = @($script:keptFiles | Sort-Object -Unique)
$df = @($script:divergedOverwrites | Sort-Object -Unique)
if ($kf.Count -gt 0) {
    Write-Host "  Kept via .sd003-keep (not overwritten): $($kf.Count)" -ForegroundColor Magenta
    foreach ($p in $kf) { Write-Host "    = $p" -ForegroundColor Magenta }
    Write-Host ""
}
if ($df.Count -gt 0) {
    Write-Host "  OVERWROTE local divergence (backed up in $BackupDir): $($df.Count)" -ForegroundColor Yellow
    foreach ($p in $df) { Write-Host "    ! $p" -ForegroundColor Yellow }
    Write-Host "  -> If any were intentional customizations, restore from backup and add them to .sd003-keep." -ForegroundColor Yellow
    Write-Host ""
}

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
