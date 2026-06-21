$ErrorActionPreference = "Stop"

$root = Get-Location
$scriptPath = Join-Path $root "GodotSimulation\ducky-bot\scripts\LeadTruckDriver.gd"
$scenePath = Join-Path $root "GodotSimulation\ducky-bot\scenes\convoying.tscn"
$serverPath = Join-Path $root "servers\convoying\virtual_server.py"
$templatePath = Join-Path $root "servers\templates\convoying.py"

$required = @($scriptPath, $scenePath, $serverPath, $templatePath)
foreach ($p in $required) {
    if (!(Test-Path $p)) {
        Write-Host "Missing expected file: $p" -ForegroundColor Red
        Write-Host "Run this from the KvatiTown project root, not from inside the patch folder." -ForegroundColor Yellow
        exit 1
    }
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "kvati_backup_leader_autostart_$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($p in $required) {
    Copy-Item $p (Join-Path $backup (Split-Path $p -Leaf)) -Force
}

function Replace-InFile([string]$Path, [string]$Old, [string]$New) {
    $text = Get-Content $Path -Raw
    if ($text.Contains($Old)) {
        $text = $text.Replace($Old, $New)
        Set-Content -Path $Path -Value $text -NoNewline
    }
}

# HOTFIX: make the leader self-start. The previous patch waited for CameraStreamer TCP status,
# which can stay disconnected/unknown in this KvatiTown setup and keeps the truck frozen.
Replace-InFile $scriptPath '@export var speed: float = 0.055' '@export var speed: float = 0.080'
Replace-InFile $scriptPath '@export var start_grace_s: float = 1.0' '@export var start_grace_s: float = 0.2'
Replace-InFile $scriptPath '@export var wait_for_camera: bool = true' '@export var wait_for_camera: bool = false'
Replace-InFile $scriptPath 'var _base_speed: float = 0.055' 'var _base_speed: float = 0.080'

Replace-InFile $scenePath 'speed = 0.055' 'speed = 0.080'
Replace-InFile $scenePath 'start_grace_s = 1.0' 'start_grace_s = 0.2'
Replace-InFile $scenePath 'wait_for_camera = true' 'wait_for_camera = false'

# Keep dashboard/server default aligned with the scene. User can still tune live using the slider.
Replace-InFile $serverPath 'leader_speed = 0.055' 'leader_speed = 0.080'
Replace-InFile $serverPath "wheels.set_leader_speed(leader_speed)" "wheels.set_leader_speed(leader_speed)"

Replace-InFile $templatePath '<span id="leader-speed-val">0.055</span>' '<span id="leader-speed-val">0.080</span>'
Replace-InFile $templatePath 'id="leader-speed-slider" min="0" max="0.18" step="0.005" value="0.055"' 'id="leader-speed-slider" min="0" max="0.18" step="0.005" value="0.080"'

Write-Host "Applied leader autostart hotfix. Backup: $backup" -ForegroundColor Green
Write-Host "Run: python launch.py --sim --task convoying" -ForegroundColor Cyan
