# SD003 Framework Deployment Script v3.2.0 (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1 <target-project-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,
    [switch]$IncludeOptional,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Configuration
$SD003_VERSION = "3.2.0"
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
        ".agents\skills", ".codex", ".grok", ".sd\settings", ".sd\design", ".sd\ralph",
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
        "antigravity.md", "AGENTS.md", "grok.md", ".claude\settings.json",
        "docs\quality-gates.md", "scripts\validate-test-data.ps1",
        "scripts\validate-test-data.sh", "scripts\sync-cli-commands.py",
        "scripts\verify-deployment.mjs",
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

    # Git hooks: source path (templates/git-hooks) differs from target path
    # (.git/hooks), so this can't reuse the generic scanDirs/scanFiles loops above.
    $gitHooksScanSrc = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\git-hooks"
    if (Test-Path $gitHooksScanSrc -PathType Container) {
        Get-ChildItem -Path $gitHooksScanSrc -File -ErrorAction SilentlyContinue | ForEach-Object {
            $hookRel = ".git/hooks/$($_.Name)"
            if (Test-Kept $hookRel) { $kept += $hookRel; return }
            $hookTgt = Join-Path $TargetProject ".git\hooks\$($_.Name)"
            if (-not (Test-Path $hookTgt)) { $newCount++; return }
            if ((Get-FileHash $_.FullName).Hash -ne (Get-FileHash $hookTgt).Hash) {
                $diverged += $hookRel
            } else { $sameCount++ }
        }
    }

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

$backupTargets = @("CLAUDE.md", "AGENTS.md", "antigravity.md", "grok.md")
foreach ($f in $backupTargets) {
    $path = Join-Path $TargetProject $f
    if (Test-Path $path) {
        Copy-Item $path $BackupDir -Force
    }
}

$backupDirs = @(".claude", ".codex", ".agents", ".grok", ".sd")
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
    ".grok/skills",
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

# 4-8: .grok/ (tree) - Grok CLI reads skills here as SKILL.md + GROK_SPEC.md
Copy-DirTree -RelPath ".grok" -Label "Grok"

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

# 4-12: docs/quality-gates.md (overwrite unless protected by .sd003-keep)
$qgSrc = Join-Path $SOURCE_DIR "docs\quality-gates.md"
$qgDst = Join-Path $TargetProject "docs\quality-gates.md"
if (Test-Kept "docs/quality-gates.md") {
    Write-Host "  KEEP: docs/quality-gates.md preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "docs/quality-gates.md"
    $copyStats["Docs/QualityGates"] = 0
} elseif (Test-Path $qgSrc) {
    if ((Test-Path $qgDst) -and ((Get-FileHash $qgSrc).Hash -ne (Get-FileHash $qgDst).Hash)) { $script:divergedOverwrites += "docs/quality-gates.md" }
    Copy-Item $qgSrc $qgDst -Force
    $copyStats["Docs/QualityGates"] = 1
} else {
    $copyStats["Docs/QualityGates"] = 0
}

# 4-13: .handoff/ (tree)
Copy-DirTree -RelPath ".handoff" -Label "Handoff"



# 4-15a: scripts/validate-test-data.ps1 (single file - overwrite unless protected by .sd003-keep)
$vtdPs1Src = Join-Path $SOURCE_DIR "scripts\validate-test-data.ps1"
$vtdPs1Dst = Join-Path $TargetProject "scripts\validate-test-data.ps1"
if (Test-Kept "scripts/validate-test-data.ps1") {
    Write-Host "  KEEP: scripts/validate-test-data.ps1 preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "scripts/validate-test-data.ps1"
    $copyStats["Validate Test Data (ps1)"] = 0
} elseif (Test-Path $vtdPs1Src) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    if ((Test-Path $vtdPs1Dst) -and ((Get-FileHash $vtdPs1Src).Hash -ne (Get-FileHash $vtdPs1Dst).Hash)) { $script:divergedOverwrites += "scripts/validate-test-data.ps1" }
    Copy-Item $vtdPs1Src $vtdPs1Dst -Force
    $copyStats["Validate Test Data (ps1)"] = 1
} else {
    $copyStats["Validate Test Data (ps1)"] = 0
}

