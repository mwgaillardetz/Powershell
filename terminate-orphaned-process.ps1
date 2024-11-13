# Define the process name and path
$processName = 'processName.exe'
$processPath = 'c:\process-path'

# Get all processes with the specified name
$processes = Get-Process | Where-Object { $_.ProcessName -eq $processName }

# Filter processes by checking their executable path and name
$orphanedProcesses = $processes | Where-Object {
    $_.ProcessName -eq $processName -and $_.MainModule.FileName -like "$processPath*"
}

# Loop through the processes and terminate them
foreach ($process in $orphanedProcesses) {
    try {
        # Attempt to stop the process gracefully
        $process.CloseMainWindow()

        # Wait for a few seconds for the process to exit
        $process.WaitForExit(5)

        if (!$process.HasExited) {
            $process | Stop-Process -Force
            Write-Host "Terminated process ID: $($process.Id) (Name: $($process.ProcessName))"
        } else {
            Write-Host "Terminated process ID: $($process.Id) (Name: $($process.ProcessName))"
        }
    } catch {
        Write-Host "Failed to terminate process ID: $($process.Id) (Name: $($process.ProcessName))"
    }
}

# Display the orphaned processes (if any remain)
$remainingProcesses = Get-Process | Where-Object { $_.ProcessName -eq $processName }
if ($remainingProcesses.Count -gt 0) {
    Write-Host "Orphaned processes found but not terminated:"
    $remainingProcesses | ForEach-Object {
        Write-Host "Process ID: $($_.Id), Name: $($_.ProcessName), Path: $($_.MainModule.FileName)"
    }
} else {
    Write-Host "No orphaned processes found."
}
