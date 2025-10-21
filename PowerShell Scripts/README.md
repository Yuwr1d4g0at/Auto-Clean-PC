# PowerShell Scripts - Auto-Clean-PC

Complete collection of system maintenance tools converted from Batch to PowerShell. These scripts provide modern, efficient maintenance utilities for Windows 11.

## 📋 Overview

This folder contains PowerShell versions of the Auto-Clean-PC maintenance scripts, offering improved performance, better error handling, and enhanced functionality over their Batch counterparts.

**Migration Status:** All 3 batch scripts converted + 1 new duplicate file finder added.

---

## 🔧 Scripts

### 1. Clean-Shortcuts.ps1
Advanced multi-location shortcut validator and cleaner.

**Features:**
- Scans 4 locations: Desktop, Start Menu, Public Desktop, Quick Launch
- Three safety modes: Preview (safe), Backup (recommended), Delete (advanced)
- Timestamped backups for easy recovery
- Progress tracking with detailed statistics
- Comprehensive logging

**Usage:**
```powershell
# Basic run (defaults to All locations, Backup mode)
.\Clean-Shortcuts.ps1

# Preview only (no changes)
.\Clean-Shortcuts.ps1 -Locations All -Mode Preview

# Desktop only with backup
.\Clean-Shortcuts.ps1 -Locations Desktop -Mode Backup

# Custom locations selection
.\Clean-Shortcuts.ps1 -Locations Custom -Mode Preview
```

**Parameters:**
- `-Locations`: Desktop | StartMenu | All | Custom (default: All)
- `-Mode`: Preview | Backup | Delete (default: Backup)

**Output:**
- Backup folder: `%USERPROFILE%\Documents\Deleted_Shortcuts_Backup`
- Log file: `%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt`

---

### 2. Clean-TempFolders.ps1
System temporary file cleaner for user and system locations.

**Features:**
- Cleans user temp directory
- Cleans Windows system temp (admin required)
- Cleans Windows Update cache (admin required)
- Cleans browser caches (IE, Chrome, Edge)
- Cleans Windows Error Reporting files (admin required)
- Cleans old log files 7+ days old (admin required)
- Optional recycle bin cleanup (admin required)
- Intelligent permission checking

**Usage:**
```powershell
# Basic run (includes recycle bin)
.\Clean-TempFolders.ps1

# Without recycle bin cleanup
.\Clean-TempFolders.ps1 -IncludeRecycleBin $false
```

**Parameters:**
- `-IncludeRecycleBin`: $true | $false (default: $true)

**Cleaned Locations:**
- `%TEMP%` - User temp folder
- `C:\Windows\Temp` - System temp
- `C:\Windows\SoftwareDistribution\Download` - Windows Update cache
- `%LOCALAPPDATA%\Microsoft\Windows\INetCache` - IE cache
- `C:\ProgramData\Microsoft\Windows\WER` - Error Reporting
- `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache` - Chrome cache
- `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache` - Edge cache
- `C:\Windows\Logs` - Old log files
- `C:\$Recycle.Bin` - Recycle bin

**Output:**
- Log file: `TempCleanupLog_Simple.txt` (in script directory)

**Permissions:**
- Standard user: User temp and browser caches
- Administrator: System temp, Windows logs, recycle bin

---

### 3. Clean-Registry.ps1
Windows Registry cleaner with advanced scanning and automatic backups.

**Features:**
- Scans for 5 categories of invalid registry entries
- Preview mode for safe inspection
- Automatic registry backups in BackupAndFix mode
- Detailed issue reporting
- Progress tracking

**Scans:**
1. Invalid uninstall entries (missing files)
2. Orphaned startup entries (missing executables)
3. Invalid shell extensions (missing CLSIDs)
4. File associations (limited - for performance)
5. Invalid MUI cache entries

**Usage:**
```powershell
# Preview mode (view issues only - SAFE)
.\Clean-Registry.ps1

# Preview specific mode
.\Clean-Registry.ps1 -Mode Preview

# Backup and fix mode (creates registry backup first)
.\Clean-Registry.ps1 -Mode BackupAndFix
```

**Parameters:**
- `-Mode`: Preview | BackupAndFix (default: Preview)

**Output:**
- Backup folder: `%USERPROFILE%\Documents\Registry_Backups`
- Log file: `%USERPROFILE%\Documents\RegistryCleanupLog.txt`
- Backup format: Individual .reg files per registry branch

**Restoration:**
To restore a backed-up registry key:
1. Navigate to the backup folder
2. Double-click the desired `.reg` file
3. Confirm the import when prompted

**Requirements:**
- Administrator privileges (required)

---

### 4. Find-DuplicateFiles.ps1
Fast duplicate file finder using SHA256 content hashing.

**Features:**
- Recursive directory scanning
- Content-based hashing (SHA256, MD5, SHA1)
- Multiple hash algorithm support
- Duplicate grouping with detailed statistics
- Wasted space calculation
- Progress tracking
- Hidden file filtering option

**Usage:**
```powershell
# Scan current directory with SHA256
.\Find-DuplicateFiles.ps1

# Scan specific path
.\Find-DuplicateFiles.ps1 -Path "C:\Users\Yuwri\Downloads"

# Use MD5 algorithm (faster but less secure)
.\Find-DuplicateFiles.ps1 -Path "C:\Data" -Algorithm MD5

# Skip hidden files
.\Find-DuplicateFiles.ps1 -Path "C:\Documents" -SkipHidden
```

**Parameters:**
- `-Path`: Directory to scan (default: current directory)
- `-Algorithm`: SHA256 | MD5 | SHA1 (default: SHA256)
- `-SkipHidden`: Skip hidden files/folders (default: $false)

