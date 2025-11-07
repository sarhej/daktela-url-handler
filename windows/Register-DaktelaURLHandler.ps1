# Register-DaktelaURLHandler.ps1
# PowerShell script to register Daktela as the default handler for tel: and callto: URL schemes on Windows
# Version: 1.0.0

<#
.SYNOPSIS
    Registers Daktela as the default handler for telephone URL schemes (tel: and callto:) on Windows.

.DESCRIPTION
    This script modifies the Windows Registry to set Daktela as the default application for
    tel: and callto: URL schemes. It automatically detects the Daktela installation path.

.PARAMETER DaktelaPath
    Optional. Explicit path to Daktela.exe. If not provided, the script will search common locations.

.PARAMETER DryRun
    If specified, shows what changes would be made without actually making them.

.EXAMPLE
    .\Register-DaktelaURLHandler.ps1
    Auto-detects Daktela and registers URL handlers

.EXAMPLE
    .\Register-DaktelaURLHandler.ps1 -DaktelaPath "C:\Program Files\Daktela\Daktela.exe"
    Uses explicit path to Daktela

.EXAMPLE
    .\Register-DaktelaURLHandler.ps1 -DryRun
    Shows what would be changed without making changes

.NOTES
    Requires: Windows 10+, PowerShell 5.1+, Administrator privileges
    License: MIT
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DaktelaPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

#Requires -RunAsAdministrator

# Script metadata
$ScriptVersion = "1.0.0"
$SupportedSchemes = @("tel", "callto")

#region Helper Functions

function Write-Info {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-DaktelaInstallation {
    <#
    .SYNOPSIS
        Searches for Daktela installation in common locations
    #>
    
    Write-Info "Searching for Daktela installation..."
    
    # Common installation paths
    $searchPaths = @(
        "${env:ProgramFiles}\Daktela\Daktela.exe",
        "${env:ProgramFiles(x86)}\Daktela\Daktela.exe",
        "${env:LOCALAPPDATA}\Programs\Daktela\Daktela.exe",
        "${env:ProgramFiles}\Daktela Desktop\Daktela.exe",
        "${env:ProgramFiles(x86)}\Daktela Desktop\Daktela.exe"
    )
    
    # Check each path
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Success "Found Daktela at: $path"
            return $path
        }
    }
    
    # Search in Program Files recursively (slower but thorough)
    Write-Info "Searching Program Files directories..."
    $programFiles = @($env:ProgramFiles, ${env:ProgramFiles(x86)})
    
    foreach ($dir in $programFiles) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "Daktela.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                Write-Success "Found Daktela at: $($found.FullName)"
                return $found.FullName
            }
        }
    }
    
    # Search in AppData\Local\Programs
    Write-Info "Searching user-installed applications..."
    $localApps = "$env:LOCALAPPDATA\Programs"
    if (Test-Path $localApps) {
        $found = Get-ChildItem -Path $localApps -Filter "Daktela.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Success "Found Daktela at: $($found.FullName)"
            return $found.FullName
        }
    }
    
    return $null
}

function Test-DaktelaExecutable {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    # Verify it's an executable
    if ($Path -notmatch '\.exe$') {
        return $false
    }
    
    # Try to get file version info
    try {
        $fileInfo = Get-Item $Path -ErrorAction Stop
        return $fileInfo.Exists
    }
    catch {
        return $false
    }
}

function Register-URLScheme {
    param(
        [string]$Scheme,
        [string]$ExecutablePath,
        [bool]$DryRun
    )
    
    $registryPath = "HKCU:\Software\Classes\$Scheme"
    
    if ($DryRun) {
        Write-Info "DRY RUN: Would register $Scheme protocol"
        Write-Host "  Registry Path: $registryPath"
        Write-Host "  Executable: $ExecutablePath"
        Write-Host "  Command: `"$ExecutablePath`" `"%1`""
        return $true
    }
    
    try {
        # Create or update the protocol key
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Set protocol properties
        Set-ItemProperty -Path $registryPath -Name "(Default)" -Value "URL:$Scheme Protocol"
        Set-ItemProperty -Path $registryPath -Name "URL Protocol" -Value ""
        
        # Create shell\open\command key
        $commandPath = "$registryPath\shell\open\command"
        if (-not (Test-Path $commandPath)) {
            New-Item -Path $commandPath -Force | Out-Null
        }
        
        # Set command
        $command = "`"$ExecutablePath`" `"%1`""
        Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $command
        
        Write-Success "Registered $Scheme protocol -> $ExecutablePath"
        return $true
    }
    catch {
        Write-ErrorMessage "Failed to register $Scheme protocol: $_"
        return $false
    }
}

