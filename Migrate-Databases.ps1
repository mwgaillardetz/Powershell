$databases = @(
        "INSTANCE\dbName"
    )
# Ensure the SQL Server module is installed
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module -Name SqlServer -AllowClobber -Force
}

# Import the SQL Server module if not already imported
if (-not (Get-Module -Name SqlServer)) {
    Import-Module -Name SqlServer
}

$sharePath = "\\Share-Path\temp"

foreach ($db in $databases) {
    try {
        $parts = $db -split '\\'
        $SourceServer = "fqdn.com\$($parts[0])"
        $MigratingDatabase = $parts[1]

        # Modify the destination instance name based on the source instance name
        $DestinationInstance = $parts[0] -replace 'DEV', 'CLIENT' -replace 'QA', 'CLIENT' -replace 'SHARED', 'CLIENT'
        $DestinationServer = "destinationFQDN.com\$DestinationInstance"

        # Get the current owner of the database
        $currentOwner = Invoke-Sqlcmd -ServerInstance $SourceServer -Database $MigratingDatabase -Query "SELECT SUSER_SNAME(owner_sid) AS Owner FROM sys.databases WHERE name = '$MigratingDatabase'"

        Copy-DbaDatabase `
            -Source $SourceServer `
            -Destination $DestinationServer `
            -Database $MigratingDatabase `
            -BackupRestore `
            -SharedPath $sharePath `
            -SetSourceOffline `
            -NoBackupCleanup `
            -Verbose

        Invoke-Sqlcmd -ServerInstance $DestinationServer -Database $MigratingDatabase -Query "ALTER AUTHORIZATION ON DATABASE::[$MigratingDatabase] TO [$($currentOwner.Owner)]"
    }
    catch {
        Write-Error "An error occurred while migrating $db : $_"
    }
}