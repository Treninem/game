param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ImPuls",
    [switch]$Background,
    [switch]$WaitForGameExit
)

$ErrorActionPreference = "Stop"
$Repo = "Treninem/game"
$Headers = @{ "User-Agent" = "ImPuls-Updater/3.0"; "Accept" = "application/vnd.github+json" }
$Api = "https://api.github.com/repos/$Repo/releases/tags/stable"
$TagFile = Join-Path $InstallDir "release_tag.txt"
$CurrentDir = Join-Path $InstallDir "current"
$BackupDir = Join-Path $InstallDir "backup"
$script:ProgressForm = $null
$script:ProgressBar = $null
$script:StatusLabel = $null
$script:DetailLabel = $null

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
    $form.ClientSize = New-Object System.Drawing.Size(520, 168)
    $form.BackColor = [System.Drawing.Color]::FromArgb(13, 19, 29)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(225, 239, 248)
    $form.TopMost = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Обновление ImPuls"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(20, 16)
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Подготовка..."
    $status.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $status.AutoEllipsis = $true
    $status.Location = New-Object System.Drawing.Point(22, 54)
    $status.Size = New-Object System.Drawing.Size(474, 22)
    $form.Controls.Add($status)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(22, 82)
    $bar.Size = New-Object System.Drawing.Size(474, 22)
    $bar.Minimum = 0
    $bar.Maximum = 100
    $bar.Style = "Marquee"
    $form.Controls.Add($bar)

    $detail = New-Object System.Windows.Forms.Label
    $detail.Text = ""
    $detail.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $detail.ForeColor = [System.Drawing.Color]::FromArgb(148, 184, 205)
    $detail.AutoEllipsis = $true
    $detail.Location = New-Object System.Drawing.Point(22, 114)
    $detail.Size = New-Object System.Drawing.Size(474, 34)
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

