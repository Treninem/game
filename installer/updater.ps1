param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Updater/2.0" }
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"

if ($Background -and (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)) { exit 0 }

if ($WaitForGameExit) {
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    if (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) { exit 2 }
}

try { $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 20 } catch { exit 0 }

$RemoteTag = [string]$Release.name
$LocalTag = if (Test-Path $TagFile) { (Get-Content $TagFile -Raw).Trim() } else { "" }
if ([string]::IsNullOrWhiteSpace($RemoteTag) -or $RemoteTag -eq $LocalTag) { exit 0 }

$GameAsset = $Release.assets | Where-Object { $_.name -eq "ImPuls-PC-Windows-x64.zip" } | Select-Object -First 1
$RuntimeAsset = $Release.assets | Where-Object { $_.name -eq "ImPuls-Updater-Runtime.zip" } | Select-Object -First 1
$SumAsset = $Release.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" } | Select-Object -First 1
if (-not $GameAsset -or -not $RuntimeAsset -or -not $SumAsset) { exit 0 }

$TempDir = Join-Path $env:TEMP ("ImPulsUpdate-" + [guid]::NewGuid())
$GameZip = Join-Path $TempDir "ImPuls-PC-Windows-x64.zip"
$RuntimeZip = Join-Path $TempDir "ImPuls-Updater-Runtime.zip"
$SumsPath = Join-Path $TempDir "SHA256SUMS.txt"
$StageDir = Join-Path $TempDir "stage"
$RuntimeDir = Join-Path $TempDir "runtime"
$BackupDir = Join-Path $InstallDir "backup"

New-Item -ItemType Directory -Path $TempDir,$StageDir,$RuntimeDir -Force | Out-Null

function Verify-Asset([string]$Path, [string]$Name, [string]$SumsPath) {
    if (-not (Test-Path $SumsPath)) { throw "SHA256SUMS.txt is required" }
    $Line = Get-Content $SumsPath | Where-Object { $_ -match [regex]::Escape($Name) } | Select-Object -First 1
    if (-not $Line) { throw "Missing SHA256 entry for $Name" }
    $Expected = ($Line -split "\s+")[0].ToLowerInvariant()
    if ($Expected -notmatch '^[0-9a-f]{64}$') { throw "Invalid SHA256 entry for $Name" }
    $Actual = (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Expected -ne $Actual) { throw "SHA256 verification failed for $Name" }
}

try {
    Invoke-WebRequest -Uri $GameAsset.browser_download_url -Headers $Headers -OutFile $GameZip
    Invoke-WebRequest -Uri $RuntimeAsset.browser_download_url -Headers $Headers -OutFile $RuntimeZip
    Invoke-WebRequest -Uri $SumAsset.browser_download_url -Headers $Headers -OutFile $SumsPath
    Verify-Asset $GameZip "ImPuls-PC-Windows-x64.zip" $SumsPath
    Verify-Asset $RuntimeZip "ImPuls-Updater-Runtime.zip" $SumsPath

    Expand-Archive -Path $RuntimeZip -DestinationPath $RuntimeDir -Force
    Expand-Archive -Path $GameZip -DestinationPath $StageDir -Force
    if (-not (Test-Path (Join-Path $StageDir "ImPuls.exe"))) { throw "Downloaded build does not contain ImPuls.exe" }

    if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
    if (Test-Path $CurrentDir) { Move-Item $CurrentDir $BackupDir }
    Move-Item $StageDir $CurrentDir
    Set-Content -Path $TagFile -Value $RemoteTag -Encoding ASCII

    foreach ($Name in @("launcher.vbs", "install_update_task.ps1", "refresh_shortcuts.ps1", "impuls.ico", "updater.ps1")) {
        $Source = Join-Path $RuntimeDir $Name
        if (Test-Path $Source) { Copy-Item $Source (Join-Path $InstallDir $Name) -Force }
    }

    $TaskInstaller = Join-Path $InstallDir "install_update_task.ps1"
    if (Test-Path $TaskInstaller) {
        Start-Process powershell.exe -ArgumentList @("-NoProfile","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",$TaskInstaller,"-InstallDir",$InstallDir) -WindowStyle Hidden -Wait
    }
    $ShortcutRefresh = Join-Path $InstallDir "refresh_shortcuts.ps1"
    if (Test-Path $ShortcutRefresh) {
        Start-Process powershell.exe -ArgumentList @("-NoProfile","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",$ShortcutRefresh,"-InstallDir",$InstallDir) -WindowStyle Hidden -Wait
    }

    if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
    if ($WaitForGameExit) {
        $GameExe = Join-Path $CurrentDir "ImPuls.exe"
        if (Test-Path $GameExe) { Start-Process -FilePath $GameExe -WorkingDirectory $CurrentDir }
    }
} catch {
    if (-not (Test-Path $CurrentDir) -and (Test-Path $BackupDir)) { Move-Item $BackupDir $CurrentDir }
    if (-not $Background) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Не удалось обновить ImPuls.`nБудет запущена установленная версия.`n`n$($_.Exception.Message)","ImPuls Update","OK","Warning") | Out-Null
    }
    if ($WaitForGameExit -and (Test-Path (Join-Path $CurrentDir "ImPuls.exe"))) {
        Start-Process -FilePath (Join-Path $CurrentDir "ImPuls.exe") -WorkingDirectory $CurrentDir
    }
} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
