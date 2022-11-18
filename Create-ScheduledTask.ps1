# create task with the account
$ServerList = "server","name","for","each","comma","seperated","host"
$session = New-PsSession -ComputerName $ServerList

$CreateScheduledTask = ({
    $principal = New-ScheduledTaskPrincipal -UserId 'DOMAIN\gmsa$' -LogonType Password
    $TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -ExecutionTimeLimit 06:00:00 -AllowStartIfOnBatteries
    $trigger = New-ScheduledTaskTrigger -At 06:00:01 -Daily
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-File "D:\path\to\.ps1"'
    $Task = Register-ScheduledTask "TaskName" -Action $action -Trigger $trigger -Principal $principal -Settings $TaskSettings
})

Invoke-Command -session $session -scriptblock $CreateScheduledTask
Write-Output "Created scheduled task for $ServerList."
