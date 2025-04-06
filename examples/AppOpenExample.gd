# MIT License

# Copyright (c) 2023-present Poing Studios

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends Node

# Сигнал для отслеживания состояния загрузки/просмотра рекламы
# is_completed = false: реклама начала загружаться/показываться
# is_completed = true: реклама просмотрена или произошла ошибка
signal ad_state_changed(is_completed)

var app_open_ad_plugin
var admob
var app_open_ad_uid = -1  # Объявляем как член класса
var is_ad_loaded = false  # Флаг для отслеживания загрузки рекламы

func _ready():
	if !Engine.has_singleton("PoingGodotAdMob"):
		print("PoingGodotAdMob plugin not found")
		return
	
	ad_state_changed.connect(_handle_state)
	# Инициализация AdMob
	if Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobAppOpenAd"):
		print("PoingGodotAdMob plugin found")
		admob = Engine.get_singleton("PoingGodotAdMob")
		admob.initialize()
		
		app_open_ad_plugin = Engine.get_singleton("PoingGodotAdMobAppOpenAd")
		# Подключение сигналов
		app_open_ad_plugin.connect("on_app_open_ad_loaded", Callable(self, "_on_app_open_ad_loaded"))
		app_open_ad_plugin.connect("on_app_open_ad_failed_to_load", Callable(self, "_on_app_open_ad_failed_to_load"))
		app_open_ad_plugin.connect("on_app_open_ad_showed_full_screen_content", Callable(self, "_on_app_open_ad_showed_full_screen_content"))
		app_open_ad_plugin.connect("on_app_open_ad_failed_to_show_full_screen_content", Callable(self, "_on_app_open_ad_failed_to_show_full_screen_content"))
		app_open_ad_plugin.connect("on_app_open_ad_clicked", Callable(self, "_on_app_open_ad_clicked"))
		app_open_ad_plugin.connect("on_app_open_ad_dismissed_full_screen_content", Callable(self, "_on_app_open_ad_dismissed_full_screen_content"))
		app_open_ad_plugin.connect("on_app_open_ad_impression", Callable(self, "_on_app_open_ad_impression"))
		
		# Создаем экземпляр App Open Ad и получаем его UID
		app_open_ad_uid = app_open_ad_plugin.create()
		
		# Загрузка App Open Ad с полным набором параметров
		var ad_request = {
			"is_designed_for_families": false,
			"tag_for_under_age_of_consent": 0,
			"tag_for_child_directed_treatment": 0,
			"max_ad_content_rating": "T",
			"test_device_ids": [],
			"keywords": [],
			"content_url": "",
			"neighbouring_content_urls": [],
			"mediation_extras": {}, # Важно: этот ключ должен быть в словаре
			"google_request_agent": "",
			"extras": {} # Важно: этот ключ тоже должен быть в словаре
		}
		
		# Используем правильный тестовый ID для App Open Ad
		var ad_unit_id = "ca-app-pub-3940256099942544/9257395921" # Тестовый ID для App Open Ad
		
		# Сигнализируем о начале загрузки рекламы
		ad_state_changed.emit(false)
		
		app_open_ad_plugin.load(ad_unit_id, ad_request, [], app_open_ad_uid, 1) # 1 = PORTRAIT

# Обработка уведомлений приложения
func _notification(what):
	#if what == NOTIFICATION_APPLICATION_RESUMED:
		## Показать рекламу при возвращении в приложение, если она загружена
		#if is_ad_loaded:
			#show_app_open_ad()
	pass

func _handle_state(app_open_end):
	get_tree().paused = app_open_end

# Функция для показа рекламы
func show_app_open_ad():
	if app_open_ad_uid >= 0 and app_open_ad_plugin and is_ad_loaded:
		print("Showing App Open Ad")
		# Сигнализируем о начале показа рекламы
		ad_state_changed.emit(false)
		app_open_ad_plugin.show(app_open_ad_uid)
	else:
		print("App Open Ad not ready to show")
		# Если реклама не готова, сразу сигнализируем о завершении
		ad_state_changed.emit(true)

# Обработчики сигналов
func _on_app_open_ad_loaded(uid):
	if uid == app_open_ad_uid:
		print("App Open Ad loaded successfully")
		is_ad_loaded = true
		
		# Показываем рекламу сразу после загрузки
		# Небольшая задержка для уверенности, что всё инициализировано
		await get_tree().create_timer(0.5).timeout
		show_app_open_ad()

func _on_app_open_ad_failed_to_load(uid, error_data):
	if uid == app_open_ad_uid:
		print("Failed to load App Open Ad: ", error_data)
		is_ad_loaded = false
		
		# Сигнализируем о завершении из-за ошибки
		ad_state_changed.emit(true)
		
		# Пробуем загрузить снова с другим тестовым ID
		app_open_ad_uid = app_open_ad_plugin.create()
		var ad_request = {
			"is_designed_for_families": false,
			"tag_for_under_age_of_consent": 0,
			"tag_for_child_directed_treatment": 0,
			"max_ad_content_rating": "T",
			"test_device_ids": [],
			"keywords": [],
			"content_url": "",
			"neighbouring_content_urls": [],
			"mediation_extras": {},
			"google_request_agent": "",
			"extras": {}
		}
		var ad_unit_id = "ca-app-pub-3940256099942544/3419835294" # Альтернативный тестовый ID
		
		# Сигнализируем о начале новой загрузки
		ad_state_changed.emit(false)
		
		app_open_ad_plugin.load(ad_unit_id, ad_request, [], app_open_ad_uid, 1)

func _on_app_open_ad_showed_full_screen_content(uid):
	if uid == app_open_ad_uid:
		print("App Open Ad showed")

func _on_app_open_ad_failed_to_show_full_screen_content(uid, error_data):
	if uid == app_open_ad_uid:
		print("Failed to show App Open Ad: ", error_data)
		is_ad_loaded = false
		
		# Сигнализируем о завершении из-за ошибки показа
		ad_state_changed.emit(true)

func _on_app_open_ad_clicked(uid):
	if uid == app_open_ad_uid:
		print("App Open Ad clicked")

func _on_app_open_ad_dismissed_full_screen_content(uid):
	if uid == app_open_ad_uid:
		print("App Open Ad dismissed")
		is_ad_loaded = false
		
		# Сигнализируем о завершении просмотра рекламы
		ad_state_changed.emit(true)
		
		# Освобождаем ресурсы рекламы
		if app_open_ad_plugin:
			app_open_ad_plugin.destroy(app_open_ad_uid)
			app_open_ad_uid = -1
			print("App Open Ad resources released")

func _on_app_open_ad_impression(uid):
	if uid == app_open_ad_uid:
		print("App Open Ad impression recorded")
