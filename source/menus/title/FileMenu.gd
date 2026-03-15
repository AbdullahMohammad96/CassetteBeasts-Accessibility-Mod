extends SlidingControl

const FileButton = preload("FileButton.gd")
const DefaultFileThumbnail = preload("default_file_thumbnail.png")

onready var mp_title_panel = find_node("MPTitlePanel")
onready var scroll_interior = find_node("ScrollInterior")
onready var file_button_container = find_node("FileButtonContainer")
onready var test_world_button = find_node("TestWorldButton")
onready var custom_battle_button = find_node("CustomBattleButton")
onready var file_thumbnail = find_node("FileThumbnail")
onready var static_material = find_node("Static").material
onready var save_data_container = find_node("SaveDataContainer")
onready var play_button = find_node("PlayButton")
onready var erase_button = find_node("EraseButton")
onready var custom_button = find_node("CustomButton")
onready var player_sprite = find_node("PlayerSprite")
onready var player_sprite_container = player_sprite.get_parent()
onready var back_button = find_node("BackButton")

var current_button: FileButton = null
var thumbnail_tween: Tween
var file_buttons: Array

func _ready():
	for child in file_button_container.get_children():
		if child is FileButton:
			file_buttons.push_back(child)
	
	thumbnail_tween = Tween.new()
	add_child(thumbnail_tween)
	
	if not Debug.dev_mode:
		file_button_container.remove_child(test_world_button)
		test_world_button.queue_free()
		test_world_button = null
		file_button_container.remove_child(custom_battle_button)
		custom_battle_button.queue_free()
		custom_battle_button = null
	
	file_button_container.setup_focus()
	
	for file_button in file_buttons:
		file_button.connect("focus_entered", self, "_on_file_focused", [file_button])
	
	if Net.has_pending_invite():
		mp_title_panel.visible = true
		scroll_interior.get_stylebox("panel").content_margin_top = 0
		back_button.text = "UI_BUTTON_CANCEL"
	else:
		mp_title_panel.visible = false
		scroll_interior.get_stylebox("panel").content_margin_top = 97
		back_button.text = "UI_BUTTON_BACK"
	
	_on_file_focused(file_buttons[0])
	
	if SceneManager.current_scene == self:
		show()
	
	if Accessibility:
		call_deferred("_announce_file_menu_open")

func _announce_file_menu_open() -> void:
	# Accessibility: No menu announcement here — the first FileButton focus_entered
	# already announces the save slot, so announcing the menu name on top would
	# interrupt it. Connecting button signals is still needed.
	play_button.connect("focus_entered", self, "_on_play_button_focused")
	erase_button.connect("focus_entered", self, "_on_erase_button_focused")
	back_button.connect("focus_entered", self, "_on_back_button_focused")

func _on_play_button_focused() -> void:
	if Accessibility:
		Accessibility.speak(Loc.tr(play_button.text), true)

func _on_erase_button_focused() -> void:
	if Accessibility:
		Accessibility.speak(Loc.tr("UI_LOAD_FILE_ERASE"), true)

func _on_back_button_focused() -> void:
	if Accessibility:
		Accessibility.speak(Loc.tr("UI_BUTTON_BACK"), true)

func cancel():
	if Net.has_pending_invite():
		Net.cancel_pending_invite()
	return .cancel()

func grab_focus():
	file_button_container.grab_focus()

func _on_file_focused(file_button):
	save_data_container.visible = true
	
	if current_button and current_button != file_button:
		current_button.disconnect("state_changed", self, "refresh_file_data")
	
	if current_button != file_button:
		current_button = file_button
		current_button.connect("state_changed", self, "refresh_file_data")
	
	refresh_file_data()

func refresh_file_data():
	save_data_container.current_button = current_button
	
	play_button.visible = current_button.can_be_played()
	erase_button.visible = false
	custom_button.visible = false
	
	if current_button.state == FileButton.State.LOADED:
		tween_thumbnail_static(0.0)
		file_thumbnail.texture = DefaultFileThumbnail
		player_sprite.idle = "defeated" if current_button.game_over else "tapeless_idle"
		player_sprite_container.visible = true
		player_sprite.part_names = current_button.player_part_names.duplicate()
		player_sprite.colors = current_button.player_colors.duplicate()
		player_sprite.refresh()
		
		play_button.set_text("UI_LOAD_FILE_CONTINUE_GAME")
		erase_button.visible = true
		custom_button.visible = UserSettings.enable_custom_modes and not Platform.is_demo()
		
	elif current_button.state == FileButton.State.EMPTY:
		tween_thumbnail_static(1.0)
		play_button.set_text("UI_LOAD_FILE_NEW_GAME")
		custom_button.visible = UserSettings.enable_custom_modes and not Platform.is_demo()
		
	else:
		
		tween_thumbnail_static(1.0)
		erase_button.visible = true

func tween_thumbnail_static(amount: float):
	thumbnail_tween.stop_all()
	thumbnail_tween.remove_all()
	thumbnail_tween.interpolate_property(static_material, "shader_param/amount", null, amount, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	thumbnail_tween.start()

func _on_TestWorldButton_pressed():
	SceneManager.set_in_game(true)
	SaveSystem.clear_state_dev()
	SceneManager.change_scene("res://world/maps/Overworld.tscn")

func _on_CustomBattleButton_pressed():
	SceneManager.change_scene("res://tools/custom_battle/CustomBattle.tscn")

func _on_TestWorldButton_focus_entered():
	current_button = null
	save_data_container.current_button = current_button
	play_button.visible = false
	erase_button.visible = false
	custom_button.visible = false

func _on_CustomBattleButton_focus_entered():
	current_button = null
	save_data_container.current_button = current_button
	play_button.visible = false
	erase_button.visible = false
	custom_button.visible = false

func _on_PlayButton_pressed():
	if current_button and current_button.can_be_played():
		current_button.load_file()

func _on_EraseButton_pressed():
	assert (current_button != null)
	var file = current_button
	if file:
		if yield(MenuHelper.confirm("UI_SAVE_ERASE_CONFIRM", 1, 1), "completed") and not SaveSystem.busy and not SceneManager.transitioning:
			file.erase()
		file.grab_focus()

func _on_CustomButton_pressed():
	var file_button = current_button
	assert (file_button != null)
	
	if SaveSystem.busy or SceneManager.transitioning:
		return
	
	Controls.set_disabled(self, true)
	
	if file_button.state == FileButton.State.LOADED:
		if not yield(MenuHelper.confirm("UI_SAVE_ERASE_CONFIRM", 1, 1), "completed"):
			Controls.set_disabled(self, false)
			file_button.grab_focus()
			return
	
	if not SaveSystem.busy and not SceneManager.transitioning:
		var menu = preload("GameModeMenu.tscn").instance()
		MenuHelper.add_child(menu)
		var result: GameMode = yield(menu.run_menu(), "completed")
		MenuHelper.remove_child(menu)
		menu.queue_free()
		
		if result and not SaveSystem.busy and not SceneManager.transitioning:
			file_button.load_new_state(result)
			return
		
	Controls.set_disabled(self, false)
	file_button.grab_focus()

func _on_FileButton_load_file():
	Controls.set_disabled(self, true)

func _on_FileButton_load_file_failed():
	Controls.set_disabled(self, false)
