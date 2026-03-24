# Session Manager for Claude Code on Windows
# Reads session data from ~/.claude/sessions/

function Get-ClaudeConfigPath {
    return "$env:USERPROFILE\.claude"
}

function Get-SessionsPath {
    return "$(Get-ClaudeConfigPath)\sessions"
}

function Get-ProjectsPath {
    return "$(Get-ClaudeConfigPath)\projects"
}

function Get-ClaudeSessions {
    $sessionsPath = Get-SessionsPath
    $sessions = @()
    
    if (!(Test-Path $sessionsPath)) {
        return $sessions
    }
    
    # Read all session JSON files
    Get-ChildItem -Path $sessionsPath -Filter "*.json" | ForEach-Object {
        try {
            $sessionData = Get-Content $_.FullName -Raw | ConvertFrom-Json
            
            # Get process info
            $process = Get-Process -Id $sessionData.pid -ErrorAction SilentlyContinue
            $isRunning = $null -ne $process
            
            # Try to get project state for more info
            $projectState = $null
            $contextTokens = 0
            $lastActivity = $null
            $model = "unknown"
            
            if ($sessionData.projectPath) {
                $projectHash = Get-ProjectHash -Path $sessionData.projectPath
                $statePath = "$(Get-ProjectsPath)\$projectHash\state.json"
                if (Test-Path $statePath) {
                    $projectState = Get-Content $statePath -Raw | ConvertFrom-Json
                    
                    if ($projectState.contextTokens) {
                        $contextTokens = $projectState.contextTokens
                    }
                    
                    if ($projectState.model) {
                        $model = $projectState.model
                    }
                    
                    if ($projectState.lastMessageTime) {
                        $lastActivity = $projectState.lastMessageTime
                    }
                }
            }
            
            # If no project state, use startedAt as fallback
            if (!$lastActivity -and $sessionData.startedAt) {
                $lastActivity = (Get-Date -UnixTimeSeconds ($sessionData.startedAt / 1000)).ToString("o")
            }
            
            # Generate a name from the directory
            $name = $sessionData.sessionId.Substring(0, 8)
            if ($sessionData.cwd) {
                $name = Split-Path $sessionData.cwd -Leaf
            }
            
            # Determine status
            $status = Get-SessionStatus -SessionData $sessionData -ProjectState $projectState -IsRunning $isRunning
            
            if ($isRunning) {
                $sessions += [PSCustomObject]@{
                    id = $sessionData.sessionId
                    name = $name
                    pid = $sessionData.pid
                    directory = $sessionData.cwd
                    projectPath = $sessionData.projectPath
                    status = $status
                    model = $model
                    contextTokens = $contextTokens
                    lastActivity = $lastActivity
                    createdAt = (Get-Date -UnixTimeSeconds ($sessionData.startedAt / 1000)).ToString("o")
                }
            }
        } catch {
            Write-Warning "Failed to read session $($_.Name): $_"
        }
    }
    
    return $sessions
}

function Get-SessionStatus {
    param(
        $SessionData,
        $ProjectState,
        $IsRunning
    )
    
    if (!$IsRunning) {
        return "Idle"
    }
    
    # Check if there's any activity
    if (!$SessionData.startedAt) {
        return "New"
    }
    
    # If we have project state, check for pending approvals
    if ($ProjectState) {
        if ($ProjectState.pendingApproval -eq $true) {
            return "Input"
        }
        
        if ($ProjectState.isStreaming -eq $true -or $ProjectState.isToolRunning -eq $true) {
            return "Working"
        }
        
        if ($ProjectState.lastMessageTime) {
            try {
                $lastMsg = [DateTime]::Parse($ProjectState.lastMessageTime)
                $timeSince = (Get-Date) - $lastMsg
                
                if ($timeSince.TotalMinutes -lt 2) {
                    return "Working"
                }
            } catch {
                # Ignore parse errors
            }
        }
    }
    
    # Check how long since session started
    try {
        $started = Get-Date -UnixTimeSeconds ($SessionData.startedAt / 1000)
        $timeSince = (Get-Date) - $started
        
        if ($timeSince.TotalMinutes -lt 1) {
            return "New"
        }
    } catch {
        # Ignore parse errors
    }
    
    # Default to Idle if nothing else matches
    return "Idle"
}

function Get-ProjectHash {
    param([string]$Path)
    
    # Create a simple hash from the path
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Path)
    $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower().Substring(0, 8)
}

function New-ClaudeSession {
    param([string]$Name)
    
    $cwd = Get-Location
    $claudePath = (Get-Command claude -ErrorAction SilentlyContinue).Source
    
    if (!$claudePath) {
        Write-Host "Claude Code not found. Make sure it's installed." -ForegroundColor Red
        return
    }
    
    # Start Claude Code in a new PowerShell window
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "claude"
    
    Write-Host "Claude Code started. Session will appear in dashboard once initialized." -ForegroundColor Green
}

function Resume-ClaudeSession {
    param([string]$Id)
    
    $session = Get-ClaudeSessions | Where-Object { $_.id -eq $Id }
    
    if (!$session) {
        Write-Host "Session not found: $Id" -ForegroundColor Red
        return
    }
    
    # Check if process is still running
    $process = Get-Process -Id $session.pid -ErrorAction SilentlyContinue
    
    if (!$process) {
        Write-Host "Session process is no longer running." -ForegroundColor Yellow
        Write-Host "Starting new Claude Code session..." -ForegroundColor Cyan
        New-ClaudeSession -Name $session.name
        return
    }
    
    # Attach to the session (for now, just open the directory)
    Set-Location $session.directory
    Write-Host "Switched to session '$($session.name)' directory: $($session.directory)" -ForegroundColor Green
    Write-Host "Claude Code should be running in PID $($session.pid)" -ForegroundColor Cyan
}

function Remove-ClaudeSession {
    param([string]$Id)
    
    $session = Get-ClaudeSessions | Where-Object { $_.id -eq $Id }
    
    if (!$session) {
        Write-Host "Session not found: $Id" -ForegroundColor Red
        return
    }
    
    $process = Get-Process -Id $session.pid -ErrorAction SilentlyContinue
    
    if ($process) {
        Stop-Process -Id $session.pid -Force
        Write-Host "Session '$($session.name)' terminated." -ForegroundColor Green
    }
}
