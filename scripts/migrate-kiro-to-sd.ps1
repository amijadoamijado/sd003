<#
.SYNOPSIS
    .kiro → .sd 一括マイグレーションスクリプト

.DESCRIPTION
    既存プロジェクトの .kiro 参照を .sd に一括変更し、
    .kiro/sessions/ → .sessions/ へのセッション移動を行う。

.PARAMETER TargetProject
    マイグレーション対象プロジェクトのパス

.PARAMETER DryRun
    変更予定の一覧を表示（実際の変更なし）

.PARAMETER Execute
    変更を実行

.EXAMPLE
    .\migrate-kiro-to-sd.ps1 -TargetProject "D:\claudecode\myproject" -DryRun
    .\migrate-kiro-to-sd.ps1 -TargetProject "D:\claudecode\myproject" -Execute
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,

    [switch]$DryRun,
    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────

if (-not $DryRun -and -not $Execute) {
    Write-Host "ERROR: -DryRun または -Execute のいずれかを指定してください。" -ForegroundColor Red
    exit 1
}

if ($DryRun -and $Execute) {
    Write-Host "ERROR: -DryRun と -Execute は同時に指定できません。" -ForegroundColor Red
    exit 1
}

$TargetProject = (Resolve-Path $TargetProject -ErrorAction SilentlyContinue)?.Path
if (-not $TargetProject -or -not (Test-Path $TargetProject -PathType Container)) {
    Write-Host "ERROR: ターゲットプロジェクトが存在しません: $TargetProject" -ForegroundColor Red
    exit 1
}

$mode = if ($DryRun) { "DRY RUN" } else { "EXECUTE" }
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " migrate-kiro-to-sd.ps1 [$mode]" -ForegroundColor Cyan
Write-Host " Target: $TargetProject" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────

$targetExtensions = @(".md", ".sh", ".ps1", ".toml", ".json", ".ts", ".js")

$targetDirs = @(
    ".claude", ".gemini", ".codex", ".antigravity", ".handoff",
    "docs", "scripts", "src", "tests"
)

$rootFiles = @(
    "CLAUDE.md", "README.md", "AGENTS.md", "gemini.md",
    "package.json", ".gitignore"
)

$excludeDirs = @(".git", "node_modules", "dist")

# Content replacement pairs (order matters: longer patterns first)
$contentReplacements = @(
    @{ Pattern = '.kiro/'; Replacement = '.sd/' },
    @{ Pattern = 'kiro-'; Replacement = 'sd-' },
    @{ Pattern = 'kiro:'; Replacement = 'sd:' },
    @{ Pattern = 'Kiro'; Replacement = 'SD' }
)

# Directory/file rename operations
$renameOperations = @(
    @{ From = '.claude/commands/kiro'; To = '.claude/commands/sd' },
    @{ From = '.codex/prompts/kiro'; To = '.codex/prompts/sd' },
    @{ From = '.gemini/skills/kiro-deploy'; To = '.gemini/skills/sd-deploy' }
)

# Counters
$stats = @{
    FilesScanned = 0
    FilesModified = 0
    DirsRenamed = 0
    FilesRenamed = 0
    SessionsCopied = 0
    DataCopied = 0
}

# ─────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────

function Should-Exclude {
    param([string]$Path)
    foreach ($ex in $excludeDirs) {
        if ($Path -match "(\\|/)$([regex]::Escape($ex))(\\|/|$)") {
            return $true
        }
    }
    # Exclude .sd003-backup-* directories
    if ($Path -match "(\\|/)\.sd003-backup-") {
        return $true
    }
    return $false
}

function Get-TargetFiles {
    $files = @()

    # Files in target directories
    foreach ($dir in $targetDirs) {
        $dirPath = Join-Path $TargetProject $dir
        if (Test-Path $dirPath -PathType Container) {
            $found = Get-ChildItem -Path $dirPath -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object {
                    ($targetExtensions -contains $_.Extension) -and
                    -not (Should-Exclude $_.FullName)
                }
            if ($found) { $files += $found }
        }
    }

    # Root files
    foreach ($rf in $rootFiles) {
        $rfPath = Join-Path $TargetProject $rf
        if (Test-Path $rfPath -PathType Leaf) {
            $files += Get-Item $rfPath
        }
    }

    return $files
}

