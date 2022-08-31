<#
.SYNOPSIS
	Indexes servers' https bindings and updates SSL certificate in IIS.
    * May have to run as administrator.

.DESCRIPTION
	This script relies on three variables -
    $certPath: Place your new certificate path in this variable.
    $certpwd: If your certificate came with a password, assign in here.
    $servers: If you want to run this script against multiple servers, add the .csv file here.
    With these variables in place, it will copy the cert to c:\temp on the target host and
    import the certificate. After it's been imported, it will delete the temp file and
    seach for https bindings. After finding applicable https binding it will replace that cert
    with the new one you have uploaded.
    Note: If you need to generate list of sites nearing ssl cert expiration, run-
    $/In-House Utilities/DevOps/Tyler.DevOps.PowerShell/Scripts/Get-ExpiringCerts.ps1

.NOTES
	Author: Matt Gaillardetz
	Last Edit: 08-31-2022
	Version 1.1
#>

# Assign variables
$certPath = "\\erpfileshare.tylertech.com\Public_Software\DevOpsTools\temp\star.tylertech.com-2023-c1-private.pfx"
$certName = Split-Path $certPath -leaf
$pfxpass = Read-Host "Enter certificate Password" -AsSecureString

# Use if you would like to run against individual server(s).
# $servers = @('fdvmmunapptest')

# Import list of servers with expiring cert into an array. Change to your local csv.
$servers = Get-Content -Path 'C:\TylerDev\psScripts\update_ssl_certs\servers2.csv'

# Copy certificate over to c:\temp on each server
$servers | foreach-Object { copy-item -Path $certPath -Destination "\\$_\c`$\temp" }
Write-Output "Successfully copied new certificate to temp location."


# Start psSession with each host to complete certificate transaction
$session = New-PsSession -ComputerName $servers


# Update bindings for each https site in IIS to use new cert in all listed servers
Write-Output "Updating bindings for each site in servers..."
$importCertificatesCommand = ({

    $newCert = Import-PfxCertificate `
      -FilePath "c:\temp\$($using:certName)"  `
      -CertStoreLocation "Cert:\LocalMachine\My" `
      -password $using:pfxpass

    Import-Module Webadministration
    Import-Module ServerManager
    Add-WindowsFeature Web-Scripting-Tools

    $sites = Get-ChildItem -Path IIS:\Sites

    foreach ($site in $sites)
    {
        foreach ($binding in $site.Bindings.Collection)
        {
            if ($binding.protocol -eq 'https' -and  $binding.hostname -like '.tylertech.com')
            {
                $binding.AddSslCertificate($newCert.Thumbprint, "my")
                $newCert.FriendlyName = $certName
            }
        }
    }
})

# Import certificate into local machine store for each listed host by calling above command
Invoke-Command -session $session -scriptblock $importCertificatesCommand
Write-Output "Importing certificate into certificate store for each server in $servers."

Invoke-command -Session $session { remove-item -path "c:\temp\$($using:certName)" }
Write-Output "Removing certificate from temporary location..."

Write-Output "Gods be good. The deed is done."