# 4-15b: scripts/validate-test-data.sh (single file - overwrite unless protected by .sd003-keep)
$vtdShSrc = Join-Path $SOURCE_DIR "scripts\validate-test-data.sh"
$vtdShDst = Join-Path $TargetProject "scripts\validate-test-data.sh"
if (Test-Kept "scripts/validate-test-data.sh") {
    Write-Host "  KEEP: scripts/validate-test-data.sh preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "scripts/validate-test-data.sh"
    $copyStats["Validate Test Data (sh)"] = 0
} elseif (Test-Path $vtdShSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    if ((Test-Path $vtdShDst) -and ((Get-FileHash $vtdShSrc).Hash -ne (Get-FileHash $vtdShDst).Hash)) { $script:divergedOverwrites += "scripts/validate-test-data.sh" }
    Copy-Item $vtdShSrc $vtdShDst -Force
    $copyStats["Validate Test Data (sh)"] = 1
} else {
    $copyStats["Validate Test Data (sh)"] = 0
}

# 4-15c: scripts/verify-deployment.mjs (single file - deploy content-verification gate - overwrite unless protected by .sd003-keep)
$verifySrc = Join-Path $SOURCE_DIR "scripts\verify-deployment.mjs"
$verifyDst = Join-Path $TargetProject "scripts\verify-deployment.mjs"
if (Test-Kept "scripts/verify-deployment.mjs") {
    Write-Host "  KEEP: scripts/verify-deployment.mjs preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "scripts/verify-deployment.mjs"
    $copyStats["Verify Deployment (mjs)"] = 0
} elseif (Test-Path $verifySrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    if ((Test-Path $verifyDst) -and ((Get-FileHash $verifySrc).Hash -ne (Get-FileHash $verifyDst).Hash)) { $script:divergedOverwrites += "scripts/verify-deployment.mjs" }
    Copy-Item $verifySrc $verifyDst -Force
    $copyStats["Verify Deployment (mjs)"] = 1
} else {
    $copyStats["Verify Deployment (mjs)"] = 0
}

