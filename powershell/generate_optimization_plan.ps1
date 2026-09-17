#requires -Version 5.1

<#
Local-AI-PC-Agent
Performance Diagnosis and Optimization Planner v0.4

Purpose:
- Read system health data
- Read performance diagnostics
- Identify possible causes of sluggish performance
- Generate a structured optimization plan

IMPORTANT:
This script does NOT perform optimization.
It only creates a plan.

Safety levels:
SAFE    = Read-only or very low-risk action
CONFIRM = Requires explicit user confirmation
BLOCKED = Must not be automatically executed
#>

$ErrorActionPreference = "Stop"


# ============================================================
# Paths
# ============================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$SystemInfoFile = Join-Path `
    $ProjectRoot `
    "reports\system_info.json"

$HealthReportFile = Join-Path `
    $ProjectRoot `
    "reports\health_report.json"

$PerformanceReportFile = Join-Path `
    $ProjectRoot `
    "reports\performance_report.json"

$OutputFile = Join-Path `
    $ProjectRoot `
    "reports\optimization_plan.json"


# ============================================================
# Validate input files
# ============================================================

$requiredFiles = @(
    $SystemInfoFile
    $HealthReportFile
    $PerformanceReportFile
)

foreach ($file in $requiredFiles) {

    if (-not (Test-Path $file)) {

        Write-Host ""
        Write-Host "ERROR: Required file not found:" `
            -ForegroundColor Red

        Write-Host $file

        exit 1
    }
}


# ============================================================
# Read JSON
# ============================================================

$system = Get-Content `
    $SystemInfoFile `
    -Raw |
    ConvertFrom-Json

$health = Get-Content `
    $HealthReportFile `
    -Raw |
    ConvertFrom-Json

$performance = Get-Content `
    $PerformanceReportFile `
    -Raw |
    ConvertFrom-Json


# ============================================================
# Containers
# ============================================================

$causes = @()
$actions = @()


# ============================================================
# Helper: Add performance cause
# ============================================================

function Add-Cause {

    param(
        [string]$ID,
        [string]$Category,
        [string]$Severity,
        [string]$Confidence,
        [string]$Description,
        [object]$Evidence
    )

    $script:causes += [PSCustomObject]@{

        ID = $ID

        Category = $Category

        Severity = $Severity

        Confidence = $Confidence

        Description = $Description

        Evidence = $Evidence
    }
}


# ============================================================
# Helper: Add optimization action
# ============================================================

function Add-Action {

    param(
        [string]$ID,
        [string]$CauseID,
        [string]$Title,
        [string]$Description,
        [string]$SafetyLevel,
        [string]$RiskLevel,
        [bool]$RequiresAdministrator,
        [bool]$AutomaticExecutionAllowed
    )

    $script:actions += [PSCustomObject]@{

        ID = $ID

        CauseID = $CauseID

        Title = $Title

        Description = $Description

        SafetyLevel = $SafetyLevel

        RiskLevel = $RiskLevel

        RequiresAdministrator = $RequiresAdministrator

        AutomaticExecutionAllowed = $AutomaticExecutionAllowed

        UserApproved = $false

        Executed = $false
    }
}


# ============================================================
# Collect main performance values
# ============================================================

$cpuUsage = [double]$performance.CPU.CurrentLoadPercent

$memoryUsage = [double]$performance.Memory.UsagePercent

$processCount = [int]$performance.Processes.Count

$startupCount = [int]$performance.Startup.Count

$tempSizeGB = [double]$performance.Temp.SizeGB

$tempFileCount = [int]$performance.Temp.FileCount


# ============================================================
# Cause 1: Memory pressure
# ============================================================

if ($memoryUsage -ge 70) {

    $severity = "Info"

    if ($memoryUsage -ge 90) {
        $severity = "Critical"
    }
    elseif ($memoryUsage -ge 80) {
        $severity = "Warning"
    }

    $memoryEvidence = [ordered]@{

        UsagePercent = $memoryUsage

        TopProcesses = @(
            $performance.Processes.TopMemory |
            Select-Object -First 10
        )
    }

    Add-Cause `
        -ID "MEMORY_PRESSURE" `
        -Category "Memory" `
        -Severity $severity `
        -Confidence "High" `
        -Description "Memory pressure may contribute to reduced responsiveness." `
        -Evidence $memoryEvidence


    Add-Action `
        -ID "REVIEW_MEMORY_PROCESSES" `
        -CauseID "MEMORY_PRESSURE" `
        -Title "Review high-memory processes" `
        -Description "Review applications using the most physical memory." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true


    Add-Action `
        -ID "CLOSE_OPTIONAL_APPLICATIONS" `
        -CauseID "MEMORY_PRESSURE" `
        -Title "Close optional applications" `
        -Description "Close selected applications that are no longer needed." `
        -SafetyLevel "CONFIRM" `
        -RiskLevel "Medium" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $false
}


