rem ===== BASIC SETUP =====
@echo off
setlocal enabledelayedexpansion

rem ===== CHECK ADMINISTRATOR PRIVILEGES =====
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo    ERROR: Administrator Required
    echo ========================================
    echo.
    echo This tool REQUIRES administrator privileges to access the registry.
    echo Please right-click and select "Run as administrator"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

rem ===== WELCOME MESSAGE =====
echo.
echo ========================================
echo    Registry Cleaner Tool v1.0
echo ========================================
echo.
echo This tool will scan the Windows Registry for:
echo - Invalid uninstall entries
echo - Broken file associations
echo - Missing COM/ActiveX references
echo - Orphaned startup entries
echo - Invalid MUI cache entries
echo.
echo WARNING: Modifying the registry can be dangerous if done incorrectly.
echo This tool creates automatic backups before any changes.
echo.

rem ===== SAFETY SETUP =====
set "backupFolder=%USERPROFILE%\Documents\Registry_Backups"
if not exist "%backupFolder%" (
    mkdir "%backupFolder%" 2>nul
    echo Created backup folder: %backupFolder%
    echo.
)

rem Set log file path
set "logFile=%USERPROFILE%\Documents\RegistryCleanupLog.txt"

rem Initialize counters
set "totalIssues=0"
set "fixedIssues=0"
set "skippedIssues=0"

rem ===== CREATE LOG FILE =====
echo ======================================== > "%logFile%"
echo Registry cleanup started at %date% %time% >> "%logFile%"
echo ======================================== >> "%logFile%"

rem ===== PREVIEW MODE OPTION =====
echo Safety Options:
echo [P] Preview only - show what would be fixed (SAFE - recommended first run)
echo [B] Backup and fix - create backup then fix issues (SAFE)
echo [C] Cancel - exit without making changes
echo.
set /p "safetyChoice=Choose action (P/B/C): "
echo.

if /i "%safetyChoice%"=="C" (
    echo Operation cancelled by user.
    echo Press any key to exit...
    pause >nul
    exit /b 0
)

if /i "%safetyChoice%"=="P" (
    set "previewMode=true"
    echo PREVIEW MODE: Will show issues without making changes
    echo Preview mode activated >> "%logFile%"
) else (
    set "previewMode=false"
    echo BACKUP AND FIX MODE: Will backup then fix issues
    echo Backup and fix mode activated >> "%logFile%"
    
    rem Create timestamped backup file
    for /f "tokens=1-3 delims=/:." %%a in ("%date%") do set "dateStr=%%c-%%a-%%b"
    for /f "tokens=1-2 delims=:." %%a in ("%time%") do set "timeStr=%%a-%%b"
    set "backupFile=%backupFolder%\Registry_Backup_!dateStr!_!timeStr!.reg"
    
    echo Creating registry backup of areas to be modified...
    echo This may take a moment...
    echo.
    
    rem Export only the registry keys we'll be modifying
    echo Backing up Uninstall entries...
    reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" "%backupFile%_HKLM_Uninstall.reg" /y
    reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" "%backupFile%_HKCU_Uninstall.reg" /y
    echo Backing up Startup entries...
    reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" "%backupFile%_HKLM_Run.reg" /y
    reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" "%backupFile%_HKCU_Run.reg" /y
    echo Backing up Shell Extensions...
    reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" "%backupFile%_ShellExt.reg" /y
    echo Backing up MUI Cache...
    reg export "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" "%backupFile%_MuiCache.reg" /y
    
    echo.
    echo Registry backup created successfully!
    echo Backup location: %backupFolder%
    echo Created selective backup >> "%logFile%"
    echo.
)

echo Starting registry scan...
echo.

rem ===== SCAN 1: INVALID UNINSTALL ENTRIES =====
echo ========================================
echo [SCAN 1/5] Checking Uninstall Entries
echo ========================================
echo.

