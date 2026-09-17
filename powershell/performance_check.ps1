#requires -Version 5.1

<#
Local-AI-PC-Agent
Performance Diagnostics v0.1

Read-only performance diagnostics.
No system settings are modified.
#>

$ErrorActionPreference = "SilentlyContinue"

# ==========================================
# Current CPU load
# ==========================================

$cpu = Get-CimInstance Win32_Processor

$cpuLoad = [math]::Round(
    ($cpu | Measure-Object -Property LoadPercentage -Average).Average,
    2
)


# ==========================================
# Memory
# ==========================================

$os = Get-CimInstance Win32_OperatingSystem

$totalMemoryKB = [double]$os.TotalVisibleMemorySize
$freeMemoryKB = [double]$os.FreePhysicalMemory

$usedMemoryKB = $totalMemoryKB - $freeMemoryKB

$memoryUsage = [math]::Round(
    ($usedMemoryKB / $totalMemoryKB) * 100,
    2
)


# ==========================================
# Process statistics
# ==========================================

$processes = @(Get-Process)

$processCount = $processes.Count

$topMemoryProcesses = @(
    $processes |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 10 |
    ForEach-Object {

        [PSCustomObject]@{
            Name = $_.ProcessName
            PID = $_.Id
            MemoryMB = [math]::Round(
                $_.WorkingSet64 / 1MB,
                2
            )
        }
    }
)


# ==========================================
# Startup programs
# ==========================================

$startupPrograms = @(
    Get-CimInstance Win32_StartupCommand |
    ForEach-Object {

        [PSCustomObject]@{
            Name = $_.Name
            Command = $_.Command
            Location = $_.Location
            User = $_.User
        }
    }
)


# ==========================================
# TEMP directory analysis
# ==========================================

$tempPath = $env:TEMP

$tempFiles = @(
    Get-ChildItem `
        $tempPath `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue
)

$tempSizeBytes = (
    $tempFiles |
    Measure-Object Length -Sum
).Sum

if ($null -eq $tempSizeBytes) {
    $tempSizeBytes = 0
}

$tempSizeGB = [math]::Round(
    $tempSizeBytes / 1GB,
    2
)


# ==========================================
# Page file
# ==========================================

$pageFiles = @(
    Get-CimInstance Win32_PageFileUsage |
    ForEach-Object {

        [PSCustomObject]@{
            Name = $_.Name
            AllocatedMB = $_.AllocatedBaseSize
            CurrentUsageMB = $_.CurrentUsage
            PeakUsageMB = $_.PeakUsage
        }
    }
)


# ==========================================
# Power plan
# ==========================================

$powerPlan = $null

try {

    $powerOutput = powercfg /getactivescheme

    $powerPlan = ($powerOutput -join " ").Trim()

}
catch {

    $powerPlan = "Unknown"
}


# ==========================================
# Disk type
# ==========================================

$physicalDisks = @()

if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {

    $physicalDisks = @(
        Get-PhysicalDisk |
        ForEach-Object {

            [PSCustomObject]@{
                FriendlyName = $_.FriendlyName
                MediaType = $_.MediaType
                HealthStatus = $_.HealthStatus
                OperationalStatus = $_.OperationalStatus
                SizeGB = [math]::Round(
                    $_.Size / 1GB,
                    2
                )
            }
        }
    )
}


# ==========================================
# Performance findings
# ==========================================

$findings = @()


if ($memoryUsage -ge 70) {

    $findings += [PSCustomObject]@{
        Type = "MemoryPressure"
        Severity = "Info"
        Value = "$memoryUsage%"
        Message = "Memory usage is elevated."
    }
}


if ($processCount -ge 150) {

    $findings += [PSCustomObject]@{
        Type = "HighProcessCount"
        Severity = "Info"
        Value = $processCount
        Message = "A large number of processes are currently running."
    }
}


if ($startupPrograms.Count -ge 10) {

    $findings += [PSCustomObject]@{
        Type = "ManyStartupPrograms"
        Severity = "Info"
        Value = $startupPrograms.Count
        Message = "Many startup entries were detected."
    }
}


if ($tempSizeGB -ge 1) {

    $findings += [PSCustomObject]@{
        Type = "LargeTempDirectory"
        Severity = "Info"
        Value = "$tempSizeGB GB"
        Message = "The user TEMP directory contains a significant amount of data."
    }
}


# ==========================================
# Build report
# ==========================================

$report = [ordered]@{

    GeneratedAt = (Get-Date).ToString(
        "yyyy-MM-dd HH:mm:ss"
    )

    ComputerName = $env:COMPUTERNAME

    CPU = [ordered]@{
        CurrentLoadPercent = $cpuLoad
    }

    Memory = [ordered]@{
        UsagePercent = $memoryUsage
    }

    Processes = [ordered]@{
        Count = $processCount
        TopMemory = $topMemoryProcesses
    }

    Startup = [ordered]@{
        Count = $startupPrograms.Count
        Programs = $startupPrograms
    }

    Temp = [ordered]@{
        Path = $tempPath
        SizeGB = $tempSizeGB
        FileCount = $tempFiles.Count
    }

    PageFile = $pageFiles

    PowerPlan = $powerPlan

    PhysicalDisks = $physicalDisks

    Findings = $findings
}


# ==========================================
# Output JSON
# ==========================================

$report |
    ConvertTo-Json -Depth 10