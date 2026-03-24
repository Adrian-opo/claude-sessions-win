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
        return "--"
    }
    
    try {
        $time = [DateTime]::Parse($Timestamp)
        $diff = (Get-Date) - $time
        
        if ($diff.TotalSeconds -lt 60) {
            return "<1m"
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
    
    $PIPE = "|"
    $DASH = "-"
    $PLUS = "+"
    
    $line = $PLUS
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $line += $DASH * ($Widths[$i] + 2)
        if ($i -lt $Columns.Count - 1) { $line += $PLUS }
    }
    $line += $PLUS
    Write-Host $line -ForegroundColor DarkGray
    
    $header = $PIPE
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $header += " " + $Columns[$i].PadRight($Widths[$i]) + " "
        if ($i -lt $Columns.Count - 1) { $header += $PIPE }
    }
    $header += $PIPE
    Write-Host $header -ForegroundColor White
    
    $line = $PLUS
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $line += $DASH * ($Widths[$i] + 2)
        if ($i -lt $Columns.Count - 1) { $line += $PLUS }
    }
    $line += $PLUS
    Write-Host $line -ForegroundColor DarkGray
}

function Write-TableRow {
    param(
        [string[]]$Cells,
        [int[]]$Widths,
        [ConsoleColor]$Color = $Colors.Default
    )
    
    $PIPE = "|"
    
    $row = $PIPE
    for ($i = 0; $i -lt $Cells.Count; $i++) {
        $row += " " + $Cells[$i].PadRight($Widths[$i]) + " "
        if ($i -lt $Cells.Count - 1) { $row += $PIPE }
    }
    $row += $PIPE
    Write-Host $row -ForegroundColor $Color
}

function Write-TableFooter {
    param(
        [int[]]$Widths
    )
    
    $PLUS = "+"
    $DASH = "-"
    
    $line = $PLUS
    for ($i = 0; $i -lt $Widths.Count; $i++) {
        $line += $DASH * ($Widths[$i] + 2)
        if ($i -lt $Widths.Count - 1) { $line += $PLUS }
    }
    $line += $PLUS
    Write-Host $line -ForegroundColor DarkGray
}

function Write-HelpText {
    param([string]$Text)
    
    Write-Host $Text -ForegroundColor DarkGray -NoNewline
}

function Format-ContextBar {
    param(
        [int]$Tokens,
        [int]$MaxTokens,
        [int]$Width = 15
    )
    
    if ($MaxTokens -eq 0) {
        return (" " * $Width)
    }
    
    $percentage = [math]::Min(100, ($Tokens / $MaxTokens) * 100)
    $filled = [math]::Max(1, [math]::Floor(($percentage / 100) * ($Width - 2)))
    $empty = $Width - 2 - $filled
    
    # Determine color based on usage
    $barColor = "Green"
    if ($percentage -gt 80) {
        $barColor = "Red"
    } elseif ($percentage -gt 50) {
        $barColor = "Yellow"
    }
    
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    
    # Return with color info
    return @{
        Text = $bar
        Percentage = $percentage
        Color = $barColor
    }
}

function Write-ContextBar {
    param(
        [int]$Tokens,
        [int]$MaxTokens,
        [int]$Width = 15
    )
    
    $result = Format-ContextBar -Tokens $Tokens -MaxTokens $MaxTokens -Width $Width
    
    Write-Host $result.Text -ForegroundColor $result.Color -NoNewline
}
