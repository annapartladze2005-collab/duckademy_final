@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply_kvati_leader_path_system_fix.ps1"
if errorlevel 1 exit /b %errorlevel%
pause
