#requires -Version 7.0
param([Parameter(Position=0,Mandatory=$true)][ValidateSet('acquire','release','status')][string]$Action,
      [Parameter(Position=1)][string]$Ai)
$ErrorActionPreference = 'Stop'
function Read-Lock { if (Test-Path -LiteralPath $lock) { Get-Content -LiteralPath $lock -Raw | ConvertFrom-Json } }
function Is-Live($record) { if (-not $record) { return $false }; return $null -ne (Get-Process -Id $record.pid -ErrorAction SilentlyContinue) }
function Get-RealOwnerPid {
  $process = Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
  $realPid = $process.ParentProcessId
  while ($process -and $process.ParentProcessId -ne 0) {
    $parentPid = $process.ParentProcessId
    $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$parentPid" -ErrorAction SilentlyContinue
    if (-not $parent) { break }
    $name = $parent.Name.ToLower()
    $cmd = $parent.CommandLine
    $isTemporary = $false
    if ($name -match '^(pwsh|powershell|cmd|bash|sh|node)\.exe$') {
      if ($cmd -and ($cmd -match '\.(ps1|sh|js|bat|cmd)\b' -or $cmd -match '\s-(File|Command|c)\b')) {
        $isTemporary = $true
      }
    } elseif ($name -match '^(git|tsc|npm|eslint)\.exe$') {
      $isTemporary = $true
    }
    if (-not $isTemporary) {
      $realPid = $parentPid
      break
    }
    $process = $parent
  }
  return $realPid
}
$mutex = $null
$held = $false
$failed = $false
try {
  $gitDir = & git -C (Join-Path $PSScriptRoot '..') rev-parse --absolute-git-dir
  if ($LASTEXITCODE -ne 0 -or -not $gitDir) { throw 'cannot resolve repository Git directory' }
  $gitDir = [IO.Path]::GetFullPath(($gitDir | Select-Object -Last 1).Trim())
  $lock = Join-Path $gitDir 'sd-lead.lock'
  # Serialize the read/check/write sequence, including stale-lock recovery and release.
  $identity = if ($IsWindows) { $gitDir.ToLowerInvariant() } else { $gitDir }
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $hash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($identity))).Replace('-', '') }
  finally { $sha.Dispose() }
  $mutex = [Threading.Mutex]::new($false, "sd003-lead-$hash")
  try { $held = $mutex.WaitOne(10000) }
  catch [Threading.AbandonedMutexException] { $held = $true }
  if (-not $held) { throw 'timed out waiting for repository lock operation' }
  $current = Read-Lock
  $ownerPid = Get-RealOwnerPid
  switch ($Action) {
    'acquire' {
      if (-not $Ai) { throw 'ai name is required' }
      if ($current -and (Is-Live $current)) {
        if ($current.ai -ne $Ai -or $current.pid -ne $ownerPid) { throw "repo lock held by $($current.ai) pid=$($current.pid)" }
      } else {
        if (Test-Path -LiteralPath $lock) { Remove-Item -LiteralPath $lock -Force }
        $record = @{ ai=$Ai; pid=$ownerPid; startedAt=(Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json -Compress
        $stream = [IO.File]::Open($lock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
          $bytes = [Text.Encoding]::UTF8.GetBytes($record)
          $stream.Write($bytes, 0, $bytes.Length)
          $stream.Flush($true)
        } finally { $stream.Dispose() }
      }
      Write-Host "acquired ai=$Ai pid=$ownerPid"
    }
    'release' {
      if (-not $Ai) { throw 'ai name is required' }
      if ($current -and ($current.ai -ne $Ai -or $current.pid -ne $ownerPid)) { throw "repo lock held by $($current.ai) pid=$($current.pid)" }
      if (Test-Path -LiteralPath $lock) { Remove-Item -LiteralPath $lock -Force }
      Write-Host 'released'
    }
    'status' {
      if (-not $current) { Write-Host 'unlocked' }
      else {
        $state = if (Is-Live $current) { 'live' } else { 'stale' }
        Write-Host "$state ai=$($current.ai) pid=$($current.pid) startedAt=$($current.startedAt)"
      }
    }
  }
} catch {
  [Console]::Error.WriteLine($_.Exception.Message)
  $failed = $true
} finally {
  if ($held) { $mutex.ReleaseMutex() }
  if ($mutex) { $mutex.Dispose() }
}
if ($failed) { exit 1 }
