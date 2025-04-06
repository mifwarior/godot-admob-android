extends Node

# Объявление переменных для работы с App Open Ad
var app_open_ad_plugin
var app_open_ad_uid = -1

# Константы для ориентации App Open Ad
const APP_OPEN_AD_ORIENTATION_PORTRAIT = 1
const APP_OPEN_AD_ORIENTATION_LANDSCAPE = 2

# Тестовый ID для App Open Ad
const TEST_APP_OPEN_AD_ID = "ca-app-pub-3940256099942544/3419835294"

# Сигналы для App Open Ad
signal app_open_ad_loaded
signal app_open_ad_failed_to_load(error_data)
signal app_open_ad_clicked
signal app_open_ad_dismissed
signal app_open_ad_failed_to_show(error_data)
signal app_open_ad_impression
signal app_open_ad_showed

func _ready():
	# Инициализация AdMob
	var admob_plugin = Engine.get_singleton("PoingGodotAdMob")
	if admob_plugin:
		admob_plugin.initialize()
		print("AdMob инициализирован")
	
	# Инициализация плагина App Open Ad
	app_open_ad_plugin = Engine.get_singleton("PoingGodotAdMobAppOpenAd")
	if app_open_ad_plugin:
		print("Плагин App Open Ad загружен")
		
		# Подключение сигналов
		app_open_ad_plugin.connect("on_app_open_ad_loaded", self, "_on_app_open_ad_loaded")
		app_open_ad_plugin.connect("on_app_open_ad_failed_to_load", self, "_on_app_open_ad_failed_to_load")
		app_open_ad_plugin.connect("on_app_open_ad_clicked", self, "_on_app_open_ad_clicked")
		app_open_ad_plugin.connect("on_app_open_ad_dismissed_full_screen_content", self, "_on_app_open_ad_dismissed")
		app_open_ad_plugin.connect("on_app_open_ad_failed_to_show_full_screen_content", self, "_on_app_open_ad_failed_to_show")
		app_open_ad_plugin.connect("on_app_open_ad_impression", self, "_on_app_open_ad_impression")
		app_open_ad_plugin.connect("on_app_open_ad_showed_full_screen_content", self, "_on_app_open_ad_showed")
		
		# Создание и загрузка App Open Ad
		load_app_open_ad()

# Функция для создания и загрузки App Open Ad
func load_app_open_ad():
	if app_open_ad_plugin:
		# Создаем новый экземпляр App Open Ad
		app_open_ad_uid = app_open_ad_plugin.create()
		print("Создан App Open Ad с UID: ", app_open_ad_uid)
		
		# Создаем словарь для AdRequest
		var ad_request = {
			"is_designed_for_families": false,
			"tag_for_under_age_of_consent": 0, # TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED
			"tag_for_child_directed_treatment": 0, # TAG_FOR_CHILD_DIRECTED_TREATMENT_UNSPECIFIED
			"max_ad_content_rating": "T", # Teenage
			"test_device_ids": []
		}
		
		# Загружаем App Open Ad
		# Параметры: adUnitId, adRequestDictionary, keywords, uid, orientation
		app_open_ad_plugin.load(TEST_APP_OPEN_AD_ID, ad_request, [], app_open_ad_uid, APP_OPEN_AD_ORIENTATION_PORTRAIT)
		print("Загрузка App Open Ad...")

# Функция для показа App Open Ad
func show_app_open_ad():
	if app_open_ad_plugin and app_open_ad_uid >= 0:
		app_open_ad_plugin.show(app_open_ad_uid)
		print("Показ App Open Ad...")

# Функция для уничтожения App Open Ad
func destroy_app_open_ad():
	if app_open_ad_plugin and app_open_ad_uid >= 0:
		app_open_ad_plugin.destroy(app_open_ad_uid)
		app_open_ad_uid = -1
		print("App Open Ad уничтожен")

# Обработчики сигналов
func _on_app_open_ad_loaded(uid):
	print("App Open Ad загружен: ", uid)
	emit_signal("app_open_ad_loaded")

func _on_app_open_ad_failed_to_load(uid, error_data):
	print("Не удалось загрузить App Open Ad: ", uid, " Ошибка: ", error_data)
	emit_signal("app_open_ad_failed_to_load", error_data)

func _on_app_open_ad_clicked(uid):
	print("Клик по App Open Ad: ", uid)
	emit_signal("app_open_ad_clicked")

func _on_app_open_ad_dismissed(uid):
	print("App Open Ad закрыт: ", uid)
	emit_signal("app_open_ad_dismissed")
	
	# Перезагружаем рекламу после закрытия
	load_app_open_ad()

func _on_app_open_ad_failed_to_show(uid, error_data):
	print("Не удалось показать App Open Ad: ", uid, " Ошибка: ", error_data)
	emit_signal("app_open_ad_failed_to_show", error_data)

func _on_app_open_ad_impression(uid):
	print("App Open Ad показан (impression): ", uid)
	emit_signal("app_open_ad_impression")

func _on_app_open_ad_showed(uid):
	print("App Open Ad показан: ", uid)
	emit_signal("app_open_ad_showed")

# Пример использования в игре
func _on_show_app_open_ad_button_pressed():
	show_app_open_ad()

# При выходе из приложения уничтожаем рекламу
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		destroy_app_open_ad()
		get_tree().quit()
