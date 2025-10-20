# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Auto-Clean-PC is a Windows system maintenance utility collection consisting of batch scripts designed to clean and optimize Windows 11 systems. The project focuses on automating common cleanup tasks such as removing invalid desktop shortcuts and clearing temporary files.

## Architecture

### Core Components

- **Auto_Clean_Shortcuts.bat**: Advanced multi-location shortcut validator and cleaner v2.0
  - Scans 4+ locations: Desktop, Start Menu, Public Desktop, Quick Launch
  - Interactive user interface with location and safety mode selection
  - Three safety modes: Preview (safe), Backup (recommended), Delete (advanced)
  - Smart backup system with timestamped files in Documents/Deleted_Shortcuts_Backup
  - Uses PowerShell COM objects with enhanced error handling (try/catch blocks)
  - Progress tracking with real-time feedback and statistics
  - Comprehensive logging with mode tracking and multi-location coverage

- **Delete_Temp_Folders.bat**: System temporary file cleaner with comprehensive comments
  - Cleans user temp directory (%temp%) and browser caches
  - Cleans Windows system temp (C:\Windows\Temp) - requires admin
  - Cleans Windows Update cache (C:\Windows\SoftwareDistribution\Download) - requires admin
  - Cleans old Windows log files (7+ days) and recycle bin - requires admin
  - Implements safe deletion with error handling for locked files
  - Detailed beginner-friendly comments explaining every code block
  - Progress indicators and statistics reporting
  - Creates timestamped log files with comprehensive operation tracking

### Logging Strategy

Both scripts implement comprehensive logging with enhanced features:
- **Auto_Clean_Shortcuts.bat**: 
  - Main log: `%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt`
  - Backup folder: `%USERPROFILE%\Documents\Deleted_Shortcuts_Backup`
  - Mode tracking (Preview/Backup/Delete) for audit compliance
  - Multi-location result tracking with per-location statistics
- **Delete_Temp_Folders.bat**: 
  - Logs to `TempCleanupLog_Simple.txt` in script directory
  - Detailed beginner-friendly comments throughout code
  - Progress indicators and real-time user feedback
- **Common features**: Timestamps, operation results, error handling for locked/inaccessible files, statistics tracking

### Permission Model

Scripts are designed to work with standard user permissions where possible, with enhanced safety features:

**Auto_Clean_Shortcuts.bat (Standard permissions):**
- Desktop, Start Menu, Quick Launch: Standard permissions
- Public Desktop access: Standard permissions (read-only locations)
- Backup folder creation/management: Standard permissions
- All safety modes available without elevation

**Delete_Temp_Folders.bat (Mixed permissions):**
- User temp cleanup: Standard permissions
- Browser cache cleanup: Standard permissions  
- System temp cleanup: Admin required
- Windows Update cache: Admin required
- Windows logs and recycle bin: Admin required

## Development Commands

### Testing Scripts
```powershell
# Test shortcut cleaner with built-in preview mode
.\Auto_Clean_Shortcuts.bat
# Choose [P] for Preview mode when prompted - shows what would be done
# Choose location option [1] for Desktop only during testing

# Test temp cleaner (comprehensive logging)
.\Delete_Temp_Folders.bat
# View real-time progress and detailed statistics
```

### Running Scripts
```powershell
# Navigate to script directory
cd "Auto Clean PC"

# Run enhanced shortcut cleaner (interactive interface)
.\Auto_Clean_Shortcuts.bat
# Interactive prompts will guide you through:
# 1. Location selection (Desktop, Start Menu, All, Custom)
# 2. Safety mode (Preview, Backup, Delete)
# 3. Real-time progress with statistics

# Run temp folder cleaner (may require admin prompt for system operations)
.\Delete_Temp_Folders.bat
# Enhanced with progress indicators and comprehensive comments
```

### Validating Logs
```powershell
# View shortcut cleanup log with mode information
Get-Content "$env:USERPROFILE\Documents\DeletedInvalidShortcutsLog.txt" -Tail 30

# View temp cleanup log (updated filename)
Get-Content ".\TempCleanupLog_Simple.txt" -Tail 20

# List backed up shortcuts with timestamps
Get-ChildItem "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup" | Format-Table Name, LastWriteTime, Length

# Search for specific shortcut in backup
Get-ChildItem "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup" | Where-Object Name -like "*program*"
```

### Managing Backups
```powershell
# Restore a specific shortcut to desktop
move "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup\2025-10-20_21-35_MyApp.lnk" "$env:USERPROFILE\Desktop\MyApp.lnk"

# Clean old backups (older than 30 days)
Get-ChildItem "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup" | Where-Object LastWriteTime -lt (Get-Date).AddDays(-30) | Remove-Item

# View backup folder size
Get-ChildItem "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup" | Measure-Object Length -Sum
```

## Code Patterns

### Enhanced Error Handling Pattern
- **Batch error handling**: Uses `errorlevel` checks and null redirection (`2>nul`) for locked files
- **PowerShell error handling**: Wraps COM object operations in try/catch blocks
- **Graceful degradation**: Scripts continue operation even when individual operations fail
- **Multi-mode error handling**: Different error handling strategies for Preview, Backup, and Delete modes

### Advanced PowerShell Integration
- **Enhanced COM objects**: Auto_Clean_Shortcuts.bat uses PowerShell COM objects with error recovery
- **Hybrid scripting**: Seamless integration of PowerShell commands within batch loops
- **Error recovery**: PowerShell failures return "ERROR" string for batch processing
- **Performance optimization**: `-NoProfile` flag for faster PowerShell execution

### Comprehensive Logging Pattern
- **Multi-mode logging**: Different log formats for Preview/Backup/Delete operations
- **Timestamped operations**: All operations include precise timestamps
- **Statistical tracking**: Counters for processed, skipped, and valid items
- **Location-aware logging**: Separate tracking for different scan locations
- **Audit trail compliance**: Mode tracking and backup location logging for enterprise use

### Interactive User Interface Pattern
- **Progressive disclosure**: Users choose complexity level (locations, safety modes)
- **Real-time feedback**: Progress indicators and status messages during operations
- **Safety-first design**: Default to safest options with explicit user choices for advanced modes
- **Validation and confirmation**: Clear explanations of choices and their implications

## Windows-Specific Considerations

### Environment and Paths
- **Environment variables**: `%USERPROFILE%`, `%temp%`, `%PUBLIC%`, `%LOCALAPPDATA%`
- **Multi-location awareness**: Handles different Windows shortcut locations
- **Path handling**: Proper quoting for spaces and special characters in all locations
- **Backup path management**: Creates and manages backup directories automatically

### Windows Integration
- **COM object interaction**: Requires Windows Script Host for shortcut reading
- **PowerShell execution policy**: May require policy adjustment for COM operations  
- **UAC elevation**: Some temp cleanup operations require administrator privileges
- **Multi-user environments**: Handles both user-specific and system-wide locations

### Windows Commands and Features
- **Batch commands**: `del`, `rmdir`, `dir`, `move` with Windows-specific flags
- **Advanced file operations**: Timestamped file naming for backup conflict resolution
- **Windows shortcut system**: Deep integration with .lnk file format and COM objects
- **Permission handling**: Graceful handling of Windows permission model across locations

### Compatibility
- **Windows 10/11**: Fully tested and optimized for modern Windows versions
- **PowerShell versions**: Compatible with Windows PowerShell 5.1+ and PowerShell 7+
- **File system**: NTFS-aware for proper timestamp and permission handling
