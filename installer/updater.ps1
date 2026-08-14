param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$CurrentDir = Join-Path $InstallDir "current"
$NeedsRepair = -not (Test-Path (Join-Path $CurrentDir "ImPuls.exe")) -or -not (Test-Path (Join-Path $CurrentDir "ImPuls.pck"))
$Target = if ($NeedsRepair) { Join-Path $PSScriptRoot "repair_sync.ps1" } else { Join-Path $PSScriptRoot "updater_bootstrap.ps1" }

if (-not (Test-Path $Target)) {
    throw "ImPuls updater runtime is incomplete: $([IO.Path]::GetFileName($Target)) is missing."
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Source = [System.IO.File]::ReadAllText($Target, $Utf8)
$Runner = [ScriptBlock]::Create($Source)
& $Runner -InstallDir $InstallDir -Background:$Background -WaitForGameExit:$WaitForGameExit
exit $LASTEXITCODE
