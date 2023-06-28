<#
.SYNOPSIS
	Configures a pre-installed Octopus Tentacle.

.DESCRIPTION
    This script can be processed post installation of the Octopus
    Tentacle installation. Ansible copies this over to C:\scripts
    while the initial role is ran against the applicable server.

.NOTES
	Author: Matt Gaillardetz
	Last Edit: 06-28-2023
	Version 1.0
#>


# Thumbprint can be retrieved by hitting the Octopus Deploy web portal,
# browsing to the Environments tab, then clicking 'Add deployment
# target' for the appropriate environment.

$DeployDirectory = "C:\octopus\deploy"
$Thumbprint = Read-Key "Enter Octopus Server Thumbprint"

# Install Octopus Tentacle
$url = "https://octopus.com/downloads/latest/OctopusTentacle64"
$downloadPath = "$env:TEMP\octopus\"
 
if (Test-Path $downloadPath) {
    Remove-Item -Path $downloadPath -Recurse -Force
}
 
New-Item -Type Directory -Path $downloadPath | Out-Null
 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile($url, "$downloadPath\Octopus.Tentacle.msi")
 
& "$downloadPath\Octopus.Tentacle.msi" /passive
 
while ((Get-Process | where { $_.ProcessName -eq 'msiexec' } | Measure-Object).Count -ne 1) {
    Start-Sleep -Seconds 1
}
Write-Output "Octopus Tentacle Installed."

# Configure Octopus Tentacle
Push-Location "C:\Program Files\Octopus Deploy\Tentacle"
& .\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config"
& .\Tentacle.exe new-certificate --instance "Tentacle" --if-blank
& .\Tentacle.exe configure --instance "Tentacle" --reset-trust
& .\Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" `
    --app "$DeployDirectory " --port "10933" --noListen "False"
& .\Tentacle.exe configure --instance "Tentacle" --trust $Thumbprint
& .\Tentacle.exe service --instance "Tentacle" --install --start
Pop-Location

Write-Output "Octopus Tentacle Configured. You will need to Add this server to Octopus:"
$fqdn = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
Write-Output " * $fqdn"
