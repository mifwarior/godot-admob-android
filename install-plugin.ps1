param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

# Проверка существования пути проекта
if (-not (Test-Path -Path $ProjectPath)) {
    Write-Error "Путь к проекту не существует: $ProjectPath"
    exit 1
}

# Проверка, является ли путь проектом Godot (наличие project.godot)
$projectFile = Join-Path -Path $ProjectPath -ChildPath "project.godot"
if (-not (Test-Path -Path $projectFile)) {
    Write-Error "Указанный путь не является проектом Godot (отсутствует файл project.godot): $ProjectPath"
    exit 1
}

# Создание необходимых директорий в проекте
$androidPluginsDir = Join-Path -Path $ProjectPath -ChildPath "android/plugins"
$addonsAdmobDir = Join-Path -Path $ProjectPath -ChildPath "addons/admob"

Write-Host "Создание директорий для плагина..."
New-Item -ItemType Directory -Force -Path $androidPluginsDir | Out-Null
New-Item -ItemType Directory -Force -Path $addonsAdmobDir | Out-Null

# Путь к выходной директории с собранным плагином
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath ".output"
if (-not (Test-Path -Path $outputDir)) {
    Write-Error "Директория с собранным плагином не найдена: $outputDir. Пожалуйста, соберите плагин перед установкой."
    exit 1
}

# Поиск последнего ZIP-архива с плагином
$zipFiles = Get-ChildItem -Path $outputDir -Filter "poing-godot-admob-android-*.zip" | Sort-Object -Property LastWriteTime -Descending
if ($zipFiles.Count -eq 0) {
    Write-Error "ZIP-архив с плагином не найден в директории $outputDir. Пожалуйста, соберите плагин перед установкой."
    exit 1
}

$latestZip = $zipFiles[0]
Write-Host "Найден архив с плагином: $($latestZip.Name)"

# Временная директория для распаковки архива
$tempDir = Join-Path -Path $env:TEMP -ChildPath "godot-admob-temp"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Распаковка архива
Write-Host "Распаковка архива плагина..."
Expand-Archive -Path $latestZip.FullName -DestinationPath $tempDir

# Копирование AAR и GDAP файлов в android/plugins
$aarFiles = Get-ChildItem -Path $tempDir -Filter "*.aar" -Recurse
$gdapFiles = Get-ChildItem -Path $tempDir -Filter "*.gdap" -Recurse

Write-Host "Копирование Android-плагинов в $androidPluginsDir..."
foreach ($file in $aarFiles) {
    Copy-Item -Path $file.FullName -Destination $androidPluginsDir -Force
    Write-Host "  Скопирован: $($file.Name)"
}

foreach ($file in $gdapFiles) {
    Copy-Item -Path $file.FullName -Destination $androidPluginsDir -Force
    Write-Host "  Скопирован: $($file.Name)"
}

# Копирование директории admob в addons
$admobSourceDir = Join-Path -Path $PSScriptRoot -ChildPath "admob"
if (Test-Path -Path $admobSourceDir) {
    Write-Host "Копирование GDScript файлов в $addonsAdmobDir..."
    
    # Копирование с сохранением структуры директорий
    $items = Get-ChildItem -Path $admobSourceDir -Recurse
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($admobSourceDir.Length)
        $destination = Join-Path -Path $addonsAdmobDir -ChildPath $relativePath
        
        if ($item.PSIsContainer) {
            if (-not (Test-Path -Path $destination)) {
                New-Item -ItemType Directory -Force -Path $destination | Out-Null
            }
        } else {
            $destinationDir = Split-Path -Path $destination -Parent
            if (-not (Test-Path -Path $destinationDir)) {
                New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
            }
            Copy-Item -Path $item.FullName -Destination $destination -Force
        }
    }
    
    Write-Host "  GDScript файлы скопированы успешно"
} else {
    Write-Error "Директория с GDScript файлами не найдена: $admobSourceDir"
    exit 1
}

# Очистка временной директории
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "Плагин AdMob успешно установлен в проект: $ProjectPath" -ForegroundColor Green
Write-Host ""
Write-Host "Для завершения установки:"
Write-Host "1. Откройте проект в Godot"
Write-Host "2. Перейдите в Project > Project Settings > Plugins"
Write-Host "3. Убедитесь, что плагин AdMob включен"
Write-Host "4. Настройте Android export в Project > Export > Android"
Write-Host ""
Write-Host "Подробная инструкция доступна в файле INSTALL.md"
