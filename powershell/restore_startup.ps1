#requires -Version 5.1

<#
Local-AI-PC-Agent
Startup Restore v0.6
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BackupFile = Join-Path $ProjectRoot "reports\startup_backup.json"

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent Startup Restore"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $BackupFile)) {
    Write-Host "No startup backup was found."
    Write-Host "Nothing was changed."
    exit 0
}

$backup = Get-Content $BackupFile -Raw | ConvertFrom-Json

Write-Host "Backup entry:"
Write-Host ""
Write-Host "Name:"
Write-Host $backup.Name

Write-Host ""
Write-Host "Command:"
Write-Host $backup.Command

Write-Host ""
Write-Host "Original location:"
Write-Host $backup.Location

Write-Host ""
Write-Host "This will restore the startup entry."
Write-Host ""

$answer = Read-Host "Restore this startup entry? Type Y or N"

if ($answer -notmatch '^[Yy]$') {
    Write-Host ""
    Write-Host "Restore cancelled."
    Write-Host "No changes were made."
    exit 0
}

try {

    if (-not (Test-Path $backup.RegistryPath)) {
        Write-Host ""
        Write-Host "ERROR: Original registry location no longer exists."
        Write-Host "No changes were made."
        exit 1
    }

    New-ItemProperty `
        -LiteralPath $backup.RegistryPath `
        -Name $backup.Name `
        -Value $backup.Command `
        -PropertyType String `
        -Force `
        -ErrorAction Stop |
        Out-Null

    Write-Host ""
    Write-Host "Startup entry restored successfully."
    Write-Host ""
    Write-Host "Restored:"
    Write-Host $backup.Name
}
catch {

    Write-Host ""
    Write-Host "Restore failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}