function Download-File([string]$Url, [string]$Destination, [string]$Label) {
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("ImPuls-Updater/3.0")
    try {
        $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $response.EnsureSuccessStatusCode()
        $total = if ($response.Content.Headers.ContentLength) { [long]$response.Content.Headers.ContentLength } else { 0L }
        $input = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        try {
            $output = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                $buffer = New-Object byte[] (1024 * 1024)
                [long]$done = 0
                while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $output.Write($buffer, 0, $read)
                    $done += $read
                    $percent = if ($total -gt 0) { [int](($done * 100L) / $total) } else { -1 }
                    $detail = if ($total -gt 0) { "$(Format-Bytes $done) из $(Format-Bytes $total)" } else { "Загружено $(Format-Bytes $done)" }
                    Set-ProgressUi "Загрузка: $Label" $percent $detail
                }
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

function Asset-ByName($Release, [string]$Name) {
    return $Release.assets | Where-Object { $_.name -eq $Name } | Select-Object -First 1
}

function Build-Number([string]$Tag) {
    if ($Tag -match '^build-(\d+)$') { return [int]$Matches[1] }
    return -1
}

function Get-DeltaChain($Release, [string]$From, [string]$To) {
    $edges = @{}
    foreach ($asset in $Release.assets) {
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
        $cursor = $edge.To
        if ($result.Count -gt 50) { return @() }
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

function Apply-Delta([string]$ZipPath, [string]$StageDir, [string]$ExpectedFrom, [string]$ExpectedTo, [string]$WorkDir) {
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
                    if (-not $source) { throw "Delta требует отсутствующий исходный файл: $relative" }
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
        Set-ProgressUi "Применение изменений" $percent $relative
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
Set-ProgressUi "Проверка стабильного канала..." -1 "Соединение с GitHub"

if ($Background -and (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue)) { exit 0 }

if ($WaitForGameExit) {
    Set-ProgressUi "Ожидание закрытия игры..." -1 "Сохранённая версия не изменяется до полной проверки обновления"
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        if (-not $Background) { [System.Windows.Forms.Application]::DoEvents() }
    }
    if (Get-Process -Name "ImPuls" -ErrorAction SilentlyContinue) { exit 2 }
}

try { $Release = Invoke-RestMethod -Uri $Api -Headers $Headers -TimeoutSec 20 } catch {
    Set-ProgressUi "Сеть недоступна" 0 "Будет запущена уже установленная версия"
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

$GameAsset = Asset-ByName $Release "ImPuls-PC-Windows-x64.zip"
$RuntimeAsset = Asset-ByName $Release "ImPuls-Updater-Runtime.zip"
$SumAsset = Asset-ByName $Release "SHA256SUMS.txt"
$ManifestAsset = Asset-ByName $Release "ImPuls-File-Manifest.json"
if (-not $GameAsset -or -not $RuntimeAsset -or -not $SumAsset -or -not $ManifestAsset) { throw "Стабильный релиз неполный" }

$TempDir = Join-Path $env:TEMP ("ImPulsUpdate-" + [guid]::NewGuid())
$StageDir = Join-Path $TempDir "stage"
$RuntimeDir = Join-Path $TempDir "runtime"
$RuntimeZip = Join-Path $TempDir "ImPuls-Updater-Runtime.zip"
$SumsPath = Join-Path $TempDir "SHA256SUMS.txt"
$ManifestPath = Join-Path $TempDir "ImPuls-File-Manifest.json"
$GameZip = Join-Path $TempDir "ImPuls-PC-Windows-x64.zip"
New-Item -ItemType Directory -Path $TempDir,$StageDir,$RuntimeDir -Force | Out-Null

try {
    Download-File $SumAsset.browser_download_url $SumsPath "контрольные суммы"
    Download-File $ManifestAsset.browser_download_url $ManifestPath "манифест файлов"
    Verify-AssetFromSums $ManifestPath "ImPuls-File-Manifest.json" $SumsPath

    $deltaChain = @(Get-DeltaChain $Release $LocalTag $RemoteTag)
    [long]$deltaBytes = 0
    foreach ($edge in $deltaChain) { $deltaBytes += [long]$edge.Asset.size }
    $useDelta = $deltaChain.Count -gt 0 -and $deltaBytes -gt 0 -and $deltaBytes -lt [long]$GameAsset.size

    if ($useDelta) {
        Set-ProgressUi "Подготовка локальной копии" -1 "Из сети будут загружены только изменившиеся блоки"
        Get-ChildItem -Force $CurrentDir | Copy-Item -Destination $StageDir -Recurse -Force
        $cursor = $LocalTag
        $deltaIndex = 0
        foreach ($edge in $deltaChain) {
            $deltaIndex++
            $asset = $edge.Asset
            $zipPath = Join-Path $TempDir ([string]$asset.name)
            $sumName = ([string]$asset.name) + ".sha256"
            $deltaSumAsset = Asset-ByName $Release $sumName
            if (-not $deltaSumAsset) { throw "Нет контрольной суммы для $($asset.name)" }
            $deltaSumPath = Join-Path $TempDir $sumName
            Download-File $asset.browser_download_url $zipPath "дельта $deltaIndex из $($deltaChain.Count)"
            Download-File $deltaSumAsset.browser_download_url $deltaSumPath "SHA-256 дельты"
            $expected = (Get-Content $deltaSumPath -Raw).Trim().Split()[0]
            Verify-Hash $zipPath $expected
            Apply-Delta $zipPath $StageDir $cursor ([string]$edge.To) $TempDir
            $cursor = [string]$edge.To
        }
    } else {
        $reason = if ($deltaChain.Count -eq 0) { "Нет безопасной цепочки дельт для этой старой версии" } else { "Полный архив меньше доступной цепочки дельт" }
        Set-ProgressUi "Используется полный пакет восстановления" -1 $reason
        Download-File $GameAsset.browser_download_url $GameZip "полная версия"
        Verify-AssetFromSums $GameZip "ImPuls-PC-Windows-x64.zip" $SumsPath
        Expand-Archive -Path $GameZip -DestinationPath $StageDir -Force
    }

    if (-not (Test-Path (Join-Path $StageDir "ImPuls.exe"))) { throw "Новая сборка не содержит ImPuls.exe" }
    Verify-Manifest $StageDir $ManifestPath

    Download-File $RuntimeAsset.browser_download_url $RuntimeZip "служебные файлы обновления"
    Verify-AssetFromSums $RuntimeZip "ImPuls-Updater-Runtime.zip" $SumsPath
    Expand-Archive -Path $RuntimeZip -DestinationPath $RuntimeDir -Force

    Set-ProgressUi "Установка проверенной версии" -1 "Старая версия сохранена для мгновенного отката"
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
    Set-ProgressUi "Готово" 100 "$LocalTag → $RemoteTag"
    if ($script:ProgressForm) { Start-Sleep -Milliseconds 650 }
    Restart-GameIfRequested
} catch {
    if (-not (Test-Path $CurrentDir) -and (Test-Path $BackupDir)) { Move-Item $BackupDir $CurrentDir }
    Set-ProgressUi "Обновление отменено" 0 $_.Exception.Message
    if (-not $Background) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Не удалось обновить ImPuls.`nУстановленная версия сохранена и будет запущена.`n`n$($_.Exception.Message)","ImPuls Update","OK","Warning") | Out-Null
    }
    Restart-GameIfRequested
} finally {
    if ($script:ProgressForm) { $script:ProgressForm.Close() }
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
