param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Repair/2.0"; "Accept" = "application/vnd.github+json" }
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"
$BackupDir = Join-Path $InstallDir "backup"
$LogPath = Join-Path $InstallDir "update.log"
$CacheRoot = Join-Path $InstallDir "repair-cache"
$CoreFiles = @("ImPuls.exe", "ImPuls.pck")

$script:ProgressForm = $null
$script:ProgressBar = $null
$script:StatusLabel = $null
$script:DetailLabel = $null
$script:BytesPlanned = 0L
$script:BytesFinished = 0L
$script:RepairSucceeded = $false

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
    $client.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("ImPuls-Repair/2.0")
    $partPath = "$Destination.part"
    try {
        $parent = Split-Path $Destination -Parent
        if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

        if (Test-Path $Destination) {
            [long]$completeSize = (Get-Item $Destination).Length
            if ($ExpectedBytes -le 0 -or $completeSize -eq $ExpectedBytes) {
                $script:BytesFinished += $completeSize
                Set-ProgressUi "Использование уже загруженных данных" -1 "$Label • $(Format-Bytes $completeSize)"
                return
            }
            Remove-Item $Destination -Force -ErrorAction SilentlyContinue
        }

        [long]$existing = 0L
        if (Test-Path $partPath) {
            $existing = (Get-Item $partPath).Length
            if ($ExpectedBytes -gt 0 -and $existing -gt $ExpectedBytes) {
                Remove-Item $partPath -Force
                $existing = 0L
            } elseif ($ExpectedBytes -gt 0 -and $existing -eq $ExpectedBytes) {
                Move-Item $partPath $Destination -Force
                $script:BytesFinished += $existing
                return
            }
        }

        $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $Url)
        if ($existing -gt 0) {
            $request.Headers.Range = New-Object System.Net.Http.Headers.RangeHeaderValue($existing, $null)
            Set-ProgressUi "Продолжение восстановления" -1 "$Label • уже есть $(Format-Bytes $existing)"
        }

        $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        try {
            $response.EnsureSuccessStatusCode()
            $resuming = $existing -gt 0 -and [int]$response.StatusCode -eq 206
            if ($existing -gt 0 -and -not $resuming) {
                Remove-Item $partPath -Force -ErrorAction SilentlyContinue
                $existing = 0L
            }

            [long]$responseBytes = 0L
            if ($response.Content.Headers.ContentLength) { $responseBytes = [long]$response.Content.Headers.ContentLength }
            [long]$total = if ($ExpectedBytes -gt 0) { $ExpectedBytes } elseif ($resuming) { $existing + $responseBytes } else { $responseBytes }

            $input = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
            try {
                $mode = if ($resuming) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
                $output = [System.IO.File]::Open($partPath, $mode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                try {
                    $buffer = New-Object byte[] (1024 * 1024)
                    [long]$downloaded = 0L
                    while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $output.Write($buffer, 0, $read)
                        $downloaded += $read
                        [long]$fileDone = $existing + $downloaded
                        [long]$overall = $script:BytesFinished + $fileDone
                        $percent = if ($script:BytesPlanned -gt 0) { [int](($overall * 100L) / $script:BytesPlanned) } else { -1 }
                        $detail = if ($total -gt 0) {
                            "$(Format-Bytes $fileDone) из $(Format-Bytes $total) • $Label"
                        } else {
                            "Загружено $(Format-Bytes $fileDone) • $Label"
                        }
                        Set-ProgressUi "Загрузка только нужных файлов" $percent $detail
                    }
                } finally { $output.Dispose() }
            } finally { $input.Dispose() }

            [long]$finalSize = (Get-Item $partPath).Length
            if ($ExpectedBytes -gt 0 -and $finalSize -ne $ExpectedBytes) {
                throw "Загрузка прервана: $Label. Файл сохранён для докачки."
            }
            Move-Item $partPath $Destination -Force
            $script:BytesFinished += $finalSize
        } finally {
            $response.Dispose()
            $request.Dispose()
        }
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
    if ($actual -ne $Expected.ToLowerInvariant()) {
        Remove-Item $Path -Force -ErrorAction SilentlyContinue
        Remove-Item "$Path.part" -Force -ErrorAction SilentlyContinue
        throw "Проверка SHA-256 не пройдена: $([IO.Path]::GetFileName($Path)). Повреждённый кэш удалён."
    }
}

function Asset-ByName($Assets, [string]$Name) {
    return $Assets | Where-Object { $_.name -eq $Name } | Select-Object -First 1
}

function Get-ReleaseAssets($Release) {
    $all = @()
    $page = 1
    while ($page -le 20) {
        $items = @(Invoke-RestMethod -Uri "$($Release.assets_url)?per_page=100&page=$page" -Headers $Headers -TimeoutSec 0)
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
    if (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) {
        Write-Log "Game did not exit before timeout"
        $message = "Игра всё ещё запущена. Восстановление файлов отменено, установленная версия не изменена."
        Set-ProgressUi "Игра всё ещё запущена" 0 $message
        if ($script:ProgressForm) { Start-Sleep -Milliseconds 1200; $script:ProgressForm.Close() }
        exit 2
    }
}

try {
    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 0
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

$RemoteTag = [string]$Release.name
$CacheDir = Join-Path $CacheRoot $RemoteTag
$DownloadDir = Join-Path $CacheDir "downloads"
$StageDir = Join-Path $CacheDir "stage"
$RuntimeDir = Join-Path $CacheDir "runtime"
$ManifestPath = Join-Path $DownloadDir "ImPuls-File-Manifest.json"
$RuntimeZip = Join-Path $DownloadDir "ImPuls-Updater-Runtime.zip"
New-Item -ItemType Directory -Path $CacheRoot,$CacheDir,$DownloadDir -Force | Out-Null
Remove-Item $StageDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $RuntimeDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $StageDir,$RuntimeDir -Force | Out-Null

try {
    Set-ProgressUi "Чтение манифеста..." -1 "Определяем только отсутствующие или устаревшие файлы"
    Download-File $ManifestAsset.browser_download_url $ManifestPath "манифест файлов" ([long]$ManifestAsset.size)
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

    [long]$planned = [long]$ManifestAsset.size + [long]$RuntimeAsset.size
    foreach ($item in $Needed) { $planned += [long]$item.Asset.size }
    $script:BytesPlanned = $planned
    $script:BytesFinished = 0L

    if ($Needed.Count -eq 0) {
        Set-ProgressUi "Файлы игры уже целы" 70 "Загрузка игровых файлов не требуется"
    } else {
        foreach ($item in $Needed) {
            $cached = Join-Path $DownloadDir ([string]$item.Name)
            Download-File $item.Asset.browser_download_url $cached ([string]$item.Name) ([long]$item.Asset.size)
            if ((Get-Item $cached).Length -ne [long]$item.Info.size) { throw "Неверный размер $($item.Name)" }
            Verify-Hash $cached ([string]$item.Info.sha256)
            Copy-Item $cached (Join-Path $StageDir ([string]$item.Name)) -Force
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
    $script:RepairSucceeded = $true
    Write-Log "File repair complete. Needed=$($Needed.Count), downloaded/cached=$(Format-Bytes $script:BytesFinished)"
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
    if ($script:RepairSucceeded) {
        Remove-Item $CacheDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item $StageDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $RuntimeDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Repair download cache preserved for resume: $DownloadDir"
    }
}
