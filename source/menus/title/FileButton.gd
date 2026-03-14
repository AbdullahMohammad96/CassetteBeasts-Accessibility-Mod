extends HighlightOnFocus

signal state_changed
signal load_file
signal load_file_failed

enum State{LOADING, LOADED, EMPTY, CORRUPT}

const TEX_FILE_NORMAL = preload("res://ui/party/tape.png")
const TEX_FILE_CUSTOM = preload("res://ui/party/tape_bootleg.png")

export (String) var file_path: String = "user://file1.json"

onready var player_name_label = find_node("PlayerNameLabel")
onready var player_level_label = find_node("PlayerLevelLabel")
onready var game_over_sticker = find_node("GameOverSticker")

var state = State.LOADING
var player_name: String = ""
var player_level: int = 0
var player_colors: Dictionary
var player_part_names: Dictionary
var location_name: String = ""
var play_time: int = 0
var saved_datetime: int = 0
var game_over: bool = false
var version_dlc: Dictionary

var data_promise: Promise

func _ready():
	refresh()
	connect("focus_entered", self, "_on_focus_entered_tts")

func _on_focus_entered_tts() -> void:
	if not Accessibility:
		return
	var slot_name = file_path.get_file().get_basename().replace("file", "Save slot ")
	match state:
		State.LOADING:
			Accessibility.speak(slot_name + ", loading", true)
		State.EMPTY:
			Accessibility.speak(slot_name + ", empty. Press Enter to start new game.", true)
		State.CORRUPT:
			Accessibility.speak(slot_name + ", corrupt save data", true)
		State.LOADED:
			var text = slot_name
			if player_name != "":
				text += ", " + player_name
			if player_level > 0:
				text += ", level " + str(player_level)
			if location_name != "":
				text += ", " + location_name
			if game_over:
				text += ", game over"
			Accessibility.speak(text, true)

func refresh():
	set_state(State.LOADING, null)
	
	data_promise = SaveSystem.storage.read_async(file_path)
	data_promise.connect("fulfilled", self, "_on_data_loaded", [], CONNECT_ONESHOT)

func _on_data_loaded(result):
	if is_queued_for_deletion() or not is_inside_tree():
		return
	
	if result.error == ERR_FILE_NOT_FOUND:
		set_state(State.EMPTY, null)
	elif result.error == OK and result.versions.size() > 0:
		set_state(State.LOADED, result.versions[0])
	else:
		set_state(State.CORRUPT, null)

func set_state(state: int, data):
	self.state = state
	
	player_name_label.text = ""
	player_level_label.text = ""
	player_name = ""
	player_level = 0
	location_name = ""
	play_time = 0
	saved_datetime = 0
	game_over = false
	game_over_sticker.visible = false
	version_dlc.clear()
	
	var self0 = self
	var button = self0 as TextureButton
	button.texture_normal = TEX_FILE_NORMAL
	
	if state == State.LOADED and data:
		if _check_path(data, ["party", "player", "custom", "name"]):
			player_name = str(data.party.player.custom.name)
			player_name_label.text = player_name
		if _check_path(data, ["party", "player", "custom", "human_part_names"]):
			player_part_names = data.party.player.custom.human_part_names.duplicate()
		if _check_path(data, ["party", "player", "custom", "human_colors"]):
			player_colors = data.party.player.custom.human_colors.duplicate()
		if _check_path(data, ["party", "player", "level"]):
			player_level = int(data.party.player.level)
			player_level_label.text = Loc.trf("UI_CHARACTER_LEVEL", ["%02d" % player_level])
		
		location_name = str(data.get("location_name", ""))
		play_time = int(data.get("play_time", 0))
		saved_datetime = int(data.get("saved_datetime", 0))
		
		if data.get("game_mode") != null:
			button.texture_normal = TEX_FILE_CUSTOM
		
		game_over = data.get("game_over", false) == true
		game_over_sticker.visible = game_over
		
		version_dlc = data.get("version_dlc", {}).duplicate()
		
	elif state == State.LOADING:
		player_name_label.text = "UI_LOAD_FILE_LOADING"
	elif state == State.EMPTY:
		player_name_label.text = "UI_LOAD_FILE_EMPTY"
	else:
		player_name_label.text = "UI_LOAD_FILE_INVALID"
	
	emit_signal("state_changed")

func _check_path(json: Dictionary, path: Array) -> bool:
	for i in range(path.size()):
		var elem = path[i]
		if not json.has(elem):
			return false
		if i == path.size() - 1:
			return true
		if not (json[elem] is Dictionary):
			return false
		json = json[elem]
	return true

func can_be_played() -> bool:
	return (state == State.LOADED or state == State.EMPTY) and not game_over and not get("disabled") and not SaveSystem.busy and not SceneManager.transitioning

func _pressed():
	if can_be_played():
		load_file()

func _contains_save_tags(file_tags: Dictionary, current_tags: Dictionary):
	for tag in current_tags.keys():
		if not file_tags.has(tag):
			return false
	return true

func load_file():
	release_focus()
	
	if not _contains_save_tags(version_dlc, DLC.save_file_format_tags):
		GlobalMessageDialog.clear_state()
		yield(GlobalMessageDialog.show_message("CONFIRM_LOAD_SAVE_WITH_NEW_MODS1", false), "completed")
		if Net.is_enabled():
			yield(GlobalMessageDialog.show_message("CONFIRM_LOAD_SAVE_WITH_NEW_MODS_MP", false), "completed")
		if not yield(MenuHelper.confirm("CONFIRM_LOAD_SAVE_WITH_NEW_MODS2", 1, 1), "completed"):
			grab_focus()
			return
	
	emit_signal("load_file")
	var result = SaveSystem.load_file(file_path)
	if result is GDScriptFunctionState:
		result = yield(Co.safe_yield(self, result), "completed")
	if not result:
		emit_signal("load_file_failed")
		grab_focus()

func load_new_state(game_mode = null):
	release_focus()
	emit_signal("load_file")
	var result = SaveSystem.load_new_state(file_path, game_mode)
	if result is GDScriptFunctionState:
		result = yield(Co.safe_yield(self, result), "completed")
	if not result:
		emit_signal("load_file_failed")
		grab_focus()

func erase():
	set_state(State.LOADING, null)
	yield(SaveSystem.erase_file(file_path), "completed")
	refresh()
