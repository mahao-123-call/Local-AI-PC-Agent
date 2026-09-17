#requires -Version 5.1

<#
Local-AI-PC-Agent
Windows System Health Collector v0.2

Purpose:
- Read-only Windows system inspection
- Produce structured JSON for later AI analysis
- Compatible with Windows PowerShell 5.1 where possible

This script DOES NOT:
- Modify registry
- Stop/start services
- Delete files
- Change network settings
- Install/uninstall software
- Perform optimization
#>

$ErrorActionPreference = "SilentlyContinue"

# -----------------------------
# Helper functions
# -----------------------------

function Convert-BytesToGB {
    param([double]$Bytes)

    if ($null -eq $Bytes) {
        return $null
    }

    return [math]::Round($Bytes / 1GB, 2)
}

function Get-Percent {
    param(
        [double]$Part,
        [double]$Total
    )

    if ($Total -le 0) {
        return $null
    }

    return [math]::Round(($Part / $Total) * 100, 2)
}


# -----------------------------
# Operating System
# -----------------------------

$os = Get-CimInstance Win32_OperatingSystem
$computerSystem = Get-CimInstance Win32_ComputerSystem

$bootTime = $os.LastBootUpTime
$uptime = (Get-Date) - $bootTime

$osInfo = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    Caption      = $os.Caption
    Version      = $os.Version
    BuildNumber  = $os.BuildNumber
    Architecture = $os.OSArchitecture
    BootTime     = $bootTime
    Uptime       = [ordered]@{
        Days    = $uptime.Days
        Hours   = $uptime.Hours
        Minutes = $uptime.Minutes
    }
}


# -----------------------------
# CPU
# -----------------------------

$processors = @(Get-CimInstance Win32_Processor)

$cpuInfo = @(
    foreach ($cpu in $processors) {

        [ordered]@{
            Name                    = $cpu.Name.Trim()
            Manufacturer            = $cpu.Manufacturer
            PhysicalCores           = $cpu.NumberOfCores
            LogicalProcessors       = $cpu.NumberOfLogicalProcessors
            CurrentClockMHz         = $cpu.CurrentClockSpeed
            MaxClockMHz             = $cpu.MaxClockSpeed
            CurrentLoadPercent      = $cpu.LoadPercentage
        }
    }
)


# -----------------------------
# Memory
# -----------------------------

$totalMemoryKB = [double]$os.TotalVisibleMemorySize
$freeMemoryKB  = [double]$os.FreePhysicalMemory
$usedMemoryKB  = $totalMemoryKB - $freeMemoryKB

$memoryInfo = [ordered]@{
    TotalGB = [math]::Round($totalMemoryKB / 1MB, 2)
    UsedGB  = [math]::Round($usedMemoryKB / 1MB, 2)
    FreeGB  = [math]::Round($freeMemoryKB / 1MB, 2)

    UsagePercent = Get-Percent `
        -Part $usedMemoryKB `
        -Total $totalMemoryKB
}


# -----------------------------
# Logical Disks
# -----------------------------

$logicalDisks = @(
    Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    ForEach-Object {

        $size = [double]$_.Size
        $free = [double]$_.FreeSpace
        $used = $size - $free

        [ordered]@{
            Drive        = $_.DeviceID
            VolumeName   = $_.VolumeName
            FileSystem   = $_.FileSystem

            SizeGB       = Convert-BytesToGB $size
            UsedGB       = Convert-BytesToGB $used
            FreeGB       = Convert-BytesToGB $free

            UsagePercent = Get-Percent `
                -Part $used `
                -Total $size
        }
    }
)


# -----------------------------
# Physical Disks
# -----------------------------

$physicalDisks = @(
    Get-CimInstance Win32_DiskDrive |
    ForEach-Object {

        [ordered]@{
            Model         = $_.Model
            InterfaceType = $_.InterfaceType
            MediaType     = $_.MediaType
            SizeGB        = Convert-BytesToGB $_.Size
            SerialNumber  = if ($_.SerialNumber) {
                $_.SerialNumber.Trim()
            }
            else {
                $null
            }
        }
    }
)


# -----------------------------
# GPU
# -----------------------------

$gpuInfo = @(
    Get-CimInstance Win32_VideoController |
    ForEach-Object {

        [ordered]@{
            Name          = $_.Name
            DriverVersion = $_.DriverVersion

            AdapterRAM_GB = if ($_.AdapterRAM) {
                Convert-BytesToGB $_.AdapterRAM
            }
            else {
                $null
            }

            VideoMode     = $_.VideoModeDescription
        }
    }
)


# -----------------------------
# Network
# -----------------------------

$networkInfo = @()

# Prefer Get-NetIPConfiguration where available
if (Get-Command Get-NetIPConfiguration -ErrorAction SilentlyContinue) {

    $networkInfo = @(
        Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4Address -and
            $_.NetAdapter.Status -eq "Up"
        } |
        ForEach-Object {

            $ipv4 = @(
                $_.IPv4Address |
                ForEach-Object {
                    $_.IPAddress
                }
            )

            $gateway = @(
                $_.IPv4DefaultGateway |
                ForEach-Object {
                    $_.NextHop
                }
            )

            [ordered]@{
                InterfaceAlias = $_.InterfaceAlias
                Description    = $_.NetAdapter.InterfaceDescription
                Status         = $_.NetAdapter.Status
                IPv4Address    = $ipv4
                DefaultGateway = $gateway
            }
        }
    )
}
else {

    # Fallback for older environments
    $networkInfo = @(
        Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object {
            $_.IPEnabled
        } |
        ForEach-Object {

            $ipv4 = @(
                $_.IPAddress |
                Where-Object {
                    $_ -match '^\d{1,3}(\.\d{1,3}){3}$'
                }
            )

            [ordered]@{
                InterfaceAlias = $_.Description
                Description    = $_.Description
                Status         = "Unknown"
                IPv4Address    = $ipv4
                DefaultGateway = @($_.DefaultIPGateway)
            }
        }
    )
}


# -----------------------------
# Top CPU Processes
# -----------------------------

$topCPUProcesses = @(
    Get-Process |
    Where-Object {
        $_.CPU -ne $null
    } |
    Sort-Object CPU -Descending |
    Select-Object -First 10 |
    ForEach-Object {

        [ordered]@{
            ProcessName = $_.ProcessName
            PID         = $_.Id
            CPUSeconds  = [math]::Round($_.CPU, 2)
        }
    }
)


# -----------------------------
# Top Memory Processes
# -----------------------------

$topMemoryProcesses = @(
    Get-Process |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 10 |
    ForEach-Object {

        [ordered]@{
            ProcessName = $_.ProcessName
            PID         = $_.Id
            MemoryMB    = [math]::Round(
                $_.WorkingSet64 / 1MB,
                2
            )
        }
    }
)


# -----------------------------
# Final Report
# -----------------------------

$report = [ordered]@{

    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    OperatingSystem = $osInfo

    CPU = $cpuInfo

    Memory = $memoryInfo

    LogicalDisks = $logicalDisks

    PhysicalDisks = $physicalDisks

    GPU = $gpuInfo

    Network = $networkInfo

    TopCPUProcesses = $topCPUProcesses

    TopMemoryProcesses = $topMemoryProcesses
}


# Output JSON
$report | ConvertTo-Json -Depth 8