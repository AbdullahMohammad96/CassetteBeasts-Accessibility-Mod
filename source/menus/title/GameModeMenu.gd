extends "res://menus/BaseMenu.gd"

onready var input_container = find_node("InputContainer")
onready var hint_label = find_node("HintLabel")

onready var permadeath_tapes_input = find_node("PermadeathTapesInput")
onready var permadeath_defeat_input = find_node("PermadeathDefeatInput")
onready var randomize_monsters_input = find_node("RandomizeMonstersInput")
onready var randomize_types_input = find_node("RandomizeTypesInput")
onready var randomize_stickers_input = find_node("RandomizeStickersInput")
onready var random_seed_input = find_node("RandomSeedInput")

func _ready():
	if Accessibility:
		Accessibility.announce_menu(Loc.tr("UI_NEW_GAME_MODES_TITLE"))
	for control in input_container.get_children():
		control.connect("focus_entered", self, "_on_input_focus_entered", [control])
		control.connect("focus_exited", self, "_on_input_focus_exited", [control])
		if control.hint_tooltip != "":
			control.hint_tooltip = Loc.tr(control.hint_tooltip)
		if Net.is_enabled() and ((control.name.begins_with("Randomize") and Net.DISABLE_NET_IN_RAND_MODE) or control.name == "RandomizeTypesInput"):
			
			if control.hint_tooltip != "":
				control.hint_tooltip += "\n"
			control.hint_tooltip += Loc.tr("UI_NEW_GAME_MODES_RANDOMISE_MULTIPLAYER_HINT")
	
	random_seed_input.text = str(randi())

func grab_focus():
	.grab_focus()
	input_container.grab_focus()

func _on_input_focus_entered(control):
	if control.hint_tooltip != "":
		hint_label.text = control.hint_tooltip
	# Accessibility: Announce input label and current value
	if Accessibility:
		Accessibility.announce_focus(control)

func _on_input_focus_exited(control):
	if hint_label.text == control.hint_tooltip:
		hint_label.text = ""

func get_random_seed() -> int:
	if random_seed_input.text.is_valid_integer():
		var int_value = int(random_seed_input.text)
		if int_value >= 0 and int_value <= 4294967295:
			return int_value
	return random_seed_input.text.hash()

func get_game_mode() -> GameMode:
	var result = GameMode.new()
	result.permadeath_tapes = permadeath_tapes_input.selected_value == true
	result.permadeath_defeat = permadeath_defeat_input.selected_value == true
	result.randomize_monsters = randomize_monsters_input.selected_value == true
	result.randomize_types = randomize_types_input.selected_value == true
	result.randomize_stickers = randomize_stickers_input.selected_value == true
	result.random_seed = get_random_seed()
	return result

func _on_CancelButton_pressed():
	cancel()

func _on_StartButton_pressed():
	choose_option(get_game_mode())
