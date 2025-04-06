# Скрипт для автоматической загрузки Java 11 и сборки проекта
# Автор: Poing Studios

# Параметры
param(
    [string]$GodotVersion,
    [string]$PluginExportPath = $null,
    [switch]$BuildOnly = $false,
    [switch]$ExportFiles = $false,
    [switch]$ZipPlugins = $false,
    [string]$AndroidSdkPath = $null
)

# Получаем версию Godot из переменных среды или используем значение по умолчанию
$defaultGodotVersion = "4.2"
$envGodotVersion = $env:GODOT_VERSION

# Устанавливаем версию Godot, если она не указана в параметрах
if (-not $GodotVersion) {
    $GodotVersion = if ($envGodotVersion) { $envGodotVersion } else { $defaultGodotVersion }
}

# Если не указаны флаги, включаем все по умолчанию
if (-not ($BuildOnly -or $ExportFiles -or $ZipPlugins)) {
    $ZipPlugins = $true
    Write-Host "Не указаны флаги операций, по умолчанию будет выполнена сборка и создание ZIP-архива" -ForegroundColor Yellow
}

# Создаем временную директорию для Java 11 в каталоге проекта
$tempDir = Join-Path $PSScriptRoot ".java11_temp"
$javaDir = Join-Path $tempDir "jdk-11"
$javaZip = Join-Path $tempDir "jdk11.zip"
$originalJavaHome = $env:JAVA_HOME
$originalAndroidHome = $env:ANDROID_HOME