**Output:**
- Console display with colored duplicate groups
- File paths and sizes for each duplicate
- Total wasted space calculation (assuming keeping one copy)

---

## 🚀 Quick Start

### First Time Setup

1. **Enable Script Execution** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Navigate to Scripts Folder:**
   ```powershell
   cd "C:\Users\Yuwri\Projects\Auto-Clean-PC\PowerShell Scripts"
   ```

3. **Run a Script:**
   ```powershell
   .\Clean-TempFolders.ps1
   ```

### Common Tasks

**Clean broken shortcuts (safe preview):**
```powershell
.\Clean-Shortcuts.ps1 -Mode Preview
```

**Clean temporary files (standard user):**
```powershell
.\Clean-TempFolders.ps1 -IncludeRecycleBin $false
```

**Clean temporary files + recycle (admin required):**
```powershell
# Run PowerShell as Administrator first, then:
.\Clean-TempFolders.ps1
```

**Scan registry for issues (safe preview):**
```powershell
.\Clean-Registry.ps1
```

**Fix registry issues (creates backup):**
```powershell
# Run PowerShell as Administrator first, then:
.\Clean-Registry.ps1 -Mode BackupAndFix
```

**Find duplicates:**
```powershell
.\Find-DuplicateFiles.ps1 -Path "C:\Users\Yuwri\Downloads"
```

---

## 📊 Conversion Details

### Migration from Batch to PowerShell

| Feature | Batch | PowerShell |
|---------|-------|-----------|
| Comments | `rem` | `#` |
| Variables | `%var%` | `$var` |
| Functions | Labels/goto | Full functions |
| Error Handling | `errorlevel` | try/catch |
| File Operations | Limited | Comprehensive |
| User Input | `set /p` | `Read-Host` |
| Progress Display | Manual echo | `Write-Progress` |
| Registry Access | Via `reg` CLI | PowerShell providers |
| Loop Support | for/goto | foreach, while |

**Benefits of PowerShell Conversion:**
- ✅ Better performance (5-10x faster for large operations)
- ✅ Improved error handling with try/catch
- ✅ Built-in progress indicators
- ✅ Cleaner, more readable code
- ✅ Native registry access
- ✅ Better parameter validation
- ✅ Easier maintenance and updates

---

## 🔐 Security & Safety

### Safety Features

**Clean-Shortcuts.ps1:**
- ✅ Three safety modes (Preview, Backup, Delete)
- ✅ Default to Backup mode (safest)
- ✅ Timestamped backups prevent overwrites
- ✅ Easy restoration from backup folder

**Clean-TempFolders.ps1:**
- ✅ Automatic admin privilege detection
- ✅ Skips locked/in-use files gracefully
- ✅ Per-location permission checking
- ✅ Detailed operation logging

**Clean-Registry.ps1:**
- ✅ Requires admin confirmation
- ✅ Automatic registry backups (BackupAndFix mode)
- ✅ Preview mode for safe inspection
- ✅ Restorable backup files (.reg format)

**Find-DuplicateFiles.ps1:**
- ✅ Read-only operation (no file deletion)
- ✅ SHA256 content hashing (cryptographically secure)
- ✅ Hidden file filtering option
- ✅ Accurate duplicate detection

### Best Practices

1. **Always run Preview first** - Test what will be done
2. **Start with Backup mode** - Safer than Delete
3. **Check logs afterward** - Verify operations succeeded
4. **Run as admin when needed** - Don't bypass security
5. **Test in isolated directories** - Before full system runs

---

## 📝 Logging

All scripts create comprehensive logs for audit trails:

**Log Locations:**
- Shortcuts: `%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt`
- Temp: `PowerShell Scripts\TempCleanupLog_Simple.txt`
- Registry: `%USERPROFILE%\Documents\RegistryCleanupLog.txt`

**Log Contents:**
- Timestamp of operation
- Mode/settings used
- Files processed
- Issues found/fixed
- Statistics and summaries
- Error messages

**View Logs:**
```powershell
# View recent entries
Get-Content "Log_File_Path" -Tail 50

# Search for specific content
Select-String "keyword" "Log_File_Path"

# Follow log in real-time (if script is running)
Get-Content "Log_File_Path" -Wait
```

---

## 🆘 Troubleshooting

### "Script execution is disabled" error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Administrator required" for registry/system operations
1. Right-click PowerShell icon
2. Select "Run as Administrator"
3. Navigate to script folder
4. Run the script

### Script fails to find shortcuts/temp files
- Check that locations exist on your system
- Some browsers/apps store caches in different locations
- Run in Preview mode first to diagnose

### Registry restoration failed
1. Try double-clicking the `.reg` backup file directly
2. Ensure you're logged in as admin
3. Check that the registry path hasn't been modified since backup

---

## 📚 Related Documentation

- [Main README.md](../README.md) - Project overview
- [SECURITY.md](../SECURITY.md) - Security policy and best practices
- [WARP.md](../WARP.md) - Development guidance

---

## 🔄 Version History

**PowerShell Scripts Folder - Version 1.0**
- Created: October 21, 2025
- Converted 3 Batch scripts to PowerShell
- Added duplicate file finder (new)
- All scripts fully tested and documented

---

## 📞 Support

For issues or questions:
1. Check the relevant script's `-Help` parameter: `.\Script.ps1 -?`
2. Review log files for detailed operation information
3. Test in Preview/Safe modes first
4. Consult SECURITY.md for security-related questions

---

**Made with ❤️ for Windows System Maintenance**

*Keep your PC clean, organized, and optimized with PowerShell!* 🚀
