$ErrorActionPreference = "Stop"

$Root = Get-Location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Overlay = Join-Path $ScriptDir "overlay"

if (!(Test-Path (Join-Path $Root "launch.py")) -or !(Test-Path (Join-Path $Root "GodotSimulation"))) {
    throw "Run this from the KvatiTown project root, for example: C:\Users\sergi\PycharmProjects\KvatiTown"
}

$Backup = Join-Path $Root ("kvati_backup_leader_speed_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$Files = @(
    "GodotSimulation/ducky-bot/scripts/LeadTruckDriver.gd",
    "GodotSimulation/ducky-bot/scripts/WheelCommandServer.gd",
    "GodotSimulation/ducky-bot/scenes/convoying.tscn",
    "duckiebot/wheel_driver/godot_wheels_driver.py",
    "servers/convoying/virtual_server.py",
    "servers/templates/convoying.py"
)

foreach ($File in $Files) {
    $Source = Join-Path $Root $File
    if (Test-Path $Source) {
        $Dest = Join-Path $Backup $File
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Dest -Force
    }
}

Copy-Item -Path (Join-Path $Overlay "*") -Destination $Root -Recurse -Force
Write-Host "Applied KvatiTown leader truck speed/path patch. Backup: $Backup"
Write-Host "Run: python launch.py --sim --task convoying"
