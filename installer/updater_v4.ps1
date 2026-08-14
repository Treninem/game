param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Updater/4.0"; "Accept" = "application/vnd.github+json" }
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"
$BackupDir = Join-Path $InstallDir "backup"
$LogPath = Join-Path $InstallDir "update.log"

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
    $form.Text = "ImPuls — обновление"
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.ClientSize = New-Object System.Drawing.Size(560, 188)
    $form.BackColor = [System.Drawing.Color]::FromArgb(13, 19, 29)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(225, 239, 248)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Обновление ImPuls"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(22, 16)
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Подготовка..."
    $status.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $status.AutoEllipsis = $true
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
    $detail.ForeColor = [System.Drawing.Color]::FromArgb(148, 184, 205)
    $detail.AutoEllipsis = $true
    $detail.Location = New-Object System.Drawing.Point(22, 118)
    $detail.Size = New-Object System.Drawing.Size(514, 50)
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
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("ImPuls-Updater/4.0")
    try {
        $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $response.EnsureSuccessStatusCode()
        [long]$total = 0L
        if ($response.Content.Headers.ContentLength) { $total = [long]$response.Content.Headers.ContentLength }
        if ($total -le 0 -and $ExpectedBytes -gt 0) { $total = $ExpectedBytes }
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
                    [long]$overallDone = $script:BytesFinished + $done
                    $percent = if ($script:BytesPlanned -gt 0) { [int](($overallDone * 100L) / $script:BytesPlanned) } else { -1 }
                    $detail = if ($script:BytesPlanned -gt 0) {
                        "$(Format-Bytes $overallDone) из $(Format-Bytes $script:BytesPlanned) • $Label"
                    } elseif ($total -gt 0) {
                        "$(Format-Bytes $done) из $(Format-Bytes $total) • $Label"
                    } else {
                        "Загружено $(Format-Bytes $done) • $Label"
                    }
                    Set-ProgressUi "Загрузка только недостающих данных" $percent $detail
                }
                $script:BytesFinished += $done
            } finally { $output.Dispose() }
        } finally { $input.Dispose() }
    } finally { $client.Dispose() }
}

function Verify-Hash([string]$Path, [string]$Expected) {
    if ($Expected -notmatch '^[0-9a-fA-F]{64}$') { throw "Некорректный SHA-256 для $Path" }
    $actual = (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected.ToLowerInvariant()) { throw "Проверка SHA-256 не пройдена: $([IO.Path]::GetFileName($Path))" }
}

function Verify-AssetFromSums([string]$Path, [string]$Name, [string]$SumsPath) {
    if (-not (Test-Path $SumsPath)) { throw "SHA256SUMS.txt отсутствует" }
    $line = Get-Content $SumsPath | Where-Object { $_ -match ("\s" + [regex]::Escape($Name) + "$") } | Select-Object -First 1
    if (-not $line) { throw "Нет SHA-256 для $Name" }
    $expected = ($line -split "\s+")[0]
    Verify-Hash $Path $expected
}

function Get-ReleaseAssets($Release) {
    $all = @()
    $page = 1
    while ($page -le 20) {
        $url = "$($Release.assets_url)?per_page=100&page=$page"
        $items = @(Invoke-RestMethod -Uri $url -Headers $Headers -TimeoutSec 20)
        if ($items.Count -eq 0) { break }
        $all += $items
        if ($items.Count -lt 100) { break }
        $page++
    }
    return $all
}

function Asset-ByName($Assets, [string]$Name) {
    return $Assets | Where-Object { $_.name -eq $Name } | Select-Object -First 1
}

function Build-Number([string]$Tag) {
    if ($Tag -match '^build-(\d+)$') { return [int]$Matches[1] }
    return -1
}

function Get-DeltaChain($Assets, [string]$From, [string]$To) {
    $edges = @{}
    foreach ($asset in $Assets) {
        if ([string]$asset.name -match '^ImPuls-Delta-(build-\d+)-to-(build-\d+)\.zip$') {
            $source = $Matches[1]
            $target = $Matches[2]
            if (-not $edges.ContainsKey($source)) { $edges[$source] = @() }
            $edges[$source] += [pscustomobject]@{ From = $source; To = $target; Asset = $asset }
        }
    }

    $result = @()
    $cursor = $From
    $seen = @{}
    $targetNumber = Build-Number $To
    while ($cursor -ne $To) {
        if ($seen.ContainsKey($cursor) -or -not $edges.ContainsKey($cursor)) { return @() }
        $seen[$cursor] = $true
        $choices = @($edges[$cursor] | Where-Object {
            $n = Build-Number $_.To
            $n -ge 0 -and ($targetNumber -lt 0 -or $n -le $targetNumber)
        } | Sort-Object { Build-Number $_.To } -Descending)
        if ($choices.Count -eq 0) { return @() }
        $edge = $choices[0]
        $result += $edge
        $cursor = [string]$edge.To
        if ($result.Count -gt 200) { return @() }
    }
    return $result
}