# ============================================================
# Cause 2: Large number of running processes
# ============================================================

if ($processCount -ge 150) {

    $processEvidence = [ordered]@{

        ProcessCount = $processCount

        TopMemoryProcesses = @(
            $performance.Processes.TopMemory |
            Select-Object -First 10
        )
    }

    Add-Cause `
        -ID "HIGH_PROCESS_COUNT" `
        -Category "Processes" `
        -Severity "Info" `
        -Confidence "Medium" `
        -Description "A large number of running processes may increase background resource usage." `
        -Evidence $processEvidence


    Add-Action `
        -ID "REVIEW_BACKGROUND_PROCESSES" `
        -CauseID "HIGH_PROCESS_COUNT" `
        -Title "Review background processes" `
        -Description "Identify optional background applications and services consuming resources." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true


    Add-Action `
        -ID "TERMINATE_SELECTED_PROCESS" `
        -CauseID "HIGH_PROCESS_COUNT" `
        -Title "Terminate selected optional process" `
        -Description "Terminate only a user-selected optional process after confirmation." `
        -SafetyLevel "CONFIRM" `
        -RiskLevel "Medium" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $false
}


# ============================================================
# Cause 3: Startup programs
# ============================================================

if ($startupCount -ge 8) {

    $startupEvidence = [ordered]@{

        StartupCount = $startupCount

        Programs = @(
            $performance.Startup.Programs
        )
    }

    Add-Cause `
        -ID "MANY_STARTUP_PROGRAMS" `
        -Category "Startup" `
        -Severity "Info" `
        -Confidence "Medium" `
        -Description "Many startup programs may increase boot time and background resource usage." `
        -Evidence $startupEvidence


    Add-Action `
        -ID "REVIEW_STARTUP_PROGRAMS" `
        -CauseID "MANY_STARTUP_PROGRAMS" `
        -Title "Review startup programs" `
        -Description "Review applications configured to launch automatically with Windows." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true


    Add-Action `
        -ID "DISABLE_SELECTED_STARTUP" `
        -CauseID "MANY_STARTUP_PROGRAMS" `
        -Title "Disable selected startup entry" `
        -Description "Disable only user-selected non-essential startup entries." `
        -SafetyLevel "CONFIRM" `
        -RiskLevel "Medium" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $false
}


# ============================================================
# Cause 4: TEMP accumulation
# ============================================================

if (
    ($tempSizeGB -ge 0.5) -or
    ($tempFileCount -ge 2000)
) {

    $tempEvidence = [ordered]@{

        Path = $performance.Temp.Path

        SizeGB = $tempSizeGB

        FileCount = $tempFileCount
    }

    Add-Cause `
        -ID "TEMP_ACCUMULATION" `
        -Category "Storage" `
        -Severity "Info" `
        -Confidence "Medium" `
        -Description "The TEMP directory contains accumulated temporary data." `
        -Evidence $tempEvidence


    Add-Action `
        -ID "SCAN_TEMP_FILES" `
        -CauseID "TEMP_ACCUMULATION" `
        -Title "Scan temporary files" `
        -Description "Identify temporary files that may be candidates for cleanup." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true


    Add-Action `
        -ID "CLEAN_SAFE_TEMP_FILES" `
        -CauseID "TEMP_ACCUMULATION" `
        -Title "Clean selected temporary files" `
        -Description "Remove only eligible temporary files after confirmation." `
        -SafetyLevel "CONFIRM" `
        -RiskLevel "Medium" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $false
}


# ============================================================
# Cause 5: CPU pressure
# ============================================================

if ($cpuUsage -ge 70) {

    $cpuSeverity = "Info"

    if ($cpuUsage -ge 90) {
        $cpuSeverity = "Critical"
    }
    elseif ($cpuUsage -ge 80) {
        $cpuSeverity = "Warning"
    }

    $cpuEvidence = [ordered]@{

        CurrentLoadPercent = $cpuUsage

        TopCPUProcesses = @(
            $system.TopCPUProcesses |
            Select-Object -First 10
        )
    }

    Add-Cause `
        -ID "CPU_PRESSURE" `
        -Category "CPU" `
        -Severity $cpuSeverity `
        -Confidence "Medium" `
        -Description "Current CPU load may contribute to reduced responsiveness." `
        -Evidence $cpuEvidence


    Add-Action `
        -ID "REVIEW_CPU_PROCESSES" `
        -CauseID "CPU_PRESSURE" `
        -Title "Review CPU-intensive processes" `
        -Description "Review processes consuming CPU resources." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true
}


