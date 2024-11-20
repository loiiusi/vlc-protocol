# VLC Protocol Handler PowerShell Script

# Get input parameter
param(
    [Parameter(Mandatory=$true)]
    [string]$InputUrl
)

# Function: URL decode
function UrlDecode {
    param([string]$UrlEncodedString)
    
    Add-Type -AssemblyName System.Web
    return [System.Web.HttpUtility]::UrlDecode($UrlEncodedString)
}

# Function: Process URL
function ProcessUrl {
    param([string]$Url)
    
    Write-Host "Input URL: $Url"
    
    # Handle weblink format
    if ($Url.StartsWith("vlc://weblink?url=") -or $Url.StartsWith("vlc://weblink/?url=")) {
        Write-Host "Detected weblink format"
        $Url = $Url.Replace("vlc://weblink?url=", "").Replace("vlc://weblink/?url=", "")
        Write-Host "Extracted URL: $Url"
        $Url = UrlDecode $Url
        Write-Host "URL decoded: $Url"
        return $Url
    }
    
    # Remove vlc:// prefix
    if ($Url -match "vlc://(.+)") {
        $Url = $matches[1]
        Write-Host "Removed prefix: $Url"
    }
    
    # Fix Chrome 130+ format
    if ($Url.StartsWith("http//") -or $Url.StartsWith("https//")) {
        Write-Host "Fixing Chrome 130+ format"
        $Url = $Url.Replace("http//", "http://").Replace("https//", "https://")
        Write-Host "Fixed URL: $Url"
    }
    
    return $Url
}

# Main program
try {
    # Get script directory
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $vlcPath = Join-Path $scriptPath "vlc.exe"
    
    # Check if VLC exists
    if (-not (Test-Path $vlcPath)) {
        Write-Host "Error: vlc.exe not found"
        Write-Host "Current directory: $scriptPath"
        Write-Host "Please make sure this script is in the VLC installation directory."
        exit 1
    }
    
    # Process URL
    $processedUrl = ProcessUrl $InputUrl
    Write-Host "Final URL: $processedUrl"
    
    # Start VLC with no window
    Write-Host "Starting VLC..."
    Write-Host "Command line: '$vlcPath' --open '$processedUrl'"
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $vlcPath
    $startInfo.Arguments = "--open `"$processedUrl`""
    $startInfo.CreateNoWindow = $true
    $startInfo.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($startInfo)
    
    # Write logs to temp file for debugging
    $logFile = "$env:TEMP\vlc-protocol.log"
    Get-Content $logFile -ErrorAction SilentlyContinue
    $Host.UI.RawUI.FlushInputBuffer()
    "$(Get-Date) - Processed URL: $processedUrl" | Out-File -Append $logFile
} catch {
    $errorMessage = "Error occurred: $_"
    $errorMessage | Out-File -Append "$env:TEMP\vlc-protocol-error.log"
    exit 1
}
