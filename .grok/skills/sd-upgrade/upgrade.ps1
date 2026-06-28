# SD003 Safe Framework Upgrade (PowerShell)
# Replaces an OLDER SD003 install with the latest framework, removing deprecated
# artifacts WITHOUT touching the project's own code/data.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File upgrade.ps1 <target-project> [-Execute] [-IncludeOptional]
#
#   (default = DRY-RUN: only reports what would change. Add -Execute to apply.)

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,
    [switch]$Execute,
    [switch]$IncludeOptional
)

$ErrorActionPreference = "Stop"
$SOURCE_DIR = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$DEPLOY_PS1 = Join-Path $SOURCE_DIR ".claude\skills\sd-deploy\deploy.ps1"
$TIMESTAMP  = Get-Date -Format "yyyyMMdd_HHmmss"
$Mode = if ($Execute) { "EXECUTE" } else { "DRY-RUN" }

# ------------------------------------------------------------------
# Deprecated framework artifacts to REMOVE (archive-then-remove).
# NOTE: `.agent` (singular, old) is deprecated; `.agents` (plural) is the CURRENT
# Antigravity/agy skills path and is NEVER listed here.
# ------------------------------------------------------------------
$deprecatedDirs = @(
    ".gemini", ".cursor", ".windsurf", ".qwen", ".agent", ".kiro",
    ".codex\prompts", ".antigravity\commands", ".antigravity\skills"
)
$deprecatedFiles = @(
    "GEMINI.md", "gemini.md",
    "scripts\sync-gemini-features.js",
    "scripts\migrate-kiro-to-sd.ps1",
    ".antigravity\rules.md"
)

# ------------------------------------------------------------------
# PROTECTED project assets — never deleted (deploy preserves these too).
# ------------------------------------------------------------------
$protectedNote = @(
    "src/", "tests/ (except framework tests/gas-fakes/setup.ts)",
    ".sd/specs/", ".sd/ai-coordination/", ".sessions/session-*.md", ".sessions/TIMELINE.md",
    "materials/", ".clasp.json", ".git/", "node_modules/", "dist/", ".env*",
    ".agents/skills/ (CURRENT agy path)"
)

Write-Host "=== SD003 Safe Upgrade ($Mode) ===" -ForegroundColor Cyan
Write-Host "Source: $SOURCE_DIR"
Write-Host "Target: $TargetProject"
Write-Host ""

# Phase 1: validate
if (-not (Test-Path $TargetProject -PathType Container)) {
    Write-Host "Error: target '$TargetProject' not found" -ForegroundColor Red; exit 1
}
if (-not (Test-Path (Join-Path $TargetProject ".git") -PathType Container)) {
    Write-Host "WARN: target is not a git repo. Recommended to 'git init' first for rollback safety." -ForegroundColor Yellow
}
if (-not (Test-Path $DEPLOY_PS1)) {
    Write-Host "Error: deploy.ps1 not found at $DEPLOY_PS1" -ForegroundColor Red; exit 1
}

# Phase 2: detect deprecated artifacts present
$delDirsPresent  = @($deprecatedDirs  | Where-Object { Test-Path (Join-Path $TargetProject $_) })
$delFilesPresent = @($deprecatedFiles | Where-Object { Test-Path (Join-Path $TargetProject $_) })

# claude-mem stub CLAUDE.md files (nested, content-marked), excluding root + vcs/deps
$stubFiles = @()
Get-ChildItem -Path $TargetProject -Recurse -File -Filter "CLAUDE.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($TargetProject.TrimEnd('\').Length + 1)
    if ($rel -eq "CLAUDE.md") { return }                       # keep real root CLAUDE.md
    if ($rel -match '(^|\\)(\.git|node_modules|\.sd003-backup|\.sd003-upgrade-backup)(\\|$)') { return }
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '<claude-mem-context>') { $stubFiles += $rel }
}

# Detect current version marker
$claudeMd = Join-Path $TargetProject "CLAUDE.md"
$ver = "(unknown)"
if (Test-Path $claudeMd) {
    $m = Select-String -Path $claudeMd -Pattern 'SD003 v([0-9.]+)' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($m) { $ver = $m.Matches[0].Groups[1].Value }
}

