<#
.SYNOPSIS
    Finds duplicate files in a directory based on file hash (content).

.DESCRIPTION
    This script scans a directory recursively for duplicate files by comparing
    file hashes. It uses SHA256 for hashing and reports all duplicates found.

.PARAMETER Path
    The root directory to scan for duplicates. Defaults to current directory.

.PARAMETER Algorithm
    Hash algorithm to use: SHA256 (default), MD5, or SHA1.

.PARAMETER SkipHidden
    Skip hidden files and folders. Defaults to $false.

.EXAMPLE
    .\Find-DuplicateFiles.ps1 -Path "C:\Downloads"
    .\Find-DuplicateFiles.ps1 -Path "C:\Users\Yuwri\Documents" -Algorithm MD5
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("SHA256", "MD5", "SHA1")]
    [string]$Algorithm = "SHA256",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipHidden
)

# Initialize results
$fileHashes = @{}
$duplicates = @()
$processedFiles = 0
$totalFiles = 0

# Get all files
Write-Host "Scanning directory: $Path" -ForegroundColor Cyan
$files = @(Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue)
$totalFiles = $files.Count

if ($SkipHidden) {
    $files = @($files | Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) })
}

Write-Host "Found $($files.Count) files to process" -ForegroundColor Cyan

# Process each file
foreach ($file in $files) {
    $processedFiles++
    Write-Progress -Activity "Hashing files" -Status "Processing: $($file.FullName)" -PercentComplete (($processedFiles / $files.Count) * 100)
    
    try {
        # Calculate file hash
        $hash = (Get-FileHash -Path $file.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
        
        # Store hash and file info
        if ($fileHashes.ContainsKey($hash)) {
            # Duplicate found
            $fileHashes[$hash] += @($file)
            $duplicates += $hash
        } else {
            # First occurrence of this hash
            $fileHashes[$hash] = @($file)
        }
    }
    catch {
        Write-Warning "Failed to hash file: $($file.FullName) - $_"
    }
}

Write-Progress -Activity "Hashing files" -Completed

# Report results
Write-Host "`n" -ForegroundColor Green
Write-Host "=== DUPLICATE FILE SCAN RESULTS ===" -ForegroundColor Green
Write-Host "Total files scanned: $totalFiles" -ForegroundColor Cyan
Write-Host "Unique file hashes: $($fileHashes.Count)" -ForegroundColor Cyan
Write-Host "Duplicate groups found: $($duplicates.Count)" -ForegroundColor Yellow

if ($duplicates.Count -eq 0) {
    Write-Host "`nNo duplicates found!" -ForegroundColor Green
} else {
    Write-Host "`n=== DUPLICATES ===" -ForegroundColor Yellow
    
    $duplicateGroup = 1
    $uniqueDuplicateHashes = @($duplicates | Select-Object -Unique)
    
    foreach ($hash in $uniqueDuplicateHashes) {
        $files = $fileHashes[$hash]
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        
        Write-Host "`nDuplicate Group $($duplicateGroup):" -ForegroundColor Yellow
        Write-Host "  Hash: $hash" -ForegroundColor Gray
        Write-Host "  Count: $($files.Count) files" -ForegroundColor Gray
        Write-Host "  Total Size: $(Format-FileSize $totalSize)" -ForegroundColor Gray
        Write-Host "  Files:" -ForegroundColor Gray
        
        foreach ($file in $files) {
            Write-Host "    - $($file.FullName) ($(Format-FileSize $file.Length))" -ForegroundColor White
        }
        
        $duplicateGroup++
    }
    
    # Summary
    $totalWastedSpace = 0
    foreach ($hash in $uniqueDuplicateHashes) {
        $files = $fileHashes[$hash]
        if ($files.Count -gt 1) {
            # Calculate wasted space (keeping one, deleting the rest)
            $wastedSpace = ($files | Measure-Object -Property Length -Sum).Sum - $files[0].Length
            $totalWastedSpace += $wastedSpace
        }
    }
    
    Write-Host "`n=== SPACE ANALYSIS ===" -ForegroundColor Cyan
    Write-Host "Total wasted space (if duplicates removed): $(Format-FileSize $totalWastedSpace)" -ForegroundColor Yellow
}

# Helper function to format file size
function Format-FileSize {
    param([long]$bytes)
    
    if ($bytes -ge 1GB) {
        return "{0:N2} GB" -f ($bytes / 1GB)
    } elseif ($bytes -ge 1MB) {
        return "{0:N2} MB" -f ($bytes / 1MB)
    } elseif ($bytes -ge 1KB) {
        return "{0:N2} KB" -f ($bytes / 1KB)
    } else {
        return "{0} B" -f $bytes
    }
}

Write-Host "`nScan completed at $(Get-Date)" -ForegroundColor Green