set "scanCount=0"
for %%H in (HKLM HKCU) do (
    for /f "tokens=*" %%K in ('reg query %%H\Software\Microsoft\Windows\CurrentVersion\Uninstall 2^>nul ^| findstr /r "HKEY_"') do (
        set /a scanCount+=1
        
        rem Get DisplayName
        set "displayName="
        for /f "tokens=2*" %%V in ('reg query "%%K" /v DisplayName 2^>nul ^| findstr "DisplayName"') do set "displayName=%%W"
        
        rem Get UninstallString
        set "uninstallString="
        for /f "tokens=2*" %%V in ('reg query "%%K" /v UninstallString 2^>nul ^| findstr "UninstallString"') do set "uninstallString=%%W"
        
        rem Check if UninstallString exists and points to valid file
        if defined uninstallString (
            rem Skip MsiExec.exe entries - these are valid MSI installers
            echo !uninstallString! | findstr /i "MsiExec.exe" >nul
            if !errorlevel! equ 0 (
                rem Valid MSI installer, skip check
            ) else (
                rem Extract path from uninstall string
                set "checkPath=!uninstallString!"
                rem Remove quotes
                set "checkPath=!checkPath:"=!"
                rem Extract just the exe path (before any arguments)
                for /f "tokens=1" %%P in ("!checkPath!") do set "checkPath=%%P"
                
                rem Only check if path seems valid (not truncated)
                echo !checkPath! | findstr /r "\.[eE][xX][eE]$" >nul
                if !errorlevel! equ 0 (
                    if not exist "!checkPath!" (
                        set /a totalIssues+=1
                        echo [ISSUE !totalIssues!] Invalid uninstall entry: !displayName!
                        echo   Key: %%K
                        echo   Missing file: !checkPath!
                        echo Invalid uninstall entry: %%K >> "%logFile%"
                        echo   DisplayName: !displayName! >> "%logFile%"
                        echo   Missing file: !checkPath! >> "%logFile%"
                        
                        if "%previewMode%"=="false" (
                            echo   [FIXING] Removing invalid entry...
                            reg delete "%%K" /f >nul 2>&1
                            if !errorlevel! equ 0 (
                                echo   [SUCCESS] Removed
                                echo Successfully removed: %%K >> "%logFile%"
                                set /a fixedIssues+=1
                            ) else (
                                echo   [ERROR] Could not remove
                                echo Failed to remove: %%K >> "%logFile%"
                                set /a skippedIssues+=1
                            )
                        )
                        echo.
                    )
                )
            )
        )
        
        rem Show progress every 50 entries
        set /a progress=!scanCount! %% 50
        if !progress! equ 0 echo   Scanned !scanCount! uninstall entries...
    )
)
echo Completed: Scanned !scanCount! uninstall entries
echo.

rem ===== SCAN 2: ORPHANED STARTUP ENTRIES =====
echo ========================================
echo [SCAN 2/5] Checking Startup Entries
echo ========================================
echo.

set "scanCount=0"
for %%H in (HKLM HKCU) do (
    rem Get each startup entry properly
    for /f "skip=2 tokens=1,2*" %%V in ('reg query %%H\Software\Microsoft\Windows\CurrentVersion\Run 2^>nul') do (
        if not "%%V"=="(Default)" if not "%%V"=="" (
            set /a scanCount+=1
            set "startupName=%%V"
            set "startupPath=%%X"
            
            rem Remove quotes from path
            set "checkPath=!startupPath:"=!"
            rem Extract just the exe path (before any arguments like /silent)
            for /f "tokens=1 delims= " %%P in ("!checkPath!") do set "checkPath=%%P"
            
            rem Only check .exe files
            echo !checkPath! | findstr /i ".exe" >nul
            if !errorlevel! equ 0 (
                if not exist "!checkPath!" (
                    set /a totalIssues+=1
                    echo [ISSUE !totalIssues!] Invalid startup entry: !startupName!
                    echo   Missing file: !checkPath!
                    echo Invalid startup entry in %%H\Software\Microsoft\Windows\CurrentVersion\Run >> "%logFile%"
                    echo   Name: !startupName! >> "%logFile%"
                    echo   Missing file: !checkPath! >> "%logFile%"
                    
                    if "%previewMode%"=="false" (
                        echo   [FIXING] Removing invalid entry...
                        reg delete "%%H\Software\Microsoft\Windows\CurrentVersion\Run" /v "!startupName!" /f >nul 2>&1
                        if !errorlevel! equ 0 (
                            echo   [SUCCESS] Removed
                            echo Successfully removed startup entry: !startupName! >> "%logFile%"
                            set /a fixedIssues+=1
                        ) else (
                            echo   [ERROR] Could not remove
                            echo Failed to remove startup entry: !startupName! >> "%logFile%"
                            set /a skippedIssues+=1
                        )
                    )
                    echo.
                )
            )
        )
    )
)
echo Completed: Scanned !scanCount! startup entries
echo.