# 4-16: scripts/sync-cli-commands.py (single file - the agy/codex skill generator - overwrite unless protected by .sd003-keep)
$syncCliSrc = Join-Path $SOURCE_DIR "scripts\sync-cli-commands.py"
$syncCliDst = Join-Path $TargetProject "scripts\sync-cli-commands.py"
if (Test-Kept "scripts/sync-cli-commands.py") {
    Write-Host "  KEEP: scripts/sync-cli-commands.py preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "scripts/sync-cli-commands.py"
    $copyStats["Sync CLI"] = 0
} elseif (Test-Path $syncCliSrc) {
    $scriptsDst = Join-Path $TargetProject "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    if ((Test-Path $syncCliDst) -and ((Get-FileHash $syncCliSrc).Hash -ne (Get-FileHash $syncCliDst).Hash)) { $script:divergedOverwrites += "scripts/sync-cli-commands.py" }
    Copy-Item $syncCliSrc $syncCliDst -Force
    $copyStats["Sync CLI"] = 1
    # Regenerate agy/codex/grok skills in the TARGET (copy alone leaves generated
    # skills + manifest stale). Guarded: skip if python is unavailable.
    $py = (Get-Command python -ErrorAction SilentlyContinue)
    if ($py) {
        Push-Location $TargetProject
        try {
            & python "scripts\sync-cli-commands.py" 2>&1 | Out-Null
            Write-Host "  Regenerated agy/codex/grok skills (sync-cli-commands.py)" -ForegroundColor Green
        } catch {
            Write-Host "  WARN: post-copy sync failed; run 'python scripts/sync-cli-commands.py' manually in target" -ForegroundColor Yellow
        } finally { Pop-Location }
    } else {
        Write-Host "  NOTE: python not found. Run 'python scripts/sync-cli-commands.py' in target to (re)generate skills." -ForegroundColor Yellow
    }
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

# 4-20: tests/gas-fakes/setup.ts (single file - overwrite unless protected by .sd003-keep)
$gasFakesSrc = Join-Path $SOURCE_DIR "tests\gas-fakes\setup.ts"
$gasFakesDstFile = Join-Path $TargetProject "tests\gas-fakes\setup.ts"
if (Test-Kept "tests/gas-fakes/setup.ts") {
    Write-Host "  KEEP: tests/gas-fakes/setup.ts preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "tests/gas-fakes/setup.ts"
    $copyStats["Gas Fakes Setup"] = 0
} elseif (Test-Path $gasFakesSrc) {
    $gasFakesDst = Join-Path $TargetProject "tests\gas-fakes"
    if (-not (Test-Path $gasFakesDst)) { New-Item -ItemType Directory -Path $gasFakesDst -Force | Out-Null }
    if ((Test-Path $gasFakesDstFile) -and ((Get-FileHash $gasFakesSrc).Hash -ne (Get-FileHash $gasFakesDstFile).Hash)) { $script:divergedOverwrites += "tests/gas-fakes/setup.ts" }
    Copy-Item $gasFakesSrc $gasFakesDstFile -Force
    $copyStats["Gas Fakes Setup"] = 1
} else {
    Write-Host "  WARN: tests/gas-fakes/setup.ts not found" -ForegroundColor Yellow
    $copyStats["Gas Fakes Setup"] = 0
}

# 4-21: .git/hooks/ (from templates/git-hooks/) - overwrite unless protected by
# .sd003-keep. Existing hooks are backed up into $BackupDir before overwrite
# (Phase 2's backup pass, above, does not cover .git/hooks - a custom pre-commit
# was previously destroyed unrecoverably on every deploy).
$gitHooksSrc = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\templates\git-hooks"
$gitHooksDst = Join-Path $TargetProject ".git\hooks"
$hookCount = 0
if (Test-Path $gitHooksSrc -PathType Container) {
    if (-not (Test-Path $gitHooksDst)) { New-Item -ItemType Directory -Path $gitHooksDst -Force | Out-Null }
    $hookFiles = Get-ChildItem -Path $gitHooksSrc -File
    foreach ($hook in $hookFiles) {
        $hookRel = ".git/hooks/$($hook.Name)"
        $targetHook = Join-Path $gitHooksDst $hook.Name
        if (Test-Kept $hookRel) {
            Write-Host "  KEEP: $hookRel preserved via .sd003-keep" -ForegroundColor Magenta
            $script:keptFiles += $hookRel
            continue
        }
        if (Test-Path $targetHook) {
            $hookBackupDir = Join-Path $BackupDir ".git\hooks"
            if (-not (Test-Path $hookBackupDir)) { New-Item -ItemType Directory -Path $hookBackupDir -Force | Out-Null }
            Copy-Item $targetHook $hookBackupDir -Force
            if ((Get-FileHash $hook.FullName).Hash -ne (Get-FileHash $targetHook).Hash) { $script:divergedOverwrites += $hookRel }
        }
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
    # NOTE: the template stamps "SD003 v3.2.0" (not "v2.3.0" - that token never
    # existed in the template, so this substitution was previously dead code and
    # every deployed CLAUDE.md kept the hardcoded v3.2.0 forever, breaking the
    # sessionread Update-Check which treats $FRAMEWORK_VERSION as canonical).
    # Match the real token "SD003 v<version>" so the stamp becomes $FRAMEWORK_VERSION.
    $content = Get-Content $claudeTemplate -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{DATE\}\}', $DATE
    $content = $content -replace 'SD003 v[0-9]+\.[0-9]+\.[0-9]+', "SD003 v$FRAMEWORK_VERSION"
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

# 5-2b: grok.md (Grok CLI root config - overwrite unless protected by .sd003-keep)
$grokSrc = Join-Path $SOURCE_DIR "grok.md"
$grokDst = Join-Path $TargetProject "grok.md"
if (Test-Kept "grok.md") {
    Write-Host "  KEEP: grok.md preserved via .sd003-keep" -ForegroundColor Magenta
    $script:keptFiles += "grok.md"
} elseif (Test-Path $grokSrc) {
    if ((Test-Path $grokDst) -and ((Get-FileHash $grokSrc).Hash -ne (Get-FileHash $grokDst).Hash)) { $script:divergedOverwrites += "grok.md" }
    Copy-Item $grokSrc $grokDst -Force
    Write-Host "  UPDATE: grok.md (latest Grok rules applied)" -ForegroundColor Green
} else {
    Write-Host "  WARN: grok.md not found in source, skipping" -ForegroundColor Yellow
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
        [switch]$Recurse,
        [string[]]$Exclude = @()
    )

    $srcPath = Join-Path $SOURCE_DIR $SourceRelPath
    $dstPath = Join-Path $TargetProject $TargetRelPath

    if ($Recurse) {
        $srcItems = Get-ChildItem -Path $srcPath -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue
        $dstCount = (Get-ChildItem -Path $dstPath -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
    } else {
        $srcItems = Get-ChildItem -Path $srcPath -File -Filter $Filter -ErrorAction SilentlyContinue
        $dstCount = (Get-ChildItem -Path $dstPath -File -Filter $Filter -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    # Exclude items matching -Exclude (mirrors Copy-DirTree's own -Exclude match:
    # "*\$ex\*"), so e.g. "Skills" doesn't count optional-skills files that are
    # intentionally never copied - counting them made a correct deploy FAIL.
    if ($Exclude.Count -gt 0) {
        $srcItems = $srcItems | Where-Object {
            $full = $_.FullName
            $isExcluded = $false
            foreach ($ex in $Exclude) { if ($full -like "*\$ex\*") { $isExcluded = $true; break } }
            -not $isExcluded
        }
    }
    $srcCount = ($srcItems | Measure-Object).Count

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
$verifyResults += Verify-Category -Label "Skills" -SourceRelPath ".claude\skills" -Recurse -Exclude $optionalSkills
$verifyResults += Verify-Category -Label "Hooks" -SourceRelPath ".claude\hooks" -Recurse
$verifyResults += Verify-Category -Label "Agents Skills (agy)" -SourceRelPath ".agents\skills" -Recurse
$verifyResults += Verify-Category -Label "Codex" -SourceRelPath ".codex" -Recurse
$verifyResults += Verify-Category -Label "Grok" -SourceRelPath ".grok" -Recurse
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
    "grok.md",
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
# Phase 6b: Content verification gate (single Node verifier; hard-fail)
# Catches mis-wired settings.json / unsubstituted template vars / deprecated
# tokens / mojibake / invalid JSON that Phase 6's count+existence check misses.
# ============================================================
Write-Host ""
Write-Host "=== Content Verification (Phase 6b) ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  [SKIP] dry-run: nothing generated to verify" -ForegroundColor Yellow
} else {
    $verifyScript = Join-Path $SOURCE_DIR "scripts\verify-deployment.mjs"
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        Write-Host "  [FAIL] node not found on PATH - cannot run content verification" -ForegroundColor Red
        $allPassed = $false
    } elseif (-not (Test-Path $verifyScript)) {
        Write-Host "  [FAIL] verifier not found: $verifyScript" -ForegroundColor Red
        $allPassed = $false
    } else {
        & node $verifyScript $TargetProject $SOURCE_DIR
        if ($LASTEXITCODE -ne 0) { $allPassed = $false }
    }
}
Write-Host "[Phase 6b/7] Content verification completed" -ForegroundColor Green

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

# Registry reminder: new top-level projects under D:\claudecode must be registered
# in PROJECT_REGISTRY.md, otherwise projects accumulate ungoverned (2026-07-05 cleanup finding).
$resolvedTarget = (Resolve-Path $TargetProject -ErrorAction SilentlyContinue).Path
if ($resolvedTarget) {
    $parentDir = (Split-Path $resolvedTarget -Parent).TrimEnd('\')
    if ($parentDir -ieq "D:\claudecode") {
        Write-Host "[REMINDER] Target is a direct child of D:\claudecode." -ForegroundColor Yellow
        Write-Host "  -> Add one line to D:\claudecode\PROJECT_REGISTRY.md's code table (code / purpose / status=active / created date)." -ForegroundColor Yellow
        Write-Host "  -> Deployment is NOT considered complete until the registry entry is added." -ForegroundColor Yellow
        Write-Host ""
    }
}
if (-not $allPassed) {
    Write-Host "SD003 deployment FAILED verification - fix the issues above and re-run." -ForegroundColor Red
    Write-Host "(Deployed files remain in place; nothing was rolled back.)" -ForegroundColor Yellow
    exit 1
}
Write-Host "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!" -ForegroundColor Green
