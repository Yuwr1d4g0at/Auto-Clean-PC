rem ===== BASIC SETUP =====
rem This turns off the display of each command as it runs (keeps output clean)
@echo off
rem This allows us to use variables that change inside loops and if statements
setlocal enabledelayedexpansion

rem ===== WELCOME MESSAGE =====
echo.
echo ========================================
echo    Auto Clean Shortcuts Tool v2.0
echo ========================================
echo.
echo This tool will scan multiple locations for broken shortcuts:
echo - Desktop (user)
echo - Start Menu (user)
echo - Public Desktop (all users)
echo - Quick Launch toolbar
echo.
echo Broken shortcuts will be moved to a backup folder for safety.
echo.

rem ===== SAFETY SETUP =====
rem Create backup folder for moved shortcuts (safety feature)
set "backupFolder=%USERPROFILE%\Documents\Deleted_Shortcuts_Backup"
if not exist "%backupFolder%" (
    mkdir "%backupFolder%" 2>nul
    echo Created backup folder: %backupFolder%
echo.
)

rem ===== SET UP SCANNING LOCATIONS =====
rem Define all the places we'll look for shortcuts
set "desktopPath=%USERPROFILE%\Desktop"
set "startMenuPath=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu"
set "publicDesktopPath=%PUBLIC%\Desktop"
set "quickLaunchPath=%USERPROFILE%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"

rem ===== USER CHOICE: WHICH LOCATIONS TO SCAN =====
echo Select scanning locations:
echo [1] Desktop only (quick scan)
echo [2] Desktop + Start Menu (recommended)
echo [3] All locations (comprehensive)
echo [4] Custom selection
echo.
set /p "scanChoice=Enter choice (1-4): "
echo.

rem Set scanning locations based on user choice
if "%scanChoice%"=="1" (
    set "scanLocations=%desktopPath%"
    set "locationNames=Desktop"
) else if "%scanChoice%"=="2" (
    set "scanLocations=%desktopPath%^|%startMenuPath%"
    set "locationNames=Desktop^|Start Menu"
) else if "%scanChoice%"=="3" (
    set "scanLocations=%desktopPath%^|%startMenuPath%^|%publicDesktopPath%^|%quickLaunchPath%"
    set "locationNames=Desktop^|Start Menu^|Public Desktop^|Quick Launch"
) else (
    rem Default to Desktop + Start Menu if invalid choice
    set "scanLocations=%desktopPath%^|%startMenuPath%"
    set "locationNames=Desktop^|Start Menu"
    echo Invalid choice, using default: Desktop + Start Menu
)

echo Locations to scan: %locationNames:^|=, %
echo Backup folder: %backupFolder%
echo.

rem Set the log file path to Documents folder for easy access
set "logFile=%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt"

rem Initialize counters to track our progress
set "totalShortcuts=0"
set "deletedShortcuts=0"
set "skippedShortcuts=0"
set "validShortcuts=0"

rem ===== CREATE/UPDATE LOG FILE =====
rem >> means "append to file" (add to the end without erasing existing content)
echo ======================================== >> "%logFile%"
echo Shortcut cleanup started at %date% %time% >> "%logFile%"
echo Scanning location: %desktopPath% >> "%logFile%"
echo ======================================== >> "%logFile%"

rem ===== PREVIEW MODE OPTION =====
echo.
echo Safety Options:
echo [Y] Move broken shortcuts to backup folder (SAFE - recommended)
echo [D] Delete broken shortcuts permanently (DANGER)
echo [P] Preview only - show what would be done (SAFE)
echo.
set /p "safetyChoice=Choose action (Y/D/P): "
echo.

if /i "%safetyChoice%"=="P" (
    set "previewMode=true"
    echo PREVIEW MODE: Will show what would be done without making changes
) else if /i "%safetyChoice%"=="D" (
    set "previewMode=false"
    set "deleteMode=true"
    echo WARNING: Will permanently delete broken shortcuts!
) else (
    set "previewMode=false"
    set "deleteMode=false"
    echo SAFE MODE: Will move broken shortcuts to backup folder
)
echo.

rem ===== COUNT TOTAL SHORTCUTS ACROSS ALL LOCATIONS =====
rem This gives us a total count so we can show progress (X of Y)
echo Counting shortcuts to scan...