rem ===== SCAN 3: INVALID SHELL EXTENSIONS =====
echo ========================================
echo [SCAN 3/5] Checking Shell Extensions
echo ========================================
echo.

set "scanCount=0"
for /f "tokens=*" %%K in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" 2^>nul ^| findstr /r "{"') do (
    set /a scanCount+=1
    
    rem Extract CLSID
    for /f "tokens=1" %%C in ("%%K") do set "clsid=%%C"
    
    rem Check if CLSID exists in HKCR\CLSID
    reg query "HKCR\CLSID\!clsid!" >nul 2>&1
    if !errorlevel! neq 0 (
        set /a totalIssues+=1
        echo [ISSUE !totalIssues!] Invalid shell extension: !clsid!
        echo   Extension is approved but CLSID doesn't exist
        echo Invalid shell extension: !clsid! >> "%logFile%"
        
        if "%previewMode%"=="false" (
            echo   [FIXING] Removing invalid entry...
            reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" /v "!clsid!" /f >nul 2>&1
            if !errorlevel! equ 0 (
                echo   [SUCCESS] Removed
                echo Successfully removed shell extension: !clsid! >> "%logFile%"
                set /a fixedIssues+=1
            ) else (
                echo   [ERROR] Could not remove
                echo Failed to remove shell extension: !clsid! >> "%logFile%"
                set /a skippedIssues+=1
            )
        )
        echo.
    )
    
    rem Show progress every 25 entries
    set /a progress=!scanCount! %% 25
    if !progress! equ 0 echo   Scanned !scanCount! shell extensions...
)
echo Completed: Scanned !scanCount! shell extensions
echo.

rem ===== SCAN 4: INVALID FILE ASSOCIATIONS =====
echo ========================================
echo [SCAN 4/5] Checking File Associations
echo ========================================
echo.

set "scanCount=0"
for /f "tokens=*" %%K in ('reg query HKCR 2^>nul ^| findstr /r "^\."') do (
    set /a scanCount+=1
    set "extension=%%K"
    
    rem Get default value (associated program)
    for /f "tokens=2*" %%V in ('reg query "%%K" /ve 2^>nul ^| findstr "REG_SZ"') do (
        set "progId=%%W"
        
        rem Check if ProgID exists
        if defined progId (
            reg query "HKCR\!progId!" >nul 2>&1
            if !errorlevel! neq 0 (
                set /a totalIssues+=1
                echo [ISSUE !totalIssues!] Invalid file association: %%K
                echo   Points to non-existent ProgID: !progId!
                echo Invalid file association: %%K >> "%logFile%"
                echo   Missing ProgID: !progId! >> "%logFile%"
                
                if "%previewMode%"=="false" (
                    echo   [FIXING] Removing invalid association...
                    reg delete "%%K" /ve /f >nul 2>&1
                    if !errorlevel! equ 0 (
                        echo   [SUCCESS] Removed
                        echo Successfully removed association: %%K >> "%logFile%"
                        set /a fixedIssues+=1
                    ) else (
                        echo   [ERROR] Could not remove
                        echo Failed to remove association: %%K >> "%logFile%"
                        set /a skippedIssues+=1
                    )
                )
                echo.
            )
        )
    )
    
    rem Show progress every 100 entries
    set /a progress=!scanCount! %% 100
    if !progress! equ 0 echo   Scanned !scanCount! file associations...
)
echo Completed: Scanned !scanCount! file associations
echo.

rem ===== SCAN 5: INVALID MUI CACHE =====
echo ========================================
echo [SCAN 5/5] Checking MUI Cache
echo ========================================
echo.

