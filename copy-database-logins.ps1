# Alternative to copy-dbalogs, this script only copies users specific to a
# particular database instead of the whole instance.

# Import the module
Import-Module dbatools

# Define source and destination servers
$sourceServer = "sourceFQDN.com\instanceName"
$destinationServer = "destinationFQDN.com\instanceName"

# Define the list of databases
$databases = @("database-name")

# Loop over each database
foreach ($database in $databases) {
    Write-Host "Processing database: $database"

    # Get the users associated with the current database on the source server
    $users = Get-DbaDbUser -SqlInstance $sourceServer -Database $database

    # Get the logins associated with the users
    $logins = $users | ForEach-Object { Get-DbaLogin -SqlInstance $sourceServer -Login $_.Login }

    if ($logins) {
        Write-Host "Found logins: $($logins.Name -join ', ')"
    } else {
        Write-Host "No logins found for database: $database"
    }

    # Copy the logins to the destination server
    $logins | ForEach-Object {
        Write-Host "Copying login: $($_.Name)"
        try {
            Copy-DbaLogin -Source $sourceServer -Destination $destinationServer -Login $_.Name
            Write-Host "Successfully copied login: $($_.Name)"
        } catch {
            Write-Host "Failed to copy login: $($_.Name)"
            Write-Host "Error: $_.Exception.Message"
        }
    }
}