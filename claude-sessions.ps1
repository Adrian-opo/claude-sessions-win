#!/usr/bin/env pwsh
# Claude Sessions Manager for Windows
# Entry point

param(
    [string]$Command = "view",
    [string]$Id
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/src/Utils.ps1"
. "$ScriptDir/src/SessionManager.ps1"

# Colors
$ErrorColor = [ConsoleColor]::Red
$WarningColor = [ConsoleColor]::Yellow
$SuccessColor = [ConsoleColor]::Green

switch ($Command) {
    "view" {
        & "$ScriptDir/src/Tamagotchi.ps1"
    }
    "table" {
        & "$ScriptDir/src/Dashboard.ps1"
    }
    "json" {
        $sessions = Get-ClaudeSessions
        $sessions | ConvertTo-Json -Depth 5
    }
    "new" {
        Write-Host "Creating new Claude Code session..." -ForegroundColor Cyan
        $name = Read-Host "Session name"
        if ($name) {
            New-ClaudeSession -Name $name
            Write-Host "Session '$name' created!" -ForegroundColor Green
        }
    }
    "resume" {
        if ($Id) {
            Resume-ClaudeSession -Id $Id
        } else {
            $sessions = Get-ClaudeSessions | Where-Object { $_.status -ne "New" }
            if ($sessions.Count -eq 0) {
                Write-Host "No sessions to resume." -ForegroundColor Yellow
                return
            }
            Write-Host "Select a session to resume:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $sessions.Count; $i++) {
                $s = $sessions[$i]
                Write-Host "  [$($i + 1)] $($s.name) - $($s.status) - $($s.directory)" -ForegroundColor Cyan
            }
            $choice = Read-Host "Choice"
            if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $sessions.Count) {
                Resume-ClaudeSession -Id $sessions[$choice - 1].id
            }
        }
    }
    "next" {
        $inputSessions = Get-ClaudeSessions | Where-Object { $_.status -eq "Input" }
        if ($inputSessions.Count -eq 0) {
            Write-Host "No sessions waiting for input." -ForegroundColor Yellow
            return
        }
        Resume-ClaudeSession -Id $inputSessions[0].id
    }
    "help" {
        Write-Host @"
Claude Sessions Manager for Windows

Usage: .\claude-sessions.ps1 [command] [options]

Commands:
  view      Tamagotchi view (pixel art creatures)
  table     Table dashboard (default)
  json      Output sessions as JSON
  new       Create new session
  resume    Resume existing session
  next      Jump to next session waiting for input
  help      Show this help

Examples:
  .\claude-sessions.ps1              # Show dashboard
  .\claude-sessions.ps1 json         # JSON output
  .\claude-sessions.ps1 new          # Create session
  .\claude-sessions.ps1 resume       # Pick session to resume
  .\claude-sessions.ps1 next         # Jump to input session
"@ -ForegroundColor White
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Use 'help' to see available commands." -ForegroundColor Yellow
        exit 1
    }
}
