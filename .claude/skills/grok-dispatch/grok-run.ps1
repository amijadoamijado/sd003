#requires -Version 7.0
<#
grok-run.ps1 — 正準 Grok dispatch（フラグを間違えない決定論入口・pwsh版）

codex-run.sh の Grok/Windows 版。実測確定（2026-06-28）した正準 invocation を1点に集約する:
  & $GrokExe --prompt-file <tmp> -m <model> --output-format plain > <out> 2> <progress.log>

確定事実（このマシンで実測）:
  - --output-format の有効値は plain | json | streaming-json（text は無効＝exit 2）
  - --prompt-file <file> で長文プロンプトをファイル渡し可能
  - 最終回答は stdout（plain・clean）、進捗/DEBUG/telemetry は stderr へ分離
  - codex の -o（最終メッセージ専用ファイル化）相当は無い → stdout リダイレクトが正本

usage:
  pwsh -File grok-run.ps1 <repo> <out> "<prompt>" [model]
    <repo>   : 作業ディレクトリ（リポジトリ直下）
    <out>    : 最終回答の出力先（clean な最終メッセージのみ）
    <prompt> : Grok への指示本文
    [model]  : 省略時 grok-build（xAI コーディング特化モデル）

Bash tool から呼ぶ場合も `pwsh -File grok-run.ps1 ...` を使う（Codex=bash / Grok=ps1 の非対称を吸収）。
#>
param(
  [Parameter(Mandatory = $true)][string]$Repo,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true, ParameterSetName = 'Prompt')][string]$Prompt,
  [Parameter(Mandatory = $true, ParameterSetName = 'PromptFile')][string]$PromptFile,
  [string]$Model = "grok-build"
)

$ErrorActionPreference = "Stop"

# --- exe パスの正本: $env:GROK_HOME/bin/grok.exe（ハードコード D:\grok は使わない）---
if (-not $env:GROK_HOME) {
  Write-Error "GROK_HOME 未設定。例: `$env:GROK_HOME='D:\grok'`。詳細は SKILL.md / .grok/GROK_SPEC.md"
  exit 2
}
$GrokExe = Join-Path $env:GROK_HOME "bin\grok.exe"
if (-not (Test-Path $GrokExe)) {
  Write-Error "grok.exe が見つからない: $GrokExe（GROK_HOME を確認）"
  exit 2
}

# --- 最小バージョンチェック（フラグは patch で変わりうる。想定外は警告のみ）---
try {
  $ver = & $GrokExe --version 2>$null
  if ($ver -notmatch 'grok\s+0\.') {
    Write-Warning "想定外の grok version: '$ver'。--output-format/--prompt-file の仕様変化に注意。"
  }
} catch {
  Write-Warning "grok --version 取得失敗。続行するが invocation 失敗時はバージョンを疑う。"
}

# --- preflight: OOM/詰まり防止（警告のみ・ブロックしない）---
try {
  $free = [int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024)
  if ($free -lt 5000) {
    Write-Warning "free RAM ${free}MB < 5000MB — 重 CLI 同時実行は OOM 危険。人手ハンドオフ検討（SKILL.md）。"
  }
} catch {}
$busy = Get-Process grok, codex, agy, claude -ErrorAction SilentlyContinue | Where-Object { $_.Path -ne $GrokExe -or $_.Id -ne $PID }
if ($busy) {
  Write-Warning "既存 grok/codex/agy が稼働中。同一 repo への同時書き込みは排他（git 競合回避）。確認してから続行。"
}
$lockPath = Join-Path $Repo '.git\sd-lead.lock'
if ((Test-Path $lockPath) -and $env:SD003_LEAD_AI) { $holder=(Get-Content $lockPath -Raw | ConvertFrom-Json).ai; if ($holder -ne $env:SD003_LEAD_AI) { Write-Error "repo lock held by $holder"; exit 1 } }

# --- run（正準）---
$env:GROK_HOME = $env:GROK_HOME  # 子プロセスへ明示継承
$tmp = if ($PSCmdlet.ParameterSetName -eq 'Prompt') { [System.IO.Path]::GetTempFileName() } else { $null }
$promptPath = if ($tmp) { $tmp } else { (Resolve-Path $PromptFile).Path }
$prog = [System.IO.Path]::ChangeExtension($Out, ".progress.log")
try {
  if ($tmp) { Set-Content -Path $tmp -Value $Prompt -Encoding UTF8 }
  if (Test-Path $Out) { Remove-Item $Out -Force }
  Push-Location $Repo
  & $GrokExe --prompt-file $promptPath --permission-mode bypassPermissions -m $Model --output-format plain > $Out 2> $prog
  $rc = $LASTEXITCODE
} finally {
  Pop-Location -ErrorAction SilentlyContinue
  if ($tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

# --- verify（出力検証・盲目リトライ禁止）---
# rc==0 を必須にする。grok がエラー終了（rc!=0）した場合は、部分出力があっても FAIL 扱い。
$cancelled = (Test-Path $prog) -and ((Get-Content $prog -Raw) -match 'cancellationCategory["\:=\s]+PermissionCancelled')
if (($rc -eq 0) -and -not $cancelled -and (Test-Path $Out) -and ((Get-Item $Out).Length -gt 0)) {
  Write-Host "OK rc=$rc out=$Out bytes=$((Get-Item $Out).Length) model=$Model"
  exit 0
} else {
  $why = if ($cancelled) { 'PermissionCancelled marker' } elseif ($rc -ne 0) { "grok exit code $rc" } else { "$Out 未生成または空" }
  Write-Error "FAIL (${why})。盲目リトライ禁止。progress tail:"
  if (Test-Path $prog) { Get-Content $prog -Tail 12 | ForEach-Object { Write-Host $_ } }
  exit 1
}
