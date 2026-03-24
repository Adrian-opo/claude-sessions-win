# Session Manager for Claude Code on Windows
# Reads session data from ~/.claude/sessions/ and ~/.claude/projects/

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
    $projectsPath = Get-ProjectsPath
    $sessions = @()
    
    Write-Host "Debug: Sessions path: $sessionsPath" -ForegroundColor DarkGray
    Write-Host "Debug: Projects path: $projectsPath" -ForegroundColor DarkGray
    
    if (!(Test-Path $sessionsPath)) {
        Write-Host "Debug: Sessions path does not exist" -ForegroundColor DarkGray
        return $sessions
    }
    
    # Read all session JSON files
    $sessionFiles = Get-ChildItem -Path $sessionsPath -Filter "*.json"
    Write-Host "Debug: Found $($sessionFiles.Count) session file(s)" -ForegroundColor DarkGray
    
    foreach ($file in $sessionFiles) {
        try {
            Write-Host "Debug: Reading $($file.Name)" -ForegroundColor DarkGray
            
            $jsonContent = Get-Content $file.FullName -Raw
            if (!$jsonContent) {
                Write-Host "Debug: Empty file, skipping" -ForegroundColor DarkGray
                continue
            }
            
            $sessionData = $jsonContent | ConvertFrom-Json
            
            if (!$sessionData) {
                Write-Host "Debug: Failed to parse JSON" -ForegroundColor DarkGray
                continue
            }
            
            # Get process info
            $process = $null
            if ($sessionData.pid) {
                $process = Get-Process -Id $sessionData.pid -ErrorAction SilentlyContinue
            }
            $isRunning = $null -ne $process
            
            Write-Host "Debug: PID=$($sessionData.pid), Running=$isRunning" -ForegroundColor DarkGray
            
            # Initialize defaults
            $contextTokens = 0
            $lastActivity = $null
            $model = "unknown"
            $status = "Idle"
            
            # Find project directory that contains this session
            if ($sessionData.sessionId) {
                Write-Host "Debug: SessionId=$($sessionData.sessionId)" -ForegroundColor DarkGray
                
                if (Test-Path $projectsPath) {
                    $projectDirs = Get-ChildItem -Path $projectsPath -Directory -ErrorAction SilentlyContinue
                    foreach ($projDir in $projectDirs) {
                        $jsonlPath = Join-Path $projDir.FullName "$($sessionData.sessionId).jsonl"
                        if (Test-Path $jsonlPath) {
                            Write-Host "Debug: Found JSONL at $jsonlPath" -ForegroundColor DarkGray
                            
                            # Read the last few lines of the JSONL file
                            $lastLines = Get-Content $jsonlPath -Tail 10 -ErrorAction SilentlyContinue
                            foreach ($line in $lastLines) {
                                try {
                                    $entry = $line | ConvertFrom-Json
                                    
                                    # Extract context tokens
                                    if ($entry.contextTokens -and $entry.contextTokens -gt $contextTokens) {
                                        $contextTokens = $entry.contextTokens
                                    }
                                    
                                    # Extract model
                                    if ($entry.model) {
                                        $model = $entry.model
                                    }
                                    
                                    # Extract timestamp
                                    if ($entry.timestamp) {
                                        $lastActivity = $entry.timestamp
                                    }
                                    
                                    # Check for streaming/tool state
                                    if ($entry.type -eq "user" -or $entry.type -eq "assistant") {
                                        $status = "Working"
                                    }
                                } catch {
                                    # Skip invalid JSON lines
                                }
                            }
                            break
                        }
                    }
                }
            }
            
            # If no activity found, use startedAt as fallback
            if (!$lastActivity -and $sessionData.startedAt) {
                try {
                    $startTime = [DateTime]::UnixEpoch.AddMilliseconds($sessionData.startedAt)
                    $lastActivity = $startTime.ToString("o")
                } catch {
                    Write-Host "Debug: Failed to parse startedAt: $($sessionData.startedAt)" -ForegroundColor DarkGray
                }
            }
            
            # Generate a name from the directory
            $name = "unknown"
            if ($sessionData.sessionId) {
                $name = $sessionData.sessionId.Substring(0, 8)
            }
            if ($sessionData.cwd) {
                try {
                    $name = Split-Path $sessionData.cwd -Leaf
                } catch {
                    Write-Host "Debug: Failed to get directory name from $($sessionData.cwd)" -ForegroundColor DarkGray
                }
            }
            
            # Determine final status
            if (!$isRunning) {
                $status = "Idle"
            } elseif ($contextTokens -eq 0) {
                $status = "New"
            } elseif ($status -ne "Working") {
                $status = "Idle"
            }
            
            Write-Host "Debug: Session: name=$name, status=$status, tokens=$contextTokens" -ForegroundColor DarkGray
            
            if ($isRunning) {
                $sessions += [PSCustomObject]@{
                    id = $sessionData.sessionId
                    name = $name
                    pid = $sessionData.pid
                    directory = $sessionData.cwd
                    projectPath = $sessionData.projectPath
                    status = $status
                    model = $model -replace "claude-", ""
                    contextTokens = $contextTokens
                    lastActivity = $lastActivity
                    createdAt = $null
                }
                
                try {
                    if ($sessionData.startedAt) {
                        $sessions[-1].createdAt = [DateTime]::UnixEpoch.AddMilliseconds($sessionData.startedAt).ToString("o")
                    }
                } catch {
                    # Ignore
                }
            }
        } catch {
            Write-Warning "Failed to read session $($file.Name): $_"
            Write-Host "Debug: Error details: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    
    return $sessions
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
