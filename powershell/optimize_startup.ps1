#requires -Version 5.1

<#
Local-AI-PC-Agent
Startup Optimizer v0.6

Safety design:
- Scans startup entries
- Protects known system/infrastructure entries
- User selects one specific entry
- Requires Y confirmation
- Creates a backup before changing anything
- Does not uninstall software
- Does not terminate running processes
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportsDirectory = Join-Path $ProjectRoot "reports"
$BackupFile = Join-Path $ReportsDirectory "startup_backup.json"

if (-not (Test-Path $ReportsDirectory)) {
    New-Item -ItemType Directory -Path $ReportsDirectory | Out-Null
}

Write-Host ""
Write-Host "========================================"
Write-Host " Local-AI-PC-Agent Startup Optimizer"
Write-Host "========================================"
Write-Host ""

# ------------------------------------------------------------
# Read startup entries
# ------------------------------------------------------------

$allStartup = @(
    Get-CimInstance Win32_StartupCommand |
    ForEach-Object {
        [PSCustomObject]@{
            Name     = $_.Name
            Command  = $_.Command
            Location = $_.Location
            User     = $_.User
        }
    }
)

Write-Host "Startup entries detected: $($allStartup.Count)"
Write-Host ""

# ------------------------------------------------------------
# Protected entries
# ------------------------------------------------------------

$protectedPatterns = @(
    "SecurityHealth",
    "VMware User Process"
)

function Test-ProtectedStartup {
    param([string]$Name)

    foreach ($pattern in $protectedPatterns) {
        if ($Name -like "*$pattern*") {
            return $true
        }
    }

    return $false
}

# ------------------------------------------------------------
# Build selectable candidates
# ------------------------------------------------------------

$candidates = @(
    $allStartup |
    Where-Object {
        -not (Test-ProtectedStartup $_.Name)
    }
)

Write-Host "Protected entries:"
Write-Host ""

foreach ($entry in $allStartup) {
    if (Test-ProtectedStartup $entry.Name) {
        Write-Host "  [PROTECTED] $($entry.Name)"
    }
}

Write-Host ""
Write-Host "Selectable startup entries:"
Write-Host ""

for ($i = 0; $i -lt $candidates.Count; $i++) {

    $number = $i + 1
    $entry = $candidates[$i]

    Write-Host "[$number] $($entry.Name)"
    Write-Host "    Command : $($entry.Command)"
    Write-Host "    Location: $($entry.Location)"
    Write-Host ""
}

Write-Host "[0] Cancel"
Write-Host ""

# ------------------------------------------------------------
# User selection
# ------------------------------------------------------------

$selectionText = Read-Host "Select ONE startup entry to disable"

[int]$selection = 0

if (-not [int]::TryParse($selectionText, [ref]$selection)) {
    Write-Host ""
    Write-Host "Invalid selection."
    exit 1
}

if ($selection -eq 0) {
    Write-Host ""
    Write-Host "Cancelled. No changes were made."
    exit 0
}

if ($selection -lt 1 -or $selection -gt $candidates.Count) {
    Write-Host ""
    Write-Host "Invalid selection."
    exit 1
}

$selected = $candidates[$selection - 1]

# ------------------------------------------------------------
# Explain exactly what will happen
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Selected startup entry"
Write-Host "========================================"
Write-Host ""

Write-Host "Name:"
Write-Host $selected.Name

Write-Host ""
Write-Host "Command:"
Write-Host $selected.Command

Write-Host ""
Write-Host "Location:"
Write-Host $selected.Location

Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "This will disable automatic startup only."
Write-Host "It will NOT uninstall the application."
Write-Host "It will NOT close the currently running application."
Write-Host ""

# ------------------------------------------------------------
# Determine supported location
# ------------------------------------------------------------

$registryPath = $null

if ($selected.Location -match '^HKU\\(.+?)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run$') {

    $sid = $Matches[1]

    $registryPath = "Registry::HKEY_USERS\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
}
elseif ($selected.Location -eq 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') {

    $registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
}
elseif ($selected.Location -eq 'Startup') {

    Write-Host "This entry is stored in the Startup folder."
    Write-Host "Startup-folder modification is not enabled in this version."
    Write-Host "No changes were made."
    exit 0
}
else {

    Write-Host "Unsupported startup location."
    Write-Host "No changes were made."
    exit 0
}

# ------------------------------------------------------------
# Verify registry value exists
# ------------------------------------------------------------

try {

    $currentValue = Get-ItemPropertyValue `
        -LiteralPath $registryPath `
        -Name $selected.Name `
        -ErrorAction Stop
}
catch {

    Write-Host ""
    Write-Host "Could not verify the startup registry value."
    Write-Host "No changes were made."
    exit 1
}

# ------------------------------------------------------------
# Final confirmation
# ------------------------------------------------------------

Write-Host ""
$answer = Read-Host "Disable this startup entry? Type Y or N"

if ($answer -notmatch '^[Yy]$') {

    Write-Host ""
    Write-Host "Cancelled."
    Write-Host "No changes were made."
    exit 0
}

# ------------------------------------------------------------
# Backup BEFORE modification
# ------------------------------------------------------------

$backupRecord = [ordered]@{
    GeneratedAt  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Name         = $selected.Name
    Command      = [string]$currentValue
    Location     = $selected.Location
    RegistryPath = $registryPath
}

$backupRecord |
    ConvertTo-Json -Depth 5 |
    Out-File $BackupFile -Encoding utf8

Write-Host ""
Write-Host "Backup created:"
Write-Host $BackupFile

# ------------------------------------------------------------
# Disable startup entry
# ------------------------------------------------------------

try {

    Remove-ItemProperty `
        -LiteralPath $registryPath `
        -Name $selected.Name `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Startup entry disabled successfully."
    Write-Host ""
    Write-Host "Application:"
    Write-Host $selected.Name
    Write-Host ""
    Write-Host "The application was NOT uninstalled."
    Write-Host "The currently running process was NOT terminated."
}
catch {

    Write-Host ""
    Write-Host "Failed to disable the startup entry." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "The backup remains available at:"
    Write-Host $BackupFile
    exit 1
}