<#
.SYNOPSIS
	Script to health check Docker.

.DESCRIPTION
	Script to check if Docker service and Docker Desktop are running. If
    not, the script will start each respectively. This 'check' is done
    every 15 minutes.

.NOTES
	Author: Matt Gaillardetz
	Last Edit: 08-03-2023
	Version 1.1 - Updated to include logging.
#>


# Enable logging
$logFile = "C:\Logs\docker-staus.log"

Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO","WARN","ERROR")]
        [string] $level = "INFO"
    )

    # Create timestamp
    $timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")

    # Append content to log file
    Add-Content -Path $logFile -Value "$timestamp [$level] - $message"
}



# Check if Docker is running
$dockerStatus = Get-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
$processes = Get-Process -Name "*docker desktop*" -ErrorAction SilentlyContinue


# Start Docker if it's not running
if ($null -eq $dockerstatus) {
    Write-Log -level ERROR -message "Docker service not found running. Starting..."
    Start-Service -Name "Docker Desktop Service"
    # Add a sleep to give Docker some time to start up
    #Start-Sleep -Seconds 10
    #Write-Host "Docker is now running."
} else {
    #Write-Host "Docker is already running."
}

# Run docker desktop if it isn't running"
    if ($null -eq $processes){
    Write-Log -level ERROR -message "Docker Desktop not found running. Starting..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
}
    if ($null -lt $processes) {
    Write-Log -level INFO -message "Docker is already running, no action needed."
}