Write-Host "[Detect] Current CLAUDE.md SD003 version: $ver"
Write-Host ""
Write-Host "Will REMOVE (archived to backup first):" -ForegroundColor Yellow
if ($delDirsPresent.Count -eq 0 -and $delFilesPresent.Count -eq 0 -and $stubFiles.Count -eq 0) {
    Write-Host "  (none — no deprecated artifacts found)" -ForegroundColor Green
} else {
    foreach ($d in $delDirsPresent)  { Write-Host "  [dir]  $d" }
    foreach ($f in $delFilesPresent) { Write-Host "  [file] $f" }
    foreach ($s in $stubFiles)       { Write-Host "  [stub] $s" }
}
Write-Host ""
Write-Host "Will DEPLOY latest framework via deploy.ps1 (overwrites framework, preserves data)." -ForegroundColor Cyan
Write-Host "PROTECTED (never deleted):" -ForegroundColor Green
foreach ($p in $protectedNote) { Write-Host "  - $p" }
Write-Host ""

if (-not $Execute) {
    # Delegate to deploy.ps1 -DryRun so the human sees EXACTLY which framework files
    # would be overwritten (incl. local customizations that would be LOST) and which
    # are preserved via .sd003-keep. This is the honesty fix: never silently clobber.
    Write-Host ""
    Write-Host "[Deploy dry-run] Scanning framework files deploy would write ..." -ForegroundColor Cyan
    $dryArgs = @("-ExecutionPolicy", "Bypass", "-File", $DEPLOY_PS1, $TargetProject, "-DryRun")
    if ($IncludeOptional) { $dryArgs += "-IncludeOptional" }
    & powershell @dryArgs
    Write-Host ""
    Write-Host "[DRY-RUN] No changes made. Re-run with -Execute to apply." -ForegroundColor Yellow
    Write-Host "Tip: to preserve bespoke framework files, list them in '$TargetProject\.sd003-keep' BEFORE -Execute." -ForegroundColor Cyan
    exit 0
}

# Phase 3: backup (archive-then-remove)
$BackupDir = Join-Path $TargetProject ".sd003-upgrade-backup-$TIMESTAMP"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Write-Host "[Backup] $BackupDir" -ForegroundColor Green

function Move-ToBackup([string]$rel) {
    $srcPath = Join-Path $TargetProject $rel
    if (-not (Test-Path $srcPath)) { return }
    $destPath = Join-Path $BackupDir $rel
    $destParent = Split-Path $destPath -Parent
    if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
    Move-Item -LiteralPath $srcPath -Destination $destPath -Force
    Write-Host "  archived+removed: $rel"
}

foreach ($d in $delDirsPresent)  { Move-ToBackup $d }
foreach ($f in $delFilesPresent) { Move-ToBackup $f }
foreach ($s in $stubFiles)       { Move-ToBackup $s }

# If .antigravity is now empty, remove it
$antigravityDir = Join-Path $TargetProject ".antigravity"
if ((Test-Path $antigravityDir) -and -not (Get-ChildItem $antigravityDir -Force -ErrorAction SilentlyContinue)) {
    Remove-Item $antigravityDir -Force
    Write-Host "  removed empty .antigravity/"
}

# Phase 4: deploy latest framework
Write-Host ""
Write-Host "[Deploy] Running deploy.ps1 ..." -ForegroundColor Cyan
$deployArgs = @("-ExecutionPolicy", "Bypass", "-File", $DEPLOY_PS1, $TargetProject)
if ($IncludeOptional) { $deployArgs += "-IncludeOptional" }
& powershell @deployArgs

# Phase 5: verify
Write-Host ""
Write-Host "=== Upgrade Verification ===" -ForegroundColor Cyan
$ok = $true
$agentsSkills = Join-Path $TargetProject ".agents\skills"
if (Test-Path $agentsSkills) {
    $n = (Get-ChildItem $agentsSkills -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "  [PASS] .agents/skills present ($n skills)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] .agents/skills missing" -ForegroundColor Red; $ok = $false
}
foreach ($d in $deprecatedDirs) {
    if (Test-Path (Join-Path $TargetProject $d)) {
        Write-Host "  [WARN] deprecated still present: $d" -ForegroundColor Yellow
    }
}
Write-Host ""
if ($ok) {
    Write-Host "Result: UPGRADE COMPLETE. Deprecated-artifact backup: $BackupDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: review the deploy report above for 'OVERWROTE local divergence' warnings." -ForegroundColor Yellow
    Write-Host "  Those framework files had LOCAL edits that were overwritten (deploy backup: .sd003-backup-*)." -ForegroundColor Yellow
    Write-Host "  If any were intentional customizations, restore them and add to '$TargetProject\.sd003-keep'." -ForegroundColor Yellow
} else {
    Write-Host "Result: issues found - review above. Backup: $BackupDir" -ForegroundColor Red
}
Write-Host ""
Write-Host "Next: cd $TargetProject; npm install; restart agy and run /skills to confirm commands."
