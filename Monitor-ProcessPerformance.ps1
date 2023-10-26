# Specify the process name you'd like to track
$processName = "your-process-name"

# Get all running processes with the specified name
$matchingProcesses = Get-Process | Where-Object { $_.ProcessName -eq $processName }

# Define an array to store the results
$results = @()


Write-Host "Beginning search. If process owner isn't found, 'NA' will be the column assigned value. "
foreach ($process in $matchingProcesses) {
    $processStartTime = $process.StartTime
    if ($processStartTime -is [System.DateTime]) {
        $processAge = (Get-Date) - $processStartTime
        $cpuTime = $process.TotalProcessorTime.TotalMilliseconds
        $totalCPUTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue * $processAge.TotalMilliseconds
        # Alternate CPU usage retrieval method - Returns amount of CPU used by the process as a time-based value.
        # $cpu = $process.CPU
        # $cpuUsage = [Math]::Round($cpu, 2)  # Rounds the above number into an easily consumable value

        if ($totalCPUTime -gt 0) {
            $cpuUsage = [Math]::Round(($cpuTime / $totalCPUTime) * 100, 2)
        } else {
            $cpuUsage = 0  # Set to 0 if totalCPUTime is 0 to avoid division by zero
        }
    } else {
        Write-Host "Process start time not available or in an unexpected format for process $($process.ProcessName)."
    }
        try {
            $owner = $process.GetOwner().User
        } catch {
            $owner = "NA"
        }
        # Look for matching processes that have been running for over an hour.
        # You can also set a specific cpu percentage to report on (Default 0)
        if ($processAge.TotalSeconds -ge 3600 -and $cpuUsage -ge 0) {
            $result = [PSCustomObject]@{
            Name = $process.ProcessName
            ProcessID = $process.Id
            Age = $processAge
            CPU = $cpuUsage
            Owner = $owner
        }
        }

        $results += $result
    }

# Sort the results by Age & CPU in descending order
$sortedResults = $results | Sort-Object -Property Age,CPU -Descending


# Identify orphaned processes, output results
$orphanedProcesses = $results | Where-Object {
    (Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId = $($_.ProcessID)").Count -eq 0
}
if ($orphanedProcesses) {
Write-Host "Orphaned processes discovered: "
$orphanedProcesses | Format-Table -AutoSize
}
if (!$orphanedProcesses) {
Write-Host "No orphaned processes found. "
}


# Check if any processes running for an hour or more were found
if ($results.Count -gt 0) {
    Write-Error "Discovered fglrun processes running for an hour or more: "
    $sortedResults  | Format-Table -AutoSize
} else {
    Write-Host "No long-running processes found. "
}
