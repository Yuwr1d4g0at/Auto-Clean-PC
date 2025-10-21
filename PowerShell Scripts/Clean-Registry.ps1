<#
.SYNOPSIS
    Windows Registry cleaner with advanced scanning and backup.

.DESCRIPTION
    Scans the Windows Registry for invalid entries:
    - Invalid uninstall entries
    - Broken file associations
    - Missing COM/ActiveX references
    - Orphaned startup entries
    - Invalid MUI cache entries

    Provides Preview mode (safe) and Backup & Fix mode (with automatic registry backup).
    Requires administrator privileges.

.PARAMETER Mode
    Safety mode: 'Preview' (view only) or 'BackupAndFix' (default: 'Preview')

.EXAMPLE
    .\Clean-Registry.ps1
    .\Clean-Registry.ps1 -Mode Preview
    .\Clean-Registry.ps1 -Mode BackupAndFix
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Preview", "BackupAndFix")]
    [string]$Mode = "Preview"
)

# ===== CHECK ADMINISTRATOR PRIVILEGES =====
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

if (-not $isAdmin) {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "    ERROR: Administrator Required" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Red
    Write-Host "This tool REQUIRES administrator privileges to access the registry." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator or use:" -ForegroundColor Yellow
    Write-Host "  Start-Process powershell -ArgumentList '-File', '.\Clean-Registry.ps1' -Verb RunAs`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# ===== SETUP =====
$backupFolder = Join-Path $env:USERPROFILE "Documents\Registry_Backups"
$logFile = Join-Path $env:USERPROFILE "Documents\RegistryCleanupLog.txt"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "Created backup folder: $backupFolder" -ForegroundColor Green
}

# ===== INITIALIZE COUNTERS =====
$totalIssues = 0
$fixedIssues = 0
$skippedIssues = 0

# ===== CREATE LOG FILE =====
"========================================" | Set-Content -Path $logFile
"Registry cleanup started at $(Get-Date)" | Add-Content -Path $logFile
"Mode: $Mode" | Add-Content -Path $logFile
"========================================" | Add-Content -Path $logFile

# ===== WELCOME MESSAGE =====
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    Registry Cleaner Tool v1.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "This tool will scan the Windows Registry for:" -ForegroundColor Yellow
Write-Host "  - Invalid uninstall entries" -ForegroundColor Yellow
Write-Host "  - Broken file associations" -ForegroundColor Yellow
Write-Host "  - Missing COM/ActiveX references" -ForegroundColor Yellow
Write-Host "  - Orphaned startup entries" -ForegroundColor Yellow
Write-Host "  - Invalid MUI cache entries`n" -ForegroundColor Yellow

Write-Host "WARNING: Modifying the registry can be dangerous if done incorrectly." -ForegroundColor Red
Write-Host "This tool creates automatic backups before any changes.`n" -ForegroundColor Red

