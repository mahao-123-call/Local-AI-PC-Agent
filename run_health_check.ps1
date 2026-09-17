#requires -Version 5.1

<#
Local-AI-PC-Agent
One-click Windows Health Check v0.3
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot

$Collector = Join-Path $ProjectRoot "powershell\system_info.ps1"
$Analyzer  = Join-Path $ProjectRoot "powershell\analyze_health.ps1"
$Reporter  = Join-Path $ProjectRoot "powershell\generate_report.ps1"

$ReportsDirectory = Join-Path $ProjectRoot "reports"
$SystemInfoFile   = Join-Path $ReportsDirectory "system_info.json"
$TextReportFile   = Join-Path $ReportsDirectory "health_report.txt"

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent"
Write-Host " Windows Health Check v0.3"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $ReportsDirectory)) {
    New-Item -ItemType Directory -Path $ReportsDirectory | Out-Null
}

try {

    # Step 1 - Collect
    Write-Host "[1/3] Collecting Windows system information..."

    & $Collector |
        Out-File $SystemInfoFile -Encoding utf8

    Write-Host "System information collected."
    Write-Host ""

    # Step 2 - Analyze
    Write-Host "[2/3] Analyzing system health..."
    Write-Host ""

    & $Analyzer

    # Step 3 - Report
    Write-Host ""
    Write-Host "[3/3] Generating health report..."
    Write-Host ""

    & $Reporter

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Health check completed"
    Write-Host "========================================"
    Write-Host ""

    Write-Host "Readable report:"
    Write-Host $TextReportFile
    Write-Host ""
}
catch {

    Write-Host ""
    Write-Host "Health check failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}