rem Loop through each selected location and count shortcuts
for %%L in (%scanLocations%) do (
    set "currentLocation=%%L"
    if exist "!currentLocation!" (
        echo   Checking: !currentLocation!
        for /r "!currentLocation!" %%i in (*.lnk) do (
            set /a totalShortcuts+=1
        )
    )
)

echo.
echo Found !totalShortcuts! shortcuts to check across all locations
echo.
if !totalShortcuts! equ 0 (
    echo No shortcuts found in selected locations.
    echo Press any key to exit...
    pause >nul
    exit /b 0
)

if "%previewMode%"=="true" (
    echo Starting preview scan (no changes will be made)...
) else (
    echo Starting scan...
)
echo.

rem ===== MAIN SCANNING LOOP =====
rem This is the main loop that processes each shortcut file across all selected locations
rem We'll loop through each location, then through each shortcut in that location
set "currentShortcut=0"

rem Loop through each selected scanning location
for %%L in (%scanLocations%) do (
    set "currentLocation=%%L"
    if exist "!currentLocation!" (
        echo.
        echo === Scanning: !currentLocation! ===
        echo.
        
        rem Now scan all .lnk files in this location (recursively)
        for /r "!currentLocation!" %%i in (*.lnk) do (
    rem Count which shortcut we're processing (for progress display)
    set /a currentShortcut+=1
    
    rem Show progress to the user
    echo [!currentShortcut!/!totalShortcuts!] Checking: %%~nxi
    
    rem ===== GET THE SHORTCUT'S TARGET PATH =====
    rem We use PowerShell to read where the shortcut points to
    rem Clear the target path variable first
    set "targetPath="
    
    rem This PowerShell command reads the shortcut and tells us what file/folder it points to
    rem -NoProfile = faster startup, don't load user profile
    rem WScript.Shell = Windows COM object for reading shortcuts
    rem CreateShortcut = method to open and read .lnk files
    for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command ^
        "try { $sh = New-Object -ComObject WScript.Shell; $sc = $sh.CreateShortcut('%%i'); $sc.TargetPath } catch { 'ERROR' }"`) do (
        set "targetPath=%%t"
    )

    rem ===== DECIDE WHAT TO DO WITH THIS SHORTCUT =====
    rem Check if we successfully got a target path
    if defined targetPath (
        rem Check if the target path is an error or if the target actually exists
        if "!targetPath!"=="ERROR" (
            rem PowerShell failed to read the shortcut
            echo   [SKIP] Could not read shortcut properties
            echo Skipped (read error): %%~fi >> "%logFile%"
            set /a skippedShortcuts+=1
        ) else if not exist "!targetPath!" (
            rem The shortcut points to something that doesn't exist - HANDLE IT BASED ON MODE
            if "%previewMode%"=="true" (
                rem PREVIEW MODE: Just show what would be done
                echo   [PREVIEW] Would remove: Target missing: !targetPath!
                echo Preview - would process: %%~fi >> "%logFile%"
                echo   Target was: !targetPath! >> "%logFile%"
                set /a deletedShortcuts+=1
            ) else if "%deleteMode%"=="true" (
                rem DELETE MODE: Permanently delete (dangerous)
                echo   [DELETE] Target missing: !targetPath!
                echo Deleting invalid shortcut: %%~fi >> "%logFile%"
                echo   Target was: !targetPath! >> "%logFile%"
                del /f "%%~fi" 2>nul
                if !errorlevel! equ 0 (
                    set /a deletedShortcuts+=1
                ) else (
                    echo   [ERROR] Could not delete file
                    echo Failed to delete: %%~fi >> "%logFile%"
                    set /a skippedShortcuts+=1
                )
            ) else (
                rem SAFE MODE: Move to backup folder (recommended)
                echo   [BACKUP] Target missing: !targetPath!
                echo Moving invalid shortcut to backup: %%~fi >> "%logFile%"
                echo   Target was: !targetPath! >> "%logFile%"
                
                rem Create timestamped filename to avoid conflicts
                for /f "tokens=1-3 delims=/:" %%a in ("%date%") do set "dateStr=%%c-%%a-%%b"
                for /f "tokens=1-2 delims=:." %%a in ("%time%") do set "timeStr=%%a-%%b"
                set "backupName=!dateStr!_!timeStr!_%%~nxi"
                
                rem Move the shortcut to backup folder
                move "%%~fi" "%backupFolder%\!backupName!" >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   [SUCCESS] Moved to: !backupName!
                    echo Successfully moved to backup: !backupName! >> "%logFile%"
                    set /a deletedShortcuts+=1
                ) else (
                    echo   [ERROR] Could not move file
                    echo Failed to move: %%~fi >> "%logFile%"
                    set /a skippedShortcuts+=1
                )
            )
        ) else (
            rem The shortcut is valid (target exists)
            echo   [OK] Valid shortcut
            echo Valid shortcut: %%~fi >> "%logFile%"
            set /a validShortcuts+=1
        )
    ) else (
        rem The shortcut has no target path (empty or broken shortcut)
        echo   [SKIP] No target path found
        echo Skipped (no target): %%~fi >> "%logFile%"
        set /a skippedShortcuts+=1
    )
        )
    ) else (
        echo Location not found: !currentLocation!
        echo Location not accessible: !currentLocation! >> "%logFile%"
    )
)
)

rem ===== SCANNING COMPLETE - SHOW RESULTS =====
echo.
echo ========================================
echo           SCAN COMPLETE!
echo ========================================
echo.

rem ===== DISPLAY STATISTICS TO USER =====
echo RESULTS SUMMARY:
echo ===============
echo Locations scanned:     %locationNames:^|=, %
echo Total shortcuts found: !totalShortcuts!
echo Valid shortcuts:       !validShortcuts!
if "%previewMode%"=="true" (
    echo Would be processed:    !deletedShortcuts!
) else if "%deleteMode%"=="true" (
    echo Deleted shortcuts:     !deletedShortcuts!
) else (
    echo Moved to backup:       !deletedShortcuts!
)
echo Skipped shortcuts:     !skippedShortcuts!
echo.

rem ===== WRITE SUMMARY TO LOG FILE =====
echo. >> "%logFile%"
echo ======================================== >> "%logFile%"
echo Shortcut cleanup completed at %date% %time% >> "%logFile%"
echo. >> "%logFile%"
echo FINAL STATISTICS: >> "%logFile%"
echo Locations scanned: %locationNames:^|=, % >> "%logFile%"
echo Total shortcuts scanned: !totalShortcuts! >> "%logFile%"
echo Valid shortcuts found: !validShortcuts! >> "%logFile%"
if "%previewMode%"=="true" (
    echo Shortcuts that would be processed: !deletedShortcuts! >> "%logFile%"
    echo Mode: PREVIEW ONLY >> "%logFile%"
) else if "%deleteMode%"=="true" (
    echo Invalid shortcuts deleted: !deletedShortcuts! >> "%logFile%"
    echo Mode: DELETE >> "%logFile%"
) else (
    echo Invalid shortcuts moved to backup: !deletedShortcuts! >> "%logFile%"
    echo Mode: SAFE BACKUP >> "%logFile%"
    echo Backup location: %backupFolder% >> "%logFile%"
)
echo Shortcuts skipped: !skippedShortcuts! >> "%logFile%"
echo ======================================== >> "%logFile%"

rem ===== SHOW USER WHERE TO FIND DETAILED LOG =====
if !deletedShortcuts! gtr 0 (
    if "%previewMode%"=="true" (
        echo PREVIEW COMPLETE: Found !deletedShortcuts! broken shortcut(s) that would be processed
        echo Run again without preview mode to actually process them.
    ) else if "%deleteMode%"=="true" (
        echo SUCCESS: Permanently deleted !deletedShortcuts! broken shortcut(s)
    ) else (
        echo SUCCESS: Moved !deletedShortcuts! broken shortcut(s) to backup folder
        echo Backup location: %backupFolder%
    )
    echo.
) else (
    echo No broken shortcuts found - your system is clean!
    echo.
)

echo Detailed log saved to:
echo %logFile%
echo.
echo You can review this log file to see exactly what was processed.
echo.
echo ========================================
echo Press any key to exit...
pause >nul
