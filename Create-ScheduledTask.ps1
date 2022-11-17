# create task with the account
$ServerList = "FDVMMUNAPP5"
$session = New-PsSession -ComputerName $ServerList

$CreateScheduledTask = ({
    $principal = New-ScheduledTaskPrincipal -UserId 'TYLER\tdo.ecqservice$' -LogonType Password
    $TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -ExecutionTimeLimit 06:00:00 -AllowStartIfOnBatteries
    $trigger = New-ScheduledTaskTrigger -At 06:00:01 -Daily
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-File "D:\cmd\Get-HomeFolderSizes.ps1"'
    $Task = Register-ScheduledTask "GetHomeFolderSizes2" -Action $action -Trigger $trigger -Principal $principal -Settings $TaskSettings
})

Invoke-Command -session $session -scriptblock $CreateScheduledTask
Write-Output "Created scheduled task for $ServerList."