# ============================================================
# Cause 6: Balanced power plan
# ============================================================

$powerPlanText = [string]$performance.PowerPlan

if (
    $powerPlanText -match "平衡" -or
    $powerPlanText -match "Balanced"
) {

    $powerEvidence = [ordered]@{
        ActivePowerPlan = $powerPlanText
    }

    Add-Cause `
        -ID "BALANCED_POWER_PLAN" `
        -Category "Power" `
        -Severity "Info" `
        -Confidence "Low" `
        -Description "The Balanced power plan may reduce peak performance in some workloads." `
        -Evidence $powerEvidence


    Add-Action `
        -ID "REVIEW_POWER_PLAN" `
        -CauseID "BALANCED_POWER_PLAN" `
        -Title "Review Windows power plan" `
        -Description "Review whether a higher-performance power plan is appropriate for this machine." `
        -SafetyLevel "SAFE" `
        -RiskLevel "Low" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $true


    Add-Action `
        -ID "CHANGE_POWER_PLAN" `
        -CauseID "BALANCED_POWER_PLAN" `
        -Title "Change Windows power plan" `
        -Description "Change the active power plan only after user confirmation." `
        -SafetyLevel "CONFIRM" `
        -RiskLevel "Medium" `
        -RequiresAdministrator $false `
        -AutomaticExecutionAllowed $false
}


# ============================================================
# Disk observations
# ============================================================

$diskObservations = @()

foreach ($disk in @($performance.PhysicalDisks)) {

    $diskObservations += [PSCustomObject]@{

        Name = $disk.FriendlyName

        MediaType = $disk.MediaType

        HealthStatus = $disk.HealthStatus

        OperationalStatus = $disk.OperationalStatus

        SizeGB = $disk.SizeGB
    }
}


# ============================================================
# Determine performance status
# ============================================================

if ($causes.Count -eq 0) {

    $performanceStatus = "Good"

}
elseif (
    @(
        $causes |
        Where-Object {
            $_.Severity -eq "Critical"
        }
    ).Count -gt 0
) {

    $performanceStatus = "PerformanceIssue"

}
else {

    $performanceStatus = "OptimizationAvailable"
}


# ============================================================
# Safety policy
# ============================================================

$safetyPolicy = [ordered]@{

    PlannerIsReadOnly = $true

    SystemModified = $false

    AutomaticExecutionEnabled = $false

    UserConfirmationRequiredForChanges = $true

    BlockedAutomaticActions = @(
        "Delete arbitrary user files"
        "Disable security software"
        "Modify registry without an approved action"
        "Stop critical Windows services"
        "Terminate processes without user approval"
        "Disable startup entries without user approval"
        "Change power plan without user approval"
    )
}


# ============================================================
# Final plan
# ============================================================

$plan = [ordered]@{

    GeneratedAt = (Get-Date).ToString(
        "yyyy-MM-dd HH:mm:ss"
    )

    ComputerName = $system.OperatingSystem.ComputerName

    HealthStatus = $health.OverallStatus

    PerformanceStatus = $performanceStatus

    EvidenceSummary = [ordered]@{

        CPUUsagePercent = $cpuUsage

        MemoryUsagePercent = $memoryUsage

        ProcessCount = $processCount

        StartupCount = $startupCount

        TempSizeGB = $tempSizeGB

        TempFileCount = $tempFileCount

        PowerPlan = $performance.PowerPlan
    }

    CauseCount = $causes.Count

    Causes = @($causes)

    ActionCount = $actions.Count

    Actions = @($actions)

    DiskObservations = $diskObservations

    SafetyPolicy = $safetyPolicy
}


# ============================================================
# Save JSON
# ============================================================

$plan |
    ConvertTo-Json -Depth 15 |
    Out-File `
        $OutputFile `
        -Encoding utf8


# ============================================================
# Console summary
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent Performance Planner"
Write-Host "========================================"
Write-Host ""

Write-Host "Computer: $($plan.ComputerName)"
Write-Host "Health: $($plan.HealthStatus)"
Write-Host "Performance: $($plan.PerformanceStatus)"

Write-Host ""

Write-Host "Possible causes: $($causes.Count)"
Write-Host "Optimization actions: $($actions.Count)"

Write-Host ""

if ($causes.Count -gt 0) {

    Write-Host "Possible performance causes:"
    Write-Host ""

    foreach ($cause in $causes) {

        Write-Host "[$($cause.Confidence)] $($cause.Category)"
        Write-Host "  $($cause.Description)"
    }
}

Write-Host ""
Write-Host "Plan saved to:"
Write-Host $OutputFile

Write-Host ""

Write-Host "IMPORTANT:"
Write-Host "No optimization actions were executed."
Write-Host "No system settings were changed."
Write-Host ""