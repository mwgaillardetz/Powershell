# Define the path to search for in the process path
$targetPath = "\\fjs\\fglgws\\bin\\"

# Retrieve current date and time to determine process age
$currentTime = Get-Date

# Get a list of all running processes with a path containing the target path
$processes = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE CommandLine LIKE '%$targetPath%'"

# Define an array to store the results
$results = @()

foreach ($process in $processes) {
    if ($process.Name -ne "cmd.exe") {
        # Calculate the process age
        $processStartTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($process.CreationDate)
        $processAge = New-TimeSpan -Start $processStartTime -End $currentTime

        # Get CPU usage
        $processName = $process.Name.Replace(".exe", "")
        $CPUusage = (Get-Counter -Counter "\Process($processName)\% Processor Time").CounterSamples | Select-Object -ExpandProperty CookedValue
        $CPUusage = [math]::Round($CPUusage, 2)
        # Try to retrieve the owner information, catching any exceptions
        try {
            $owner = $process.GetOwner().User
        } catch {
            Write-Host "Error retrieving owner information for $($process.Name): $_"
        }

        $result = [PSCustomObject]@{
            Name = $process.Name
            ProcessID = $process.ProcessId
            Age = $processAge
            CPU = $CPUusage
            Owner = $owner
        }

        $results += $result
    }
}

# Identify orphaned processes
$orphanedProcesses = $results | Where-Object {
    (Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId = $($_.ProcessID)").Count -eq 0
}

# Output the results
Write-Host "Running fgl processes: "
$results | Format-Table -AutoSize

Write-Host "Orphaned processes: "
$orphanedProcesses | Format-Table -AutoSize
