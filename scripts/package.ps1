param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Folder = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# Check if version is provided
if ([string]::IsNullOrEmpty($Version)) {
    Write-Host "Usage: .\package.ps1 <version> [folder]"
    exit 1
}

$TempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$LargeFiles = @()
$OriginalLocation = Get-Location

Set-Location $Folder

# Remove __pycache__ folders
Get-ChildItem -Path . -Recurse -Directory -Name "__pycache__" | ForEach-Object {
    Remove-Item -Path $_ -Recurse -Force
}

# Find files > 100MB and move them to temp directory
$LargeFiles = Get-ChildItem -Path . -Recurse -File | Where-Object { $_.Length -gt 100MB }
foreach ($file in $LargeFiles) {
    Move-Item -Path $file.FullName -Destination $TempDir.FullName
}

# Zip the folder contents
$ZipName = "krita_vision_tools-windows-x64-$Version.zip"
& 7z a -tzip $ZipName ".\*" | Out-Null

# Restore large files
foreach ($file in $LargeFiles) {
    $tempFile = Join-Path $TempDir.FullName $file.Name
    Move-Item -Path $tempFile -Destination $file.FullName
}

# Move zip to user's home directory
$HomeZipPath = Join-Path $Folder .. .. $ZipName
Move-Item -Path $ZipName -Destination $HomeZipPath

# Clean up temp directory
Remove-Item -Path $TempDir.FullName -Recurse -Force

Write-Host "Packaging complete. Zip file moved to $HomeZipPath"

Set-Location $OriginalLocation