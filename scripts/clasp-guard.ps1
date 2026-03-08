# clasp-guard.ps1 - clasp deploy/undeploy を物理的にブロック
#
# Codex / Gemini CLI など hook が使えないAI向けのガード。
# package.json の gas:deploy 等から呼ばれる。
#
# 許可: clasp push, clasp pull, clasp status, clasp versions, clasp deployments
# 禁止: clasp deploy, clasp undeploy

$ErrorActionPreference = 'Stop'

$subcommand = $args[0]
$restArgs = $args[1..($args.Length - 1)]

switch ($subcommand) {
  { $_ -in 'deploy', 'undeploy' } {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "BLOCKED: clasp $subcommand is prohibited." -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "GAS code sync uses 'clasp push' only." -ForegroundColor Red
    Write-Host "To update a fixed deployment, get explicit" -ForegroundColor Red
    Write-Host "user permission first." -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    exit 1
  }
  { $_ -in 'push', 'pull', 'status', 'versions', 'deployments', 'login', 'logout', 'open', 'logs', 'run', 'version' } {
    & clasp $subcommand @restArgs
    exit $LASTEXITCODE
  }
  default {
    Write-Host "clasp-guard: unknown subcommand '$subcommand'" -ForegroundColor Red
    Write-Host "Allowed: push, pull, status, versions, deployments, login, logout, open, logs, run, version" -ForegroundColor Red
    exit 1
  }
}