# Функция для очистки временных файлов и восстановления переменных среды
function Cleanup {
    Write-Host "Очистка временных файлов и восстановление переменных среды..."
    if ($originalJavaHome) {
        $env:JAVA_HOME = $originalJavaHome
        Write-Host "JAVA_HOME восстановлен: $env:JAVA_HOME"
    }
    else {
        $env:JAVA_HOME = $null
        Write-Host "JAVA_HOME сброшен"
    }
    
    # Восстанавливаем ANDROID_HOME, если он был изменен
    if ($originalAndroidHome) {
        $env:ANDROID_HOME = $originalAndroidHome
        Write-Host "ANDROID_HOME восстановлен: $env:ANDROID_HOME"
    }
    else {
        $env:ANDROID_HOME = $null
        Write-Host "ANDROID_HOME сброшен"
    }
    
    # Не удаляем временные файлы, чтобы не скачивать Java каждый раз
    # Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

# Обработка ошибок
trap {
    Write-Host "Произошла ошибка: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Определяем путь к Android SDK
if (-not $AndroidSdkPath) {
    # Пытаемся получить путь из переменной среды
    $AndroidSdkPath = $env:ANDROID_HOME
    
    # Если переменная среды не задана, пытаемся найти SDK в стандартных местах
    if (-not $AndroidSdkPath) {
        $possiblePaths = @(
            "$env:LOCALAPPDATA\Android\Sdk",
            "$env:USERPROFILE\AppData\Local\Android\Sdk",
            "C:\Android\Sdk",
            "D:\Android\Sdk",
            "$env:PROGRAMFILES\Android\Sdk"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $AndroidSdkPath = $path
                break
            }
        }
    }
}

# Создаем local.properties с путем к Android SDK и устанавливаем ANDROID_HOME
if ($AndroidSdkPath) {
    Write-Host "Найден Android SDK: $AndroidSdkPath" -ForegroundColor Green
    
    # Устанавливаем переменную среды ANDROID_HOME
    $env:ANDROID_HOME = $AndroidSdkPath
    Write-Host "Установлена переменная среды ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Green
    
    # Создаем файл local.properties
    $localPropertiesPath = Join-Path $PSScriptRoot "local.properties"
    "sdk.dir=$($AndroidSdkPath.Replace('\', '\\'))" | Out-File -FilePath $localPropertiesPath -Encoding utf8
    Write-Host "Создан файл local.properties с путем к Android SDK" -ForegroundColor Green
    
    # Добавляем инструменты Android SDK в PATH
    $androidTools = Join-Path $AndroidSdkPath "tools"
    $androidPlatformTools = Join-Path $AndroidSdkPath "platform-tools"
    $env:PATH = "$androidTools;$androidPlatformTools;$env:PATH"
    Write-Host "Добавлены инструменты Android SDK в PATH" -ForegroundColor Green
}
else {
    Write-Host "ВНИМАНИЕ: Путь к Android SDK не найден!" -ForegroundColor Red
    Write-Host "Укажите путь к Android SDK с помощью параметра -AndroidSdkPath или установите переменную среды ANDROID_HOME" -ForegroundColor Yellow
    Write-Host "Сборка может завершиться с ошибкой" -ForegroundColor Yellow
}

# Функция для скачивания библиотеки Godot
function Download-GodotLib {
    param (
        [string]$Version
    )
    
    $godotLibDir = Join-Path $PSScriptRoot "libs\godot-lib"
    $godotLibFile = Join-Path $godotLibDir "godot-lib.aar"
    
    # Проверяем, существует ли уже файл
    if (Test-Path $godotLibFile) {
        Write-Host "Библиотека Godot уже существует: $godotLibFile" -ForegroundColor Green
        return
    }
    
    # Формируем URL для скачивания
    $godotLibUrl = "https://github.com/godotengine/godot-builds/releases/download/$CURRENT_GODOT_VERSION-$BUILD_VERSION/$GODOT_AAR_FILENAME"
    
    Write-Host "Скачивание библиотеки Godot из $godotLibUrl" -ForegroundColor Cyan
    Write-Host "Это может занять некоторое время, пожалуйста, подождите..." -ForegroundColor Yellow
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $godotLibUrl -OutFile $godotLibFile
        Write-Host "Библиотека Godot успешно скачана: $godotLibFile" -ForegroundColor Green
    }
    catch {
        # Если не удалось скачать с template_release, пробуем release
        Write-Host "Не удалось скачать библиотеку с template_release, пробуем другой формат..." -ForegroundColor Yellow
        
        $godotLibUrlAlt = "https://github.com/godotengine/godot/releases/download/$Version-stable/godot-lib.$Version.stable.release.aar"
        
        try {
            Invoke-WebRequest -Uri $godotLibUrlAlt -OutFile $godotLibFile
            Write-Host "Библиотека Godot успешно скачана: $godotLibFile" -ForegroundColor Green
        }
        catch {
            # Если не удалось скачать стабильную версию, пробуем скачать RC версию
            Write-Host "Не удалось скачать стабильную версию Godot $Version, пробуем RC версию..." -ForegroundColor Yellow
            
            $godotLibUrlRC = "https://github.com/godotengine/godot/releases/download/$Version-rc1/godot-lib.$Version.rc1.template_release.aar"
            
            try {
                Invoke-WebRequest -Uri $godotLibUrlRC -OutFile $godotLibFile
                Write-Host "Библиотека Godot RC успешно скачана: $godotLibFile" -ForegroundColor Green
            }
            catch {
                # Если не удалось скачать RC версию с template_release, пробуем release
                $godotLibUrlRCAlt = "https://github.com/godotengine/godot/releases/download/$Version-rc1/godot-lib.$Version.rc1.release.aar"
                
                try {
                    Invoke-WebRequest -Uri $godotLibUrlRCAlt -OutFile $godotLibFile
                    Write-Host "Библиотека Godot RC успешно скачана: $godotLibFile" -ForegroundColor Green
                }
                catch {
                    # Если не удалось скачать RC версию, пробуем скачать beta версию
                    Write-Host "Не удалось скачать RC версию Godot $Version, пробуем beta версию..." -ForegroundColor Yellow
                    
                    $godotLibUrlBeta = "https://github.com/godotengine/godot/releases/download/$Version-beta1/godot-lib.$Version.beta1.template_release.aar"
                    
                    try {
                        Invoke-WebRequest -Uri $godotLibUrlBeta -OutFile $godotLibFile
                        Write-Host "Библиотека Godot Beta успешно скачана: $godotLibFile" -ForegroundColor Green
                    }
                    catch {
                        # Если не удалось скачать beta версию с template_release, пробуем release
                        $godotLibUrlBetaAlt = "https://github.com/godotengine/godot/releases/download/$Version-beta1/godot-lib.$Version.beta1.release.aar"
                        
                        try {
                            Invoke-WebRequest -Uri $godotLibUrlBetaAlt -OutFile $godotLibFile
                            Write-Host "Библиотека Godot Beta успешно скачана: $godotLibFile" -ForegroundColor Green
                        }
                        catch {
                            Write-Host "Ошибка при скачивании библиотеки Godot: $_" -ForegroundColor Red
                            Write-Host "Пожалуйста, скачайте библиотеку Godot вручную и поместите ее в директорию: $godotLibDir" -ForegroundColor Yellow
                            Write-Host "URL для скачивания: $godotLibUrl" -ForegroundColor Yellow
                            throw "Не удалось скачать библиотеку Godot"
                        }
                    }
                }
            }
        }
    }
}

