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

# Over-engineering artifacts removed from SD003 on 2026-07-05 (Ralph Loop / refactor
# system / 7-stage workflow / context-autonomy). Archived out of the framework body, but
# deploy only COPIES+overwrites and never prunes files gone from source, so without
# purging these here every upgraded project keeps ORPHANED command/skill/rule files that
# reference deleted rules. Matched across ALL known roots (.claude, the mirror skill dirs
# .agents/.codex/.grok, and the .sd generated mirrors). .gemini mirror copies are already
# covered by the wholesale .gemini removal above.
$overengCmdNames   = @("ralph-wiggum-plan","ralph-wiggum-run","ralph-wiggum-status","refactor-batch","refactor-complete","refactor-init","refactor-plan","refactor-rollback","sd003-loop-lint","sd003-loop-test","sd003-loop-type","workflow-init","workflow-order","workflow-request","workflow-review","workflow-status","workflow-test","workflow-impl")
$overengSkillNames = @("context-autonomy","rollback-guard","session-autosave")
$overengExtra      = @(".claude\hooks\context-monitor-hook.ps1", ".claude\rules\ralph-loop.md", ".claude\rules\refactoring", ".sd\ralph", ".sd\refactor", ".claude\hooks\sd003-stop-hook.sh", ".claude\hooks\sd003-stop-hook.ps1", ".claude\hooks\sd003-stop-hook-endgame.sh", ".claude\hooks\sd003-stop-hook-endgame.ps1", "scripts\deploy-ralph-wiggum.sh")

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

# Expand over-engineering artifacts to concrete relative paths across all roots; keep present ones.
$overengAll = @()
foreach ($c in $overengCmdNames)   { $overengAll += ".claude\commands\$c.md", ".sd\commands\specs\$c.md", ".agents\skills\$c", ".codex\skills\$c", ".grok\skills\$c" }
foreach ($s in $overengSkillNames) { $overengAll += ".claude\skills\$s", ".agents\skills\$s", ".codex\skills\$s", ".grok\skills\$s" }
$overengAll += $overengExtra
$delOverengPresent = @($overengAll | Where-Object { Test-Path (Join-Path $TargetProject $_) })

# claude-mem stub CLAUDE.md files (nested, content-marked), excluding root + vcs/deps
$stubFiles = @()
Get-ChildItem -Path $TargetProject -Recurse -File -Filter "CLAUDE.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($TargetProject.TrimEnd('\').Length + 1)
    if ($rel -eq "CLAUDE.md") { return }                       # keep real root CLAUDE.md
    if ($rel -match '(^|\\)(\.git|node_modules|\.sd003-backup[^\\]*|\.sd003-upgrade-backup[^\\]*)(\\|$)') { return }
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
if ($delDirsPresent.Count -eq 0 -and $delFilesPresent.Count -eq 0 -and $stubFiles.Count -eq 0 -and $delOverengPresent.Count -eq 0) {
    Write-Host "  (none — no deprecated artifacts found)" -ForegroundColor Green
} else {
    foreach ($d in $delDirsPresent)  { Write-Host "  [dir]  $d" }
    foreach ($f in $delFilesPresent) { Write-Host "  [file] $f" }
    foreach ($s in $stubFiles)       { Write-Host "  [stub] $s" }
    foreach ($o in $delOverengPresent) { Write-Host "  [oeng] $o" }
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
foreach ($o in $delOverengPresent) { Move-ToBackup $o }

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
$deployExitCode = $LASTEXITCODE
if ($deployExitCode -ne 0) {
    Write-Host ""
    Write-Host "[WARN] deploy.ps1 exited with code $deployExitCode." -ForegroundColor Yellow
    Write-Host "  This can be benign (e.g. optional-skills count mismatch or a kept settings.json)," -ForegroundColor Yellow
    Write-Host "  but this script cannot confirm success from here. Backup prune (Phase 6) will be skipped." -ForegroundColor Yellow
}

# Phase 5: verify
Write-Host ""
Write-Host "=== Upgrade Verification ===" -ForegroundColor Cyan
$ok = ($deployExitCode -eq 0)
if (-not $ok) {
    Write-Host "  [FAIL] deploy.ps1 exited nonzero ($deployExitCode) - see warning above" -ForegroundColor Red
}
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
    if ($deployExitCode -ne 0) {
        Write-Host "  NOT claiming success: deploy.ps1 exited $deployExitCode. Existing backups were left untouched (no prune)." -ForegroundColor Red
    }
}

