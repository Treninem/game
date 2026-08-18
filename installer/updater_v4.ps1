param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "Treninem/game"
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$Headers = @{
    "User-Agent" = "ImPuls-Updater/5.0"
    "Accept" = "application/vnd.github+json"
}
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"
$LogPath = Join-Path $InstallDir "update.log"
$script:Interactive = (-not $Background) -and [bool]$WaitForGameExit
$script:Form = $null
$script:Bar = $null
$script:Status = $null
$script:Detail = $null

function Write-Log([string]$Text) {
    try {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $LogPath -Value "[$stamp] $Text" -Encoding UTF8
    } catch {}
}

function Initialize-Ui {
    if (-not $script:Interactive) { return }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ImPuls — обновление"
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(560, 176)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Обновление ImPuls"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(22, 16)
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Проверка обновления..."
    $status.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $status.Location = New-Object System.Drawing.Point(22, 54)
    $status.Size = New-Object System.Drawing.Size(514, 24)
    $form.Controls.Add($status)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(22, 84)
    $bar.Size = New-Object System.Drawing.Size(514, 24)
    $bar.Minimum = 0
    $bar.Maximum = 100
    $bar.Style = "Marquee"
    $form.Controls.Add($bar)

    $detail = New-Object System.Windows.Forms.Label
    $detail.Text = ""
    $detail.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $detail.Location = New-Object System.Drawing.Point(22, 118)
    $detail.Size = New-Object System.Drawing.Size(514, 42)
    $form.Controls.Add($detail)

    $script:Form = $form
    $script:Bar = $bar
    $script:Status = $status
    $script:Detail = $detail
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Ui([string]$Status, [int]$Percent = -1, [string]$Detail = "") {
    if (-not $script:Interactive -or -not $script:Form) { return }
    $script:Status.Text = $Status
    $script:Detail.Text = $Detail
    if ($Percent -lt 0) {
        $script:Bar.Style = "Marquee"
    } else {
        $script:Bar.Style = "Blocks"
        $script:Bar.Value = [Math]::Max(0, [Math]::Min(100, $Percent))
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Close-Ui {
    if ($script:Form) {
        try { $script:Form.Close(); $script:Form.Dispose() } catch {}
        $script:Form = $null
    }
}

function Format-Bytes([long]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N2} ГБ" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} МБ" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N0} КБ" -f ($Bytes / 1KB) }
    return "$Bytes Б"
}

function Build-Number([string]$Tag) {
    if ($Tag -match 'build-(\d+)') { return [int64]$Matches[1] }
    return -1
}

function Current-Tag {
    if (-not (Test-Path $TagFile)) { return "" }
    return (Get-Content -Path $TagFile -Raw -ErrorAction SilentlyContinue).Trim()
}

function Get-GameProcesses {
    return @(Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)
}

function Wait-ForGameExit([int]$TimeoutSeconds = 120) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-GameProcesses).Count -gt 0) {
        if ((Get-Date) -ge $deadline) {
            throw "ImPuls не завершился за $TimeoutSeconds секунд. Обновление отменено."
        }
        Set-Ui "Ожидание закрытия игры..." -1 "Обновление продолжится автоматически."
        Start-Sleep -Milliseconds 250
    }
}

function Download-File([string]$Url, [string]$Destination, [string]$Label) {
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(20)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("ImPuls-Updater/5.0")
    try {
        $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $response.EnsureSuccessStatusCode()
        [long]$total = 0
        if ($response.Content.Headers.ContentLength) { $total = [long]$response.Content.Headers.ContentLength }
        $input = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        try {
            $parent = Split-Path $Destination -Parent
            if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $output = [IO.File]::Open($Destination, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                $buffer = New-Object byte[] (1024 * 1024)
                [long]$done = 0
                while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $output.Write($buffer, 0, $read)
                    $done += $read
                    $percent = if ($total -gt 0) { [int](($done * 100L) / $total) } else { -1 }
                    $detail = if ($total -gt 0) {
                        "$(Format-Bytes $done) из $(Format-Bytes $total)"
                    } else {
                        "Загружено $(Format-Bytes $done)"
                    }
                    Set-Ui $Label $percent $detail
                }
            } finally {
                $output.Dispose()
            }
        } finally {
            $input.Dispose()
        }
    } finally {
        $client.Dispose()
    }
}

