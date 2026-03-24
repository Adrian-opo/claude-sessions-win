# Tamagotchi View for Claude Sessions Manager
# Visual dashboard with pixel-art creatures

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/Utils.ps1"
. "$ScriptDir/SessionManager.ps1"

# Tamagotchi state
$script:SelectedIndex = 0
$script:Sessions = @()
$script:Page = 0
$script:PageSize = 4
$script:ZoomedRoom = $null

# Pixel art creatures (8x8 grid using half-block characters)
$Creatures = @{
    Working = @'
  ▄▄▄▄▄▄  
  █●●●●█  
  █●●●●█  
  █●▀▀●█  
  █●●●●█  
  ▀▀█▀█▀  
    █ █   
    ▀ ▀   
'@
    Input = @'
  ▄▄▄▄▄▄  
  █▼▼▼▼█  
  █▼▼▼▼█  
  █▼▄▄▼█  
  █▼▼▼▼█  
  ▀▀█▀█▀  
    █ █   
    ▀ ▀   
'@
    Idle = @'
  ▄▄▄▄▄▄  
  █────█  
  █────█  
  █─▀▀─█  
  █────█  
  ▀▀█▀█▀  
   Z Z Z  
    ▀ ▀   
'@
    New = @'
  ▄▄▄▄▄▄  
  █ ● ● █  
  █  ●  █  
  █ ● ● █  
  █  ●  █  
  ▀▀█▀█▀  
    █ █   
    ▀ ▀   
'@
}

$CreatureColors = @{
    Working = [ConsoleColor]::Green
    Input = [ConsoleColor]::Yellow
    Idle = [ConsoleColor]::DarkBlue
    New = [ConsoleColor]::DarkGray
}

function Write-Creature {
    param(
        [string]$Status,
        [int]$Left = 0,
        [int]$Top = 0
    )
    
    $creature = $Creatures[$Status]
    $color = $CreatureColors[$Status]
    
    if (!$creature) { return }
    
    $lines = $creature -split "`n"
    $row = $Top
    
    foreach ($line in $lines) {
        if ($line) {
            $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $Left, $row
            Write-Host $line -ForegroundColor $color -NoNewline
            $row++
        }
    }
}

function Get-Rooms {
    param($Sessions)
    
    $rooms = @{}
    
    foreach ($session in $Sessions) {
        $repo = $session.repo
        if (!$repo) { $repo = "unknown" }
        
        if (!$rooms[$repo]) {
            $rooms[$repo] = @()
        }
        $rooms[$repo] += $session
    }
    
    return $rooms
}

function Show-Tamagotchi {
    Clear-Host
    
    Write-Host ""
    Write-Host "  +========================================================+" -ForegroundColor Magenta
    Write-Host "  |     Claude Sessions - Tamagotchi View                  |" -ForegroundColor Magenta
    Write-Host "  |     Press 'v' for table, 'q' to quit                   |" -ForegroundColor Magenta
    Write-Host "  +========================================================+" -ForegroundColor Magenta
    Write-Host ""
    
    # Load sessions
    $script:Sessions = @(Get-ClaudeSessions)
    
    if ($script:Sessions.Count -eq 0) {
        Write-Host "  No active sessions." -ForegroundColor DarkGray
        Write-Host ""
        return
    }
    
    # Group by repo (rooms)
    $rooms = Get-Rooms -Sessions $script:Sessions
    $roomNames = @($rooms.Keys)
    
    if ($roomNames.Count -eq 0) { return }
    
    # Pagination
    $totalPages = [math]::Ceiling($roomNames.Count / $script:PageSize)
    $currentPage = [math]::Min($script:Page, $totalPages - 1)
    
    $startIdx = $currentPage * $script:PageSize
    $endIdx = [math]::Min($startIdx + $script:PageSize, $roomNames.Count)
    
    # Display rooms
    $cursorY = 3
    $cursorX = 2
    
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        $roomName = $roomNames[$i]
        $sessions = $rooms[$roomName]
        
        # Room header
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $cursorX, $cursorY
        Write-Host "┌────────────────────────────────────┐" -ForegroundColor DarkGray -NoNewline
        $cursorY++
        
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($cursorX + 2), $cursorY
        Write-Host "Room: $roomName" -ForegroundColor Cyan -NoNewline
        $cursorY++
        
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($cursorX + 2), $cursorY
        Write-Host "Sessions: $($sessions.Count)" -ForegroundColor DarkGray -NoNewline
        $cursorY++
        
        # Display creatures for each session in room
        $creatureX = $cursorX + 2
        foreach ($session in $sessions) {
            Write-Creature -Status $session.status -Left $creatureX -Top $cursorY
            
            # Session name below creature
            $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $creatureX, ($cursorY + 10)
            $nameDisplay = $session.name
            if ($nameDisplay.Length -gt 16) {
                $nameDisplay = $nameDisplay.Substring(0, 14) + "..."
            }
            Write-Host $nameDisplay.PadRight(16) -ForegroundColor White -NoNewline
            
            $creatureX += 18
        }
        
        $cursorY += 13
        $cursorX = 2
    }
    
    # Footer
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 2, ($cursorY + 2)
    Write-Host "  Page: $($currentPage + 1)/$totalPages" -ForegroundColor DarkGray -NoNewline
    
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 30, ($cursorY + 2)
    Write-Host "  j/k: Page  |  v: Table View  |  q: Quit" -ForegroundColor DarkGray -NoNewline
    
    Write-Host ""
    Write-Host ""
    
    # Legend
    Write-Host "  Legend: " -ForegroundColor DarkGray -NoNewline
    Write-Colored "● Working " ([ConsoleColor]::Green)
    Write-Colored "● Input " ([ConsoleColor]::Yellow)
    Write-Colored "○ Idle " ([ConsoleColor]::DarkBlue)
    Write-Colored "◌ New" ([ConsoleColor]::DarkGray)
    Write-Host ""
}

function Handle-TamagotchiInput {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            74 { # j - next page
                $rooms = Get-Rooms -Sessions $script:Sessions
                $totalPages = [math]::Ceiling($rooms.Keys.Count / $script:PageSize)
                if ($script:Page -lt $totalPages - 1) {
                    $script:Page++
                }
                Show-Tamagotchi
            }
            75 { # k - prev page
                if ($script:Page -gt 0) {
                    $script:Page--
                }
                Show-Tamagotchi
            }
            86 { # v - table view
                Show-Dashboard
            }
            81 { # q - quit
                Clear-Host
                exit 0
            }
        }
    }
}

# Main loop
Show-Tamagotchi

while ($true) {
    Start-Sleep -Milliseconds 100
    Handle-TamagotchiInput
}
