param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Updater/1.1" }
$Api = "https://api.github.com/repos/$Repo/releases/latest"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"

if ($Background -and (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)) {
    exit 0
}

if ($WaitForGameExit) {
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    if (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) {
        exit 2
    }
}

try {
    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 20
} catch {
    exit 0
}

$RemoteTag = [string]$Release.tag_name
$LocalTag = if (Test-Path $TagFile) { (Get-Content $TagFile -Raw).Trim() } else { "" }
if ($RemoteTag -eq $LocalTag) {
    exit 0
}

$Asset = $Release.assets | Where-Object { $_.name -eq "ImPuls-PC-Windows-x64.zip" } | Select-Object -First 1
if (-not $Asset) {
    exit 0
}

$TempDir = Join-Path $env:TEMP ("ImPulsUpdate-" + [guid]::NewGuid())
$ZipPath = Join-Path $TempDir "ImPuls-PC-Windows-x64.zip"
$StageDir = Join-Path $TempDir "stage"
$BackupDir = Join-Path $InstallDir "backup"

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

try {
    Invoke-WebRequest -Uri $Asset.browser_download_url -Headers $Headers -OutFile $ZipPath

    $SumAsset = $Release.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" } | Select-Object -First 1
    if ($SumAsset) {
        $SumPath = Join-Path $TempDir "SHA256SUMS.txt"
        Invoke-WebRequest -Uri $SumAsset.browser_download_url -Headers $Headers -OutFile $SumPath
        $Line = Get-Content $SumPath | Where-Object { $_ -match "ImPuls-PC-Windows-x64.zip" } | Select-Object -First 1
        if ($Line) {
            $Expected = ($Line -split "\s+")[0].ToLowerInvariant()
            $Actual = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($Expected -ne $Actual) {
                throw "SHA256 verification failed"
            }
        }
    }

    Expand-Archive -Path $ZipPath -DestinationPath $StageDir -Force
    if (-not (Test-Path (Join-Path $StageDir "ImPuls.exe"))) {
        throw "Downloaded build does not contain ImPuls.exe"
    }

    if (Test-Path $BackupDir) {
        Remove-Item $BackupDir -Recurse -Force
    }
    if (Test-Path $CurrentDir) {
        Move-Item $CurrentDir $BackupDir
    }

    Move-Item $StageDir $CurrentDir
    Set-Content -Path $TagFile -Value $RemoteTag -Encoding ASCII

    if (Test-Path $BackupDir) {
        Remove-Item $BackupDir -Recurse -Force
    }

    if ($WaitForGameExit) {
        $GameExe = Join-Path $CurrentDir "ImPuls.exe"
        if (Test-Path $GameExe) {
            Start-Process -FilePath $GameExe -WorkingDirectory $CurrentDir
        }
    }
} catch {
    if (-not (Test-Path $CurrentDir) -and (Test-Path $BackupDir)) {
        Move-Item $BackupDir $CurrentDir
    }
    if (-not $Background) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "Не удалось обновить ImPuls.`nБудет запущена установленная версия.`n`n$($_.Exception.Message)",
            "ImPuls Update",
            "OK",
            "Warning"
        ) | Out-Null
    }
    if ($WaitForGameExit -and (Test-Path (Join-Path $CurrentDir "ImPuls.exe"))) {
        Start-Process -FilePath (Join-Path $CurrentDir "ImPuls.exe") -WorkingDirectory $CurrentDir
    }
} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
