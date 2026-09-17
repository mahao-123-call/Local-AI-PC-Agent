# Windows System Information Collector

$info = @{
    ComputerName = $env:COMPUTERNAME

    OS = (Get-CimInstance Win32_OperatingSystem).Caption

    CPU = (Get-CimInstance Win32_Processor).Name

    CPU_Cores = (Get-CimInstance Win32_Processor).NumberOfCores

    Memory_GB = [math]::Round(
        (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,
        2
    )

    Disk = Get-CimInstance Win32_LogicalDisk |
    Where-Object {$_.DriveType -eq 3} |
    Select-Object DeviceID,
    @{
        Name="SizeGB";
        Expression={
            [math]::Round($_.Size/1GB,2)
        }
    },
    @{
        Name="FreeGB";
        Expression={
            [math]::Round($_.FreeSpace/1GB,2)
        }
    }
}

$info | ConvertTo-Json -Depth 3