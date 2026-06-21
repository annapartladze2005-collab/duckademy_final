$ErrorActionPreference = "Stop"

$root = Get-Location
$patchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$overlay = Join-Path $patchDir "overlay"

$files = @(
    "GodotSimulation\ducky-bot\scripts\LeadTruckDriver.gd",
    "GodotSimulation\ducky-bot\scripts\WheelCommandServer.gd",
    "GodotSimulation\ducky-bot\scenes\convoying.tscn",
    "duckiebot\wheel_driver\godot_wheels_driver.py",
    "servers\convoying\virtual_server.py",
    "servers\templates\convoying.py"
)

foreach ($rel in $files) {
    $target = Join-Path $root $rel
    $source = Join-Path $overlay $rel
    if (!(Test-Path $target)) {
        Write-Host "Missing expected project file: $target" -ForegroundColor Red
        Write-Host "Run this from the KvatiTown project root." -ForegroundColor Yellow
        exit 1
    }
    if (!(Test-Path $source)) {
        Write-Host "Missing patch overlay file: $source" -ForegroundColor Red
        exit 1
    }
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "kvati_backup_leader_force_move_$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

foreach ($rel in $files) {
    $target = Join-Path $root $rel
    $backupPath = Join-Path $backup $rel
    $backupParent = Split-Path -Parent $backupPath
    New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
    Copy-Item $target $backupPath -Force
}

foreach ($rel in $files) {
    $target = Join-Path $root $rel
    $source = Join-Path $overlay $rel
    Copy-Item $source $target -Force
}

Write-Host "Applied FORCE-MOVE leader truck fix." -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host "Run: python launch.py --sim --task convoying" -ForegroundColor Cyan
Write-Host "Expected terminal logs: [LeadTruckDriver FORCE] ready / moving" -ForegroundColor Yellow