function Find-GlobRenames {
    # Find kiro-* files in hooks directories
    $renames = @()

    # hooks/kiro-* → sd-*
    $hooksDirs = @(
        (Join-Path $TargetProject ".claude/hooks"),
        (Join-Path $TargetProject ".gemini/hooks"),
        (Join-Path $TargetProject "scripts")
    )
    foreach ($hDir in $hooksDirs) {
        if (Test-Path $hDir -PathType Container) {
            $kiroFiles = Get-ChildItem -Path $hDir -File -Filter "kiro-*" -ErrorAction SilentlyContinue
            foreach ($f in $kiroFiles) {
                $newName = $f.Name -replace '^kiro-', 'sd-'
                $renames += @{
                    From = $f.FullName
                    To = Join-Path $f.DirectoryName $newName
                    Type = 'File'
                }
            }
        }
    }

    # .gemini/commands/kiro-* → sd-*
    $geminiCmds = Join-Path $TargetProject ".gemini/commands"
    if (Test-Path $geminiCmds -PathType Container) {
        $kiroFiles = Get-ChildItem -Path $geminiCmds -File -Filter "kiro-*" -ErrorAction SilentlyContinue
        foreach ($f in $kiroFiles) {
            $newName = $f.Name -replace '^kiro-', 'sd-'
            $renames += @{
                From = $f.FullName
                To = Join-Path $f.DirectoryName $newName
                Type = 'File'
            }
        }
    }

    return $renames
}

# ─────────────────────────────────────────────
# Phase 1: File Content Replacement
# ─────────────────────────────────────────────

Write-Host "--- Phase 1: ファイル内容置換 ---" -ForegroundColor Yellow
$files = Get-TargetFiles
Write-Host "  対象ファイル数: $($files.Count)"

