rem ===== BASIC SETUP =====
rem This turns off the display of each command as it runs (keeps output clean)
@echo off
rem This allows us to use variables that change inside loops and if statements
setlocal enabledelayedexpansion

rem ===== CHECK IF WE'RE RUNNING AS ADMIN =====
rem Try to run a command that only admins can do (net session)
rem >nul 2>&1 means "hide all output and errors"
net session >nul 2>&1
rem Check if the last command worked (errorlevel 0 = success)
if %errorlevel% == 0 (
    rem We are admin - set a flag to remember this
    set "isAdmin=true"
    echo Running with administrator privileges
) else (
    rem We are NOT admin - set flag and warn user
    set "isAdmin=false"
    echo Running with standard user privileges
    echo Some cleanup operations will be skipped
)

rem ===== CREATE A LOG FILE TO RECORD EVERYTHING WE DO =====
rem %~dp0 means "the folder where this script is located"
rem We create a file called TempCleanupLog_Simple.txt in the same folder
set "logFile=%~dp0TempCleanupLog_Simple.txt"
rem > means "create new file and write this" (overwrites existing file)
echo ======================================== > "%logFile%"
rem >> means "add this to the end of the file" (doesn't overwrite)
echo Temp cleanup started at %date% %time% >> "%logFile%"
echo Administrator privileges: %isAdmin% >> "%logFile%"
echo ======================================== >> "%logFile%"

rem ===== SHOW USER WE'RE STARTING =====
rem echo. means "print a blank line" (for spacing)
echo.
echo Starting cleanup operations...
echo.

rem ===== CLEAN ALL THE DIFFERENT TEMP FOLDERS =====
rem call :CleanFolder means "jump to the CleanFolder function below"
rem We pass 3 things: folder path, display name, and if it needs admin rights

rem Clean the current user's temp folder (doesn't need admin)
rem %temp% is a Windows variable that points to user's temp folder
call :CleanFolder "%temp%" "User temp folder" "false"

rem Clean Windows system temp folder (needs admin rights)
call :CleanFolder "C:\Windows\Temp" "Windows temp folder" "true"

rem Clean Windows Update download cache (needs admin rights)
call :CleanFolder "C:\Windows\SoftwareDistribution\Download" "Windows Update cache" "true"

