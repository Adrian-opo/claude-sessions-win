# Dashboard TUI for Claude Sessions Manager

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/Utils.ps1"
. "$ScriptDir/SessionManager.ps1"

# Dashboard state
$script:SelectedIndex = 0
$script:Sessions = @()

function Show-Dashboard {
    Clear-Host
    
    Write-Host ""
    Write-Host "  +========================================================+" -ForegroundColor Cyan
    Write-Host "  |     Claude Sessions Manager for Windows                |" -ForegroundColor Cyan
    Write-Host "  |     Press 'q' to quit, 'r' to refresh                  |" -ForegroundColor Cyan
    Write-Host "  +========================================================+" -ForegroundColor Cyan
    Write-Host ""
    
    # Load sessions
    $script:Sessions = @(Get-ClaudeSessions)
    
    if ($script:Sessions.Count -eq 0) {
        Write-Host "  No active Claude Code sessions found." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Start a session with: claude" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # Column widths
    $widths = @(4, 18, 10, 22, 18, 10, 16, 10)
    $columns = @("#", "Session", "Status", "Repo/Branch", "Model", "Context", "Last")
    
    Write-TableHeader -Columns $columns -Widths $widths
    
    for ($i = 0; $i -lt $script:Sessions.Count; $i++) {
        $session = $script:Sessions[$i]
        $isSelected = ($i -eq $script:SelectedIndex)
        
        # Handle null values
        $repoBranch = "—"
        if ($session.repo) {
            if ($session.branch) {
                $repoBranch = "$($session.repo)::"$($session.branch)"
            } else {
                $repoBranch = $session.repo
            }
        }
        
        $modelName = "unknown"
        if ($session.model) {
            $modelName = $session.model
        }
        
        # Context bar with tokens
        $contextDisplay = ""
        if ($session.contextTokens -gt 0) {
            $contextBar = Format-ContextBar -Tokens $session.contextTokens -MaxTokens $session.maxContext -Width 12
            $contextDisplay = "$($session.contextTokens / 1000)k/$($session.maxContext / 1000)k"
        } else {
            $contextDisplay = "—"
        }
        
        $lastStr = Format-RelativeTime $session.lastActivity
        
        $cells = @(
            ($i + 1).ToString()
            $session.name.PadRight(18).Substring(0, 18)
            $session.status.PadRight(10).Substring(0, 10)
            $repoBranch.PadRight(22).Substring(0, 22)
            $modelName.PadRight(18).Substring(0, 18)
            $contextDisplay.PadRight(10)
            $lastStr.PadRight(10)
        )
        
        $color = switch ($session.status) {
            "Working" { [ConsoleColor]::Green }
            "Input" { [ConsoleColor]::Yellow }
            "Idle" { [ConsoleColor]::DarkBlue }
            "New" { [ConsoleColor]::DarkGray }
            default { [ConsoleColor]::White }
        }
        
        if ($isSelected) {
            Write-Host "→ " -ForegroundColor Cyan -NoNewline
            Write-TableRow -Cells $cells -Widths $widths -Color $color
        } else {
            Write-Host "  " -NoNewline
            Write-TableRow -Cells $cells -Widths $widths -Color $color
        }
    }
    
    Write-TableFooter -Widths $widths
    
    Write-Host ""
    Write-HelpText "  j/k: Navigate  |  Enter: Open  |  i: Next Input  |  x: Kill  |  r: Refresh  |  q: Quit"
    Write-Host ""
    
    # Count by status
    $statusCounts = $script:Sessions | Group-Object -Property status
    foreach ($status in $statusCounts) {
        $color = switch ($status.Name) {
            "Working" { [ConsoleColor]::Green }
            "Input" { [ConsoleColor]::Yellow }
            "Idle" { [ConsoleColor]::DarkBlue }
            "New" { [ConsoleColor]::DarkGray }
            default { [ConsoleColor]::White }
        }
        Write-Colored "  $($status.Name): $($status.Count)  " $color
    }
    
    # Total context usage
    $totalTokens = ($script:Sessions | Measure-Object -Property contextTokens -Sum).Sum
    $maxTokens = ($script:Sessions | Measure-Object -Property maxContext -Sum).Sum
    if ($totalTokens -gt 0) {
        Write-Colored "  |  Total: "$($totalTokens / 1000)k/$($maxTokens / 1000)k  " $DefaultColor
    }
    
    Write-Host ""
}

function Handle-Input {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            74 { # j - down
                if ($script:SelectedIndex -lt $script:Sessions.Count - 1) {
                    $script:SelectedIndex++
                }
                Show-Dashboard
            }
            75 { # k - up
                if ($script:SelectedIndex -gt 0) {
                    $script:SelectedIndex--
                }
                Show-Dashboard
            }
            13 { # Enter - open session
                if ($script:Sessions.Count -gt 0) {
                    $session = $script:Sessions[$script:SelectedIndex]
                    Resume-ClaudeSession -Id $session.id
                }
            }
            73 { # i - next input
                $inputSessions = $script:Sessions | Where-Object { $_.status -eq "Input" }
                if ($inputSessions.Count -gt 0) {
                    $script:SelectedIndex = $script:Sessions.IndexOf($inputSessions[0])
                }
                Show-Dashboard
            }
            88 { # x - kill session
                if ($script:Sessions.Count -gt 0) {
                    $session = $script:Sessions[$script:SelectedIndex]
                    $confirm = Read-Host "Kill session '$($session.name)' (y/n)"
                    if ($confirm -eq "y") {
                        Remove-ClaudeSession -Id $session.id
                        Show-Dashboard
                    }
                }
            }
            82 { # r - refresh
                Show-Dashboard
            }
            81 { # q - quit
                Clear-Host
                exit 0
            }
            38 { # Up arrow
                if ($script:SelectedIndex -gt 0) {
                    $script:SelectedIndex--
                }
                Show-Dashboard
            }
            40 { # Down arrow
                if ($script:SelectedIndex -lt $script:Sessions.Count - 1) {
                    $script:SelectedIndex++
                }
                Show-Dashboard
            }
        }
    }
}

# Main loop
Show-Dashboard

while ($true) {
    Start-Sleep -Milliseconds 100
    Handle-Input
}
