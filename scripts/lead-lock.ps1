#requires -Version 7.0
param([Parameter(Position=0,Mandatory=$true)][ValidateSet('acquire','release','status')][string]$Action,
      [Parameter(Position=1)][string]$Ai)
$lock = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\.git')) 'sd-lead.lock'
function Read-Lock { if (Test-Path $lock) { try { Get-Content $lock -Raw | ConvertFrom-Json } catch { $null } } }
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
$current = Read-Lock
$ownerPid = Get-RealOwnerPid
switch ($Action) {
  'acquire' {
    if (-not $Ai) { throw 'ai name is required' }
    if ($current -and (Is-Live $current) -and ($current.ai -ne $Ai -or $current.pid -ne $ownerPid)) { Write-Error "repo lock held by $($current.ai) pid=$($current.pid)"; exit 1 }
    @{ ai=$Ai; pid=$ownerPid; startedAt=(Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json -Compress | Set-Content $lock -NoNewline -Encoding utf8
    Write-Host "acquired ai=$Ai pid=$ownerPid"
  }
  'release' {
    if ($current -and $Ai -and $current.ai -ne $Ai) { Write-Error "repo lock held by $($current.ai)"; exit 1 }
    if (Test-Path $lock) { Remove-Item $lock -Force }
    Write-Host 'released'
  }
  'status' {
    if (-not $current) { Write-Host 'unlocked'; exit 0 }
    $state = if (Is-Live $current) { 'live' } else { 'stale' }
    Write-Host "$state ai=$($current.ai) pid=$($current.pid) startedAt=$($current.startedAt)"
  }
}
