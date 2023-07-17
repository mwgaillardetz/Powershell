<#
.SYNOPSIS
	Generates report of missing hosts present in Remote Desktop Manager, but missing from Ansible. 

.DESCRIPTION
	This script pulls the ansible production file from github, and 
   	pulls an RDM inventory for Windows & Linux hosts with the tag 'ERPDevOps'.
    	A comparison is completed to output hosts missing from the Ansible production file, 
    	but present in RDM's inventory. Results are saved under C:\TylerDev\temp\results.csv.

.NOTES
	Author: Matt Gaillardetz
	Last Edit: 07-22-2022
	Version 1.1 - Updated cosmetics, synopsis, and trim process for uneccessary objects.
#>


# Remove old versions of ansible repo
$ansiblePath = "C:\temp\ansible"
if (Test-Path $ansiblePath) {
    Remove-Item -Path $ansiblePath -Force
    Write-Host "Removing old ansible directory C:\temp\ansible"
}

# Check for RDM powershell module, and install if not present.
$moduleExists = Get-InstalledModule -Name "RemoteDesktopManager"
if (!$moduleExists) {
    Write-Host "Installing RDM Powershell Module"
    Install-Module -Name RemoteDesktopManager -Scope CurrentUser
}
Import-Module -Name RemoteDesktopManager
$rdmcsv = "C:\temp\RDMproduction.csv"

# Remove old versions of the RDM inventory export
if (Test-Path $rdmcsv) {
    Remove-Item -Path $rdmcsv -Force
}

# Retrieve inventory from RDM. Only collecting hosts that are 'live', POC is ERP DevOps, and wsus:Yes. 
Write-Host "Generating RDM inventory..."
$RDMServers = Get-RDMSession | 
Where-Object {($_.MetaInformation.Keywords -eq "TeamName") -and (($_.Group -eq "Parent-Folder\Live Linux Machines") -or ($_.Group -eq "Parent-Folder\Live Windows Machines"))} |
ForEach-Object { 
    New-Object PSObject -Property @{ 
        FullName = $_.MetaInformation.MachineName
            }
};

# Save RDM results to csv
$RDMServers | Export-Csv $rdmcsv -notypeinformation;
Write-Host "RDM inventory successfully created."


# Download erpDevOps ansible repo to local folder & add the header 'FullName'
Write-Host "Cloning erp-devops-ansible repo for latest inventory file."
gh repo clone tyler-technologies/erp-devops-ansible c:\tylerdev\temp\ansible
$ansibleMaster = "C:\temp\ansible\production"
$ansibleProd = "C:\temp\ansibleProduction.csv"
$ansibleItems = Get-Content -Path $ansibleMaster
Set-Content $ansibleProd -Value "FullName"
Add-Content -Path $ansibleProd -Value $ansibleItems
Write-Host "Clone complete."
Write-Host "Cleaning up inventory file for RDM comparison..."

# Remove everything aside from hosts, then remove 'domain:' from ansible hosts to match RDM computer name
(Get-Content $ansibleProd) | Where-Object {$_ -match '\.com:'} | Set-Content $ansibleProd
(Get-Content $ansibleProd) | ForEach-Object {$_ -replace '.business.com:', ""} | Set-Content $ansibleProd
(Get-Content $ansibleProd) | ForEach-Object {$_ -replace '.business.com:', ""} | Set-Content $ansibleProd

# Remove white spaces from ansible prod file
(Get-Content $ansibleProd) | ForEach-Object {
    if ($_ -notlike 'Directory=*') {
        $_ -replace ' ', ''
    } else {
        $_
    }
} | Set-Content $ansibleProd


# Add 'FullName' header for comparison to ansible csv file, then import updated csv files for comparison
Write-Host "Importing ansible and RDM csv files for comparison. "
$filedata = Import-Csv -Path "C:\temp\ansibleProduction.csv" -Header "FullName"  
$filedata | Export-Csv -Path "C:\temp\ansibleProduction.csv" -NoTypeInformation
$fileA = Import-Csv -Path "C:\temp\ansibleProduction.csv"
$fileB = Import-Csv -Path "C:\temp\RDMproduction.csv"

#Compare rdm and ansible inventory object arrays
$Results = Compare-Object  $fileA $fileB -Property FullName
$Array = @()       
Foreach($R in $Results)
{
    If( $R.sideindicator -eq "=>" )
    {
        $Object = [pscustomobject][ordered] @{
            "Hosts missing from Ansible" = $R.FullName
            
        }
        $Array += $Object
    }
}
 
#Export results to csv
$Array | Export-Csv "C:\temp\results.csv"

# Temporary file cleanup
Remove-Item "C:\temp\ansible" -Recurse -Force
Remove-Item "C:\temp\RDMproduction.csv"
Remove-Item "C:\temp\ansibleProduction.csv"
Write-Host "Removing temporary files..."

Write-Host "Complete. Results are saved under C:\temp\results.csv"
Invoke-Item "C:\temp\results.csv"
