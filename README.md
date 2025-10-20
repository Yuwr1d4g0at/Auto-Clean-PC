# 🧹 Auto-Clean-PC

**A comprehensive Windows 11 system maintenance toolkit for keeping your PC clean and optimized**

[![Windows 11](https://img.shields.io/badge/Windows-11-0078d4?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows/windows-11)
[![Batch Script](https://img.shields.io/badge/Language-Batch-green?style=flat-square)](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)
[![PowerShell](https://img.shields.io/badge/PowerShell-Integration-blue?style=flat-square&logo=powershell)](https://docs.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](#license)

---

## 🚀 Overview

Auto-Clean-PC is a collection of intelligent batch scripts designed to automate common Windows 11 maintenance tasks. Keep your system running smoothly with automated cleanup of temporary files, broken shortcuts, and system clutter.

### ✨ Key Features

- 🔗 **Advanced Shortcut Cleaner** - Scans 4+ locations with backup safety system
- 🗂️ **Comprehensive Temp Cleaner** - Cleans temporary files from multiple system locations
- 🛡️ **Triple Safety Modes** - Preview, Backup, or Delete with user control
- 📊 **Detailed Logging** - Complete audit trails for all operations
- 🔄 **Backup & Recovery** - Timestamped backup system for easy restoration
- ⚡ **Performance Optimized** - Fast execution with minimal system impact
- 🔐 **Permission Aware** - Works with standard user rights, escalates only when needed
- 🏢 **Enterprise Ready** - Preview modes and comprehensive reporting

---

## 📋 What's Included

### 🔗 Auto_Clean_Shortcuts.bat
**Advanced Multi-Location Shortcut Validator & Cleaner v2.0**

- **Multiple Scan Locations**: Desktop, Start Menu, Public Desktop, Quick Launch
- **Three Safety Modes**: Preview, Safe Backup, or Permanent Delete
- **Smart Backup System**: Moves broken shortcuts to timestamped backup folder
- **Comprehensive Coverage**: Scans user and system-wide shortcut locations
- **Interactive Interface**: User chooses locations and safety preferences
- **Enterprise Ready**: Preview mode for testing, detailed audit logs
- **PowerShell Integration**: Advanced COM object validation with error handling
- **Progress Tracking**: Real-time feedback with statistics and status indicators

### 🗑️ Delete_Temp_Folders.bat
**System Temporary File Cleaner**

- **User Temp Folder** (`%temp%`) - Standard permissions
- **Windows System Temp** (`C:\Windows\Temp`) - Admin required
- **Windows Update Cache** (`C:\Windows\SoftwareDistribution\Download`) - Admin required
- **Browser Caches** (IE, Chrome, Edge) - Standard permissions
- **Windows Error Reporting** - Admin required
- **Old Log Files** (7+ days) - Admin required
- **System Recycle Bin** - Admin required

---

## 🚀 Quick Start

### Prerequisites
- Windows 11 (or Windows 10)
- PowerShell (for shortcut validation)
- Administrator rights (optional, for system-level cleaning)

### Installation
1. Download or clone this repository
2. Navigate to the `Auto Clean PC` folder
3. Run the desired script

### Usage

#### 🔗 Clean Broken Shortcuts
```batch
# Navigate to script directory
cd "Auto Clean PC"

# Run enhanced shortcut cleaner (interactive)
.\Auto_Clean_Shortcuts.bat

# The script will prompt you to choose:
# 1. Scanning locations (Desktop, Start Menu, All, etc.)
# 2. Safety mode (Preview, Backup, or Delete)
# 3. View real-time progress and results
```

**Scanning Options:**
- **[1] Desktop only** - Quick scan of desktop shortcuts
- **[2] Desktop + Start Menu** - Recommended for most users  
- **[3] All locations** - Comprehensive system-wide scan
- **[4] Custom selection** - Advanced configuration

**Safety Modes:**
- **[Y] Safe Backup** - Move broken shortcuts to backup folder (RECOMMENDED)
- **[P] Preview Only** - Show what would be done without changes (SAFE)
- **[D] Permanent Delete** - Delete shortcuts permanently (ADVANCED)

#### 🗑️ Clean Temporary Files
```batch
# Standard user cleanup
.\Delete_Temp_Folders.bat

# For complete system cleanup (run as administrator)
Right-click → "Run as administrator"
```

---

## 📊 Features in Detail

### 🛡️ Safety Features
- **Comprehensive logging** - Every action is recorded with timestamps
- **Locked file handling** - Gracefully skips files in use
- **Permission validation** - Checks admin rights before system operations
- **Error recovery** - Continues operation even if individual files fail

### 📈 Performance
- **Fast execution** - Optimized for speed and efficiency
- **Minimal resource usage** - Low memory and CPU footprint
- **Progress indicators** - Real-time feedback during operations
- **Batch processing** - Handles large file sets efficiently

### 📝 Logging System
- **Auto_Clean_Shortcuts**: Logs to `%USERPROFILE%\Documents\DeletedInvalidShortcutsLog.txt`
- **Backup Location**: `%USERPROFILE%\Documents\Deleted_Shortcuts_Backup`
- **Delete_Temp_Folders**: Logs to `TempCleanupLog_Simple.txt` in script directory
- **Timestamped entries** with detailed operation results
- **Mode tracking** (Preview, Backup, Delete) for audit compliance
- **Multi-location coverage** with per-location result tracking
- **Backup file naming** with timestamps to prevent conflicts

---

## 🔧 Advanced Usage

### Viewing Logs
```powershell
# View shortcut cleanup log
Get-Content "$env:USERPROFILE\Documents\DeletedInvalidShortcutsLog.txt" -Tail 20

# View temp cleanup log
Get-Content ".\TempCleanupLog_Simple.txt" -Tail 20

# List backed up shortcuts
Get-ChildItem "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup" | Format-Table Name, LastWriteTime
```

### Restoring Shortcuts
```powershell
# Navigate to backup folder
cd "$env:USERPROFILE\Documents\Deleted_Shortcuts_Backup"

# List available backups
dir

# Restore a specific shortcut to desktop
move "2025-10-20_21-35_MyProgram.lnk" "$env:USERPROFILE\Desktop\MyProgram.lnk"
```

### Scheduling Automatic Runs
Create a Windows Task Scheduler entry to run these scripts automatically:
1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (daily/weekly)
4. Set action to run the batch file

---

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- Report bugs or issues
- Suggest new features
- Submit pull requests
- Improve documentation

### Development Setup
1. Fork this repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

These scripts modify your file system. While designed to be safe:
- **Always backup important data** before running system maintenance scripts
- **Test in a controlled environment** before production use
- **Review logs** after each operation
- **Run as administrator** only when necessary for enhanced security

---

## 📞 Support

If you encounter any issues or have questions:
- Check the log files for detailed error information
- Ensure you have the necessary permissions
- Verify Windows version compatibility

---

<div align="center">

**Made with ❤️ for Windows 11 users**

*Keep your PC clean, fast, and optimized!* 🚀

</div>
