param(
    [int]$Hours = 48,
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    Write-Host "recover-agy-artifacts.ps1 - Recover agy (Antigravity CLI) deliverables on Windows"
    Write-Host "Usage:"
    Write-Host "  .\scripts\recover-agy-artifacts.ps1 [-Hours <int>] [-DryRun]"
    exit 0
}

# Get project root
$ProjectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel 2>$null) }
if (-not $ProjectDir) { 
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectDir = Split-Path -Parent $ScriptDir
}

# Brain directory
$HomeDir = [System.Environment]::GetFolderPath('UserProfile')
$Brain = Join-Path $HomeDir ".gemini\antigravity-cli\brain"

if (-not (Test-Path $Brain)) {
    Write-Host "agy brain dir not found: $Brain (nothing to recover)"
    exit 0
}

# Destination stamp
$Stamp = Get-Date -Format "yyyyMMdd"
$Dest = Join-Path $ProjectDir "materials\_agy-recovered\$Stamp"

Write-Host "Searching for agy deliverables modified in the last $Hours hours under $Brain..."

# Find candidate files
$CutoffTime = (Get-Date).AddHours(-$Hours)
$Files = Get-ChildItem -Path $Brain -Recurse -File | Where-Object {
    $_.LastWriteTime -gt $CutoffTime -and
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\\.system_generated\\' -and
    $_.FullName -notmatch '\\scratch\\' -and
    $_.Name -notmatch '^transcript\.jsonl$' -and
    $_.Name -notmatch '^\.gitignore$'
}

if (-not $Files) {
    Write-Host "No agy deliverables modified in the last $Hours hours."
    exit 0
}

Write-Host "Found $($Files.Count) candidate file(s)."
Write-Host "Destination: $Dest"
if ($DryRun) { Write-Host "(--dry-run: no files will be copied)" }
Write-Host ""

$Copied = 0
foreach ($file in $Files) {
    # Rel path under brain: brain/<uuid>/filename
    $RelPath = $file.FullName.Substring($Brain.Length + 1)
    $Convo = $RelPath.Split([System.IO.Path]::DirectorySeparatorChar)[0]
    $ShortConvo = if ($Convo.Length -gt 8) { $Convo.Substring(0, 8) } else { $Convo }
    
    $NewName = "${ShortConvo}__$($file.Name)"
    $OutPath = Join-Path $Dest $NewName
    
    if ($DryRun) {
        Write-Host "would copy: $($file.FullName)"
        Write-Host "        -> $OutPath"
    } else {
        if (-not (Test-Path $Dest)) {
            New-Item -ItemType Directory -Path $Dest -Force | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $OutPath -Force -ErrorAction SilentlyContinue
        if (Test-Path $OutPath) {
            Write-Host "recovered: $OutPath"
            $Copied++
        } else {
            Write-Warning "FAILED to copy: $($file.FullName)"
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Preview complete. Re-run without -DryRun to copy into the project."
} else {
    Write-Host "Recovered $Copied file(s) into: $Dest"
}
