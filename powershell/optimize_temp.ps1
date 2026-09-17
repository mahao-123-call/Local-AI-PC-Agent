#requires -Version 5.1

<#
Local-AI-PC-Agent
Safe TEMP Optimizer v0.6

Purpose:
- Scan the current user's TEMP directory
- Select old temporary files
- Show estimated cleanup size
- Require explicit confirmation
- Delete only selected old files
- Record results

Safety:
- Current user TEMP only
- Files only
- No arbitrary directories
- No Windows system directories
- Explicit Y confirmation required
#>

$ErrorActionPreference = "SilentlyContinue"

$TempPath = $env:TEMP

# Only files older than this many days are candidates.
$MinimumAgeDays = 7

$CutoffDate = (Get-Date).AddDays(-$MinimumAgeDays)


Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent TEMP Optimizer"
Write-Host "========================================"
Write-Host ""

Write-Host "TEMP directory:"
Write-Host $TempPath

Write-Host ""
Write-Host "Cleanup rule:"
Write-Host "Files not modified in the last $MinimumAgeDays days."
Write-Host ""


# ============================================================
# Safety validation
# ============================================================

if (-not (Test-Path $TempPath)) {

    Write-Host "ERROR: TEMP directory does not exist." `
        -ForegroundColor Red

    exit 1
}


# ============================================================
# Find candidate files
# ============================================================

Write-Host "Scanning TEMP files..."

$candidates = @(
    Get-ChildItem `
        -LiteralPath $TempPath `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.LastWriteTime -lt $CutoffDate
    }
)


$candidateCount = $candidates.Count

$candidateBytes = (
    $candidates |
    Measure-Object `
        -Property Length `
        -Sum
).Sum


if ($null -eq $candidateBytes) {
    $candidateBytes = 0
}


$candidateMB = [math]::Round(
    $candidateBytes / 1MB,
    2
)


Write-Host ""
Write-Host "Candidate files: $candidateCount"
Write-Host "Estimated cleanup: $candidateMB MB"
Write-Host ""


# ============================================================
# Nothing to clean
# ============================================================

if ($candidateCount -eq 0) {

    Write-Host "No eligible TEMP files were found."
    Write-Host "No system changes were made."

    exit 0
}


# ============================================================
# Confirmation
# ============================================================

Write-Host "IMPORTANT:"
Write-Host "Only files older than $MinimumAgeDays days will be attempted."
Write-Host "Files that cannot be deleted will be skipped."
Write-Host ""

$answer = Read-Host "Proceed with TEMP cleanup? Type Y or N"


if ($answer -notmatch '^[Yy]$') {

    Write-Host ""
    Write-Host "Cleanup cancelled."
    Write-Host "No files were deleted."

    exit 0
}


# ============================================================
# Execute cleanup
# ============================================================

$deletedCount = 0
$deletedBytes = 0

$failedCount = 0


foreach ($file in $candidates) {

    try {

        $fileLength = $file.Length

        Remove-Item `
            -LiteralPath $file.FullName `
            -Force `
            -ErrorAction Stop

        $deletedCount++

        $deletedBytes += $fileLength

    }
    catch {

        $failedCount++
    }
}


$deletedMB = [math]::Round(
    $deletedBytes / 1MB,
    2
)


# ============================================================
# Result
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " TEMP cleanup completed"
Write-Host "========================================"

Write-Host ""

Write-Host "Deleted files: $deletedCount"
Write-Host "Skipped/failed files: $failedCount"
Write-Host "Released approximately: $deletedMB MB"

Write-Host ""