param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir,
    [int]$GamePid = 0
)

$ErrorActionPreference = "Stop"

function Show-ImPulsMessage([string]$Text, [bool]$IsError = $false) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $icon = if ($IsError) { [System.Windows.Forms.MessageBoxIcon]::Error } else { [System.Windows.Forms.MessageBoxIcon]::Information }
        [System.Windows.Forms.MessageBox]::Show(
            $Text,
            "ImPuls — обновление исходников",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            $icon
        ) | Out-Null
    } catch {
        Write-Host $Text
    }
}

function Resolve-GitExecutable {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $env:ProgramFiles "Git\cmd\git.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Git\cmd\git.exe")
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }

    $desktopRoot = Join-Path $env:LOCALAPPDATA "GitHubDesktop"
    if (Test-Path $desktopRoot) {
        $apps = @(Get-ChildItem -Path $desktopRoot -Directory -Filter "app-*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
        foreach ($app in $apps) {
            foreach ($relative in @("resources\app\git\cmd\git.exe", "resources\app\git\bin\git.exe")) {
                $candidate = Join-Path $app.FullName $relative
                if (Test-Path $candidate) { return $candidate }
            }
        }
    }
    return $null
}

try {
    $ProjectDir = [IO.Path]::GetFullPath($ProjectDir)
    if (-not (Test-Path (Join-Path $ProjectDir "project.godot"))) {
        throw "В указанной папке не найден project.godot: $ProjectDir"
    }
    if (-not (Test-Path (Join-Path $ProjectDir ".git"))) {
        throw "Папка проекта не является Git-репозиторием: $ProjectDir"
    }

    if ($GamePid -gt 0) {
        $deadline = (Get-Date).AddSeconds(30)
        while ((Get-Process -Id $GamePid -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 250
        }
        if (Get-Process -Id $GamePid -ErrorAction SilentlyContinue) {
            throw "DEBUG-процесс ImPuls не завершился за 30 секунд."
        }
    }

    $git = Resolve-GitExecutable
    if (-not $git) {
        throw "Git не найден. Установите Git for Windows либо GitHub Desktop."
    }

    $branch = (& $git -C $ProjectDir rev-parse --abbrev-ref HEAD 2>&1 | Select-Object -First 1).ToString().Trim()
    if ($LASTEXITCODE -ne 0) { throw "Не удалось определить текущую ветку Git." }
    if ($branch -ne "main") {
        throw "Автообновление исходников разрешено только для ветки main. Сейчас открыта ветка: $branch"
    }

    $dirty = @(& $git -C $ProjectDir status --porcelain --untracked-files=no 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Не удалось проверить состояние Git-репозитория." }
    if ($dirty.Count -gt 0) {
        throw "Есть локальные изменения в отслеживаемых файлах. Чтобы ничего не потерять, автообновление остановлено. Сначала Commit/Stash/Discard этих изменений в GitHub Desktop."
    }

    & $git -C $ProjectDir fetch origin main --prune
    if ($LASTEXITCODE -ne 0) { throw "Не удалось получить изменения origin/main." }

    $local = (& $git -C $ProjectDir rev-parse HEAD | Select-Object -First 1).ToString().Trim()
    $remote = (& $git -C $ProjectDir rev-parse origin/main | Select-Object -First 1).ToString().Trim()
    if ($local -eq $remote) {
        Show-ImPulsMessage "Исходники ImPuls уже обновлены. Ветка main совпадает с GitHub."
        exit 0
    }

    & $git -C $ProjectDir merge --ff-only origin/main
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось выполнить безопасное fast-forward обновление. Локальные файлы не перезаписывались принудительно."
    }

    $newHead = (& $git -C $ProjectDir rev-parse --short=8 HEAD | Select-Object -First 1).ToString().Trim()
    Show-ImPulsMessage "Исходники ImPuls обновлены до $newHead. Godot автоматически увидит изменённые файлы; при необходимости перезапустите проект."
    exit 0
} catch {
    Show-ImPulsMessage $_.Exception.Message $true
    exit 1
}
