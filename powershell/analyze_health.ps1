#requires -Version 5.1

<#
Local-AI-PC-Agent
Health Analyzer v0.1

Read-only analysis:
- Reads reports\system_info.json
- Evaluates CPU, memory and disk usage
- Generates reports\health_report.json

This script does NOT modify Windows.
#>

$ErrorActionPreference = "Stop"

# Project paths
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$InputFile   = Join-Path $ProjectRoot "reports\system_info.json"
$OutputFile  = Join-Path $ProjectRoot "reports\health_report.json"

# -----------------------------
# Check input
# -----------------------------

if (-not (Test-Path $InputFile)) {
    Write-Host "ERROR: system_info.json not found." -ForegroundColor Red
    Write-Host "Run system_info.ps1 first."
    exit 1
}

# Read JSON
$data = Get-Content $InputFile -Raw | ConvertFrom-Json

$issues = @()
$recommendations = @()

# Default status
$overallStatus = "Healthy"


# -----------------------------
# Helper function
# -----------------------------

function Add-HealthIssue {

    param(
        [string]$Component,
        [string]$Severity,
        [string]$Message,
        [string]$Recommendation
    )

    $script:issues += [PSCustomObject]@{
        Component = $Component
        Severity  = $Severity
        Message   = $Message
    }

    if ($Recommendation) {
        $script:recommendations += $Recommendation
    }

    if ($Severity -eq "Critical") {
        $script:overallStatus = "Critical"
    }
    elseif (
        $Severity -eq "Warning" -and
        $script:overallStatus -ne "Critical"
    ) {
        $script:overallStatus = "Warning"
    }
}


# -----------------------------
# Memory analysis
# -----------------------------

$memoryUsage = [double]$data.Memory.UsagePercent

if ($memoryUsage -ge 90) {

    Add-HealthIssue `
        -Component "Memory" `
        -Severity "Critical" `
        -Message "Memory usage is $memoryUsage%." `
        -Recommendation "Check applications using large amounts of memory."

}
elseif ($memoryUsage -ge 80) {

    Add-HealthIssue `
        -Component "Memory" `
        -Severity "Warning" `
        -Message "Memory usage is $memoryUsage%." `
        -Recommendation "Review high-memory processes."
}


# -----------------------------
# Disk analysis
# -----------------------------

foreach ($disk in $data.LogicalDisks) {

    $usage = [double]$disk.UsagePercent

    if ($usage -ge 90) {

        Add-HealthIssue `
            -Component "Disk $($disk.Drive)" `
            -Severity "Critical" `
            -Message "Disk usage is $usage%. Free space: $($disk.FreeGB) GB." `
            -Recommendation "Review large files, temporary files and unnecessary data on $($disk.Drive)."

    }
    elseif ($usage -ge 80) {

        Add-HealthIssue `
            -Component "Disk $($disk.Drive)" `
            -Severity "Warning" `
            -Message "Disk usage is $usage%. Free space: $($disk.FreeGB) GB." `
            -Recommendation "Monitor available disk space on $($disk.Drive)."
    }
}


# -----------------------------
# CPU analysis
# -----------------------------

foreach ($cpu in $data.CPU) {

    if ($null -ne $cpu.CurrentLoadPercent) {

        $cpuLoad = [double]$cpu.CurrentLoadPercent

        if ($cpuLoad -ge 90) {

            Add-HealthIssue `
                -Component "CPU" `
                -Severity "Critical" `
                -Message "Current CPU load is $cpuLoad%." `
                -Recommendation "Review processes currently consuming CPU resources."

        }
        elseif ($cpuLoad -ge 80) {

            Add-HealthIssue `
                -Component "CPU" `
                -Severity "Warning" `
                -Message "Current CPU load is $cpuLoad%." `
                -Recommendation "Monitor CPU load and review high-CPU processes."
        }
    }
}


# -----------------------------
# Uptime analysis
# -----------------------------

$uptimeDays = [int]$data.OperatingSystem.Uptime.Days

if ($uptimeDays -ge 30) {

    Add-HealthIssue `
        -Component "System Uptime" `
        -Severity "Warning" `
        -Message "Windows has been running for $uptimeDays days." `
        -Recommendation "Consider a planned restart after saving work and confirming maintenance requirements."
}


# -----------------------------
# Remove duplicate recommendations
# -----------------------------

$recommendations = @(
    $recommendations |
    Select-Object -Unique
)


# -----------------------------
# Build report
# -----------------------------

$report = [ordered]@{

    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    ComputerName = $data.OperatingSystem.ComputerName

    OverallStatus = $overallStatus

    Summary = [ordered]@{
        CPUCount           = @($data.CPU).Count
        MemoryUsagePercent = $data.Memory.UsagePercent
        DiskCount          = @($data.LogicalDisks).Count
        UptimeDays         = $data.OperatingSystem.Uptime.Days
        IssueCount         = @($issues).Count
    }

    Issues = @($issues)

    Recommendations = @($recommendations)
}


# -----------------------------
# Save JSON
# -----------------------------

$report |
    ConvertTo-Json -Depth 8 |
    Out-File $OutputFile -Encoding utf8


# -----------------------------
# Console result
# -----------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent Health Analysis"
Write-Host "========================================"

Write-Host "Computer: $($report.ComputerName)"
Write-Host "Status:   $($report.OverallStatus)"
Write-Host "Issues:   $($report.Summary.IssueCount)"
Write-Host ""

if ($issues.Count -eq 0) {

    Write-Host "No threshold-based health issues detected."

}
else {

    foreach ($issue in $issues) {

        Write-Host "[$($issue.Severity)] $($issue.Component)"
        Write-Host "  $($issue.Message)"
    }
}

Write-Host ""
Write-Host "Report saved to:"
Write-Host $OutputFile