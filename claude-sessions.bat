@echo off
REM Claude Sessions Manager for Windows
REM Batch wrapper to run PowerShell script

setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\claude-sessions.ps1" %*
endlocal
