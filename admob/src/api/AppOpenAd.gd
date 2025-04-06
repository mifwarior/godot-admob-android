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

class_name AppOpenAd
extends MobileSingletonPlugin

# Константы для ориентации App Open Ad
enum Orientation {
	PORTRAIT = 1,
	LANDSCAPE = 2
}

static var _plugin := _get_plugin("PoingGodotAdMobAppOpenAd")

var full_screen_content_callback := FullScreenContentCallback.new()
var _uid : int

# Сигналы для App Open Ad
signal on_app_open_ad_loaded
signal on_app_open_ad_failed_to_load(error_data)
signal on_app_open_ad_clicked
signal on_app_open_ad_dismissed
signal on_app_open_ad_failed_to_show(error_data)
signal on_app_open_ad_impression
signal on_app_open_ad_showed

func _init(uid : int) -> void:
	_uid = uid
	
	if _plugin:
		# Подключение сигналов от нативного плагина
		_plugin.connect("on_app_open_ad_loaded", _on_app_open_ad_loaded)
		_plugin.connect("on_app_open_ad_failed_to_load", _on_app_open_ad_failed_to_load)
		_plugin.connect("on_app_open_ad_clicked", _on_app_open_ad_clicked)
		_plugin.connect("on_app_open_ad_dismissed_full_screen_content", _on_app_open_ad_dismissed)
		_plugin.connect("on_app_open_ad_failed_to_show_full_screen_content", _on_app_open_ad_failed_to_show)
		_plugin.connect("on_app_open_ad_impression", _on_app_open_ad_impression)
		_plugin.connect("on_app_open_ad_showed_full_screen_content", _on_app_open_ad_showed)

# Загрузка App Open Ad
func load(ad_unit_id : String = "", ad_request : AdRequest = null, orientation : Orientation = Orientation.PORTRAIT) -> void:
	if _plugin:
		if ad_unit_id != "":
			var ad_request_dictionary := ad_request.to_dictionary() if ad_request else {}
			var keywords := ad_request.keywords if ad_request else []
			
			_plugin.load(ad_unit_id, ad_request_dictionary, keywords, _uid, orientation)
		else:
			# Если ad_unit_id не указан, используем ранее сохраненный
			_plugin.load("", {}, [], _uid, orientation)

# Показ App Open Ad
func show() -> void:
	if _plugin:
		_plugin.show(_uid)

# Проверка, загружена ли реклама
func is_loaded() -> bool:
	if _plugin:
		return _plugin.is_loaded(_uid)
	return false

# Уничтожение экземпляра App Open Ad
func destroy() -> void:
	if _plugin:
		_plugin.destroy(_uid)

# Обработчики сигналов от нативного плагина
func _on_app_open_ad_loaded(uid : int) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_loaded")
		full_screen_content_callback.emit_signal("on_ad_loaded")

func _on_app_open_ad_failed_to_load(uid : int, error_data) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_failed_to_load", error_data)
		
		var ad_error := AdError.new()
		ad_error.code = error_data.code
		ad_error.message = error_data.message
		ad_error.domain = error_data.domain
		
		var load_ad_error := LoadAdError.new()
		load_ad_error.code = ad_error.code
		load_ad_error.message = ad_error.message
		load_ad_error.domain = ad_error.domain
		load_ad_error.response_info = ResponseInfo.new()
		
		full_screen_content_callback.emit_signal("on_ad_failed_to_load", load_ad_error)

func _on_app_open_ad_clicked(uid : int) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_clicked")
		full_screen_content_callback.emit_signal("on_ad_clicked")

func _on_app_open_ad_dismissed(uid : int) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_dismissed")
		full_screen_content_callback.emit_signal("on_ad_dismissed_full_screen_content")

func _on_app_open_ad_failed_to_show(uid : int, error_data) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_failed_to_show", error_data)
		
		var ad_error := AdError.new()
		ad_error.code = error_data.code
		ad_error.message = error_data.message
		ad_error.domain = error_data.domain
		
		full_screen_content_callback.emit_signal("on_ad_failed_to_show_full_screen_content", ad_error)

func _on_app_open_ad_impression(uid : int) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_impression")
		full_screen_content_callback.emit_signal("on_ad_impression")

func _on_app_open_ad_showed(uid : int) -> void:
	if uid == _uid:
		emit_signal("on_app_open_ad_showed")
		full_screen_content_callback.emit_signal("on_ad_showed_full_screen_content")