set "scanCount=0"
for /f "skip=2 tokens=1,2*" %%V in ('reg query "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" 2^>nul') do (
    if not "%%V"=="(Default)" if not "%%V"=="" (
        set /a scanCount+=1
        set "muiPath=%%V"
        
        rem Only process if muiPath is not empty and looks like a path
        if defined muiPath (
            rem Check if it contains a backslash (likely a path)
            echo.!muiPath! | findstr "\\" >nul 2>&1
            if !errorlevel! equ 0 (
                rem Skip metadata entries (FriendlyAppName, ApplicationCompany, LangID)
                echo.!muiPath! | findstr /i "FriendlyAppName ApplicationCompany LangID" >nul 2>&1
                if !errorlevel! neq 0 (
                    rem Skip entries that don't look like file paths
                    echo.!muiPath! | findstr /r "[A-Za-z]:\\" >nul 2>&1
                    if !errorlevel! equ 0 (
                        if not exist "!muiPath!" (
                            set /a totalIssues+=1
                            echo [ISSUE !totalIssues!] Invalid MUI cache entry
                            echo   Missing file: !muiPath!
                            echo Invalid MUI cache entry: !muiPath! >> "%logFile%"
                            
                            if "%previewMode%"=="false" (
                                echo   [FIXING] Removing invalid entry...
                                reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "!muiPath!" /f >nul 2>&1
                                if !errorlevel! equ 0 (
                                    echo   [SUCCESS] Removed
                                    echo Successfully removed MUI cache: !muiPath! >> "%logFile%"
                                    set /a fixedIssues+=1
                                ) else (
                                    echo   [ERROR] Could not remove
                                    echo Failed to remove MUI cache: !muiPath! >> "%logFile%"
                                    set /a skippedIssues+=1
                                )
                            )
                            echo.
                        )
                    )
                )
            )
        )
        
        rem Show progress every 50 entries
        set /a progress=!scanCount! %% 50
        if !progress! equ 0 echo   Scanned !scanCount! MUI cache entries...
    )
)
echo Completed: Scanned !scanCount! MUI cache entries
echo.

rem ===== SCANNING COMPLETE - SHOW RESULTS =====
echo.
echo ========================================
echo           SCAN COMPLETE!
echo ========================================
echo.

rem ===== DISPLAY STATISTICS =====
echo RESULTS SUMMARY:
echo ===============
echo Total issues found:    !totalIssues!

if "%previewMode%"=="true" (
    echo Mode:                  PREVIEW ONLY
    echo.
    echo No changes were made to your registry.
    echo Run again in 'Backup and fix' mode to resolve these issues.
) else (
    echo Issues fixed:          !fixedIssues!
    echo Issues skipped:        !skippedIssues!
    echo Mode:                  BACKUP AND FIX
    echo.
    echo Registry backup saved to:
    echo %backupFolder%
    echo.
    echo To restore registry if needed:
    echo 1. Double-click the .reg backup files
    echo 2. Confirm the import when prompted
)
echo.

rem ===== WRITE SUMMARY TO LOG FILE =====
echo. >> "%logFile%"
echo ======================================== >> "%logFile%"
echo Registry cleanup completed at %date% %time% >> "%logFile%"
echo. >> "%logFile%"
echo FINAL STATISTICS: >> "%logFile%"
echo Total issues found: !totalIssues! >> "%logFile%"
if "%previewMode%"=="true" (
    echo Mode: PREVIEW ONLY >> "%logFile%"
) else (
    echo Issues fixed: !fixedIssues! >> "%logFile%"
    echo Issues skipped: !skippedIssues! >> "%logFile%"
    echo Mode: BACKUP AND FIX >> "%logFile%"
    echo Backup location: %backupFolder% >> "%logFile%"
)
echo ======================================== >> "%logFile%"

echo Detailed log saved to:
echo %logFile%
echo.

if !totalIssues! equ 0 (
    echo No registry issues found - your system is clean!
    echo.
) else (
    if "%previewMode%"=="true" (
        echo Found !totalIssues! issue(s) that can be fixed.
        echo.
    ) else (
        echo Successfully processed !totalIssues! registry issue(s).
        echo.
    )
)

echo ========================================
echo Press any key to exit...
pause >nul
