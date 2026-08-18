<#
.SYNOPSIS
    Headless-сборка .cfe расширения из EDT-проекта.
.DESCRIPTION
    Пайплайн: EDT (import + export в XML) -> Designer (XML -> ИБ) -> Designer (ИБ -> cfe).
    Версия артефакта: <семантика из Configuration.mdo>.<N>, где N — количество коммитов,
    тронувших исходники расширения (src/, DT-INF/, .project).
#>
param(
    [string]$EdtCli    = "E:\DEV_LOCAL\INSTALLED\1C\1CE\components\1c-edt-2025.2.6+4-x86_64\1cedtcli.exe",
    [string]$Designer  = "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150\bin\1cv8.exe",
    [string]$BaseIb    = "E:\DEV_LOCAL\zup_empty",
    [string]$RepoRoot  = "E:\DEV_LOCAL\GIT\voicechat-extension-history",
    [string]$Project   = "VoiceChatIntegration",       # имя EDT-проекта
    [string]$Extension = "ВЧ_ИнтеграцияСVoceChat"      # имя расширения в 1С
)
$ErrorActionPreference = "Stop"

function Invoke-Designer([string]$Arguments) {
    $before = @(Get-Process -Name "1cv8" -EA SilentlyContinue | Select-Object -ExpandProperty Id)
    $p = Start-Process -FilePath $Designer -ArgumentList $Arguments -PassThru
    Wait-Process -Id $p.Id -Timeout 900
    if ($p.ExitCode -ne 0) { throw "Designer завершился с кодом $($p.ExitCode): $Arguments" }
    Start-Sleep 2
    Get-Process -Name "1cv8" -EA SilentlyContinue |
        Where-Object { $before -notcontains $_.Id } |
        Wait-Process -Timeout 900
}

# Build-корень на E: — видно, не теряется при перезагрузке, не захламляет temp
$root = "E:\DEV_LOCAL\BUILD\cfe-build"
Remove-Item $root -Recurse -Force -EA SilentlyContinue
New-Item -ItemType Directory -Force -Path "$root\ws","$root\src","$root\xml","$root\ib","$root\out" | Out-Null

# Копия репо
robocopy $RepoRoot "$root\src" /E /XD .git | Out-Null

# Семантическая версия из mdo
$mdo = "$root\src\src\Configuration\Configuration.mdo"
$mdoText = Get-Content $mdo -Raw -Encoding UTF8
$sem = [regex]::Match($mdoText, '<version>([\d.]+)</version>').Groups[1].Value
if ($sem -notmatch '^\d+\.\d+\.\d+$') {
    throw "В Configuration.mdo версия '$sem'. Ожидается формат X.Y.Z (например 2.1.0)."
}

# Схема C — только коммиты, тронувшие исходники расширения
Push-Location $RepoRoot
$build = git rev-list --count HEAD -- src/ DT-INF/ .project
Pop-Location
$version = "$sem.$build"
Write-Host "▶ Версия сборки: $version" -ForegroundColor Cyan

# Патч версии — UTF-8 без BOM
$mdoText = $mdoText -replace '<version>[\d.]+</version>', "<version>$version</version>"
[System.IO.File]::WriteAllText($mdo, $mdoText, [System.Text.UTF8Encoding]::new($false))

# 1. EDT: импорт проекта + экспорт в XML
& $EdtCli -data "$root\ws" -timeout 1800 -command import --project "$root\src"
& $EdtCli -data "$root\ws" -timeout 1800 -command export --project-name $Project --configuration-files "$root\xml"
if (-not (Test-Path "$root\xml\Configuration.xml")) { throw "EDT export не создал Configuration.xml" }

# 2. Designer: XML -> ИБ (копия каркаса, расширение создаётся с именем $Extension)
robocopy $BaseIb "$root\ib" /E | Out-Null
Invoke-Designer "DESIGNER /F$root\ib /DisableStartupMessages /LoadConfigFromFiles $root\xml -Extension $Extension /UpdateDBCfg"

# 3. Designer: ИБ -> cfe (ищем расширение по правильному имени)
$cfe = "$root\out\$Extension-$version.cfe"
Invoke-Designer "DESIGNER /F$root\ib /DisableStartupMessages /DumpCfg $cfe -Extension $Extension"

# Пост-проверка артефакта
$f = Get-Item $cfe -EA SilentlyContinue
if (-not $f -or $f.Length -lt 10KB) { throw "cfe не создан или подозрительно мал: $($f.Length) байт" }
Write-Host "✅ Готово: $($f.FullName) ($($f.Length) байт)" -ForegroundColor Green