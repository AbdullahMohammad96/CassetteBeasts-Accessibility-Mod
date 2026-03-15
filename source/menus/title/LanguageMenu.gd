extends SlidingControl

signal chose_option(option)

export (bool) var save_choice: bool = true

onready var buttons = find_node("Buttons")
onready var btn_en = find_node("Btn_en")
onready var btn_eo = find_node("Btn_eo")

func _ready():
	if not Debug.dev_mode:
		buttons.remove_child(btn_eo)
		btn_eo.queue_free()
	
	buttons.setup_focus()
	if Accessibility:
		Accessibility.announce_menu(Loc.tr("TITLE_SCREEN_LANGUAGE_BUTTON"))
		for btn in buttons.get_children():
			if btn.has_signal("focus_entered"):
				btn.connect("focus_entered", self, "_on_language_button_focused", [btn])
	
	var locale = UserSettings.locale
	var current_btn = find_node("Btn_" + locale)
	if current_btn:
		buttons.initial_focus = buttons.get_path_to(current_btn)
	
	if SceneManager.current_scene == self:
		Controls.set_disabled(self, false)
		set_scaled_offset(visible_offset)
		visible = true
		grab_focus()

func _input(event):
	if SceneManager.transitioning:
		return
	if event.is_action_pressed("ui_cancel"):
		cancel()
		get_tree().set_input_as_handled()

func _on_language_button_focused(btn) -> void:
	# Accessibility: Announce language button name
	if Accessibility:
		Accessibility.speak(btn.text, true)

func choose_option(option):
	emit_signal("chose_option", option)
	if SceneManager.current_scene == self:
		SceneManager.change_scene(SceneManager.TITLE_SCENE)
	else:
		hide()

func cancel():
	choose_option(null)

func choose_locale(locale: String):
	if save_choice:
		UserSettings.locale = locale
		UserSettings.apply_settings()
		UserSettings.save_settings()
	else:
		TranslationServer.set_locale(locale)
		UserSettings.emit_signal("locale_changed")
	choose_option(locale)
