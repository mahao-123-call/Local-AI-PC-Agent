#requires -Version 5.1

<#
Local-AI-PC-Agent
One-click Windows Health Check
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot

$Collector = Join-Path $ProjectRoot "powershell\system_info.ps1"
$Analyzer  = Join-Path $ProjectRoot "powershell\analyze_health.ps1"

$ReportsDirectory = Join-Path $ProjectRoot "reports"
$SystemInfoFile   = Join-Path $ReportsDirectory "system_info.json"

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent"
Write-Host " Windows Health Check"
Write-Host "========================================"
Write-Host ""

# Ensure reports directory exists
if (-not (Test-Path $ReportsDirectory)) {
    New-Item `
        -ItemType Directory `
        -Path $ReportsDirectory |
        Out-Null
}

# Check required scripts
if (-not (Test-Path $Collector)) {
    Write-Host "ERROR: system_info.ps1 not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Analyzer)) {
    Write-Host "ERROR: analyze_health.ps1 not found." -ForegroundColor Red
    exit 1
}

try {

    # ---------------------------------
    # Step 1 - Collect
    # ---------------------------------

    Write-Host "[1/2] Collecting Windows system information..."

    & $Collector |
        Out-File `
            $SystemInfoFile `
            -Encoding utf8

    Write-Host "System information collected."
    Write-Host ""

    # ---------------------------------
    # Step 2 - Analyze
    # ---------------------------------

    Write-Host "[2/2] Analyzing system health..."
    Write-Host ""

    & $Analyzer

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Health check completed"
    Write-Host "========================================"

}
catch {

    Write-Host ""
    Write-Host "Health check failed." -ForegroundColor Red
    Write-Host $_.Exception.Message

    exit 1
}