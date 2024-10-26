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
    $/Get-ExpiringCerts.ps1

.NOTES
	Author: Matt Gaillardetz
	Last Edit: 09-1-2022
	Version 1.2
#>

# Assign variables
$certPath = "\\your-cert-path"
$certName = Split-Path $certPath -leaf
$pfxpass = Read-Host "Enter certificate Password" -AsSecureString

# Use if you would like to run against individual server(s).
# $servers = @('server-name')

# Import list of servers with expiring cert into an array. Change to your local csv.
$servers = Get-Content -Path '\\your-server-csv-path'

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
            if ($binding.protocol -eq 'https' -and  $binding.BindingInformation -like '*.cert.domain.tobe.replaced.com')
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
