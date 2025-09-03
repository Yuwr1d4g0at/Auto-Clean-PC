@echo off
setlocal enabledelayedexpansion

rem Log file path
set "logFile=%~dp0TempCleanupLog.txt"
echo Temp cleanup started at %date% %time% > "%logFile%"

rem Function to delete contents of a folder and log, skipping locked files
:CleanFolder
set "folder=%~1"
if exist "%folder%" (
    echo Cleaning %folder% >> "%logFile%"
    echo Deleting files...
    for /f "delims=" %%f in ('dir /b /s /a:-d "%folder%"') do (
        del /f /q "%%f" 2>nul
        if errorlevel 1 (
            echo Skipped locked file: %%f >> "%logFile%"
        ) else (
            echo Deleted file: %%f >> "%logFile%"
        )
    )

    echo Deleting folders...
    for /f "delims=" %%d in ('dir /b /s /a:d "%folder%" ^| sort /r') do (
        rmdir /s /q "%%d" 2>nul
        if errorlevel 1 (
            echo Skipped locked folder: %%d >> "%logFile%"
        ) else (
            echo Deleted folder: %%d >> "%logFile%"
        )
    )
) else (
    echo Folder not found: %folder% >> "%logFile%"
)
goto :eof

rem Clean user temp folder
call :CleanFolder "%temp%"

rem Clean Windows temp folder (requires admin)
call :CleanFolder "C:\Windows\Temp"

rem Clean Windows Update download cache (requires admin)
call :CleanFolder "C:\Windows\SoftwareDistribution\Download"

echo Temp cleanup completed at %date% %time% >> "%logFile%"

echo Temp cleanup done. See the log file at:
echo %logFile%
pause
