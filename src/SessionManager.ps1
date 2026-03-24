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

function Get-GitBranch {
    param([string]$Directory)
    
    if (!$Directory -or !(Test-Path $Directory)) {
        return $null
    }
    
    $gitDir = Join-Path $Directory ".git"
    if (!(Test-Path $gitDir)) {
        # Try parent directories (max 3 levels)
        $parent = Split-Path $Directory -Parent
        if ($parent -ne $Directory) {
            return Get-GitBranch -Directory $parent
        }
        return $null
    }
    
    try {
        $headFile = Join-Path $gitDir "HEAD"
        if (Test-Path $headFile) {
            $headContent = Get-Content $headFile -Raw
            if ($headContent -match "ref: refs/heads/(.+)") {
                return $matches[1]
            }
        }
    } catch {
        # Ignore git errors
    }
    
    return $null
}

function Get-RepoName {
    param([string]$Directory)
    
    if (!$Directory) {
        return "unknown"
    }
    
    # Try to get from git remote
    try {
        if (Test-Path $Directory) {
            $gitDir = Join-Path $Directory ".git"
            if (Test-Path $gitDir) {
                $configFile = Join-Path $gitDir "config"
                if (Test-Path $configFile) {
                    $config = Get-Content $configFile -Raw
                    if ($config -match "url = .+/(.+)\.git") {
                        return $matches[1]
                    }
                }
            }
        }
    } catch {
        # Ignore
    }
    
    # Fallback to directory name
    return Split-Path $Directory -Leaf
}

function Get-ClaudeSessions {
    $sessionsPath = Get-SessionsPath
    $projectsPath = Get-ProjectsPath
    $sessions = @()
    
    if (!(Test-Path $sessionsPath)) {
        return $sessions
    }
    
    # Read all session JSON files
    Get-ChildItem -Path $sessionsPath -Filter "*.json" | ForEach-Object {
        try {
            $jsonContent = Get-Content $_.FullName -Raw
            if (!$jsonContent) { continue }
            
            $sessionData = $jsonContent | ConvertFrom-Json
            if (!$sessionData) { continue }
            
            # Get process info
            $process = $null
            if ($sessionData.pid) {
                $process = Get-Process -Id $sessionData.pid -ErrorAction SilentlyContinue
            }
            $isRunning = $null -ne $process
            
            # Initialize defaults
            $contextTokens = 0
            $maxContext = 200000  # Default Claude context window
            $lastActivity = $null
            $model = "unknown"
            $status = "Idle"
            $branch = $null
            $repoName = "unknown"
            
            # Find project directory that contains this session
            if ($sessionData.sessionId -and (Test-Path $projectsPath)) {
                $projectDirs = Get-ChildItem -Path $projectsPath -Directory -ErrorAction SilentlyContinue
                foreach ($projDir in $projectDirs) {
                    $jsonlPath = Join-Path $projDir.FullName "$($sessionData.sessionId).jsonl"
                    if (Test-Path $jsonlPath) {
                        # Read the last few lines of the JSONL file
                        $lastLines = Get-Content $jsonlPath -Tail 10 -ErrorAction SilentlyContinue
                        foreach ($line in $lastLines) {
                            try {
                                $entry = $line | ConvertFrom-Json
                                
                                if ($entry.contextTokens -and $entry.contextTokens -gt $contextTokens) {
                                    $contextTokens = $entry.contextTokens
                                }
                                
                                if ($entry.model) {
                                    $model = $entry.model
                                }
                                
                                if ($entry.timestamp) {
                                    $lastActivity = $entry.timestamp
                                }
                                
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
            
            # Get repo and branch info
            if ($sessionData.cwd) {
                $repoName = Get-RepoName -Directory $sessionData.cwd
                $branch = Get-GitBranch -Directory $sessionData.cwd
            }
            
            # If no activity found, use startedAt as fallback
            if (!$lastActivity -and $sessionData.startedAt) {
                try {
                    $startTime = [DateTime]::UnixEpoch.AddMilliseconds($sessionData.startedAt)
                    $lastActivity = $startTime.ToString("o")
                } catch {
                    # Ignore parse errors
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
                    # Use sessionId as fallback
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
                    maxContext = $maxContext
                    lastActivity = $lastActivity
                    createdAt = $null
                    repo = $repoName
                    branch = $branch
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
            # Skip sessions that fail to parse
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
    
    # Attach to the session (try to open the directory)
    if ($session.directory -and (Test-Path $session.directory)) {
        Set-Location $session.directory
        Write-Host "Switched to session '$($session.name)' directory: $($session.directory)" -ForegroundColor Green
    } else {
        Write-Host "Session '$($session.name)' is running (PID $($session.pid))" -ForegroundColor Green
        Write-Host "Directory not accessible: $($session.directory)" -ForegroundColor Yellow
    }
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
