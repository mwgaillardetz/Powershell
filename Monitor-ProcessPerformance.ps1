# Define process to monitor
$processName = "process-name"

Write-Host "Beginning search. If process owner isn't found, 'NA' will be the column assigned value."
Write-Host "A process is considered 'orphaned' if a parent process is missing."

# Retrieve the process' information
$processes = Get-Process | Where-Object { $_.ProcessName -eq $processName }

# Analyze and organize the processes in parallel
$processedResults = $processes | ForEach-Object -Parallel {
    $process = $_  # The current process object
    $processStartTime = $process.StartTime
    $processId = $_.Id # The current process' ID
    if ($processStartTime -is [System.DateTime]) {
        $processAge = (Get-Date) - $processStartTime  # Precise process age
        $cpuTime = $process.TotalProcessorTime.TotalMilliseconds
        $totalCPUTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue * $processAge.TotalMilliseconds

        if ($totalCPUTime -gt 0) {
            $cpuUsage = [Math]::Round(($cpuTime / $totalCPUTime) * 100, 2)
        } else {
            $cpuUsage = 0
        }
    } else {
        # Write-Host "Process start time not available or in an unexpected format for $($process.ProcessName) process."
        return  # Skip to the next process
    }

    try {
        $ownerInfo = (Get-CimInstance Win32_Process -Filter "ProcessId = $processId")
        $owner = Invoke-CimMethod -InputObject $ownerInfo -MethodName GetOwner | Select-Object -ExpandProperty user
    } catch {
        $owner = "NA"
    }

    # Check if the process is orphaned
    $isOrphaned = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($process.Id)").ParentProcessId -eq 0
    if ($isOrphaned){
        $orphaned = "Yes"
    } else{
        $orphaned = "No"
    }

    # Determine if process is at least an hour old, and using at least 2% total CPU
    if ($processAge.TotalSeconds -ge 3600 -and $cpuUsage -ge 0.02) {
        [PSCustomObject]@{
            Name = $process.ProcessName
            ProcessID = $processId
            Age = $processAge
            CPU = $cpuUsage
            Owner = $owner
            Orphaned = $orphaned
        }
    }
} -ThrottleLimit 5

# Sort the results by Age & CPU in descending order
$sortedResults = $processedResults | Sort-Object -Property Age,CPU -Descending

# Check if any processes running for an hour or more were found
if ($sortedResults.Count -gt 0) {
    Write-Error "Discovered fglrun processes running for an hour or more: "
    $sortedResults | Format-Table -AutoSize
} else {
    Write-Host "No long-running processes found! "
}
