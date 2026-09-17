#requires -Version 5.1

<#
Local-AI-PC-Agent v1.0
Main Controller

Workflow:
1. Collect system information
2. Collect performance information
3. Analyze health
4. Diagnose performance issues
5. Generate optimization plan
6. Generate readable report
7. Let the user select an optimization
8. Re-run diagnostics after the operation
#>

$ErrorActionPreference = "Stop"


# ============================================================
# Project paths
# ============================================================

$Root = $PSScriptRoot

$PSDir = Join-Path `
    $Root `
    "powershell"

$Reports = Join-Path `
    $Root `
    "reports"


# ============================================================
# Internal modules
# ============================================================

$SystemInfo = Join-Path `
    $PSDir `
    "system_info.ps1"

$PerformanceCheck = Join-Path `
    $PSDir `
    "performance_check.ps1"

$HealthAnalyzer = Join-Path `
    $PSDir `
    "analyze_health.ps1"

$Planner = Join-Path `
    $PSDir `
    "generate_optimization_plan.ps1"

$Reporter = Join-Path `
    $PSDir `
    "generate_report.ps1"


# ============================================================
# Optimization modules
# ============================================================

$TempOptimizer = Join-Path `
    $PSDir `
    "optimize_temp.ps1"

$StartupOptimizer = Join-Path `
    $PSDir `
    "optimize_startup.ps1"

$StartupRestore = Join-Path `
    $PSDir `
    "restore_startup.ps1"

$ProcessOptimizer = Join-Path `
    $PSDir `
    "optimize_process.ps1"


# ============================================================
# Report files
# ============================================================

$SystemJSON = Join-Path `
    $Reports `
    "system_info.json"

$PerformanceJSON = Join-Path `
    $Reports `
    "performance_report.json"

$HealthJSON = Join-Path `
    $Reports `
    "health_report.json"

$PlanJSON = Join-Path `
    $Reports `
    "optimization_plan.json"

$ReadableReport = Join-Path `
    $Reports `
    "health_report.txt"


# ============================================================
# Ensure reports directory exists
# ============================================================

if (-not (Test-Path $Reports)) {

    New-Item `
        -ItemType Directory `
        -Path $Reports |
        Out-Null
}


# ============================================================
# Helper: section title
# ============================================================

function Write-Section {

    param(
        [string]$Text
    )

    Write-Host ""

    Write-Host "========================================"

    Write-Host " $Text"

    Write-Host "========================================"

    Write-Host ""
}


# ============================================================
# Helper: check required script
# ============================================================

function Test-AgentModule {

    param(
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path $Path)) {

        Write-Host ""

        Write-Host "ERROR: Required module not found:" `
            -ForegroundColor Red

        Write-Host $Name

        Write-Host ""
        Write-Host "Expected path:"
        Write-Host $Path

        return $false
    }

    return $true
}


# ============================================================
# Validate core modules
# ============================================================

$coreModules = @(
    @{
        Path = $SystemInfo
        Name = "system_info.ps1"
    },
    @{
        Path = $PerformanceCheck
        Name = "performance_check.ps1"
    },
    @{
        Path = $HealthAnalyzer
        Name = "analyze_health.ps1"
    },
    @{
        Path = $Planner
        Name = "generate_optimization_plan.ps1"
    },
    @{
        Path = $Reporter
        Name = "generate_report.ps1"
    }
)


foreach ($module in $coreModules) {

    if (
        -not (
            Test-AgentModule `
                -Path $module.Path `
                -Name $module.Name
        )
    ) {

        exit 1
    }
}


# ============================================================
# Diagnostics pipeline
# ============================================================

function Invoke-AgentDiagnostics {

    # --------------------------------------------------------
    # Step 1
    # --------------------------------------------------------

    Write-Section "1. System Information"

    Write-Host "Collecting Windows system information..."

    & $SystemInfo |
        Out-File `
            $SystemJSON `
            -Encoding utf8

    Write-Host "System information collected."


    # --------------------------------------------------------
    # Step 2
    # --------------------------------------------------------

    Write-Section "2. Performance Diagnostics"

    Write-Host "Collecting performance information..."

    & $PerformanceCheck |
        Out-File `
            $PerformanceJSON `
            -Encoding utf8

    Write-Host "Performance information collected."


    # --------------------------------------------------------
    # Step 3
    # --------------------------------------------------------

    Write-Section "3. Health Analysis"

    & $HealthAnalyzer


    # --------------------------------------------------------
    # Step 4
    # --------------------------------------------------------

    Write-Section "4. Performance Diagnosis"

    & $Planner


    # --------------------------------------------------------
    # Step 5
    # --------------------------------------------------------

    Write-Section "5. Readable Health Report"

    & $Reporter
}


# ============================================================
# Program header
# ============================================================

Clear-Host

Write-Host "=============================================="

Write-Host " Local-AI-PC-Agent v1.0"

Write-Host " Windows Performance Diagnosis & Optimization"

Write-Host "=============================================="

Write-Host ""

Write-Host "The agent will first perform read-only diagnostics."

Write-Host ""

Write-Host "Operations that can change Windows require"

Write-Host "explicit user confirmation."

Write-Host ""


# ============================================================
# Initial diagnostics
# ============================================================

try {

    Invoke-AgentDiagnostics

}
catch {

    Write-Host ""

    Write-Host "Initial diagnostics failed." `
        -ForegroundColor Red

    Write-Host $_.Exception.Message

    exit 1
}


# ============================================================
# Verify optimization plan
# ============================================================

