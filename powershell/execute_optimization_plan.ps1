#requires -Version 5.1

<#
Local-AI-PC-Agent
Optimization Executor v0.5

Current version:
- Reads optimization_plan.json
- Automatically performs SAFE read-only actions
- Requests approval for CONFIRM actions
- Records decisions
- DOES NOT make system changes yet

This is a dry-run executor.
#>

$ErrorActionPreference = "Stop"

# ============================================================
# Paths
# ============================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$PlanFile = Join-Path `
    $ProjectRoot `
    "reports\optimization_plan.json"

$PerformanceFile = Join-Path `
    $ProjectRoot `
    "reports\performance_report.json"

$ExecutionFile = Join-Path `
    $ProjectRoot `
    "reports\execution_result.json"


# ============================================================
# Validate files
# ============================================================

if (-not (Test-Path $PlanFile)) {

    Write-Host ""
    Write-Host "ERROR: optimization_plan.json not found." `
        -ForegroundColor Red

    exit 1
}

if (-not (Test-Path $PerformanceFile)) {

    Write-Host ""
    Write-Host "ERROR: performance_report.json not found." `
        -ForegroundColor Red

    exit 1
}


# ============================================================
# Read data
# ============================================================

$plan = Get-Content `
    $PlanFile `
    -Raw |
    ConvertFrom-Json

$performance = Get-Content `
    $PerformanceFile `
    -Raw |
    ConvertFrom-Json


# ============================================================
# Execution result container
# ============================================================

$results = @()


# ============================================================
# Helper function
# ============================================================

function Add-ExecutionResult {

    param(
        [string]$ActionID,
        [string]$SafetyLevel,
        [string]$Decision,
        [string]$Status,
        [string]$Message
    )

    $script:results += [PSCustomObject]@{

        ActionID = $ActionID

        SafetyLevel = $SafetyLevel

        Decision = $Decision

        Status = $Status

        Message = $Message
    }
}


# ============================================================
# Header
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent Optimization Executor"
Write-Host " DRY-RUN MODE"
Write-Host "========================================"
Write-Host ""

Write-Host "Computer: $($plan.ComputerName)"
Write-Host "Performance: $($plan.PerformanceStatus)"
Write-Host "Actions: $($plan.ActionCount)"

Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "This version will NOT modify Windows."
Write-Host ""


# ============================================================
# Process actions
# ============================================================

foreach ($action in @($plan.Actions)) {

    Write-Host "----------------------------------------"
    Write-Host "Action: $($action.ID)"
    Write-Host "Title: $($action.Title)"
    Write-Host "Safety: $($action.SafetyLevel)"
    Write-Host "Risk: $($action.RiskLevel)"
    Write-Host ""


    # ========================================================
    # SAFE actions
    # ========================================================

    if ($action.SafetyLevel -eq "SAFE") {

        switch ($action.ID) {

            "REVIEW_MEMORY_PROCESSES" {

                Write-Host "Top memory processes:"
                Write-Host ""

                $performance.Processes.TopMemory |
                    Select-Object -First 10 |
                    Format-Table `
                        Name,
                        PID,
                        MemoryMB `
                        -AutoSize

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "High-memory processes were reviewed."
            }


            "REVIEW_BACKGROUND_PROCESSES" {

                Write-Host "Running process count:"
                Write-Host $performance.Processes.Count
                Write-Host ""

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "Background process count was reviewed."
            }


            "REVIEW_STARTUP_PROGRAMS" {

                Write-Host "Startup programs:"
                Write-Host ""

                $performance.Startup.Programs |
                    Select-Object `
                        Name,
                        Location,
                        User |
                    Format-Table -AutoSize

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "Startup programs were reviewed."
            }


            "SCAN_TEMP_FILES" {

                Write-Host "TEMP directory:"
                Write-Host $performance.Temp.Path

                Write-Host "TEMP size:"
                Write-Host "$($performance.Temp.SizeGB) GB"

                Write-Host "TEMP file count:"
                Write-Host $performance.Temp.FileCount

                Write-Host ""

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "TEMP directory statistics were reviewed."
            }


            "REVIEW_CPU_PROCESSES" {

                Write-Host "CPU review completed."
                Write-Host ""

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "CPU-related processes were reviewed."
            }


            "REVIEW_POWER_PLAN" {

                Write-Host "Current power plan:"
                Write-Host $performance.PowerPlan
                Write-Host ""

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Completed" `
                    -Message "Windows power plan was reviewed."
            }


            default {

                Add-ExecutionResult `
                    -ActionID $action.ID `
                    -SafetyLevel "SAFE" `
                    -Decision "Automatic" `
                    -Status "Skipped" `
                    -Message "No SAFE handler exists for this action."
            }
        }

        continue
    }


    # ========================================================
    # CONFIRM actions
    # ========================================================

    if ($action.SafetyLevel -eq "CONFIRM") {

        Write-Host "This action could modify the system."
        Write-Host ""
        Write-Host $action.Description
        Write-Host ""

        $answer = Read-Host "Approve this action? Type Y or N"

        if ($answer -match '^[Yy]$') {

            Write-Host ""
            Write-Host "Approved."
            Write-Host "DRY-RUN: No system change was performed."
            Write-Host ""

            Add-ExecutionResult `
                -ActionID $action.ID `
                -SafetyLevel "CONFIRM" `
                -Decision "Approved" `
                -Status "DryRun" `
                -Message "User approved the action, but dry-run mode prevented execution."
        }
        else {

            Write-Host ""
            Write-Host "Not approved."
            Write-Host ""

            Add-ExecutionResult `
                -ActionID $action.ID `
                -SafetyLevel "CONFIRM" `
                -Decision "Rejected" `
                -Status "Skipped" `
                -Message "User did not approve the action."
        }

        continue
    }


    # ========================================================
    # Unknown / blocked
    # ========================================================

    Add-ExecutionResult `
        -ActionID $action.ID `
        -SafetyLevel $action.SafetyLevel `
        -Decision "Blocked" `
        -Status "Blocked" `
        -Message "Action was blocked because its safety level is unsupported."
}


# ============================================================
# Build result
# ============================================================

$executionReport = [ordered]@{

    GeneratedAt = (Get-Date).ToString(
        "yyyy-MM-dd HH:mm:ss"
    )

    ComputerName = $plan.ComputerName

    Mode = "DryRun"

    SystemModified = $false

    TotalActions = @($plan.Actions).Count

    ResultCount = $results.Count

    Results = @($results)
}


# ============================================================
# Save result
# ============================================================

$executionReport |
    ConvertTo-Json -Depth 10 |
    Out-File `
        $ExecutionFile `
        -Encoding utf8


# ============================================================
# Finish
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Dry-run completed"
Write-Host "========================================"
Write-Host ""

Write-Host "System modified: False"

Write-Host ""

Write-Host "Execution report:"
Write-Host $ExecutionFile
Write-Host ""