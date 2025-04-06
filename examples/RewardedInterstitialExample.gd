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
# Сигнал для отслеживания получения награды
signal reward_earned(amount, type)

var rewarded_interstitial_ad_plugin
var admob
var rewarded_interstitial_ad_uid = -1  # Объявляем как член класса
var is_ad_loaded = false  # Флаг для отслеживания загрузки рекламы

func _ready():
	if !Engine.has_singleton("PoingGodotAdMob"):
		print("PoingGodotAdMob plugin not found")
		return
	
	ad_state_changed.connect(_handle_state)
	# Инициализация AdMob
	if Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobRewardedInterstitialAd"):
		print("PoingGodotAdMob plugin found")
		admob = Engine.get_singleton("PoingGodotAdMob")
		admob.initialize()
		
		rewarded_interstitial_ad_plugin = Engine.get_singleton("PoingGodotAdMobRewardedInterstitialAd")
		# Подключение сигналов
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_loaded", Callable(self, "_on_rewarded_interstitial_ad_loaded"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_failed_to_load", Callable(self, "_on_rewarded_interstitial_ad_failed_to_load"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_showed_full_screen_content", Callable(self, "_on_rewarded_interstitial_ad_showed_full_screen_content"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_failed_to_show_full_screen_content", Callable(self, "_on_rewarded_interstitial_ad_failed_to_show_full_screen_content"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_clicked", Callable(self, "_on_rewarded_interstitial_ad_clicked"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_dismissed_full_screen_content", Callable(self, "_on_rewarded_interstitial_ad_dismissed_full_screen_content"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_impression", Callable(self, "_on_rewarded_interstitial_ad_impression"))
		rewarded_interstitial_ad_plugin.connect("on_rewarded_interstitial_ad_user_earned_reward", Callable(self, "_on_rewarded_interstitial_ad_user_earned_reward"))
		
		# Создаем экземпляр Rewarded Interstitial Ad и получаем его UID
		rewarded_interstitial_ad_uid = rewarded_interstitial_ad_plugin.create()
		
		# Загрузка Rewarded Interstitial Ad с полным набором параметров
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
		
		# Используем правильный тестовый ID для Rewarded Interstitial Ad
		var ad_unit_id = "ca-app-pub-3940256099942544/5354046379" # Тестовый ID для Rewarded Interstitial Ad
		
		# Сигнализируем о начале загрузки рекламы
		ad_state_changed.emit(false)
		
		rewarded_interstitial_ad_plugin.load(ad_unit_id, ad_request, [], rewarded_interstitial_ad_uid)

func _handle_state(rewarded_interstitial_end):
	get_tree().paused = rewarded_interstitial_end

# Функция для показа рекламы
func show_rewarded_interstitial_ad():
	if rewarded_interstitial_ad_uid >= 0 and rewarded_interstitial_ad_plugin and is_ad_loaded:
		print("Showing Rewarded Interstitial Ad")
		# Сигнализируем о начале показа рекламы
		ad_state_changed.emit(false)
		
		# Настройка серверной верификации (опционально)
		# Это нужно делать ПЕРЕД показом рекламы, используя отдельный метод
		var server_side_verification = {
			"user_id": "user_123",
			"custom_data": "custom_verification_data"
		}
		rewarded_interstitial_ad_plugin.set_server_side_verification_options(rewarded_interstitial_ad_uid, server_side_verification)
		
		# Показ рекламы (метод принимает только UID)
		rewarded_interstitial_ad_plugin.show(rewarded_interstitial_ad_uid)
	else:
		print("Rewarded Interstitial Ad not ready to show")
		# Если реклама не готова, сразу сигнализируем о завершении
		ad_state_changed.emit(true)

# Обработчики сигналов
func _on_rewarded_interstitial_ad_loaded(uid):
	if uid == rewarded_interstitial_ad_uid:
		print("Rewarded Interstitial Ad loaded successfully")
		is_ad_loaded = true
		
		# Показываем рекламу сразу после загрузки
		# Небольшая задержка для уверенности, что всё инициализировано
		await get_tree().create_timer(0.5).timeout
		show_rewarded_interstitial_ad()

func _on_rewarded_interstitial_ad_failed_to_load(uid, error_data):
	if uid == rewarded_interstitial_ad_uid:
		print("Failed to load Rewarded Interstitial Ad: ", error_data)
		is_ad_loaded = false
		
		# Сигнализируем о завершении из-за ошибки
		ad_state_changed.emit(true)
		
		# Пробуем загрузить снова с тем же ID (можно использовать другой тестовый ID при необходимости)
		rewarded_interstitial_ad_uid = rewarded_interstitial_ad_plugin.create()
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
		var ad_unit_id = "ca-app-pub-3940256099942544/5354046379" # Тестовый ID для Rewarded Interstitial Ad
		
		# Сигнализируем о начале новой загрузки
		ad_state_changed.emit(false)
		
		rewarded_interstitial_ad_plugin.load(ad_unit_id, ad_request, [], rewarded_interstitial_ad_uid)

func _on_rewarded_interstitial_ad_showed_full_screen_content(uid):
	if uid == rewarded_interstitial_ad_uid:
		print("Rewarded Interstitial Ad showed")

func _on_rewarded_interstitial_ad_failed_to_show_full_screen_content(uid, error_data):
	if uid == rewarded_interstitial_ad_uid:
		print("Failed to show Rewarded Interstitial Ad: ", error_data)
		is_ad_loaded = false
		
		# Сигнализируем о завершении из-за ошибки показа
		ad_state_changed.emit(true)

func _on_rewarded_interstitial_ad_clicked(uid):
	if uid == rewarded_interstitial_ad_uid:
		print("Rewarded Interstitial Ad clicked")

func _on_rewarded_interstitial_ad_dismissed_full_screen_content(uid):
	if uid == rewarded_interstitial_ad_uid:
		print("Rewarded Interstitial Ad dismissed")
		is_ad_loaded = false
		
		# Сигнализируем о завершении просмотра рекламы
		ad_state_changed.emit(true)
		
		# Освобождаем ресурсы рекламы
		if rewarded_interstitial_ad_plugin:
			rewarded_interstitial_ad_plugin.destroy(rewarded_interstitial_ad_uid)
			rewarded_interstitial_ad_uid = -1
			print("Rewarded Interstitial Ad resources released")

func _on_rewarded_interstitial_ad_impression(uid):
	if uid == rewarded_interstitial_ad_uid:
		print("Rewarded Interstitial Ad impression recorded")

func _on_rewarded_interstitial_ad_user_earned_reward(uid, reward_data):
	if uid == rewarded_interstitial_ad_uid:
		print("User earned reward: ", reward_data)
		# Извлекаем информацию о награде
		var amount = reward_data["amount"] if "amount" in reward_data else 0
		var type = reward_data["type"] if "type" in reward_data else ""
		
		# Эмитируем сигнал о полученной награде
		reward_earned.emit(amount, type)
		print("Reward earned: ", amount, " ", type)
