<#
.SYNOPSIS
    Advanced multi-location shortcut validator and cleaner.

.DESCRIPTION
    Scans multiple Windows locations for invalid shortcuts (targets that don't exist).
    Provides three safety modes: Preview (view only), Backup (recommended), or Delete.
    Creates timestamped backups for easy recovery.

.PARAMETER Locations
    Which locations to scan: 'Desktop', 'StartMenu', 'All', or 'Custom' (default: 'All')

.PARAMETER Mode
    Safety mode: 'Preview', 'Backup' (recommended), or 'Delete' (default: 'Backup')

.EXAMPLE
    .\Clean-Shortcuts.ps1
    .\Clean-Shortcuts.ps1 -Locations Desktop -Mode Preview
    .\Clean-Shortcuts.ps1 -Locations All -Mode Backup
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Desktop", "StartMenu", "All", "Custom")]
    [string]$Locations = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Preview", "Backup", "Delete")]
    [string]$Mode = "Backup"
)

# ===== SETUP =====
$backupFolder = Join-Path $env:USERPROFILE "Documents\Deleted_Shortcuts_Backup"
$logFile = Join-Path $env:USERPROFILE "Documents\DeletedInvalidShortcutsLog.txt"
$shell = New-Object -ComObject WScript.Shell

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "Created backup folder: $backupFolder" -ForegroundColor Green
}

# ===== INITIALIZE COUNTERS =====
$totalShortcuts = 0
$validShortcuts = 0
$invalidShortcuts = 0
$skippedShortcuts = 0

# ===== DEFINE SCANNING LOCATIONS =====
$scanLocations = @{
    Desktop      = Join-Path $env:USERPROFILE "Desktop"
    StartMenu    = Join-Path $env:USERPROFILE "AppData\Roaming\Microsoft\Windows\Start Menu"
    PublicDesktop = Join-Path $env:PUBLIC "Desktop"
    QuickLaunch  = Join-Path $env:USERPROFILE "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"
}

# Determine which locations to scan
if ($Locations -eq "Desktop") {
    $locationsToScan = @{ Desktop = $scanLocations.Desktop }
} elseif ($Locations -eq "StartMenu") {
    $locationsToScan = @{ StartMenu = $scanLocations.StartMenu }
} elseif ($Locations -eq "Custom") {
    Write-Host "`nSelect scanning locations:" -ForegroundColor Cyan
    Write-Host "[1] Desktop only"
    Write-Host "[2] Desktop + Start Menu"
    Write-Host "[3] All locations"
    $choice = Read-Host "Enter choice (1-3)"
    
    if ($choice -eq "1") {
        $locationsToScan = @{ Desktop = $scanLocations.Desktop }
    } elseif ($choice -eq "2") {
        $locationsToScan = @{ 
            Desktop = $scanLocations.Desktop
            StartMenu = $scanLocations.StartMenu
        }
    } else {
        $locationsToScan = $scanLocations
    }
} else {
    $locationsToScan = $scanLocations
}

# ===== WELCOME MESSAGE =====
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    Auto Clean Shortcuts Tool v2.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Scanning locations:" -ForegroundColor Cyan
foreach ($location in $locationsToScan.Keys) {
    Write-Host "  - $location" -ForegroundColor Cyan
}
Write-Host "Mode: $Mode`n" -ForegroundColor Cyan

# ===== CREATE/UPDATE LOG FILE =====
Add-Content -Path $logFile -Value "========================================"
Add-Content -Path $logFile -Value "Shortcut cleanup started at $(Get-Date)"
Add-Content -Path $logFile -Value "Mode: $Mode"
Add-Content -Path $logFile -Value "========================================"

# ===== COUNT TOTAL SHORTCUTS =====
Write-Host "Counting shortcuts to scan..." -ForegroundColor Yellow
foreach ($location in $locationsToScan.Values) {
    if (Test-Path $location) {
        $totalShortcuts += @(Get-ChildItem -Path $location -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue).Count
    }
}