function Assert-SafeRelativePath([string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Небезопасный путь в пакете обновления: $Relative"
    }
}

function Copy-Range([System.IO.FileStream]$Source, [System.IO.FileStream]$Destination, [long]$Offset, [long]$Length) {
    $Source.Seek($Offset, [System.IO.SeekOrigin]::Begin) | Out-Null
    $buffer = New-Object byte[] (1024 * 1024)
    [long]$remaining = $Length
    while ($remaining -gt 0) {
        $want = [int][Math]::Min([long]$buffer.Length, $remaining)
        $read = $Source.Read($buffer, 0, $want)
        if ($read -le 0) { throw "Неожиданный конец исходного файла дельты" }
        $Destination.Write($buffer, 0, $read)
        $remaining -= $read
    }
}

function Apply-Delta([string]$ZipPath, [string]$StageDir, [string]$ExpectedFrom, [string]$ExpectedTo, [string]$WorkDir, [int]$DeltaIndex, [int]$DeltaCount) {
    $extract = Join-Path $WorkDir ("delta-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $extract -Force
    $metaPath = Join-Path $extract "delta.json"
    $payloadPath = Join-Path $extract "payload.bin"
    if (-not (Test-Path $metaPath) -or -not (Test-Path $payloadPath)) { throw "Повреждённый delta-пакет" }
    $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
    if ([string]$meta.from -ne $ExpectedFrom -or [string]$meta.to -ne $ExpectedTo -or [int]$meta.format -ne 2) {
        throw "Delta-пакет не соответствует установленной версии"
    }

    $changedProps = @($meta.changed.PSObject.Properties)
    $fileIndex = 0
    foreach ($prop in $changedProps) {
        $fileIndex++
        $relative = [string]$prop.Name
        Assert-SafeRelativePath $relative
        $patch = $prop.Value
        $dest = Join-Path $StageDir ($relative -replace '/', '\')
        $tempOut = "$dest.impuls-new"
        $parent = Split-Path $dest -Parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $source = $null
        if (Test-Path $dest) {
            $source = [System.IO.File]::Open($dest, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        }
        $payload = [System.IO.File]::Open($payloadPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $output = [System.IO.File]::Open($tempOut, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            foreach ($op in $patch.ops) {
                $offset = [long]$op.offset
                $length = [long]$op.length
                if ([string]$op.op -eq "copy") {
                    if (-not $source) { throw "Не хватает локального исходного файла: $relative" }
                    Copy-Range $source $output $offset $length
                } elseif ([string]$op.op -eq "literal") {
                    Copy-Range $payload $output $offset $length
                } else {
                    throw "Неизвестная операция delta: $($op.op)"
                }
            }
        } finally {
            $output.Dispose()
            $payload.Dispose()
            if ($source) { $source.Dispose() }
        }
        if ((Get-Item $tempOut).Length -ne [long]$patch.size) { throw "Размер после delta неверен: $relative" }
        Verify-Hash $tempOut ([string]$patch.sha256)
        if (Test-Path $dest) { Remove-Item $dest -Force }
        Move-Item $tempOut $dest -Force
        $percent = if ($changedProps.Count -gt 0) { [int](($fileIndex * 100) / $changedProps.Count) } else { 100 }
        Set-ProgressUi "Применение обновления $DeltaIndex из $DeltaCount" $percent $relative
    }

    foreach ($relativeValue in @($meta.deleted)) {
        $relative = [string]$relativeValue
        Assert-SafeRelativePath $relative
        $dest = Join-Path $StageDir ($relative -replace '/', '\')
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    }
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
}

function Verify-Manifest([string]$StageDir, [string]$ManifestPath) {
    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    if ([int]$manifest.format -lt 2) { throw "Неподдерживаемый манифест обновления" }
    $props = @($manifest.files.PSObject.Properties)
    $i = 0
    foreach ($prop in $props) {
        $i++
        $relative = [string]$prop.Name
        Assert-SafeRelativePath $relative
        $info = $prop.Value
        $path = Join-Path $StageDir ($relative -replace '/', '\')
        if (-not (Test-Path $path)) { throw "После обновления отсутствует файл: $relative" }
        if ((Get-Item $path).Length -ne [long]$info.size) { throw "Неверный размер файла: $relative" }
        Verify-Hash $path ([string]$info.sha256)
        $percent = if ($props.Count -gt 0) { [int](($i * 100) / $props.Count) } else { 100 }
        Set-ProgressUi "Проверка обновлённой версии" $percent $relative
    }
}

function Restart-GameIfRequested {
    if ($WaitForGameExit) {
        $gameExe = Join-Path $CurrentDir "ImPuls.exe"
        if (Test-Path $gameExe) { Start-Process -FilePath $gameExe -WorkingDirectory $CurrentDir }
    }
}

Initialize-ProgressUi
Write-Log "Updater 4.0 started. InstallDir=$InstallDir Background=$Background WaitForGameExit=$WaitForGameExit"
Set-ProgressUi "Проверка стабильного канала..." -1 "Полный пакет игры не скачивается при обычном обновлении"

if ($Background -and (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)) { exit 0 }

if ($WaitForGameExit) {
    Set-ProgressUi "Ожидание закрытия игры..." -1 "Текущая версия остаётся нетронутой до полной проверки"
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        if (-not $Background) { [System.Windows.Forms.Application]::DoEvents() }
    }
    if (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) {
        Write-Log "Game did not exit before timeout"
        exit 2
    }
}

try {
    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 20
    $Assets = @(Get-ReleaseAssets $Release)
} catch {
    Write-Log "Stable channel unavailable: $($_.Exception.Message)"
    Set-ProgressUi "Сеть недоступна" 0 "Запускается уже установленная версия"
    Restart-GameIfRequested
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 900; $script:ProgressForm.Close() }
    exit 0
}

$RemoteTag = [string]$Release.name
$LocalTag = if (Test-Path $TagFile) { (Get-Content $TagFile -Raw).Trim() } else { "" }
if ([string]::IsNullOrWhiteSpace($RemoteTag) -or $RemoteTag -eq $LocalTag) {
    Set-ProgressUi "Установлена последняя версия" 100 $RemoteTag
    Restart-GameIfRequested
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 700; $script:ProgressForm.Close() }
    exit 0
}

if (-not (Test-Path $CurrentDir) -or [string]::IsNullOrWhiteSpace($LocalTag)) {
    $message = "Не найдена корректно установленная базовая версия. Автообновление не будет скачивать полный пакет. Используйте последний установщик ImPuls один раз."
    Write-Log $message
    Set-ProgressUi "Нужна базовая установка" 0 $message
    Restart-GameIfRequested
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 1200; $script:ProgressForm.Close() }
    exit 3
}

$RuntimeAsset = Asset-ByName $Assets "ImPuls-Updater-Runtime.zip"
$SumAsset = Asset-ByName $Assets "SHA256SUMS.txt"
$ManifestAsset = Asset-ByName $Assets "ImPuls-File-Manifest.json"
if (-not $RuntimeAsset -or -not $SumAsset -or -not $ManifestAsset) { throw "Стабильный релиз неполный" }

$deltaChain = @(Get-DeltaChain $Assets $LocalTag $RemoteTag)
if ($deltaChain.Count -eq 0) {
    $message = "Для $LocalTag → $RemoteTag нет безопасной цепочки дельт. Полный архив автоматически не скачивается, чтобы не расходовать трафик."
    Write-Log $message
    Set-ProgressUi "Обновление отложено" 0 $message
    Restart-GameIfRequested
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 1500; $script:ProgressForm.Close() }
    exit 4
}

$TempDir = Join-Path $env:TEMP ("ImPulsUpdate-" + [guid]::NewGuid())
$StageDir = Join-Path $TempDir "stage"
$RuntimeDir = Join-Path $TempDir "runtime"
$RuntimeZip = Join-Path $TempDir "ImPuls-Updater-Runtime.zip"
$SumsPath = Join-Path $TempDir "SHA256SUMS.txt"
$ManifestPath = Join-Path $TempDir "ImPuls-File-Manifest.json"
New-Item -ItemType Directory -Path $TempDir,$StageDir,$RuntimeDir -Force | Out-Null

try {
    [long]$planned = [long]$RuntimeAsset.size + [long]$SumAsset.size + [long]$ManifestAsset.size
    foreach ($edge in $deltaChain) {
        $planned += [long]$edge.Asset.size
        $sumAsset = Asset-ByName $Assets (([string]$edge.Asset.name) + ".sha256")
        if (-not $sumAsset) { throw "Нет контрольной суммы для $($edge.Asset.name)" }
        $planned += [long]$sumAsset.size
    }
    $script:BytesPlanned = $planned
    $script:BytesFinished = 0L
    Write-Log "Delta chain $LocalTag -> $RemoteTag, edges=$($deltaChain.Count), planned=$(Format-Bytes $planned)"

    Download-File $SumAsset.browser_download_url $SumsPath "контрольные суммы" ([long]$SumAsset.size)
    Download-File $ManifestAsset.browser_download_url $ManifestPath "манифест файлов" ([long]$ManifestAsset.size)
    Verify-AssetFromSums $ManifestPath "ImPuls-File-Manifest.json" $SumsPath

    Set-ProgressUi "Подготовка локальной копии" -1 "Копирование выполняется на диске и не расходует интернет-трафик"
    Get-ChildItem -Force $CurrentDir | Copy-Item -Destination $StageDir -Recurse -Force

    $cursor = $LocalTag
    $deltaIndex = 0
    foreach ($edge in $deltaChain) {
        $deltaIndex++
        $asset = $edge.Asset
        $zipPath = Join-Path $TempDir ([string]$asset.name)
        $sumName = ([string]$asset.name) + ".sha256"
        $deltaSumAsset = Asset-ByName $Assets $sumName
        $deltaSumPath = Join-Path $TempDir $sumName
        Download-File $asset.browser_download_url $zipPath "дельта $deltaIndex из $($deltaChain.Count)" ([long]$asset.size)
        Download-File $deltaSumAsset.browser_download_url $deltaSumPath "проверка дельты $deltaIndex" ([long]$deltaSumAsset.size)
        $expected = (Get-Content $deltaSumPath -Raw).Trim().Split()[0]
        Verify-Hash $zipPath $expected
        Apply-Delta $zipPath $StageDir $cursor ([string]$edge.To) $TempDir $deltaIndex $deltaChain.Count
        $cursor = [string]$edge.To
    }

    if (-not (Test-Path (Join-Path $StageDir "ImPuls.exe"))) { throw "Новая сборка не содержит ImPuls.exe" }
    Verify-Manifest $StageDir $ManifestPath

    Download-File $RuntimeAsset.browser_download_url $RuntimeZip "служебные файлы обновления" ([long]$RuntimeAsset.size)
    Verify-AssetFromSums $RuntimeZip "ImPuls-Updater-Runtime.zip" $SumsPath
    Expand-Archive -Path $RuntimeZip -DestinationPath $RuntimeDir -Force

    Set-ProgressUi "Установка проверенной версии" -1 "Создаётся локальная точка отката"
    if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
    if (Test-Path $CurrentDir) { Move-Item $CurrentDir $BackupDir }
    Move-Item $StageDir $CurrentDir
    Set-Content -Path $TagFile -Value $RemoteTag -Encoding ASCII

    foreach ($Name in @("launcher.vbs", "install_update_task.ps1", "refresh_shortcuts.ps1", "impuls.ico", "updater.ps1", "updater_v4.ps1")) {
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
    Write-Log "Update completed: $LocalTag -> $RemoteTag. Network used=$(Format-Bytes $script:BytesFinished)"
    Set-ProgressUi "Готово" 100 "$LocalTag → $RemoteTag • загружено $(Format-Bytes $script:BytesFinished)"
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 900 }
    Restart-GameIfRequested
} catch {
    Write-Log "Update failed: $($_.Exception.Message)"
    if (-not (Test-Path $CurrentDir) -and (Test-Path $BackupDir)) { Move-Item $BackupDir $CurrentDir }
    Set-ProgressUi "Обновление отменено" 0 $_.Exception.Message
    if (-not $Background) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Не удалось обновить ImPuls.`nУстановленная версия сохранена.`n`n$($_.Exception.Message)","ImPuls Update","OK","Warning") | Out-Null
    }
    Restart-GameIfRequested
} finally {
    if ($script:ProgressForm) { $script:ProgressForm.Close() }
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