# Вывод информации о параметрах сборки
Write-Host "Параметры сборки:" -ForegroundColor Cyan
Write-Host "- Версия Godot: $GodotVersion"
if ($AndroidSdkPath) {
    Write-Host "- Android SDK: $AndroidSdkPath"
}
if ($PluginExportPath) {
    Write-Host "- Путь экспорта плагина: $PluginExportPath"
}
if ($BuildOnly) {
    Write-Host "- Режим: только сборка"
} elseif ($ExportFiles -and $ZipPlugins) {
    Write-Host "- Режим: сборка, экспорт файлов и создание ZIP-архива"
} elseif ($ExportFiles) {
    Write-Host "- Режим: сборка и экспорт файлов"
} elseif ($ZipPlugins) {
    Write-Host "- Режим: сборка и создание ZIP-архива"
}

# Создаем временную директорию, если она не существует
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    Write-Host "Создана временная директория: $tempDir"
}

# Проверяем, скачана ли уже Java 11
if (-not (Test-Path $javaDir)) {
    # URL для скачивания OpenJDK 11 (Adoptium/AdoptOpenJDK)
    $javaUrl = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.20.1%2B1/OpenJDK11U-jdk_x64_windows_hotspot_11.0.20.1_1.zip"
    
    Write-Host "Скачивание Java 11 из $javaUrl"
    Write-Host "Это может занять некоторое время, пожалуйста, подождите..."
    
    # Скачиваем Java 11
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip
    }
    catch {
        Write-Host "Ошибка при скачивании Java 11: $_" -ForegroundColor Red
        Cleanup
        exit 1
    }
    
    Write-Host "Распаковка Java 11..."
    
    # Распаковываем архив
    try {
        Expand-Archive -Path $javaZip -DestinationPath $tempDir -Force
        # Находим директорию JDK (имя может отличаться)
        $jdkDir = Get-ChildItem -Path $tempDir -Directory | Where-Object { $_.Name -like "jdk-11*" } | Select-Object -First 1
        if ($jdkDir) {
            # Переименовываем для удобства
            Rename-Item -Path $jdkDir.FullName -NewName "jdk-11"
        }
        else {
            throw "Не удалось найти директорию JDK после распаковки"
        }
    }
    catch {
        Write-Host "Ошибка при распаковке Java 11: $_" -ForegroundColor Red
        Cleanup
        exit 1
    }
    
    # Удаляем архив, чтобы сэкономить место
    Remove-Item -Force $javaZip -ErrorAction SilentlyContinue
}

# Устанавливаем JAVA_HOME на временную директорию
$env:JAVA_HOME = $javaDir
Write-Host "Установлен JAVA_HOME: $env:JAVA_HOME"