if (-not (Test-Path $PlanJSON)) {

    Write-Host ""

    Write-Host "ERROR: Optimization plan was not generated." `
        -ForegroundColor Red

    exit 1
}


# ============================================================
# Read plan
# ============================================================

$plan = Get-Content `
    $PlanJSON `
    -Raw |
    ConvertFrom-Json


# ============================================================
# Diagnosis summary
# ============================================================

Write-Section "Diagnosis Summary"

Write-Host "Computer:"
Write-Host $plan.ComputerName

Write-Host ""

Write-Host "Health status:"
Write-Host $plan.HealthStatus

Write-Host ""

Write-Host "Performance status:"
Write-Host $plan.PerformanceStatus

Write-Host ""

Write-Host "Possible causes:"
Write-Host $plan.CauseCount

Write-Host ""


if (@($plan.Causes).Count -eq 0) {

    Write-Host "No significant performance causes detected."
    Write-Host ""
}
else {

    foreach ($cause in @($plan.Causes)) {

        Write-Host "[$($cause.Confidence)] $($cause.Category)"

        Write-Host "  $($cause.Description)"

        Write-Host ""
    }
}


# ============================================================
# Optimization menu
# ============================================================

Write-Section "Optimization Menu"


Write-Host "[1] TEMP cleanup"

Write-Host "    Scan and optionally remove eligible old"

Write-Host "    temporary files."

Write-Host ""


Write-Host "[2] Startup optimization"

Write-Host "    Review startup applications and optionally"

Write-Host "    disable one selected startup entry."

Write-Host ""


Write-Host "[3] High-memory application optimization"

Write-Host "    Review high-memory optional applications"

Write-Host "    and optionally close one selected process."

Write-Host ""


Write-Host "[4] Restore startup entry"

Write-Host "    Restore the most recently backed-up"

Write-Host "    startup entry."

Write-Host ""


Write-Host "[5] Re-run diagnostics only"

Write-Host "    Do not perform optimization."

Write-Host ""


Write-Host "[0] Exit"

Write-Host "    Exit without optimization."

Write-Host ""


# ============================================================
# User selection
# ============================================================

$choice = Read-Host "Select an option"


# ============================================================
# Execute selected module
# ============================================================

switch ($choice) {


    # --------------------------------------------------------
    # TEMP
    # --------------------------------------------------------

    "1" {

        if (
            Test-AgentModule `
                -Path $TempOptimizer `
                -Name "optimize_temp.ps1"
        ) {

            Write-Section "TEMP Optimization"

            & $TempOptimizer
        }
    }


    # --------------------------------------------------------
    # Startup
    # --------------------------------------------------------

    "2" {

        if (
            Test-AgentModule `
                -Path $StartupOptimizer `
                -Name "optimize_startup.ps1"
        ) {

            Write-Section "Startup Optimization"

            & $StartupOptimizer
        }
    }


    # --------------------------------------------------------
    # High-memory process
    # --------------------------------------------------------

    "3" {

        if (
            Test-AgentModule `
                -Path $ProcessOptimizer `
                -Name "optimize_process.ps1"
        ) {

            Write-Section "High-memory Application Optimization"

            & $ProcessOptimizer
        }
    }


    # --------------------------------------------------------
    # Restore startup
    # --------------------------------------------------------

    "4" {

        if (
            Test-AgentModule `
                -Path $StartupRestore `
                -Name "restore_startup.ps1"
        ) {

            Write-Section "Startup Restore"

            & $StartupRestore
        }
    }


    # --------------------------------------------------------
    # Diagnostics only
    # --------------------------------------------------------

    "5" {

        Write-Host ""

        Write-Host "No optimization selected."

        Write-Host "Diagnostics will be refreshed."
    }


    # --------------------------------------------------------
    # Exit
    # --------------------------------------------------------

    "0" {

        Write-Host ""

        Write-Host "No optimization performed."

        Write-Host "Exiting Local-AI-PC-Agent."

        Write-Host ""

        exit 0
    }


    # --------------------------------------------------------
    # Invalid
    # --------------------------------------------------------

    default {

        Write-Host ""

        Write-Host "Invalid option." `
            -ForegroundColor Yellow

        Write-Host "No optimization was performed."

        exit 1
    }
}


# ============================================================
# Verification diagnostics
# ============================================================

Write-Section "Verification"

Write-Host "Re-running diagnostics after the selected operation..."

Write-Host ""


try {

    Invoke-AgentDiagnostics

}
catch {

    Write-Host ""

    Write-Host "Verification diagnostics failed." `
        -ForegroundColor Red

    Write-Host $_.Exception.Message

    exit 1
}


# ============================================================
# Read updated plan
# ============================================================

$finalPlan = Get-Content `
    $PlanJSON `
    -Raw |
    ConvertFrom-Json


# ============================================================
# Final result
# ============================================================

Write-Section "Final Result"

Write-Host "Computer:"
Write-Host $finalPlan.ComputerName

Write-Host ""

Write-Host "Health:"
Write-Host $finalPlan.HealthStatus

Write-Host ""

Write-Host "Performance:"
Write-Host $finalPlan.PerformanceStatus

Write-Host ""

Write-Host "Remaining possible causes:"
Write-Host $finalPlan.CauseCount

Write-Host ""


if (@($finalPlan.Causes).Count -gt 0) {

    foreach ($cause in @($finalPlan.Causes)) {

        Write-Host "[$($cause.Confidence)] $($cause.Category)"

        Write-Host "  $($cause.Description)"

        Write-Host ""
    }
}


# ============================================================
# Report locations
# ============================================================

Write-Host "Reports directory:"

Write-Host $Reports

Write-Host ""

Write-Host "Readable health report:"

Write-Host $ReadableReport

Write-Host ""


# ============================================================
# Finish
# ============================================================

Write-Host "=============================================="

Write-Host " Local-AI-PC-Agent completed"

Write-Host "=============================================="

Write-Host ""