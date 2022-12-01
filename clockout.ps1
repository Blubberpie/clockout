$w = Read-Host -Prompt "Work description"
$p = Read-Host -Prompt "Project"
$d = Read-Host -Prompt "Duration (int)"
$s = Read-Host -Prompt "Submit?"
$t = Read-Host -Prompt "Execution time (24 hr)"
$rand = Read-Host -Prompt "Randomize minutes?"
$b = Read-Host -Prompt "Run headed mode?"

$work = if ($w) { "-w " + "`"{0}`"" -f $w } else { "" }
$proj = if ($p) { "-p " + "`"{0}`"" -f $p } else { "" }
$dur = if ($d) { "-d " + $d } else { "" }
$submit = if ($s -eq "y" -or $s -eq "Y") { "-s" } else { "" }
$exc_time = if ($t) { $t } else { 18 }
$randomize = if ($rand) { $true } else { $false }
$use_browser = if ($b -eq "y" -or $s -eq "Y") { "-b" } else { "" }

$action = New-ScheduledTaskAction -Execute "path/to/conda.bat" -Argument (
    "run " +
    "-n " +
    "base " +
    "python " +
    "path/to/clockout.py " +
    $work + $proj + $dur + $submit + $use_browser
)
$rnd_min = if ($randomize) { Get-Random -Minimum 0 -Maximum 2 } else { 0 }
$rnd_sec = if ($randomize) { Get-Random -Minimum 0 -Maximum 10 } else { 0 }
$dt_str = "${exc_time}:$rnd_min$rnd_sec"
$dt = [DateTime]::ParseExact($dt_str, "HH:mm", $null)
$trigger = New-ScheduledTaskTrigger -Once -At $dt
$trigger.StartBoundary = [DateTime]::Parse($trigger.StartBoundary).ToLocalTime().ToString("s")
$trigger.EndBoundary = $dt.AddMinutes(1).ToString('s')
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -DeleteExpiredTaskAfter 00:00:01

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName "Clock Out" -Description "Clocks Out"
