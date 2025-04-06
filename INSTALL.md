# Инструкция по установке AdMob плагина в Godot

## Шаг 1: Подготовка проекта Godot

1. Откройте ваш проект в Godot Engine (версия 4.2 или 4.3, в зависимости от версии плагина, который вы собрали)
2. Убедитесь, что ваш проект настроен для работы с Android:
   - Перейдите в меню `Project` → `Project Settings`
   - Откройте вкладку `Export` → `Android`
   - Проверьте, что указаны пути к Android SDK и Java (JDK)

## Шаг 2: Установка плагина

1. Найдите ZIP-архив плагина, который был создан скриптом сборки:
   ```
   D:\GodotProjects\godot-admob-android\.output\poing-godot-admob-android-v4.3.zip
   ```

2. Распакуйте содержимое архива в ваш проект Godot, соблюдая следующую структуру:
   - AAR файлы и GDAP файлы должны быть размещены в директории `android/plugins`:
     ```
     project/
     ├── android/
     │   └── plugins/
     │       ├── poing-godot-admob-ads-v1.0.1-release.aar
     │       ├── poing-godot-admob-core-v1.0.1-release.aar
     │       ├── poing-godot-admob.gdap
     │       └── ...
     ```
   
   - GDScript файлы и ресурсы для взаимодействия с плагином должны быть размещены в директории `addons`:
     ```
     project/
     ├── addons/
     │   └── admob/
     │       ├── admob.gd
     │       ├── app_open_ad.gd
     │       └── ...
     ├── project.godot
     └── ...
     ```

3. Если директории `android/plugins` или `addons` не существуют, создайте их в корне проекта

## Шаг 3: Настройка плагина в проекте

1. Откройте настройки проекта: `Project` → `Project Settings`
2. Перейдите на вкладку `Plugins`
3. Убедитесь, что плагины из директории `android/plugins` отображаются в списке и активированы

## Шаг 4: Настройка Android Export

1. Перейдите в меню `Project` → `Export`
2. Выберите или создайте новую конфигурацию для Android
3. В разделе `Plugins` убедитесь, что плагин `Poing Godot AdMob` включен
4. В разделе `Custom Template` можно указать пользовательский шаблон, если это необходимо
5. В разделе `Permissions` добавьте необходимые разрешения для AdMob:
   - `android.permission.INTERNET`
   - `android.permission.ACCESS_NETWORK_STATE`

## Шаг 5: Настройка AdMob в коде

1. Создайте скрипт GDScript для инициализации и работы с AdMob (или используйте существующий из директории `addons/admob`):

```gdscript
extends Node

# Идентификаторы AdMob
var ad_unit_ids = {
    "android": {
        "app_id": "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX",
        "app_open": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    }
}

# Переменная для хранения экземпляра App Open Ad
var app_open_ad

func _ready():
    # Инициализация AdMob
    if Engine.has_singleton("PoingGodotAdMob"):
        var admob = Engine.get_singleton("PoingGodotAdMob")
        
        # Инициализация с вашим App ID
        var app_id = ad_unit_ids["android"]["app_id"]
        admob.initialize(app_id)
        
        # Создание экземпляра App Open Ad
        var ad_unit_id = ad_unit_ids["android"]["app_open"]
        app_open_ad = admob.create_app_open_ad(ad_unit_id)
        
        # Подключение сигналов
        app_open_ad.connect("on_app_open_ad_loaded", _on_app_open_ad_loaded)
        app_open_ad.connect("on_app_open_ad_failed_to_load", _on_app_open_ad_failed_to_load)
        app_open_ad.connect("on_app_open_ad_showed", _on_app_open_ad_showed)
        app_open_ad.connect("on_app_open_ad_failed_to_show", _on_app_open_ad_failed_to_show)
        app_open_ad.connect("on_app_open_ad_clicked", _on_app_open_ad_clicked)
        app_open_ad.connect("on_app_open_ad_dismissed", _on_app_open_ad_dismissed)
        app_open_ad.connect("on_app_open_ad_impression", _on_app_open_ad_impression)
        
        # Загрузка рекламы
        app_open_ad.load()

# Загрузка App Open Ad
func load_app_open_ad():
    if app_open_ad:
        app_open_ad.load()

# Показ App Open Ad
func show_app_open_ad():
    if app_open_ad and app_open_ad.is_loaded():
        app_open_ad.show()

# Обработчики сигналов
func _on_app_open_ad_loaded():
    print("App Open Ad loaded successfully")

func _on_app_open_ad_failed_to_load(error_code):
    print("App Open Ad failed to load: ", error_code)

func _on_app_open_ad_showed():
    print("App Open Ad showed")

func _on_app_open_ad_failed_to_show(error_code):
    print("App Open Ad failed to show: ", error_code)

func _on_app_open_ad_clicked():
    print("App Open Ad clicked")

func _on_app_open_ad_dismissed():
    print("App Open Ad dismissed")
    # Перезагрузка рекламы после закрытия
    load_app_open_ad()

func _on_app_open_ad_impression():
    print("App Open Ad impression recorded")
```

2. Добавьте этот скрипт к узлу в вашей сцене (например, к автозагружаемому синглтону)

## Шаг 6: Автоматическая установка с помощью скрипта

Для автоматической установки плагина в ваш проект Godot, вы можете использовать скрипт `install-plugin.ps1`:

1. Убедитесь, что вы собрали плагин с помощью скрипта `build-with-java11.ps1`
2. Запустите скрипт установки, указав путь к вашему проекту Godot:

```powershell
.\install-plugin.ps1 -ProjectPath "путь\к\вашему\проекту\godot"
```

Скрипт автоматически:
- Проверит, что указанный путь является проектом Godot
- Создаст необходимые директории в проекте
- Найдет последнюю версию собранного плагина в директории `.output`
- Скопирует AAR и GDAP файлы в директорию `android/plugins` вашего проекта
- Скопирует GDScript файлы в директорию `addons/admob` вашего проекта

После выполнения скрипта вам нужно:
1. Открыть проект в Godot
2. Перейти в Project > Project Settings > Plugins
3. Убедиться, что плагин AdMob включен
4. Настроить Android export в Project > Export > Android

## Шаг 7: Тестирование

1. Экспортируйте проект для Android: `Project` → `Export` → выберите Android и нажмите `Export Project`
2. Установите APK на устройство Android
3. Запустите приложение и проверьте работу App Open Ad

## Примечания

1. Для тестирования используйте тестовые ID AdMob:
   ```
   app_id: "ca-app-pub-3940256099942544~3347511713"
   app_open: "ca-app-pub-3940256099942544/3419835294"
   ```

2. Перед публикацией в Google Play замените тестовые ID на реальные из вашего аккаунта AdMob

3. Для отладки проблем с плагином можно использовать логи Android (adb logcat)

4. Если вам нужно обновить плагин, просто пересоберите его с помощью скрипта `build-with-java11.ps1` и замените файлы в директориях `android/plugins` и `addons`

5. Для автоматической установки или обновления плагина используйте скрипт:
   ```powershell
   .\install-plugin.ps1 -ProjectPath "путь\к\проекту\godot"
   ```

6. Структура директорий может незначительно отличаться в зависимости от версии Godot и конкретной сборки плагина. Следуйте инструкциям, которые идут в комплекте с плагином.