foreach ($file in $files) {
    $stats.FilesScanned++
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $original = $content
    $changed = $false

    foreach ($rep in $contentReplacements) {
        if ($content.Contains($rep.Pattern)) {
            $content = $content.Replace($rep.Pattern, $rep.Replacement)
            $changed = $true
        }
    }

    if ($changed) {
        $relativePath = $file.FullName.Substring($TargetProject.Length + 1)
        if ($DryRun) {
            Write-Host "  [WOULD MODIFY] $relativePath" -ForegroundColor DarkYellow
            # Show which patterns matched
            foreach ($rep in $contentReplacements) {
                if ($original.Contains($rep.Pattern)) {
                    Write-Host "    '$($rep.Pattern)' → '$($rep.Replacement)'" -ForegroundColor DarkGray
                }
            }
        } else {
            Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
            Write-Host "  [MODIFIED] $relativePath" -ForegroundColor Green
        }
        $stats.FilesModified++
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# Phase 2: Directory Renames
# ─────────────────────────────────────────────

Write-Host "--- Phase 2: ディレクトリ/ファイルのリネーム ---" -ForegroundColor Yellow

# Static directory renames
foreach ($op in $renameOperations) {
    $fromPath = Join-Path $TargetProject $op.From
    $toPath = Join-Path $TargetProject $op.To

    if (Test-Path $fromPath) {
        if (Test-Path $toPath) {
            $relFrom = $op.From
            $relTo = $op.To
            Write-Host "  [SKIP] $relFrom → $relTo (既に存在)" -ForegroundColor DarkGray
        } else {
            if ($DryRun) {
                Write-Host "  [WOULD RENAME DIR] $($op.From) → $($op.To)" -ForegroundColor DarkYellow
            } else {
                $parentDir = Split-Path $toPath -Parent
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                Move-Item -Path $fromPath -Destination $toPath
                Write-Host "  [RENAMED DIR] $($op.From) → $($op.To)" -ForegroundColor Green
            }
            $stats.DirsRenamed++
        }
    }
}

# Dynamic file renames (kiro-* → sd-*)
$globRenames = Find-GlobRenames
foreach ($ren in $globRenames) {
    if (Test-Path $ren.To) {
        $relFrom = $ren.From.Substring($TargetProject.Length + 1)
        Write-Host "  [SKIP] $relFrom (リネーム先が既に存在)" -ForegroundColor DarkGray
    } else {
        $relFrom = $ren.From.Substring($TargetProject.Length + 1)
        $relTo = $ren.To.Substring($TargetProject.Length + 1)
        if ($DryRun) {
            Write-Host "  [WOULD RENAME FILE] $relFrom → $relTo" -ForegroundColor DarkYellow
        } else {
            Move-Item -Path $ren.From -Destination $ren.To
            Write-Host "  [RENAMED FILE] $relFrom → $relTo" -ForegroundColor Green
        }
        $stats.FilesRenamed++
    }
}

# skills/kiro-deploy/ → sd-deploy/ (in .claude/skills/)
$claudeSkillsKiro = Join-Path $TargetProject ".claude/skills/kiro-deploy"
$claudeSkillsSd = Join-Path $TargetProject ".claude/skills/sd-deploy"
if (Test-Path $claudeSkillsKiro) {
    if (Test-Path $claudeSkillsSd) {
        Write-Host "  [SKIP] .claude/skills/kiro-deploy → sd-deploy (既に存在)" -ForegroundColor DarkGray
    } else {
        if ($DryRun) {
            Write-Host "  [WOULD RENAME DIR] .claude/skills/kiro-deploy → .claude/skills/sd-deploy" -ForegroundColor DarkYellow
        } else {
            Move-Item -Path $claudeSkillsKiro -Destination $claudeSkillsSd
            Write-Host "  [RENAMED DIR] .claude/skills/kiro-deploy → .claude/skills/sd-deploy" -ForegroundColor Green
        }
        $stats.DirsRenamed++
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# Phase 3: .kiro/sessions/ → .sessions/
# ─────────────────────────────────────────────

Write-Host "--- Phase 3: .kiro/sessions/ → .sessions/ コピー ---" -ForegroundColor Yellow

$kiroDir = Join-Path $TargetProject ".kiro"
$kiroSessionsDir = Join-Path $kiroDir "sessions"
$sessionsDir = Join-Path $TargetProject ".sessions"

if (-not (Test-Path $kiroDir -PathType Container)) {
    Write-Host "  [INFO] .kiro/ が存在しません。Phase 3-4 をスキップ。" -ForegroundColor DarkGray
} else {
    if (Test-Path $kiroSessionsDir -PathType Container) {
        $sessionFiles = Get-ChildItem -Path $kiroSessionsDir -Recurse -File -ErrorAction SilentlyContinue
        if ($sessionFiles -and $sessionFiles.Count -gt 0) {
            foreach ($sf in $sessionFiles) {
                $relativeSf = $sf.FullName.Substring($kiroSessionsDir.Length + 1)
                $destPath = Join-Path $sessionsDir $relativeSf

                if (Test-Path $destPath) {
                    Write-Host "  [SKIP] .sessions/$relativeSf (既に存在)" -ForegroundColor DarkGray
                } else {
                    if ($DryRun) {
                        Write-Host "  [WOULD COPY] .kiro/sessions/$relativeSf → .sessions/$relativeSf" -ForegroundColor DarkYellow
                    } else {
                        $destDir = Split-Path $destPath -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        Copy-Item -Path $sf.FullName -Destination $destPath
                        Write-Host "  [COPIED] .kiro/sessions/$relativeSf → .sessions/$relativeSf" -ForegroundColor Green
                    }
                    $stats.SessionsCopied++
                }
            }
        } else {
            Write-Host "  [INFO] .kiro/sessions/ にファイルがありません。" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [INFO] .kiro/sessions/ が存在しません。" -ForegroundColor DarkGray
    }

    Write-Host ""

    # ─────────────────────────────────────────────
    # Phase 4: .kiro/ non-session data → .sd/
    # ─────────────────────────────────────────────

    Write-Host "--- Phase 4: .kiro/ 非sessionデータ → .sd/ コピー ---" -ForegroundColor Yellow

    $sdDir = Join-Path $TargetProject ".sd"
    $kiroSubDirs = Get-ChildItem -Path $kiroDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "sessions" }

    if ($kiroSubDirs -and $kiroSubDirs.Count -gt 0) {
        foreach ($subDir in $kiroSubDirs) {
            $subFiles = Get-ChildItem -Path $subDir.FullName -Recurse -File -ErrorAction SilentlyContinue
            if (-not $subFiles) { continue }

            foreach ($sf in $subFiles) {
                $relativeFromKiro = $sf.FullName.Substring($kiroDir.Length + 1)
                $destPath = Join-Path $sdDir $relativeFromKiro

                if (Test-Path $destPath) {
                    Write-Host "  [SKIP] .sd/$relativeFromKiro (既に存在)" -ForegroundColor DarkGray
                } else {
                    if ($DryRun) {
                        Write-Host "  [WOULD COPY] .kiro/$relativeFromKiro → .sd/$relativeFromKiro" -ForegroundColor DarkYellow
                    } else {
                        $destDir = Split-Path $destPath -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        Copy-Item -Path $sf.FullName -Destination $destPath
                        Write-Host "  [COPIED] .kiro/$relativeFromKiro → .sd/$relativeFromKiro" -ForegroundColor Green
                    }
                    $stats.DataCopied++
                }
            }
        }
    } else {
        Write-Host "  [INFO] .kiro/ に非sessionサブディレクトリがありません。" -ForegroundColor DarkGray
    }

    # Also copy root-level files in .kiro/ (not in subdirectories)
    $kiroRootFiles = Get-ChildItem -Path $kiroDir -File -ErrorAction SilentlyContinue
    if ($kiroRootFiles -and $kiroRootFiles.Count -gt 0) {
        foreach ($rf in $kiroRootFiles) {
            $destPath = Join-Path $sdDir $rf.Name
            if (Test-Path $destPath) {
                Write-Host "  [SKIP] .sd/$($rf.Name) (既に存在)" -ForegroundColor DarkGray
            } else {
                if ($DryRun) {
                    Write-Host "  [WOULD COPY] .kiro/$($rf.Name) → .sd/$($rf.Name)" -ForegroundColor DarkYellow
                } else {
                    if (-not (Test-Path $sdDir)) {
                        New-Item -ItemType Directory -Path $sdDir -Force | Out-Null
                    }
                    Copy-Item -Path $rf.FullName -Destination $destPath
                    Write-Host "  [COPIED] .kiro/$($rf.Name) → .sd/$($rf.Name)" -ForegroundColor Green
                }
                $stats.DataCopied++
            }
        }
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# Phase 5: kiro残存チェック
# ─────────────────────────────────────────────

Write-Host "--- Phase 5: kiro残存チェック ---" -ForegroundColor Yellow

$residualFound = $false
$residualFiles = @()

# Re-scan all target files for remaining kiro references
$allFiles = Get-TargetFiles
foreach ($file in $allFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $matches = @()
    foreach ($rep in $contentReplacements) {
        if ($content.Contains($rep.Pattern)) {
            $matches += $rep.Pattern
        }
    }
    # Also check for bare "kiro" (case-insensitive) that might have been missed
    if ($content -match '\bkiro\b') {
        $matches += "kiro (bare word)"
    }

    if ($matches.Count -gt 0) {
        $relativePath = $file.FullName.Substring($TargetProject.Length + 1)
        $residualFiles += @{
            Path = $relativePath
            Patterns = $matches
        }
        $residualFound = $true
    }
}

# Check for kiro-named directories/files
$kiroPaths = @()
foreach ($dir in $targetDirs) {
    $dirPath = Join-Path $TargetProject $dir
    if (Test-Path $dirPath -PathType Container) {
        $items = Get-ChildItem -Path $dirPath -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'kiro' -and -not (Should-Exclude $_.FullName) }
        if ($items) { $kiroPaths += $items }
    }
}

if ($residualFound -or $kiroPaths.Count -gt 0) {
    Write-Host "  [WARN] kiro参照が残存しています:" -ForegroundColor Red
    foreach ($rf in $residualFiles) {
        Write-Host "    ファイル内容: $($rf.Path)" -ForegroundColor Red
        foreach ($p in $rf.Patterns) {
            Write-Host "      パターン: $p" -ForegroundColor DarkRed
        }
    }
    foreach ($kp in $kiroPaths) {
        $relPath = $kp.FullName.Substring($TargetProject.Length + 1)
        Write-Host "    パス名: $relPath" -ForegroundColor Red
    }
} else {
    if ($DryRun) {
        Write-Host "  [INFO] 実行後、kiro参照は残存しない見込みです。" -ForegroundColor Green
    } else {
        Write-Host "  [OK] kiro参照は残存していません。" -ForegroundColor Green
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Summary [$mode]" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  スキャンしたファイル: $($stats.FilesScanned)"
Write-Host "  内容を変更したファイル: $($stats.FilesModified)"
Write-Host "  リネームしたディレクトリ: $($stats.DirsRenamed)"
Write-Host "  リネームしたファイル: $($stats.FilesRenamed)"
Write-Host "  コピーしたセッションファイル: $($stats.SessionsCopied)"
Write-Host "  コピーした非sessionデータ: $($stats.DataCopied)"

if ($DryRun) {
    Write-Host ""
    Write-Host "  ※ DryRunモードのため実際の変更は行われていません。" -ForegroundColor Yellow
    Write-Host "  実行するには -Execute を指定してください。" -ForegroundColor Yellow
}

Write-Host ""