function Get-CurrentURLHandler {
    param([string]$Scheme)
    
    $registryPath = "HKCU:\Software\Classes\$Scheme\shell\open\command"
    
    try {
        if (Test-Path $registryPath) {
            $command = (Get-ItemProperty -Path $registryPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
            return $command
        }
    }
    catch {
        # Silently fail
    }
    
    return $null
}

function Show-CurrentHandlers {
    Write-Info "Current URL scheme handlers:"
    
    foreach ($scheme in $SupportedSchemes) {
        $handler = Get-CurrentURLHandler -Scheme $scheme
        if ($handler) {
            Write-Host "  $scheme -> $handler" -ForegroundColor Cyan
        }
        else {
            Write-Host "  $scheme -> Not registered" -ForegroundColor Yellow
        }
    }
}

#endregion

#region Main Script

function Main {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  Daktela URL Scheme Handler Registration (Windows)" -ForegroundColor Blue
    Write-Host "  Version $ScriptVersion" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
    
    # Check for admin privileges
    if (-not (Test-Administrator)) {
        Write-ErrorMessage "This script requires Administrator privileges."
        Write-ErrorMessage "Please run PowerShell as Administrator and try again."
        Write-Host ""
        Write-Info "To run as Administrator:"
        Write-Info "  1. Right-click PowerShell"
        Write-Info "  2. Select 'Run as Administrator'"
        Write-Info "  3. Navigate to script directory"
        Write-Info "  4. Run: .\Register-DaktelaURLHandler.ps1"
        exit 1
    }
    
    # Show current handlers
    Show-CurrentHandlers
    Write-Host ""
    
    # Determine Daktela path
    $exePath = $null
    
    if ($DaktelaPath) {
        Write-Info "Using provided Daktela path: $DaktelaPath"
        $exePath = $DaktelaPath
    }
    else {
        $exePath = Find-DaktelaInstallation
    }
    
    # Validate Daktela executable
    if (-not $exePath) {
        Write-ErrorMessage "Unable to find Daktela installation."
        Write-Host ""
        Write-ErrorMessage "⚠️  PREREQUISITE: Daktela must be installed on this system."
        Write-Host ""
        Write-Info "Solutions:"
        Write-Info "  1. Install Daktela from https://www.daktela.com/"
        Write-Info "  2. If already installed, specify path explicitly:"
        Write-Info "     .\Register-DaktelaURLHandler.ps1 -DaktelaPath 'C:\Path\To\Daktela.exe'"
        Write-Host ""
        exit 2
    }
    
    if (-not (Test-DaktelaExecutable -Path $exePath)) {
        Write-ErrorMessage "Invalid Daktela executable: $exePath"
        Write-ErrorMessage "Please verify the path and try again."
        exit 2
    }
    
    Write-Success "Validated Daktela executable: $exePath"
    Write-Host ""
    
    # Dry run check
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
        Write-Host ""
    }
    
    # Register each URL scheme
    $successCount = 0
    foreach ($scheme in $SupportedSchemes) {
        Write-Info "Processing $scheme protocol..."
        
        if (Register-URLScheme -Scheme $scheme -ExecutablePath $exePath -DryRun $DryRun) {
            $successCount++
        }
    }
    
    Write-Host ""
    
    if (-not $DryRun) {
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Success "Successfully registered $successCount/$($SupportedSchemes.Count) URL schemes"
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host ""
        
        # Show updated handlers
        Write-Info "Verifying registration..."
        Show-CurrentHandlers
        Write-Host ""
        
        Write-Success "Done! Daktela is now the default handler for telephone URLs."
        Write-Host ""
        Write-Info "Test it by clicking these links:"
        Write-Info "  tel:123456789"
        Write-Info "  callto:user@example.com"
        Write-Host ""
        Write-Info "Note: You may need to restart your browser for changes to take effect."
    }
    else {
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Warning "DRY RUN complete - no changes were made"
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "To apply these changes, run without -DryRun flag"
    }
}

# Entry point
try {
    Main
    exit 0
}
catch {
    Write-ErrorMessage "An unexpected error occurred: $_"
    Write-ErrorMessage $_.ScriptStackTrace
    exit 1
}

#endregion

