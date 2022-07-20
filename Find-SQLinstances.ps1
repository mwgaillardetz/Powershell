	<#
	.SYNOPSIS
		Find all running sql instances within a Windows SQL server. 

	.DESCRIPTION
		This collects each instance on FDDB2 and adds the quotations and comma for each object.
        !-might be an issue-! The last entry has a comma at the end, and the proceeding command fails 
        because of this. 

	.NOTES
		Author: Matt Gaillardetz
		Last Edit: 07-19-2022
		Version 1.1 - Updated cosmetics, export to csv logic.
	#>

# Declare server and csv path
$SERVER= "FDDB2"
$sqlcsv = "C:\TylerDev\temp\sqlInstances.csv"

function getSQLInstanceOnServer ([string]$SERVER) {
    $services = Get-Service -Computer $SERVER
    $services = $services | ? DisplayName -like "SQL Server (*)"
        try {
        $instances = $services.Name | ForEach-Object {($_).Replace("MSSQL`$","")}
    }catch{
        # if no instances are found return 
        return -1
    }
    
    return $instances
}

$allInstances = getSQLInstanceOnServer $SERVER

# write-output $allInstances
$sqlInstances = '"' + ($allInstances -join '","' ) + '"' 

# Collect results and place them in an excel sheet
Write-Output "Collecting results..."
$sqlInstances | Get-DbaDatabase | export-csv $sqlcsv -notypeinformation;