rem Clean Internet Explorer cache (doesn't need admin)
rem %LOCALAPPDATA% is a Windows variable pointing to user's local app data
call :CleanFolder "%LOCALAPPDATA%\Microsoft\Windows\INetCache" "IE cache" "false"

rem Clean Windows Error Reporting files (needs admin rights)
call :CleanFolder "C:\ProgramData\Microsoft\Windows\WER" "Windows Error Reporting" "true"

rem Clean Google Chrome cache (doesn't need admin)
call :CleanFolder "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" "Chrome cache" "false"

rem Clean Microsoft Edge cache (doesn't need admin)
call :CleanFolder "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" "Edge cache" "false"

rem ===== CLEAN OLD WINDOWS LOG FILES =====
rem We only delete log files older than 7 days (to keep recent ones for troubleshooting)
echo [LOGS] Windows Logs
rem Check if we have admin rights (only admins can delete system logs)
if "%isAdmin%"=="true" (
    rem forfiles finds files: /p = path, /s = search subfolders, /m = match pattern
    rem /d -7 = older than 7 days, /c = command to run on each file
    rem 2>nul means "hide any errors"
    forfiles /p "C:\Windows\Logs" /s /m *.log /d -7 /c "cmd /c del @path" 2>nul
    echo Deleted log files older than 7 days >> "%logFile%"
    echo   Cleaned old log files
) else (
    rem We don't have admin rights, so skip this step
    echo Skipping Windows Logs - requires administrator privileges >> "%logFile%"
    echo   [ADMIN REQUIRED] Windows Logs
)

rem ===== EMPTY THE RECYCLE BIN =====
rem This deletes everything in the recycle bin permanently
echo [RECYCLE] Recycle bin
rem Check if we have admin rights (needed for system-wide recycle bin)
if "%isAdmin%"=="true" (
    rem rd = remove directory, /s = remove all files/subfolders, /q = quiet (no prompts)
    rem C:\$Recycle.Bin is where Windows stores deleted files
    rem 2>nul means "hide any errors"
    rd /s /q C:\$Recycle.Bin 2>nul
    echo Emptied system recycle bin >> "%logFile%"
    echo   Cleaned system recycle bin
) else (
    rem We don't have admin rights, so skip this step
    echo Skipping system recycle bin - requires administrator privileges >> "%logFile%"
    echo   [ADMIN REQUIRED] System Recycle Bin
)

rem ===== FINISH UP THE LOG FILE =====
rem Write the end time to the log file so we know when it finished
echo ======================================== >> "%logFile%"
echo Temp cleanup completed at %date% %time% >> "%logFile%"
echo ======================================== >> "%logFile%"

rem ===== TELL THE USER WE'RE DONE =====
echo.
echo ======================================== 
echo Cleanup completed!
echo ======================================== 
echo.
rem Show them where to find the detailed log file
echo Log file saved to:
echo %logFile%
echo.
rem If we weren't running as admin, remind them what they missed
if "%isAdmin%"=="false" (
    echo NOTE: Some operations were skipped due to insufficient privileges.
    echo Run as Administrator for complete system cleanup.
    echo.
)
rem Wait for user to press a key before closing the window
echo Press any key to exit...
rem pause >nul means "wait for keypress but don't show 'Press any key' message"
pause >nul
rem goto :eof means "end the main script here" (don't continue to the function below)
goto :eof

rem ===== FUNCTION: CleanFolder =====
rem This is a reusable function that cleans any folder we give it
rem Functions in batch files start with a colon (:) label
:CleanFolder
rem Get the 3 pieces of information passed to this function:
rem %~1 = first parameter (folder path)
rem %~2 = second parameter (display name)
rem %~3 = third parameter ("true" if needs admin, "false" if not)
set "folder=%~1"
set "name=%~2"
set "requiresAdmin=%~3"
rem Set up counters to track how many files we delete/skip
set "deletedFiles=0"
set "skippedFiles=0"

rem Show the user what we're working on
echo [CLEAN] %name%

rem ===== CHECK IF THE FOLDER EVEN EXISTS =====
if not exist "%folder%" (
    rem The folder doesn't exist, so log it and exit this function
    echo Folder not found: %folder% >> "%logFile%"
    echo   [NOT FOUND] %folder%
    rem goto :eof means "exit this function and go back to where we were called from"
    goto :eof
)

rem ===== CHECK IF WE HAVE PERMISSION TO CLEAN THIS FOLDER =====
rem If this folder needs admin rights AND we don't have them, skip it
if "%requiresAdmin%"=="true" if "%isAdmin%"=="false" (
    echo Skipping %folder% - requires administrator privileges >> "%logFile%"
    echo   [ADMIN REQUIRED] %folder%
    goto :eof
)

rem ===== START CLEANING THE FOLDER =====
rem Log what we're doing and show progress to user
echo Cleaning %name% (%folder%) >> "%logFile%"
echo   Processing %folder%...

rem ===== DELETE ALL FILES IN THE MAIN FOLDER =====
rem This loop goes through each file in the folder (but not subfolders)
rem for %%f in ("path\*.*") means "for each file matching any name"
for %%f in ("%folder%\*.*") do (
    rem Try to delete this file:
    rem del = delete, /f = force (even read-only), /q = quiet (no prompts)
    rem 2>nul = hide any error messages
    del /f /q "%%f" 2>nul
    rem Check if the delete worked (errorlevel 0 = success)
    rem We use !errorlevel! instead of %errorlevel% because we're inside a loop
    if !errorlevel! equ 0 (
        rem File was deleted successfully, add 1 to our counter
        rem set /a means "do math" - we're adding 1 to deletedFiles
        set /a deletedFiles+=1
    ) else (
        rem File couldn't be deleted (probably in use), count it as skipped
        set /a skippedFiles+=1
        rem Log which file we couldn't delete
        echo Skipped: %%f >> "%logFile%"
    )
)

rem ===== DELETE ALL SUBFOLDERS =====
rem This loop goes through each subfolder in the main folder
rem for /d %%d means "for each directory (folder)"
for /d %%d in ("%folder%\*") do (
    rem Try to delete this entire folder and everything inside it:
    rem rd = remove directory, /s = delete all contents, /q = quiet (no prompts)
    rem 2>nul = hide any error messages
    rd /s /q "%%d" 2>nul
    rem Check if the folder deletion worked
    if !errorlevel! equ 0 (
        rem Folder was deleted, add to our counter (we add 5 to estimate multiple files)
        set /a deletedFiles+=5
    ) else (
        rem Folder couldn't be deleted (probably has files in use)
        rem Log which folder we couldn't delete
        echo Skipped folder: %%d >> "%logFile%"
    )
)

rem ===== SHOW THE USER WHAT WE ACCOMPLISHED =====
rem Tell them how many files we processed and how many we had to skip
echo   Files processed: !deletedFiles!, Skipped: !skippedFiles!

rem ===== WRITE A SUMMARY TO THE LOG FILE =====
rem This creates a permanent record of what we did in this folder
echo Summary for %name%: >> "%logFile%"
echo   Files processed: !deletedFiles! >> "%logFile%"
echo   Files skipped: !skippedFiles! >> "%logFile%"
rem Add a blank line to separate this folder's results from the next one
echo. >> "%logFile%"

rem ===== END OF FUNCTION =====
rem This returns us back to wherever this function was called from
goto :eof
