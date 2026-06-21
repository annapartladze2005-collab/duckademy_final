$ErrorActionPreference = "Stop"
$root = Get-Location
$patchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$overlay = Join-Path $patchDir "overlay"

$files = @(
    "GodotSimulation\ducky-bot\scripts\KvatiLeaderPathFollow.gd",
    "GodotSimulation\ducky-bot\scripts\WheelCommandServer.gd",
    "GodotSimulation\ducky-bot\scenes\convoying.tscn"
)

# Only these existing project files must already exist. The new path-follow script is created by this patch.
$mustExist = @(
    "GodotSimulation\ducky-bot\scripts\WheelCommandServer.gd",
    "GodotSimulation\ducky-bot\scenes\convoying.tscn"
)

foreach ($rel in $mustExist) {
    $target = Join-Path $root $rel
    if (!(Test-Path $target)) {
        Write-Host "Missing expected project file: $target" -ForegroundColor Red
        Write-Host "Run this from the KvatiTown project root." -ForegroundColor Yellow
        exit 1
    }
}
foreach ($rel in $files) {
    $source = Join-Path $overlay $rel
    if (!(Test-Path $source)) {
        Write-Host "Missing patch overlay file: $source" -ForegroundColor Red
        exit 1
    }
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "kvati_backup_leader_path_system_$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

foreach ($rel in $mustExist) {
    $target = Join-Path $root $rel
    $backupPath = Join-Path $backup $rel
    $backupParent = Split-Path -Parent $backupPath
    New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
    Copy-Item $target $backupPath -Force
}

foreach ($rel in $files) {
    $target = Join-Path $root $rel
    $source = Join-Path $overlay $rel
    $targetParent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    Copy-Item $source $target -Force
}

Write-Host "Applied KvatiTown PATH-SYSTEM leader truck fix." -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host "Run: python launch.py --sim --task convoying" -ForegroundColor Cyan
Write-Host "Expected logs: [KvatiLeaderPath] ready / moving and [WheelServer] Leader speed command" -ForegroundColor Yellow
