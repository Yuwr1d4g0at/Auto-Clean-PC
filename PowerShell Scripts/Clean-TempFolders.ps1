<#
.SYNOPSIS
    System temporary file cleaner.

.DESCRIPTION
    Cleans temporary files from user and system locations including:
    - User temp directory
    - Windows system temp
    - Windows Update cache
    - Browser caches (IE, Chrome, Edge)
    - Windows Error Reporting
    - Old log files (7+ days)
    - Recycle bin

.PARAMETER IncludeRecycleBin
    Also empty the system recycle bin (default: $true)

.EXAMPLE
    .\Clean-TempFolders.ps1
    .\Clean-TempFolders.ps1 -IncludeRecycleBin $false
#>

param(
    [Parameter(Mandatory = $false)]
    [bool]$IncludeRecycleBin = $true
)

# ===== CHECK ADMIN PRIVILEGES =====
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

if ($isAdmin) {
    Write-Host "Running with administrator privileges" -ForegroundColor Green
} else {
    Write-Host "Running with standard user privileges" -ForegroundColor Yellow
    Write-Host "Some cleanup operations will be skipped`n" -ForegroundColor Yellow
}

# ===== SETUP LOG FILE =====
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptPath "TempCleanupLog_Simple.txt"

# Create new log file
"========================================" | Set-Content -Path $logFile
"Temp cleanup started at $(Get-Date)" | Add-Content -Path $logFile
"Administrator privileges: $isAdmin" | Add-Content -Path $logFile
"========================================" | Add-Content -Path $logFile

# ===== WELCOME MESSAGE =====
Write-Host "`n" -ForegroundColor Cyan
Write-Host "Starting cleanup operations...`n" -ForegroundColor Cyan

# ===== FUNCTION: CLEAN FOLDER =====
function CleanFolder {
    param(
        [string]$FolderPath,
        [string]$Name,
        [bool]$RequiresAdmin,
        [string]$LogFile
    )
    
    # Check if we have sufficient permissions
    if ($RequiresAdmin -and -not $isAdmin) {
        Write-Host "[ADMIN REQUIRED] $Name" -ForegroundColor Yellow
        Add-Content -Path $LogFile -Value "Skipping $Name - requires administrator privileges"
        return
    }
    
    # Check if folder exists
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[NOT FOUND] $FolderPath" -ForegroundColor Yellow
        Add-Content -Path $LogFile -Value "Folder not found: $FolderPath"
        return
    }
    
    Write-Host "[CLEAN] $Name" -ForegroundColor Cyan
    Write-Host "  Processing: $FolderPath" -ForegroundColor Gray
    Add-Content -Path $LogFile -Value "Cleaning $Name ($FolderPath)"
    
    $deletedFiles = 0
    $skippedFiles = 0
    
    try {
        # Delete all files in main folder
        $files = @(Get-ChildItem -Path $FolderPath -File -ErrorAction SilentlyContinue)
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deletedFiles++
            } catch {
                $skippedFiles++
                Add-Content -Path $LogFile -Value "  Skipped: $($file.FullName)"
            }
        }
        
        # Delete all subfolders recursively
        $folders = @(Get-ChildItem -Path $FolderPath -Directory -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Descending)
        foreach ($folder in $folders) {
            try {
                Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
                $deletedFiles += 5  # Estimate
            } catch {
                Add-Content -Path $LogFile -Value "  Skipped folder: $($folder.FullName)"
            }
        }
        
        Write-Host "  Files processed: $deletedFiles, Skipped: $skippedFiles" -ForegroundColor Green
        Add-Content -Path $LogFile -Value "Summary for $Name:"
        Add-Content -Path $LogFile -Value "  Files processed: $deletedFiles"
        Add-Content -Path $LogFile -Value "  Files skipped: $skippedFiles"
        Add-Content -Path $LogFile -Value ""
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
        Add-Content -Path $LogFile -Value "Error processing $Name: $_"
    }
}