# Добавляем Java в PATH
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
Write-Host "Java добавлена в PATH"

# Проверяем версию Java
try {
    $javaExe = Join-Path $env:JAVA_HOME "bin\java.exe"
    $javaVersion = & $javaExe -version 2>&1
    Write-Host "Используется Java:"
    Write-Host $javaVersion
}
catch {
    Write-Host "Ошибка при проверке версии Java: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Скачиваем библиотеку Godot, если она не существует
try {
    Download-GodotLib -Version $GodotVersion
}
catch {
    Write-Host "Ошибка при скачивании библиотеки Godot: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Определяем команду Gradle в зависимости от ОС
$gradleCmd = "./gradlew"
if ($IsWindows -or $env:OS -like "*Windows*") {
    $gradleCmd = ".\gradlew.bat"
}

# Сборка проекта
Write-Host "Сборка проекта с помощью Gradle..." -ForegroundColor Cyan
try {
    # Создаем директорию .output, если она не существует
    $outputDir = Join-Path $PSScriptRoot ".output"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
        Write-Host "Создана директория для выходных файлов: $outputDir" -ForegroundColor Green
    }
    
    $gradleArgs = @("build", "--info")
    Write-Host "Запуск команды: $gradleCmd $gradleArgs" -ForegroundColor Yellow
    & $gradleCmd $gradleArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Сборка проекта завершилась с ошибкой (код $LASTEXITCODE)"
    }
}
catch {
    Write-Host "Ошибка при сборке проекта: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Если указан флаг BuildOnly, завершаем работу
if ($BuildOnly) {
    Write-Host "Сборка успешно завершена!" -ForegroundColor Green
    Cleanup
    exit 0
}

# Экспорт файлов, если указан флаг или путь
if ($ExportFiles -or $PluginExportPath) {
    if (-not $PluginExportPath) {
        Write-Host "Для экспорта файлов необходимо указать путь с помощью параметра -PluginExportPath" -ForegroundColor Yellow
    }
    else {
        Write-Host "Экспорт файлов плагина в $PluginExportPath..." -ForegroundColor Cyan
        try {
            $gradleArgs = @("exportFiles", "-PpluginExportPath=$PluginExportPath")
            & $gradleCmd $gradleArgs
            
            if ($LASTEXITCODE -ne 0) {
                throw "Экспорт файлов завершился с ошибкой (код $LASTEXITCODE)"
            }
            
            Write-Host "Файлы плагина успешно экспортированы в $PluginExportPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Ошибка при экспорте файлов: $_" -ForegroundColor Red
            Cleanup
            exit 1
        }
    }
}

# Создание ZIP-архива, если указан флаг или версия Godot
if ($ZipPlugins) {
    $zipArgs = @("zipPlugins")
    if ($GodotVersion) {
        $zipArgs += "-PgodotVersion=$GodotVersion"
    }
    
    Write-Host "Создание ZIP-архива плагина для Godot $GodotVersion..." -ForegroundColor Cyan
    try {
        & $gradleCmd $zipArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Создание ZIP-архива завершилось с ошибкой (код $LASTEXITCODE)"
        }
        
        # Находим созданный ZIP-файл
        $outputDir = Join-Path $PSScriptRoot ".output"
        if (Test-Path $outputDir) {
            $zipFile = Get-ChildItem -Path $outputDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if ($zipFile) {
                Write-Host "ZIP-архив плагина успешно создан: $($zipFile.FullName)" -ForegroundColor Green
            }
            else {
                Write-Host "ZIP-архив создан, но не найден в директории .output" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Директория .output не найдена, но ZIP-архив должен быть создан" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Ошибка при создании ZIP-архива: $_" -ForegroundColor Red
        Cleanup
        exit 1
    }
}

# Очистка и завершение
Cleanup
Write-Host "Все операции успешно завершены!" -ForegroundColor Green
