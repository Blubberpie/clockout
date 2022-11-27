$desc = "`"{0}`"" -f $args[0]
$action = New-ScheduledTaskAction -Execute "path/to/conda.bat" -Argument (
    "run " +
    "-n " +
    "base " +
    "python " +
    "path/to/clockout.py " +
    $desc + " " +
    $args[1]
)
$rnd_min = Get-Random -Minimum 0 -Maximum 2
$rnd_sec = Get-Random -Minimum 0 -Maximum 10
$dt_str = "18:$rnd_min$rnd_sec"
$dt = [DateTime]::ParseExact($dt_str, "HH:mm", $null)
$trigger = New-ScheduledTaskTrigger -Once -At $dt
$trigger.StartBoundary = [DateTime]::Parse($trigger.StartBoundary).ToLocalTime().ToString("s")
$trigger.EndBoundary = $dt.AddMinutes(1).ToString('s')
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -DeleteExpiredTaskAfter 00:00:01

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName "Clock Out" -Description "Clocks Out"
