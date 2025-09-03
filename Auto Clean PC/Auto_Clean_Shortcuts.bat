@echo off
setlocal enabledelayedexpansion

rem Set the desktop path to scan
set "desktopPath=C:\Users\Rodri\OneDrive\Ambiente de Trabalho"

rem Set the file for the log output
set "logFile=DeletedInvalidShortcutsLog.txt"

rem Append log header with date and time
>> "%logFile%" echo ----------------------------------------
>> "%logFile%" echo Deletion log - %date% %time%
>> "%logFile%" echo ----------------------------------------

rem Loop through all shortcut (.lnk) files in the desktopPath and its subfolders
for /r "%desktopPath%" %%i in (*.lnk) do (
    rem Use PowerShell to get target path of the shortcut
    for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command ^
        "$sh = New-Object -ComObject WScript.Shell; $sc = $sh.CreateShortcut('%%i'); $sc.TargetPath"`) do (
        set "targetPath=%%t"
    )

    rem Check if targetPath exists (file or folder)
    if not exist "!targetPath!" (
        rem Log deleted shortcut
        echo Deleting invalid shortcut: %%~fi >> "%logFile%"
        rem Delete the shortcut
        del /f "%%~fi"
    )
)

echo Scan and deletion complete. See log file:
echo %logFile%
pause