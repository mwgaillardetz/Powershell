# Variables
$serverName = "fqdn.com"
$instanceName = "instanceName"
$userName = "DOMAIN\user.name"
$dbName = "databasename"

# Create the SQL command to change the database owner
$sqlCommand = "ALTER AUTHORIZATION ON DATABASE::[$($dbName.Replace(']', ']]'))] TO [$userName];"

# Execute the SQL command
Invoke-Sqlcmd -ServerInstance "$serverName\$instanceName" -Database $dbName -Query $sqlCommand