if ($totalShortcuts -eq 0) {
    Write-Host "No shortcuts found in selected locations.`n" -ForegroundColor Green
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "Found $totalShortcuts shortcuts to check`n" -ForegroundColor Green

# ===== MAIN SCANNING LOOP =====
$current = 0
$modeMessage = if ($Mode -eq "Preview") { "preview scan (no changes)" } else { "scan" }
Write-Host "Starting $modeMessage...`n" -ForegroundColor Yellow

foreach ($locationName in $locationsToScan.Keys) {
    $locationPath = $locationsToScan[$locationName]
    
    if (-not (Test-Path $locationPath)) {
        Write-Host "Location not found: $locationPath" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "Location not accessible: $locationPath"
        continue
    }
    
    Write-Host "`n=== Scanning: $locationName ===" -ForegroundColor Cyan
    Write-Host ""
    
    $shortcuts = @(Get-ChildItem -Path $locationPath -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue)
    
    foreach ($shortcut in $shortcuts) {
        $current++
        $progress = [int]($current / $totalShortcuts * 100)
        Write-Progress -Activity "Scanning shortcuts" -Status $shortcut.Name -PercentComplete $progress
        
        try {
            # Get shortcut target
            $sc = $shell.CreateShortcut($shortcut.FullName)
            $targetPath = $sc.TargetPath
            
            if ([string]::IsNullOrWhiteSpace($targetPath)) {
                Write-Host "  [$current/$totalShortcuts] [SKIP] No target path: $($shortcut.Name)" -ForegroundColor Yellow
                Add-Content -Path $logFile -Value "Skipped (no target): $($shortcut.FullName)"
                $skippedShortcuts++
            } elseif (-not (Test-Path $targetPath)) {
                # Invalid shortcut
                Write-Host "  [$current/$totalShortcuts] [INVALID] $($shortcut.Name) -> $targetPath" -ForegroundColor Red
                Add-Content -Path $logFile -Value "Invalid shortcut: $($shortcut.FullName)"
                Add-Content -Path $logFile -Value "  Target was: $targetPath"
                
                $invalidShortcuts++
                
                if ($Mode -eq "Preview") {
                    Write-Host "    [PREVIEW] Would remove this shortcut" -ForegroundColor Yellow
                } elseif ($Mode -eq "Delete") {
                    try {
                        Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
                        Write-Host "    [DELETED] Removed shortcut" -ForegroundColor Green
                        Add-Content -Path $logFile -Value "  Successfully deleted: $($shortcut.FullName)"
                    } catch {
                        Write-Host "    [ERROR] Could not delete: $_" -ForegroundColor Red
                        Add-Content -Path $logFile -Value "  Failed to delete: $($shortcut.FullName)"
                        $skippedShortcuts++
                        $invalidShortcuts--
                    }
                } else {  # Backup mode
                    try {
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
                        $backupName = "${timestamp}_$($shortcut.Name)"
                        $backupPath = Join-Path $backupFolder $backupName
                        
                        Copy-Item -Path $shortcut.FullName -Destination $backupPath -Force -ErrorAction Stop
                        Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
                        
                        Write-Host "    [BACKED UP] Moved to: $backupName" -ForegroundColor Green
                        Add-Content -Path $logFile -Value "  Successfully moved to backup: $backupName"
                    } catch {
                        Write-Host "    [ERROR] Could not backup: $_" -ForegroundColor Red
                        Add-Content -Path $logFile -Value "  Failed to move: $($shortcut.FullName)"
                        $skippedShortcuts++
                        $invalidShortcuts--
                    }
                }
            } else {
                Write-Host "  [$current/$totalShortcuts] [OK] Valid shortcut: $($shortcut.Name)" -ForegroundColor Green
                Add-Content -Path $logFile -Value "Valid shortcut: $($shortcut.FullName)"
                $validShortcuts++
            }
        } catch {
            Write-Host "  [$current/$totalShortcuts] [SKIP] Error reading: $($shortcut.Name) - $_" -ForegroundColor Yellow
            Add-Content -Path $logFile -Value "Skipped (read error): $($shortcut.FullName)"
            $skippedShortcuts++
        }
    }
}

Write-Progress -Activity "Scanning shortcuts" -Completed

# ===== DISPLAY RESULTS =====
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "           SCAN COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RESULTS SUMMARY:" -ForegroundColor Cyan
Write-Host "==============="
Write-Host "Total shortcuts scanned:  $totalShortcuts"
Write-Host "Valid shortcuts:          $validShortcuts"
Write-Host "Invalid shortcuts:        $invalidShortcuts"
Write-Host "Skipped shortcuts:        $skippedShortcuts"
Write-Host ""

if ($Mode -eq "Preview") {
    Write-Host "PREVIEW MODE: Found $invalidShortcuts broken shortcut(s)" -ForegroundColor Yellow
    Write-Host "Run again to actually process them." -ForegroundColor Yellow
} elseif ($Mode -eq "Delete") {
    Write-Host "SUCCESS: Permanently deleted $invalidShortcuts broken shortcut(s)" -ForegroundColor Green
} else {
    Write-Host "SUCCESS: Moved $invalidShortcuts broken shortcut(s) to backup folder" -ForegroundColor Green
    Write-Host "Backup location: $backupFolder" -ForegroundColor Green
}

# ===== WRITE SUMMARY TO LOG FILE =====
Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "========================================"
Add-Content -Path $logFile -Value "Shortcut cleanup completed at $(Get-Date)"
Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "FINAL STATISTICS:"
Add-Content -Path $logFile -Value "Total shortcuts scanned: $totalShortcuts"
Add-Content -Path $logFile -Value "Valid shortcuts found: $validShortcuts"
Add-Content -Path $logFile -Value "Invalid shortcuts processed: $invalidShortcuts"
Add-Content -Path $logFile -Value "Shortcuts skipped: $skippedShortcuts"
Add-Content -Path $logFile -Value "Mode: $Mode"
Add-Content -Path $logFile -Value "========================================"

Write-Host "`nDetailed log saved to:"
Write-Host $logFile -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