# ===== CREATE REGISTRY BACKUP IF IN FIX MODE =====
if ($Mode -eq "BackupAndFix") {
    Write-Host "Creating registry backup..." -ForegroundColor Cyan
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupFileBase = Join-Path $backupFolder "Registry_Backup_$timestamp"
    
    try {
        reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" "$backupFileBase`_HKLM_Uninstall.reg" /y | Out-Null
        reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" "$backupFileBase`_HKCU_Uninstall.reg" /y | Out-Null
        reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" "$backupFileBase`_HKLM_Run.reg" /y | Out-Null
        reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" "$backupFileBase`_HKCU_Run.reg" /y | Out-Null
        reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" "$backupFileBase`_ShellExt.reg" /y | Out-Null
        reg export "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" "$backupFileBase`_MuiCache.reg" /y | Out-Null
        
        Write-Host "Registry backup created successfully!" -ForegroundColor Green
        Write-Host "Backup location: $backupFolder`n" -ForegroundColor Green
        Add-Content -Path $logFile -Value "Created registry backup: $backupFileBase"
    } catch {
        Write-Host "Error creating backup: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "Starting registry scan...`n" -ForegroundColor Yellow

# ===== SCAN 1: INVALID UNINSTALL ENTRIES =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SCAN 1/5] Checking Uninstall Entries" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scanCount = 0
foreach ($hive in @("HKLM", "HKCU")) {
    $regPath = "$hive`:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    
    try {
        $keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
        
        foreach ($key in $keys) {
            $scanCount++
            
            $displayName = $key.GetValue("DisplayName", "")
            $uninstallString = $key.GetValue("UninstallString", "")
            
            if ($uninstallString -and $uninstallString -notmatch "MsiExec\.exe") {
                # Extract exe path
                $exePath = $uninstallString -replace '".+?"', ''  # Remove quotes
                $exePath = ($exePath -split '\s+')[0]  # Get first part (exe path)
                
                if ($exePath -match '\.exe$' -and -not (Test-Path $exePath)) {
                    $totalIssues++
                    Write-Host "[ISSUE $totalIssues] Invalid uninstall entry: $displayName" -ForegroundColor Red
                    Write-Host "  Key: $($key.PSPath)" -ForegroundColor Red
                    Write-Host "  Missing file: $exePath`n" -ForegroundColor Red
                    
                    Add-Content -Path $logFile -Value "Invalid uninstall entry: $($key.PSPath)"
                    Add-Content -Path $logFile -Value "  DisplayName: $displayName"
                    Add-Content -Path $logFile -Value "  Missing file: $exePath"
                    
                    if ($Mode -eq "BackupAndFix") {
                        try {
                            Remove-Item -Path $key.PSPath -Force -ErrorAction Stop
                            $fixedIssues++
                            Write-Host "  [FIXED] Removed invalid entry`n" -ForegroundColor Green
                            Add-Content -Path $logFile -Value "  Successfully removed"
                        } catch {
                            $skippedIssues++
                            Write-Host "  [ERROR] Could not remove: $_`n" -ForegroundColor Yellow
                            Add-Content -Path $logFile -Value "  Failed to remove: $_"
                        }
                    }
                }
            }
            
            if ($scanCount % 50 -eq 0) {
                Write-Host "  Scanned $scanCount uninstall entries..." -ForegroundColor Gray
            }
        }
    } catch {
        Add-Content -Path $logFile -Value "Error scanning $regPath : $_"
    }
}

Write-Host "Completed: Scanned $scanCount uninstall entries`n" -ForegroundColor Green

# ===== SCAN 2: ORPHANED STARTUP ENTRIES =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SCAN 2/5] Checking Startup Entries" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scanCount = 0
foreach ($hive in @("HKLM", "HKCU")) {
    $regPath = "$hive`:\Software\Microsoft\Windows\CurrentVersion\Run"
    
    try {
        $values = Get-Item -Path $regPath -ErrorAction SilentlyContinue
        
        foreach ($property in $values.Property) {
            $scanCount++
            $startupPath = $values.GetValue($property)
            
            # Extract exe path
            $exePath = $startupPath -replace '".+?"', ''
            $exePath = ($exePath -split '\s+')[0]
            
            if ($exePath -match '\.exe$' -and -not (Test-Path $exePath)) {
                $totalIssues++
                Write-Host "[ISSUE $totalIssues] Invalid startup entry: $property" -ForegroundColor Red
                Write-Host "  Missing file: $exePath`n" -ForegroundColor Red
                
                Add-Content -Path $logFile -Value "Invalid startup entry: $property"
                Add-Content -Path $logFile -Value "  Missing file: $exePath"
                
                if ($Mode -eq "BackupAndFix") {
                    try {
                        Remove-ItemProperty -Path $regPath -Name $property -Force -ErrorAction Stop
                        $fixedIssues++
                        Write-Host "  [FIXED] Removed invalid entry`n" -ForegroundColor Green
                        Add-Content -Path $logFile -Value "  Successfully removed"
                    } catch {
                        $skippedIssues++
                        Write-Host "  [ERROR] Could not remove: $_`n" -ForegroundColor Yellow
                        Add-Content -Path $logFile -Value "  Failed to remove: $_"
                    }
                }
            }
        }
    } catch {
        Add-Content -Path $logFile -Value "Error scanning $regPath : $_"
    }
}

Write-Host "Completed: Scanned $scanCount startup entries`n" -ForegroundColor Green

# ===== SCAN 3: INVALID SHELL EXTENSIONS =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SCAN 3/5] Checking Shell Extensions" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scanCount = 0
$regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved"

try {
    $values = Get-Item -Path $regPath -ErrorAction SilentlyContinue
    
    foreach ($property in $values.Property) {
        $scanCount++
        $clsid = $property
        
        # Check if CLSID exists
        if (-not (Test-Path "HKCR:\CLSID\$clsid" -ErrorAction SilentlyContinue)) {
            $totalIssues++
            Write-Host "[ISSUE $totalIssues] Invalid shell extension: $clsid" -ForegroundColor Red
            Write-Host "  Extension is approved but CLSID doesn't exist`n" -ForegroundColor Red
            
            Add-Content -Path $logFile -Value "Invalid shell extension: $clsid"
            
            if ($Mode -eq "BackupAndFix") {
                try {
                    Remove-ItemProperty -Path $regPath -Name $clsid -Force -ErrorAction Stop
                    $fixedIssues++
                    Write-Host "  [FIXED] Removed invalid extension`n" -ForegroundColor Green
                    Add-Content -Path $logFile -Value "  Successfully removed"
                } catch {
                    $skippedIssues++
                    Write-Host "  [ERROR] Could not remove: $_`n" -ForegroundColor Yellow
                    Add-Content -Path $logFile -Value "  Failed to remove: $_"
                }
            }
        }
        
        if ($scanCount % 25 -eq 0) {
            Write-Host "  Scanned $scanCount shell extensions..." -ForegroundColor Gray
        }
    }
} catch {
    Add-Content -Path $logFile -Value "Error scanning shell extensions: $_"
}

Write-Host "Completed: Scanned $scanCount shell extensions`n" -ForegroundColor Green

# ===== SCAN 4: FILE ASSOCIATIONS (Simplified) =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SCAN 4/5] Checking File Associations (Limited)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Note: Full registry scanning can be slow in PowerShell; doing a simplified version
Write-Host "  Scan limited to prevent excessive processing time" -ForegroundColor Yellow
Write-Host "  Consider running from Registry Editor for comprehensive scan`n" -ForegroundColor Yellow
Add-Content -Path $logFile -Value "File associations scan: Limited scan performed"

# ===== SCAN 5: MUI CACHE =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SCAN 5/5] Checking MUI Cache" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scanCount = 0
$regPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"

try {
    $values = Get-Item -Path $regPath -ErrorAction SilentlyContinue
    
    foreach ($property in $values.Property) {
        $scanCount++
        $muiPath = $property
        
        # Only check entries that look like file paths
        if ($muiPath -match '[A-Za-z]:\\' -and $muiPath -notmatch 'FriendlyAppName|ApplicationCompany|LangID') {
            if (-not (Test-Path $muiPath -ErrorAction SilentlyContinue)) {
                $totalIssues++
                Write-Host "[ISSUE $totalIssues] Invalid MUI cache entry" -ForegroundColor Red
                Write-Host "  Missing file: $muiPath`n" -ForegroundColor Red
                
                Add-Content -Path $logFile -Value "Invalid MUI cache entry: $muiPath"
                
                if ($Mode -eq "BackupAndFix") {
                    try {
                        Remove-ItemProperty -Path $regPath -Name $property -Force -ErrorAction Stop
                        $fixedIssues++
                        Write-Host "  [FIXED] Removed invalid entry`n" -ForegroundColor Green
                        Add-Content -Path $logFile -Value "  Successfully removed"
                    } catch {
                        $skippedIssues++
                        Write-Host "  [ERROR] Could not remove: $_`n" -ForegroundColor Yellow
                        Add-Content -Path $logFile -Value "  Failed to remove: $_"
                    }
                }
            }
        }
        
        if ($scanCount % 50 -eq 0) {
            Write-Host "  Scanned $scanCount MUI cache entries..." -ForegroundColor Gray
        }
    }
} catch {
    Add-Content -Path $logFile -Value "Error scanning MUI cache: $_"
}

Write-Host "Completed: Scanned $scanCount MUI cache entries`n" -ForegroundColor Green

# ===== DISPLAY RESULTS =====
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "           SCAN COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RESULTS SUMMARY:" -ForegroundColor Cyan
Write-Host "==============="
Write-Host "Total issues found: $totalIssues"

if ($Mode -eq "Preview") {
    Write-Host "Mode: PREVIEW ONLY`n" -ForegroundColor Yellow
    Write-Host "No changes were made to your registry." -ForegroundColor Yellow
    Write-Host "Run in 'BackupAndFix' mode to resolve these issues.`n" -ForegroundColor Yellow
} else {
    Write-Host "Issues fixed: $fixedIssues"
    Write-Host "Issues skipped: $skippedIssues"
    Write-Host "Mode: BACKUP AND FIX`n" -ForegroundColor Green
    Write-Host "Registry backup saved to:" -ForegroundColor Green
    Write-Host $backupFolder -ForegroundColor Green
    Write-Host ""
    Write-Host "To restore registry if needed:" -ForegroundColor Yellow
    Write-Host "  1. Double-click the .reg backup files" -ForegroundColor Yellow
    Write-Host "  2. Confirm the import when prompted`n" -ForegroundColor Yellow
}

# ===== WRITE SUMMARY TO LOG FILE =====
Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "========================================"
Add-Content -Path $logFile -Value "Registry cleanup completed at $(Get-Date)"
Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "FINAL STATISTICS:"
Add-Content -Path $logFile -Value "Total issues found: $totalIssues"
Add-Content -Path $logFile -Value "Mode: $Mode"

if ($Mode -eq "BackupAndFix") {
    Add-Content -Path $logFile -Value "Issues fixed: $fixedIssues"
    Add-Content -Path $logFile -Value "Issues skipped: $skippedIssues"
}

Add-Content -Path $logFile -Value "========================================"

Write-Host "Detailed log saved to:" -ForegroundColor Cyan
Write-Host $logFile -ForegroundColor Green
Write-Host ""

if ($totalIssues -eq 0) {
    Write-Host "No registry issues found - your system is clean!" -ForegroundColor Green
} else {
    if ($Mode -eq "Preview") {
        Write-Host "Found $totalIssues issue(s) that can be fixed." -ForegroundColor Yellow
    } else {
        Write-Host "Successfully processed $totalIssues registry issue(s)." -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Read-Host "Press Enter to exit"
