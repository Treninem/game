param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Repair/1.0"; "Accept" = "application/vnd.github+json" }
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"
$BackupDir = Join-Path $InstallDir "backup"
$LogPath = Join-Path $InstallDir "update.log"
$CoreFiles = @("ImPuls.exe", "ImPuls.pck")

$script:ProgressForm = $null
$script:ProgressBar = $null
$script:StatusLabel = $null
$script:DetailLabel = $null
$script:BytesPlanned = 0L
$script:BytesFinished = 0L

function Write-Log([string]$Text) {
    try {
        $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $LogPath -Value "[$stamp] $Text" -Encoding UTF8
    } catch {}
}

function Initialize-ProgressUi {
    if ($Background) { return }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ImPuls — восстановление файлов"
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.ClientSize = New-Object System.Drawing.Size(580, 196)
    $form.BackColor = [System.Drawing.Color]::FromArgb(13, 19, 29)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(225, 239, 248)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Проверка файлов ImPuls"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(22, 16)
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Подготовка..."
    $status.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $status.AutoEllipsis = $true
    $status.Location = New-Object System.Drawing.Point(22, 54)
    $status.Size = New-Object System.Drawing.Size(534, 24)
    $form.Controls.Add($status)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(22, 84)
    $bar.Size = New-Object System.Drawing.Size(534, 24)
    $bar.Minimum = 0
    $bar.Maximum = 100
    $bar.Style = "Marquee"
    $form.Controls.Add($bar)

    $detail = New-Object System.Windows.Forms.Label
    $detail.Text = ""
    $detail.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $detail.ForeColor = [System.Drawing.Color]::FromArgb(148, 184, 205)
    $detail.AutoEllipsis = $true
    $detail.Location = New-Object System.Drawing.Point(22, 118)
    $detail.Size = New-Object System.Drawing.Size(534, 54)
    $form.Controls.Add($detail)

    $script:ProgressForm = $form
    $script:ProgressBar = $bar
    $script:StatusLabel = $status
    $script:DetailLabel = $detail
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-ProgressUi([string]$Status, [int]$Percent = -1, [string]$Detail = "") {
    if ($Background -or -not $script:ProgressForm) { return }
    $script:StatusLabel.Text = $Status
    $script:DetailLabel.Text = $Detail
    if ($Percent -lt 0) {
        $script:ProgressBar.Style = "Marquee"
    } else {
        $script:ProgressBar.Style = "Blocks"
        $script:ProgressBar.Value = [Math]::Max(0, [Math]::Min(100, $Percent))
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Format-Bytes([long]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N2} ГБ" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} МБ" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N0} КБ" -f ($Bytes / 1KB) }
    return "$Bytes Б"
}

function Download-File([string]$Url, [string]$Destination, [string]$Label, [long]$ExpectedBytes = 0L) {
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("ImPuls-Repair/1.0")
    try {
        $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $response.EnsureSuccessStatusCode()
        $input = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        try {
            $parent = Split-Path $Destination -Parent
            if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $output = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                $buffer = New-Object byte[] (1024 * 1024)
                [long]$done = 0L
                while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $output.Write($buffer, 0, $read)
                    $done += $read
                    [long]$overall = $script:BytesFinished + $done
                    $percent = if ($script:BytesPlanned -gt 0) { [int](($overall * 100L) / $script:BytesPlanned) } else { -1 }
                    $detail = if ($script:BytesPlanned -gt 0) {
                        "$(Format-Bytes $overall) из $(Format-Bytes $script:BytesPlanned) • $Label"
                    } else {
                        "Загружено $(Format-Bytes $done) • $Label"
                    }
                    Set-ProgressUi "Загрузка только нужных файлов" $percent $detail
                }
                $script:BytesFinished += $done
            } finally { $output.Dispose() }
        } finally { $input.Dispose() }
    } finally { $client.Dispose() }
}

function File-Matches([string]$Path, [long]$Size, [string]$Sha256) {
    if (-not (Test-Path $Path)) { return $false }
    if ((Get-Item $Path).Length -ne $Size) { return $false }
    $actual = (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    return $actual -eq $Sha256.ToLowerInvariant()
}

function Verify-Hash([string]$Path, [string]$Expected) {
    if ($Expected -notmatch '^[0-9a-fA-F]{64}$') { throw "Некорректный SHA-256 для $Path" }
    $actual = (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected.ToLowerInvariant()) { throw "Проверка SHA-256 не пройдена: $([IO.Path]::GetFileName($Path))" }
}

function Asset-ByName($Assets, [string]$Name) {
    return $Assets | Where-Object { $_.name -eq $Name } | Select-Object -First 1
}

function Get-ReleaseAssets($Release) {
    $all = @()
    $page = 1
    while ($page -le 20) {
        $items = @(Invoke-RestMethod -Uri "$($Release.assets_url)?per_page=100&page=$page" -Headers $Headers -TimeoutSec 20)
        if ($items.Count -eq 0) { break }
        $all += $items
        if ($items.Count -lt 100) { break }
        $page++
    }
    return $all
}

function Restart-GameIfRequested {
    if ($WaitForGameExit) {
        $exe = Join-Path $CurrentDir "ImPuls.exe"
        if (Test-Path $exe) { Start-Process -FilePath $exe -WorkingDirectory $CurrentDir }
    }
}

Initialize-ProgressUi
Write-Log "File repair started. InstallDir=$InstallDir"
Set-ProgressUi "Проверка стабильной версии..." -1 "Полный ZIP игры не загружается"

if ($Background -and (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)) { exit 0 }
if ($WaitForGameExit) {
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        if (-not $Background) { [System.Windows.Forms.Application]::DoEvents() }
    }
}

