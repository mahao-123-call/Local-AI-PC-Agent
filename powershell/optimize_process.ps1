#requires -Version 5.1

<#
Local-AI-PC-Agent
Optional Process Optimizer v1.0

Allows the user to select a non-protected process
and optionally close it.

Never automatically terminates a process.
#>

$ErrorActionPreference = "Stop"

$protectedNames = @(
    "System",
    "Idle",
    "Registry",
    "Memory Compression",
    "csrss",
    "wininit",
    "winlogon",
    "services",
    "lsass",
    "svchost",
    "dwm",
    "explorer",
    "MsMpEng"
)

$processes = @(
    Get-Process |
    Where-Object {
        $_.WorkingSet64 -gt 100MB
    } |
    Sort-Object WorkingSet64 -Descending
)

$candidates = @()

foreach ($process in $processes) {

    if ($protectedNames -notcontains $process.ProcessName) {

        $candidates += [PSCustomObject]@{
            Name = $process.ProcessName
            PID = $process.Id
            MemoryMB = [math]::Round(
                $process.WorkingSet64 / 1MB,
                2
            )
        }
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " High-memory Optional Applications"
Write-Host "========================================"
Write-Host ""

if ($candidates.Count -eq 0) {

    Write-Host "No optional high-memory processes found."
    exit 0
}

for ($i = 0; $i -lt $candidates.Count; $i++) {

    $number = $i + 1
    $item = $candidates[$i]

    Write-Host "[$number] $($item.Name)"
    Write-Host "    PID: $($item.PID)"
    Write-Host "    Memory: $($item.MemoryMB) MB"
    Write-Host ""
}

Write-Host "[0] Cancel"
Write-Host ""

$text = Read-Host "Select ONE application"

[int]$selection = 0

if (-not [int]::TryParse($text, [ref]$selection)) {
    Write-Host "Invalid selection."
    exit 1
}

if ($selection -eq 0) {

    Write-Host "Cancelled."
    exit 0
}

if ($selection -lt 1 -or $selection -gt $candidates.Count) {

    Write-Host "Invalid selection."
    exit 1
}

$selected = $candidates[$selection - 1]

Write-Host ""
Write-Host "Selected:"
Write-Host $selected.Name

Write-Host "PID:"
Write-Host $selected.PID

Write-Host "Memory:"
Write-Host "$($selected.MemoryMB) MB"

Write-Host ""
Write-Host "WARNING:"
Write-Host "Closing an application can cause unsaved work to be lost."
Write-Host ""

$answer = Read-Host "Close this application? Type Y or N"

if ($answer -notmatch '^[Yy]$') {

    Write-Host ""
    Write-Host "Cancelled."
    Write-Host "No process was terminated."

    exit 0
}

try {

    Stop-Process `
        -Id $selected.PID `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Process closed successfully."
}
catch {

    Write-Host ""
    Write-Host "Failed to close process." -ForegroundColor Red
    Write-Host $_.Exception.Message

    exit 1
}