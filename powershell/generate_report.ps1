#requires -Version 5.1

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$SystemInfoFile = Join-Path $ProjectRoot "reports\system_info.json"
$HealthReportFile = Join-Path $ProjectRoot "reports\health_report.json"
$OutputFile = Join-Path $ProjectRoot "reports\health_report.txt"

if (-not (Test-Path $SystemInfoFile)) {
    Write-Host "ERROR: system_info.json not found."
    exit 1
}

if (-not (Test-Path $HealthReportFile)) {
    Write-Host "ERROR: health_report.json not found."
    exit 1
}

$system = Get-Content $SystemInfoFile -Raw | ConvertFrom-Json
$health = Get-Content $HealthReportFile -Raw | ConvertFrom-Json

$lines = @()

$lines += "=================================================="
$lines += "Local-AI-PC-Agent Health Report"
$lines += "=================================================="
$lines += ""

$lines += "Generated: $($health.GeneratedAt)"
$lines += "Computer: $($system.OperatingSystem.ComputerName)"
$lines += "Windows: $($system.OperatingSystem.Caption)"
$lines += "Build: $($system.OperatingSystem.BuildNumber)"
$lines += "Overall Status: $($health.OverallStatus)"
$lines += ""

$lines += "[CPU]"

foreach ($cpu in @($system.CPU)) {
    $lines += "Model: $($cpu.Name)"
    $lines += "Physical Cores: $($cpu.PhysicalCores)"
    $lines += "Logical Processors: $($cpu.LogicalProcessors)"
    $lines += "Current Load: $($cpu.CurrentLoadPercent)%"
}

$lines += ""
$lines += "[Memory]"
$lines += "Total: $($system.Memory.TotalGB) GB"
$lines += "Used: $($system.Memory.UsedGB) GB"
$lines += "Free: $($system.Memory.FreeGB) GB"
$lines += "Usage: $($system.Memory.UsagePercent)%"
$lines += ""

$lines += "[Disks]"

foreach ($disk in @($system.LogicalDisks)) {
    $lines += "Drive: $($disk.Drive)"
    $lines += "Size: $($disk.SizeGB) GB"
    $lines += "Used: $($disk.UsedGB) GB"
    $lines += "Free: $($disk.FreeGB) GB"
    $lines += "Usage: $($disk.UsagePercent)%"
    $lines += ""
}

$lines += "[Top Memory Processes]"

$rank = 1

foreach ($process in @($system.TopMemoryProcesses | Select-Object -First 5)) {
    $lines += "$rank. $($process.ProcessName) - $($process.MemoryMB) MB"
    $rank++
}

$lines += ""
$lines += "[Detected Issues]"

if (@($health.Issues).Count -eq 0) {
    $lines += "No threshold-based issues detected."
}
else {
    foreach ($issue in @($health.Issues)) {
        $lines += "[$($issue.Severity)] $($issue.Component): $($issue.Message)"
    }
}

$lines += ""
$lines += "[Recommendations]"

if (@($health.Recommendations).Count -eq 0) {
    $lines += "No recommendations at this time."
}
else {
    foreach ($recommendation in @($health.Recommendations)) {
        $lines += "- $recommendation"
    }
}

$lines += ""
$lines += "This report is read-only. No system settings were changed."
$lines += "=================================================="

$lines | Out-File $OutputFile -Encoding utf8

Write-Host ""
Write-Host "Health report generated successfully."
Write-Host "Report:"
Write-Host $OutputFile
Write-Host ""