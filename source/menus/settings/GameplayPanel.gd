extends PanelContainer

onready var inputs = find_node("Inputs")
onready var autosave_input = find_node("AutosaveInput")
onready var show_timer_input = find_node("ShowTimerInput")
onready var quest_tracker_input = find_node("QuestTrackerInput")
onready var status_effect_tutorials_input = find_node("StatusEffectTutorialsInput")
onready var screen_shake_input = find_node("ScreenShakeInput")
onready var vibration_input = find_node("VibrationInput")
onready var ai_smartness_input = find_node("AISmartnessInput")
onready var level_scaling_input = find_node("LevelScalingInput")
onready var difficulty_description_label = find_node("DifficultyDescriptionLabel")

func _ready():
	reset()
	if Accessibility:
		call_deferred("_connect_input_signals")

func _connect_input_signals() -> void:
	for child in inputs.get_children():
		if child.has_signal("focus_entered"):
			child.connect("focus_entered", self, "_on_input_focused", [child])
		if child.has_signal("value_changed"):
			child.connect("value_changed", self, "_on_input_value_changed", [child])

func _on_input_focused(control) -> void:
	if Accessibility:
		Accessibility.announce_focus(control)
		_announce_difficulty_description(control)

func _on_input_value_changed(_value, control) -> void:
	if Accessibility:
		Accessibility.announce_setting_changed(control)
		_announce_difficulty_description(control)

func _announce_difficulty_description(control) -> void:
	if not Accessibility:
		return
	var text: String = ""
	var smartness = ai_smartness_input.selected_value
	var scaling = level_scaling_input.selected_value
	if control == ai_smartness_input:
		if abs(smartness - 0.5) < 0.01:
			text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_NORMAL")
		elif smartness < 0.5:
			text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_EASY")
		else:
			text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_HARD")
	elif control == level_scaling_input:
		if scaling < 0.0:
			text = tr("UI_SETTINGS_LEVEL_SCALING_INFO_DISABLED")
		elif abs(scaling - 0.5) < 0.01:
			text = tr("UI_SETTINGS_LEVEL_SCALING_INFO_NORMAL")
		elif scaling < 0.5:
			text = tr("UI_SETTINGS_LEVEL_SCALING_INFO_EASY")
		else:
			text = tr("UI_SETTINGS_LEVEL_SCALING_INFO_HARD")
	if not text.empty():
		text = text.replace("- ", "").replace("\n", ". ")
		Accessibility.clear_speech_queue()
		Accessibility.speak(text, false)

func is_dirty() -> bool:
	if not status_effect_tutorials_input:
		return false
	
	if autosave_input.selected_value != UserSettings.autosave:
		return true
	
	if show_timer_input.selected_value != UserSettings.show_timer:
		return true
	
	if quest_tracker_input.selected_value != UserSettings.show_quest_tracker:
		return true
	
	if status_effect_tutorials_input.selected_value != UserSettings.status_effect_tutorial_mode:
		return true
	
	if screen_shake_input.selected_value != UserSettings.enable_screen_shake:
		return true
	
	if vibration_input.selected_value != UserSettings.enable_controller_vibration:
		return true
	
	var diff = level_scaling_input.selected_value - UserSettings.level_scaling
	if abs(diff) >= level_scaling_input.step:
		return true
	
	diff = ai_smartness_input.selected_value - UserSettings.ai_smartness
	if abs(diff) >= ai_smartness_input.step:
		return true
	
	return false

func apply():
	if not status_effect_tutorials_input:
		return
	
	UserSettings.autosave = autosave_input.selected_value
	UserSettings.show_timer = show_timer_input.selected_value
	UserSettings.show_quest_tracker = quest_tracker_input.selected_value
	UserSettings.status_effect_tutorial_mode = status_effect_tutorials_input.selected_value
	UserSettings.enable_screen_shake = screen_shake_input.selected_value
	UserSettings.enable_controller_vibration = vibration_input.selected_value
	UserSettings.level_scaling = level_scaling_input.selected_value
	UserSettings.ai_smartness = ai_smartness_input.selected_value

func reset():
	autosave_input.selected_value = UserSettings.autosave
	show_timer_input.selected_value = UserSettings.show_timer
	quest_tracker_input.selected_value = UserSettings.show_quest_tracker
	status_effect_tutorials_input.selected_value = UserSettings.status_effect_tutorial_mode
	screen_shake_input.selected_value = UserSettings.enable_screen_shake
	vibration_input.selected_value = UserSettings.enable_controller_vibration
	level_scaling_input.selected_value = UserSettings.level_scaling
	ai_smartness_input.selected_value = UserSettings.ai_smartness
	
	inputs.setup_focus()

func grab_focus():
	inputs.grab_focus()

func update_difficulty_description_label(_ignored = null):
	if not difficulty_description_label:
		return
	
	var smartness = ai_smartness_input.selected_value
	var scaling = level_scaling_input.selected_value
	var text: String = ""
	
	if abs(smartness - 0.5) < 0.01:
		text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_NORMAL")
	elif smartness < 0.5:
		text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_EASY")
	else:
		assert (smartness > 0.5)
		text = tr("UI_SETTINGS_AI_SMARTNESS_INFO_HARD")
	
	if scaling < 0.0:
		text += "\n" + tr("UI_SETTINGS_LEVEL_SCALING_INFO_DISABLED")
	elif abs(scaling - 0.5) < 0.01:
		text += "\n" + tr("UI_SETTINGS_LEVEL_SCALING_INFO_NORMAL")
	elif scaling < 0.5:
		text += "\n" + tr("UI_SETTINGS_LEVEL_SCALING_INFO_EASY")
	else:
		assert (scaling > 0.5)
		text += "\n" + tr("UI_SETTINGS_LEVEL_SCALING_INFO_HARD")
	
	difficulty_description_label.text = text