function Show-Error([string]$Message) {
    Write-Log "ERROR: $Message"
    if ($script:Interactive) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Close-Ui
            [System.Windows.Forms.MessageBox]::Show(
                $Message,
                "ImPuls — ошибка обновления",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        } catch {}
    }
}

try {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Initialize-Ui
    Set-Ui "Проверка стабильного обновления..." -1 "GitHub Releases / stable"
    Write-Log "Checking stable release. Current tag: $(Current-Tag)"

    $release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 25
    $remoteTag = [string]$release.name
    if ([string]::IsNullOrWhiteSpace($remoteTag) -or (Build-Number $remoteTag) -lt 0) {
        $remoteTag = [string]$release.tag_name
    }

    $currentTag = Current-Tag
    $currentBuild = Build-Number $currentTag
    $remoteBuild = Build-Number $remoteTag
    if ($remoteBuild -lt 0) {
        throw "Стабильный релиз имеет некорректную версию: $remoteTag"
    }

    if ($currentBuild -ge 0 -and $remoteBuild -le $currentBuild) {
        Write-Log "Already current: $currentTag"
        Set-Ui "Установлена последняя версия" 100 $currentTag
        Start-Sleep -Milliseconds 250
        Close-Ui
        exit 0
    }

    if ($Background -and (Get-GameProcesses).Count -gt 0) {
        Write-Log "Update $remoteTag deferred because the game is running."
        exit 0
    }

    $assets = @($release.assets)
    $setupAsset = $assets | Where-Object { $_.name -eq "ImPuls-Setup.exe" } | Select-Object -First 1
    $shaAsset = $assets | Where-Object { $_.name -eq "ImPuls-Setup.exe.sha256" } | Select-Object -First 1
    if (-not $setupAsset -or -not $shaAsset) {
        throw "Релиз $remoteTag неполный: нужны ImPuls-Setup.exe и ImPuls-Setup.exe.sha256."
    }

    $workDir = Join-Path $env:TEMP ("ImPuls-Update-" + $remoteTag)
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $setupPath = Join-Path $workDir "ImPuls-Setup.exe"
    $shaPath = Join-Path $workDir "ImPuls-Setup.exe.sha256"

    Download-File ([string]$shaAsset.browser_download_url) $shaPath "Загрузка контрольной суммы"
    Download-File ([string]$setupAsset.browser_download_url) $setupPath "Загрузка обновления"

    $sumText = Get-Content -Path $shaPath -Raw
    if ($sumText -notmatch '(?i)\b([0-9a-f]{64})\b') {
        throw "Не удалось прочитать SHA-256 релиза."
    }
    $expectedHash = $Matches[1].ToLowerInvariant()
    Set-Ui "Проверка загруженного файла..." -1 "SHA-256"
    $actualHash = (Get-FileHash -Path $setupPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "SHA-256 не совпал. Повреждённое обновление не будет установлено."
    }
    Write-Log "Verified $remoteTag SHA-256: $actualHash"

    if ($WaitForGameExit) {
        Wait-ForGameExit 120
    } elseif ((Get-GameProcesses).Count -gt 0) {
        throw "Игра запущена. Закройте ImPuls и повторите обновление."
    }

    Set-Ui "Установка обновления..." -1 "$currentTag → $remoteTag"
    $installerArgs = @(
        "/VERYSILENT",
        "/SUPPRESSMSGBOXES",
        "/NORESTART",
        "/SP-",
        "/CLOSEAPPLICATIONS",
        "/DIR=`"$InstallDir`""
    )
    $installer = Start-Process -FilePath $setupPath -ArgumentList $installerArgs -Wait -PassThru
    if ($installer.ExitCode -ne 0) {
        throw "Установщик завершился с кодом $($installer.ExitCode)."
    }

    if (-not (Test-Path $TagFile) -or (Current-Tag) -ne $remoteTag) {
        $remoteTag | Set-Content -Path $TagFile -Encoding ASCII
    }
    Write-Log "Updated successfully to $remoteTag."
    Set-Ui "Обновление установлено" 100 $remoteTag
    Start-Sleep -Milliseconds 450
    Close-Ui

    if ($WaitForGameExit -and -not $Background) {
        $gameExe = Join-Path $CurrentDir "ImPuls.exe"
        if (Test-Path $gameExe) {
            Start-Process -FilePath $gameExe -WorkingDirectory $CurrentDir | Out-Null
        }
    }
    exit 0
} catch {
    Show-Error $_.Exception.Message
    Close-Ui
    exit 1
}
