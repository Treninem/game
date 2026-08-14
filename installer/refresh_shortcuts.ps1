param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls"
)

$ErrorActionPreference = "SilentlyContinue"
$Launcher = Join-Path $InstallDir "launcher.vbs"
$Icon = Join-Path $InstallDir "impuls.ico"
$Wscript = Join-Path $env:WINDIR "System32\wscript.exe"

if (-not (Test-Path $Launcher) -or -not (Test-Path $Icon)) {
    exit 0
}

$Shell = New-Object -ComObject WScript.Shell

function Write-ImPulsShortcut([string]$Path) {
    try {
        if (Test-Path $Path) { Remove-Item $Path -Force }
        $Shortcut = $Shell.CreateShortcut($Path)
        $Shortcut.TargetPath = $Wscript
        $Shortcut.Arguments = '"' + $Launcher + '"'
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.IconLocation = $Icon + ",0"
        $Shortcut.Description = "ImPuls"
        $Shortcut.Save()
    } catch {}
}

$Desktop = [Environment]::GetFolderPath("Desktop")
$Programs = [Environment]::GetFolderPath("Programs")
$StartMenuDir = Join-Path $Programs "ImPuls"
if (-not (Test-Path $StartMenuDir)) {
    New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
}

Write-ImPulsShortcut (Join-Path $Desktop "ImPuls.lnk")
Write-ImPulsShortcut (Join-Path $StartMenuDir "ImPuls.lnk")

# Ask Explorer to refresh shell icons/associations. This helps Windows stop showing
# a cached previous icon after an automatic branding update.
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class ImPulsShellRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@
    [ImPulsShellRefresh]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
} catch {}
