#requires -Version 7.0
param([Parameter(Mandatory=$true)][string]$Repo,[Parameter(Mandatory=$true)][string]$Out,
      [Parameter(Mandatory=$true)][string]$Prompt,[string]$ExpectedArtifact,[int]$TimeoutSeconds=600)
$ErrorActionPreference='Stop'
$lockPath = Join-Path $Repo '.git\sd-lead.lock'
if ((Test-Path $lockPath) -and $env:SD003_LEAD_AI) { $holder=(Get-Content $lockPath -Raw | ConvertFrom-Json).ai; if ($holder -ne $env:SD003_LEAD_AI) { Write-Error "repo lock held by $holder"; exit 1 } }
if (Get-Process agy,antigravity -ErrorAction SilentlyContinue) { Write-Error 'agy/antigravity is already running'; exit 1 }
$probe = Start-Process agy -ArgumentList @('help','models') -PassThru -NoNewWindow
if (-not $probe.WaitForExit(15000)) { $probe.Kill($true); Write-Error 'agy authentication probe timed out'; exit 1 }
if ($probe.ExitCode -ne 0) { Write-Error 'agy authentication probe failed'; exit 1 }
$prog=[IO.Path]::ChangeExtension($Out,'.progress.log')
$args=@('--sandbox','--mode','accept-edits','--prompt',$Prompt)
$process=Start-Process agy -ArgumentList $args -WorkingDirectory $Repo -RedirectStandardOutput $Out -RedirectStandardError $prog -PassThru -NoNewWindow
if (-not $process.WaitForExit($TimeoutSeconds*1000)) { $process.Kill($true); Write-Error 'agy timed out'; exit 1 }
if ($process.ExitCode -ne 0) { Write-Error "agy exit code $($process.ExitCode)"; exit 1 }
if ($ExpectedArtifact) { $artifact=[IO.Path]::GetFullPath((Join-Path $Repo $ExpectedArtifact)); $root=[IO.Path]::GetFullPath($Repo); if (-not $artifact.StartsWith($root) -or -not (Test-Path $artifact)) { Write-Error "expected artifact missing: $ExpectedArtifact"; exit 1 } }
if (-not (Test-Path $Out) -or (Get-Item $Out).Length -eq 0) { Write-Error 'agy output missing'; exit 1 }
Write-Host "OK out=$Out"