# ------------------------------------------------------------------
# Phase 6: prune stale backup folders (keep newest only; archive, never delete).
# Repeated deploy/upgrade runs accumulate .sd003-backup-*, .sd003-upgrade-backup-*
# and legacy .sd002-backup-* directories with no cleanup (found piled up to 8+ in
# cf001 during the 2026-07-05 D:\claudecode cleanup). Move stale ones to
# <project>/.sd003-archive/<YYYYMMDD>/ instead of deleting them.
# NOTE: destination is intentionally OUTSIDE .sd/ (unlike the previous
# .sd/cleanup/archive/ location) — .sd/ is git-tracked and gets recursively
# copied into every future .sd003-backup-*, so archiving inside it caused
# nested bloat (.sd/.../.sd003-backup-.../.sd/cleanup/archive/...) and pulled
# old backups into git commits. Also skipped entirely when deploy.ps1 did not
# exit 0, so a failed/unconfirmed deploy never causes backups to be pruned.
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[Prune] Checking for accumulated backup folders ..." -ForegroundColor Cyan
if ($deployExitCode -ne 0) {
    Write-Host "  [SKIP] deploy.ps1 exited nonzero ($deployExitCode) - skipping prune so existing backups stay intact." -ForegroundColor Yellow
} else {
    $backupPatterns = @(".sd003-backup-*", ".sd003-upgrade-backup-*", ".sd002-backup-*")
    $pruned = $false
    foreach ($pattern in $backupPatterns) {
        # Sort by the yyyyMMdd_HHmmss timestamp embedded in the DIRECTORY NAME,
        # not by LastWriteTime: touching any file inside an old backup (e.g.
        # restoring one file from it) bumps that directory's mtime and can make
        # LastWriteTime-based sorting misidentify the real newest backup.
        $found = @(Get-ChildItem -Path $TargetProject -Directory -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                $sortKey = [datetime]::MinValue
                if ($_.Name -match '(\d{8}_\d{6})$') {
                    try { $sortKey = [datetime]::ParseExact($Matches[1], 'yyyyMMdd_HHmmss', $null) } catch {}
                }
                [PSCustomObject]@{ Item = $_; SortKey = $sortKey }
            } |
            Sort-Object SortKey -Descending |
            ForEach-Object { $_.Item })
        if ($found.Count -ge 2) {
            $pruned = $true
            $keep = $found[0]
            $stale = $found | Select-Object -Skip 1
            $archiveDir = Join-Path $TargetProject ".sd003-archive\$(Get-Date -Format 'yyyyMMdd')"
            if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
            Write-Host "  [$pattern] $($found.Count) found. Keeping newest (by embedded timestamp): $($keep.Name)" -ForegroundColor Yellow
            foreach ($old in $stale) {
                $dest = Join-Path $archiveDir $old.Name
                if (Test-Path $dest) { $dest = Join-Path $archiveDir "$($old.Name)_$(Get-Date -Format 'HHmmss')" }
                Move-Item -LiteralPath $old.FullName -Destination $dest -Force
                Write-Host "    archived (not deleted): $($old.Name) -> $dest"
            }
        }
    }
    if (-not $pruned) {
        Write-Host "  (none - fewer than 2 backups per pattern, nothing to prune)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Next: cd $TargetProject; npm install; restart agy and run /skills to confirm commands."
