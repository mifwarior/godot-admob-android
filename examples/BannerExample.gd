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

var banner_plugin
var admob
var banner_uid = -1  # Объявляем как член класса
var is_ad_loaded = false  # Флаг для отслеживания загрузки рекламы
var is_loading = false  # Флаг для предотвращения повторных загрузок

func _ready():
	if !Engine.has_singleton("PoingGodotAdMob"):
		print("PoingGodotAdMob plugin not found")
		return
	
	ad_state_changed.connect(_handle_state)
	# Инициализация AdMob
	if Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobAdView"):
		print("PoingGodotAdMob plugins found")
		admob = Engine.get_singleton("PoingGodotAdMob")
		admob.initialize()
		
		banner_plugin = Engine.get_singleton("PoingGodotAdMobAdView")
		# Подключение сигналов
		banner_plugin.connect("on_ad_clicked", Callable(self, "_on_ad_clicked"))
		banner_plugin.connect("on_ad_closed", Callable(self, "_on_ad_closed"))
		banner_plugin.connect("on_ad_failed_to_load", Callable(self, "_on_ad_failed_to_load"))
		banner_plugin.connect("on_ad_impression", Callable(self, "_on_ad_impression"))
		banner_plugin.connect("on_ad_loaded", Callable(self, "_on_ad_loaded"))
		banner_plugin.connect("on_ad_opened", Callable(self, "_on_ad_opened"))
		
		# Загружаем баннер при запуске
		await get_tree().create_timer(1.0).timeout  # Небольшая задержка для инициализации плагина
		load_banner()

func _handle_state(banner_end):
	# Для баннеров обычно не требуется ставить игру на паузу
	pass

# Функция для загрузки баннера
func load_banner():
	if !banner_plugin:
		print("Banner plugin not initialized")
		return
	
	# Предотвращаем повторную загрузку, если уже идет процесс загрузки
	if is_loading:
		print("Banner is already loading")
		return
		
	# Если баннер уже существует, уничтожаем его перед созданием нового
	if banner_uid >= 0:
		banner_plugin.destroy(banner_uid)
		banner_uid = -1
	
	is_loading = true
	
	# Сигнализируем о начале загрузки рекламы
	ad_state_changed.emit(false)
	
	var adSizePlugin = Engine.get_singleton("PoingGodotAdMobAdSize")
	var ad_size = adSizePlugin.getCurrentOrientationAnchoredAdaptiveBannerAdSize(-1)
	
	# Создаем словарь с настройками баннера
	var ad_view_dictionary = {
		"ad_size": {
			"width": ad_size.width,
			"height": ad_size.height
		},
		"ad_unit_id": "ca-app-pub-3940256099942544/6300978111",  # Тестовый ID для баннера
		"ad_position": 1  # BOTTOM (0=TOP, 1=BOTTOM, 2=LEFT, 3=RIGHT, 4=TOP_LEFT, 5=TOP_RIGHT, 6=BOTTOM_LEFT, 7=BOTTOM_RIGHT, 8=CENTER)
	}
	
	# Создаем баннер и получаем его UID
	banner_uid = banner_plugin.create(ad_view_dictionary)
	print("Banner created with UID: ", banner_uid)
	
	# Настраиваем запрос рекламы
	var ad_request = {
		"is_designed_for_families": false,
		"tag_for_under_age_of_consent": 0,
		"tag_for_child_directed_treatment": 0,
		"max_ad_content_rating": "T",
		"test_device_ids": [],
		"content_url": "",
		"neighbouring_content_urls": [],
		"mediation_extras": {},
		"extras": {}
	}
	
	# Загружаем рекламу
	var keywords = ["game", "arcade"]
	banner_plugin.load_ad(banner_uid, ad_request, keywords)
	print("Banner ad loading...")

# Функция для показа баннера
func show_banner():
	if !banner_plugin:
		print("Banner plugin not initialized")
		return
		
	if banner_uid >= 0 and is_ad_loaded:
		print("Showing Banner Ad")
		banner_plugin.show(banner_uid)
	else:
		print("Banner Ad not ready to show")
		# Если реклама не готова, пробуем загрузить ее снова
		if banner_uid < 0 and !is_loading:
			load_banner()

# Функция для скрытия баннера
func hide_banner():
	if !banner_plugin:
		print("Banner plugin not initialized")
		return
		
	if banner_uid >= 0:
		print("Hiding Banner Ad")
		banner_plugin.hide(banner_uid)

# Функция для уничтожения баннера и освобождения ресурсов
func destroy_banner():
	if !banner_plugin:
		print("Banner plugin not initialized")
		return
		
	if banner_uid >= 0:
		print("Destroying Banner Ad")
		banner_plugin.destroy(banner_uid)
		banner_uid = -1
		is_ad_loaded = false
		is_loading = false
		# Сигнализируем о завершении работы с рекламой
		ad_state_changed.emit(true)

# Функция для получения размера баннера (может быть полезно для UI)
func get_banner_size():
	if !banner_plugin or banner_uid < 0:
		return Vector2.ZERO
		
	var width = banner_plugin.get_width(banner_uid)
	var height = banner_plugin.get_height(banner_uid)
	print("Banner size: ", width, "x", height)
	return Vector2(width, height)

# Обработчики событий баннера
func _on_ad_failed_to_load(uid, load_ad_error):
	if uid != banner_uid:
		return
		
	print("Failed to load Banner Ad: ", load_ad_error)
	is_ad_loaded = false
	is_loading = false
	
	# Сигнализируем о завершении из-за ошибки
	ad_state_changed.emit(true)
	
	# Можно добавить повторную попытку загрузки через некоторое время
	await get_tree().create_timer(5.0).timeout
	if !is_ad_loaded and !is_loading and banner_uid < 0:
		load_banner()

func _on_ad_loaded(uid):
	if uid != banner_uid:
		return
		
	print("Banner Ad loaded successfully")
	is_ad_loaded = true
	is_loading = false
	
	# Сигнализируем об успешной загрузке
	ad_state_changed.emit(true)
	
	# Показываем баннер сразу после загрузки
	show_banner()

func _on_ad_clicked(uid):
	if uid == banner_uid:
		print("Banner Ad clicked")

func _on_ad_closed(uid):
	if uid == banner_uid:
		print("Banner Ad closed")

func _on_ad_impression(uid):
	if uid == banner_uid:
		print("Banner Ad impression recorded")

func _on_ad_opened(uid):
	if uid == banner_uid:
		print("Banner Ad opened")

# Пример использования:
# func _on_show_banner_button_pressed():
#     show_banner()
#
# func _on_hide_banner_button_pressed():
#     hide_banner()
#
# func _on_destroy_banner_button_pressed():
#     destroy_banner()
#
# func _on_reload_banner_button_pressed():
#     load_banner()
