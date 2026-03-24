# Utility functions for Claude Sessions Manager

$Colors = @{
    Working = [ConsoleColor]::Green
    Input = [ConsoleColor]::Yellow
    Idle = [ConsoleColor]::DarkBlue
    New = [ConsoleColor]::DarkGray
    Default = [ConsoleColor]::White
}

$StatusIcons = @{
    Working = "●"
    Input = "●"
    Idle = "○"
    New = "◌"
}

function Write-Colored {
    param(
        [string]$Text,
        [ConsoleColor]$Color = $Colors.Default
    )
    
    Write-Host $Text -ForegroundColor $Color -NoNewline
}

function Write-Status {
    param([string]$Status)
    
    $icon = $StatusIcons[$Status]
    $color = $Colors[$Status]
    
    Write-Colored "$icon " $color
    Write-Colored "$Status " $color
}

function Format-RelativeTime {
    param([string]$Timestamp)
    
    if (!$Timestamp) {
        return "—"
    }
    
    try {
        $time = [DateTime]::Parse($Timestamp)
        $diff = (Get-Date) - $time
        
        if ($diff.TotalSeconds -lt 60) {
            return "< 1m"
        } elseif ($diff.TotalMinutes -lt 60) {
            return "$([math]::Floor($diff.TotalMinutes))m"
        } elseif ($diff.TotalHours -lt 24) {
            return "$([math]::Floor($diff.TotalHours))h"
        } else {
            return "$([math]::Floor($diff.TotalDays))d"
        }
    } catch {
        return $Timestamp
    }
}

function Format-Number {
    param([int]$Number)
    
    if ($Number -ge 1000000) {
        return "$([math]::Round($Number / 1000000, 1))M"
    } elseif ($Number -ge 1000) {
        return "$([math]::Round($Number / 1000, 1))k"
    } else {
        return $Number.ToString()
    }
}

function Clear-Screen {
    Clear-Host
}

function Get-ConsoleSize {
    $width = $Host.UI.RawUI.WindowSize.Width
    $height = $Host.UI.RawUI.WindowSize.Height
    return @{ Width = $width; Height = $height }
}

function Write-TableHeader {
    param(
        [string[]]$Columns,
        [int[]]$Widths
    )
    
    $line = "+"
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $line += "-" * ($Widths[$i] + 2)
        if ($i -lt $Columns.Count - 1) { $line += "+" }
    }
    $line += "+"
    Write-Host $line -ForegroundColor DarkGray
    
    $header = "|"
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $header += " " + $Columns[$i].PadRight($Widths[$i]) + " "
        if ($i -lt $Columns.Count - 1) { $header += "|" }
    }
    $header += "|"
    Write-Host $header -ForegroundColor White
    
    $line = "+"
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $line += "-" * ($Widths[$i] + 2)
        if ($i -lt $Columns.Count - 1) { $line += "+" }
    }
    $line += "+"
    Write-Host $line -ForegroundColor DarkGray
}

function Write-TableRow {
    param(
        [string[]]$Cells,
        [int[]]$Widths,
        [ConsoleColor]$Color = $Colors.Default
    )
    
    $row = "|"
    for ($i = 0; $i -lt $Cells.Count; $i++) {
        $row += " " + $Cells[$i].PadRight($Widths[$i]) + " "
        if ($i -lt $Cells.Count - 1) { $row += "|" }
    }
    $row += "|"
    Write-Host $row -ForegroundColor $Color
}

function Write-TableFooter {
    param(
        [int[]]$Widths
    )
    
    $line = "+"
    for ($i = 0; $i -lt $Widths.Count; $i++) {
        $line += "-" * ($Widths[$i] + 2)
        if ($i -lt $Widths.Count - 1) { $line += "+" }
    }
    $line += "+"
    Write-Host $line -ForegroundColor DarkGray
}

function Write-HelpText {
    param([string]$Text)
    
    Write-Host $Text -ForegroundColor DarkGray -NoNewline
}
