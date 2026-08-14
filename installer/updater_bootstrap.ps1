param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Impl = Join-Path $PSScriptRoot "updater_v4.ps1"
if (-not (Test-Path $Impl)) {
    throw "ImPuls updater runtime is incomplete: updater_v4.ps1 is missing."
}

# Windows PowerShell 5.1 treats UTF-8 files without BOM as the current ANSI
# code page. Read the localized implementation explicitly as UTF-8, then parse
# it in memory. This keeps the visible updater UI localized and syntax-safe on
# Windows 10/11 without requiring PowerShell 7.
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Source = [System.IO.File]::ReadAllText($Impl, $Utf8)
$Runner = [ScriptBlock]::Create($Source)
& $Runner -InstallDir $InstallDir -Background:$Background -WaitForGameExit:$WaitForGameExit
exit $LASTEXITCODE
