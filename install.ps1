# Installer for Claude Sessions Manager for Windows

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║     Claude Sessions Manager - Installer                  ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 5) {
    Write-Host "  ❌ PowerShell 5.1+ required. You have version $psVersion" -ForegroundColor Red
    Write-Host "  Please update PowerShell." -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ PowerShell version: $psVersion" -ForegroundColor Green

# Check if Claude Code is installed
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (!$claude) {
    Write-Host "  ⚠ Claude Code not found in PATH" -ForegroundColor Yellow
    Write-Host "  Install it first: npm install -g @anthropic-ai/claude-code" -ForegroundColor Gray
    $continue = Read-Host "  Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
} else {
    Write-Host "  ✓ Claude Code found: $($claude.Source)" -ForegroundColor Green
}

# Get install location
$defaultPath = "$env:USERPROFILE\claude-sessions-win"
$installPath = Read-Host "  Install location [$defaultPath]"
if (!$installPath) { $installPath = $defaultPath }

Write-Host ""
Write-Host "  Installing to: $installPath" -ForegroundColor Cyan

# Create directory
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
    Write-Host "  ✓ Created directory" -ForegroundColor Green
}

# Copy files
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "  Copying files..." -ForegroundColor Cyan

Copy-Item "$scriptDir\claude-sessions.ps1" -Destination $installPath -Force
Copy-Item "$scriptDir\src" -Destination $installPath -Recurse -Force
Copy-Item "$scriptDir\README.md" -Destination $installPath -Force

Write-Host "  ✓ Files copied" -ForegroundColor Green

# Add to PATH (optional)
Write-Host ""
$addToPath = Read-Host "  Add to PATH for global access? (y/n)"
if ($addToPath -eq "y") {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$installPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", "User")
        Write-Host "  ✓ Added to PATH" -ForegroundColor Green
        Write-Host "  ! Restart your terminal to use 'claude-sessions' command" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Already in PATH" -ForegroundColor Green
    }
}

# Create shortcut (optional)
Write-Host ""
$createShortcut = Read-Host "  Create desktop shortcut? (y/n)"
if ($createShortcut -eq "y") {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktop\Claude Sessions.lnk"
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoExit -File `"$installPath\claude-sessions.ps1`""
    $shortcut.WorkingDirectory = $installPath
    $shortcut.Description = "Claude Sessions Manager"
    $shortcut.Save()
    
    Write-Host "  ✓ Desktop shortcut created" -ForegroundColor Green
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║     Installation Complete!                               ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  To run:" -ForegroundColor Cyan
Write-Host "    cd $installPath" -ForegroundColor Gray
Write-Host "    .\claude-sessions.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Or use the desktop shortcut!" -ForegroundColor Cyan
Write-Host ""