try {
    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 20
    $Assets = @(Get-ReleaseAssets $Release)
} catch {
    Write-Log "Repair channel unavailable: $($_.Exception.Message)"
    Set-ProgressUi "Сеть недоступна" 0 "Уже установленные файлы не изменены"
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 900; $script:ProgressForm.Close() }
    exit 0
}

$ManifestAsset = Asset-ByName $Assets "ImPuls-File-Manifest.json"
$RuntimeAsset = Asset-ByName $Assets "ImPuls-Updater-Runtime.zip"
if (-not $ManifestAsset -or -not $RuntimeAsset) { throw "Стабильный релиз не содержит служебные файлы восстановления" }

$TempDir = Join-Path $env:TEMP ("ImPulsRepair-" + [guid]::NewGuid())
$StageDir = Join-Path $TempDir "stage"
$RuntimeDir = Join-Path $TempDir "runtime"
$ManifestPath = Join-Path $TempDir "ImPuls-File-Manifest.json"
$RuntimeZip = Join-Path $TempDir "ImPuls-Updater-Runtime.zip"
New-Item -ItemType Directory -Path $TempDir,$StageDir,$RuntimeDir -Force | Out-Null

try {
    Set-ProgressUi "Чтение манифеста..." -1 "Определяем только отсутствующие или устаревшие файлы"
    Invoke-WebRequest -Uri $ManifestAsset.browser_download_url -Headers $Headers -OutFile $ManifestPath -UseBasicParsing
    $Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    if ([int]$Manifest.format -lt 2) { throw "Неподдерживаемый манифест" }

    if (Test-Path $CurrentDir) {
        Get-ChildItem -Force $CurrentDir | Copy-Item -Destination $StageDir -Recurse -Force
    }

    $Needed = @()
    foreach ($Name in $CoreFiles) {
        $prop = $Manifest.files.PSObject.Properties[$Name]
        if ($null -eq $prop) { throw "В манифесте отсутствует $Name" }
        $info = $prop.Value
        $path = Join-Path $StageDir $Name
        if (-not (File-Matches $path ([long]$info.size) ([string]$info.sha256))) {
            $asset = Asset-ByName $Assets $Name
            if (-not $asset) { throw "В релизе отсутствует отдельный файл $Name" }
            $Needed += [pscustomobject]@{ Name=$Name; Info=$info; Asset=$asset }
        }
    }

    [long]$planned = [long]$RuntimeAsset.size
    foreach ($item in $Needed) { $planned += [long]$item.Asset.size }
    $script:BytesPlanned = $planned
    $script:BytesFinished = 0L

    if ($Needed.Count -eq 0) {
        Set-ProgressUi "Файлы игры уже целы" 70 "Загрузка игровых файлов не требуется"
    } else {
        foreach ($item in $Needed) {
            $dest = Join-Path $StageDir ([string]$item.Name)
            Download-File $item.Asset.browser_download_url $dest ([string]$item.Name) ([long]$item.Asset.size)
            if ((Get-Item $dest).Length -ne [long]$item.Info.size) { throw "Неверный размер $($item.Name)" }
            Verify-Hash $dest ([string]$item.Info.sha256)
        }
    }

    foreach ($Name in $CoreFiles) {
        $prop = $Manifest.files.PSObject.Properties[$Name]
        $info = $prop.Value
        $path = Join-Path $StageDir $Name
        if (-not (File-Matches $path ([long]$info.size) ([string]$info.sha256))) { throw "Не удалось восстановить $Name" }
    }

    Download-File $RuntimeAsset.browser_download_url $RuntimeZip "служебные файлы обновления" ([long]$RuntimeAsset.size)
    Expand-Archive -Path $RuntimeZip -DestinationPath $RuntimeDir -Force

    Set-ProgressUi "Установка проверенных файлов" 96 "Создаётся точка отката"
    if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
    if (Test-Path $CurrentDir) { Move-Item $CurrentDir $BackupDir }
    Move-Item $StageDir $CurrentDir
    Set-Content -Path $TagFile -Value ([string]$Release.name) -Encoding ASCII

    foreach ($Name in @("launcher.vbs","install_update_task.ps1","refresh_shortcuts.ps1","impuls.ico","updater.ps1","updater_bootstrap.ps1","updater_v4.ps1","repair_sync.ps1")) {
        $Source = Join-Path $RuntimeDir $Name
        if (Test-Path $Source) { Copy-Item $Source (Join-Path $InstallDir $Name) -Force }
    }

    if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
    Write-Log "File repair complete. Needed=$($Needed.Count), network=$(Format-Bytes $script:BytesFinished)"
    Set-ProgressUi "Готово" 100 "Загружено $(Format-Bytes $script:BytesFinished); полный архив не использовался"
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 900 }
    Restart-GameIfRequested
} catch {
    Write-Log "File repair failed: $($_.Exception.Message)"
    if (-not (Test-Path $CurrentDir) -and (Test-Path $BackupDir)) { Move-Item $BackupDir $CurrentDir }
    Set-ProgressUi "Восстановление отменено" 0 $_.Exception.Message
    if (-not $Background) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Не удалось восстановить файлы ImPuls.`nСуществующая установка сохранена.`n`n$($_.Exception.Message)","ImPuls Repair","OK","Warning") | Out-Null
    }
    Restart-GameIfRequested
} finally {
    if ($script:ProgressForm) { $script:ProgressForm.Close() }
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
