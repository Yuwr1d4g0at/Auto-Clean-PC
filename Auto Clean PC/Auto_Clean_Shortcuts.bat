@echo off
setlocal enabledelayedexpansion

rem Get the current user's desktop path
set "desktopPath=%USERPROFILE%\Desktop"

rem Set the log file path to Documents
set "logFile=%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt"

rem Append log header with date and time
>> "%logFile%" echo ----------------------------------------
>> "%logFile%" echo Deletion log - %date% %time%
>> "%logFile%" echo ----------------------------------------

rem Loop through all shortcut (.lnk) files in the desktopPath and its subfolders
for /r "%desktopPath%" %%i in (*.lnk) do (
    rem Use PowerShell to get target path of the shortcut
    set "targetPath="
    for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command ^
        "$sh = New-Object -ComObject WScript.Shell; $sc = $sh.CreateShortcut('%%i'); $sc.TargetPath"`) do (
        set "targetPath=%%t"
    )

    rem Check if targetPath is not empty and does not exist
    if defined targetPath (
        if not exist "!targetPath!" (
            rem Log deleted shortcut
            echo Deleting invalid shortcut: %%~fi >> "%logFile%"
            rem Delete the shortcut (Use quotes for safety)
            del /f "%%~fi"
        )
    ) else (
        rem Log shortcut with no target path
        echo Skipped (no target): %%~fi >> "%logFile%"
    )
)

echo Scan and deletion complete. See log file:
echo %logFile%
pause
