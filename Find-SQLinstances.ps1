	<#
	.SYNOPSIS
		Find all running sql instances within a Windows SQL server. 

	.DESCRIPTION
		This collects each instance on your specified server, finds databases associated to each instance, 
		and outputs the results. The option to output to a csv file is commented out, but available and 
		working. It might need some fine tuning, I wasn't satisfied with the exported csv file and preferred
		the output from powershell. 

	.NOTES
		Author: Matt Gaillardetz
		Last Edit: 01-17-2024
		Version 1.2 - Corrected logic based on new permission issues. 
	#>

$SERVER = "your-host-name.fqdn.com"
# $OutputCSV = Join-Path -Path $PSScriptRoot -ChildPath "temp\SQL-Server-Instances-And-Databases.csv"

$scriptBlock = {
    param (
        [string]$SERVER
    )
    function getSQLInstanceOnServer ([string]$SERVER) {
        $services = Get-Service -Computer $SERVER
        $sqlServices = $services | Where-Object DisplayName -like "SQL Server (*)"

        if ($sqlServices) {
            $instances = foreach ($service in $sqlServices) {
                $instanceName = $service.DisplayName -replace 'SQL Server \((.*?)\).*', '$1'

                # Get databases for the current instance
                $databases = Invoke-Sqlcmd -ServerInstance "$SERVER\$instanceName" -Query "SELECT name FROM sys.databases" -ErrorAction SilentlyContinue

                [PSCustomObject]@{
                    InstanceName = $instanceName
                    Databases = $databases.Name -join ', '
                }
            }
            return $instances
        }
        else {
            Write-Output "No SQL Server instances found on $SERVER."
            return @()
        }
    }
    # Call the function
    getSQLInstanceOnServer -SERVER $SERVER
}

Invoke-Command -ComputerName $SERVER -ScriptBlock $scriptBlock -ArgumentList $SERVER


## Invoke the script block on the remote server and output results to csv (messy)
# $result = Invoke-Command -ComputerName $SERVER -ScriptBlock $scriptBlock -ArgumentList $SERVER

# if ($result) {
#     # Output the result to a CSV file in the 'temp' directory
#     $result | Export-Csv -Path $OutputCSV -NoTypeInformation
#     Write-Host "Result exported to $OutputCSV"
# }
# else {
#     Write-Host "No result to export. Check for errors in the script block execution."
# }