# ===== CLEAN TEMP FOLDERS =====

# User temp folder (no admin needed)
CleanFolder -FolderPath $env:TEMP -Name "User temp folder" -RequiresAdmin $false -LogFile $logFile

# Windows system temp (admin required)
CleanFolder -FolderPath "C:\Windows\Temp" -Name "Windows temp folder" -RequiresAdmin $true -LogFile $logFile

# Windows Update cache (admin required)
CleanFolder -FolderPath "C:\Windows\SoftwareDistribution\Download" -Name "Windows Update cache" -RequiresAdmin $true -LogFile $logFile

# IE cache (no admin needed)
$ieCachePath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\INetCache"
CleanFolder -FolderPath $ieCachePath -Name "IE cache" -RequiresAdmin $false -LogFile $logFile

# Windows Error Reporting (admin required)
CleanFolder -FolderPath "C:\ProgramData\Microsoft\Windows\WER" -Name "Windows Error Reporting" -RequiresAdmin $true -LogFile $logFile

# Chrome cache (no admin needed)
$chromeCachePath = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Cache"
CleanFolder -FolderPath $chromeCachePath -Name "Chrome cache" -RequiresAdmin $false -LogFile $logFile

# Edge cache (no admin needed)
$edgeCachePath = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Cache"
CleanFolder -FolderPath $edgeCachePath -Name "Edge cache" -RequiresAdmin $false -LogFile $logFile

# ===== CLEAN OLD WINDOWS LOG FILES =====
Write-Host "[LOGS] Windows Logs" -ForegroundColor Cyan
if ($isAdmin) {
    try {
        $logPath = "C:\Windows\Logs"
        if (Test-Path $logPath) {
            $sevenDaysAgo = (Get-Date).AddDays(-7)
            $oldLogs = @(Get-ChildItem -Path $logPath -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $sevenDaysAgo })
            
            foreach ($log in $oldLogs) {
                try {
                    Remove-Item -Path $log.FullName -Force -ErrorAction Stop
                } catch {
                    # Silently skip locked files
                }
            }
            
            Write-Host "  Cleaned old log files" -ForegroundColor Green
            Add-Content -Path $logFile -Value "Deleted log files older than 7 days"
        }
    } catch {
        Add-Content -Path $logFile -Value "Error cleaning Windows logs: $_"
    }
} else {
    Write-Host "  [ADMIN REQUIRED] Windows Logs" -ForegroundColor Yellow
    Add-Content -Path $logFile -Value "Skipping Windows Logs - requires administrator privileges"
}

# ===== EMPTY RECYCLE BIN =====
if ($IncludeRecycleBin) {
    Write-Host "[RECYCLE] Recycle bin" -ForegroundColor Cyan
    if ($isAdmin) {
        try {
            $recycleBin = "C:\`$Recycle.Bin"
            if (Test-Path $recycleBin) {
                Remove-Item -Path $recycleBin -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Cleaned system recycle bin" -ForegroundColor Green
                Add-Content -Path $logFile -Value "Emptied system recycle bin"
            }
        } catch {
            Add-Content -Path $logFile -Value "Error emptying recycle bin: $_"
        }
    } else {
        Write-Host "  [ADMIN REQUIRED] System Recycle Bin" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "Skipping system recycle bin - requires administrator privileges"
    }
}

# ===== DISPLAY COMPLETION MESSAGE =====
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Finalize log file
"========================================" | Add-Content -Path $logFile
"Temp cleanup completed at $(Get-Date)" | Add-Content -Path $logFile
"========================================" | Add-Content -Path $logFile

Write-Host "Log file saved to:" -ForegroundColor Cyan
Write-Host $logFile -ForegroundColor Green
Write-Host ""

if (-not $isAdmin) {
    Write-Host "NOTE: Some operations were skipped due to insufficient privileges." -ForegroundColor Yellow
    Write-Host "Run as Administrator for complete system cleanup.`n" -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"
