extends "res://menus/BaseMenu.gd"

const ArrowOptionList = preload("res://nodes/menus/ArrowOptionList.gd")

const ARTIFICIAL_COLORS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
const SKIN_COLORS = [19, 20, 21, 22, 23]
const DIRECTIONS = ["down", "right", "up", "left"]

const COLOR_VALUES = {
	"skin_color": SKIN_COLORS, 
	"hair_color": ARTIFICIAL_COLORS, 
	"eye_color": ARTIFICIAL_COLORS, 
	"favorite_color": ARTIFICIAL_COLORS, 
	"body_color_1": ARTIFICIAL_COLORS, 
	"body_color_2": ARTIFICIAL_COLORS, 
	"face_accessory_color": ARTIFICIAL_COLORS, 
	"hair_accessory_color": ARTIFICIAL_COLORS, 
	"legs_color": ARTIFICIAL_COLORS, 
	"shoe_color": ARTIFICIAL_COLORS
}

const DLC_PARTS = {
	cosplay = {
		hair = ["bansheep", "candevil", "springheel", "traffikrab"], 
		body = ["pombomb"], 
		legs = ["pombomb"]
	}, 
	pier = {
		hair = ["clown_1", "clown_2", "clown_3", "clown_4"], 
		head = ["clown"]
	}, 
	fashion = {
		hair = ["cap1", "cap2", "twintails", "bow2", "fox1", "windswept", "goggles1", "mohawk1", "flower2", "beret1"], 
		head = ["glasses2"], 
		body = ["jacket5", "vest2"], 
		legs = ["boots1"]
	}, 
	wings = {
		wings = ["jetpack1", "jetpack2", "booster", "davinci", "fairy", "devil", "glider", "cape"]
	}
}

const PART_NAMES = ["hair", "head", "body", "legs", "wings"]

const UNLOCKABLE_PARTS = [
	{
		stat = "encounters", 
		stat_key = "gauntlet_00_magikrab", 
		threshold = 1, 
		hair = ["magikrab"]
	}, 
	{
		stat = "registered_species", 
		stat_key = "sirenade", 
		threshold = 1, 
		wings = ["sirenade"]
	}, 
	{
		stat = "registered_species", 
		stat_key = "kuneko", 
		threshold = 1, 
		wings = ["kuneko"]
	}, 
	{
		stat = "registered_species", 
		stat_key = "rockertrice", 
		threshold = 1, 
		wings = ["rockertrice"]
	}, 
	{
		stat = "registered_species", 
		stat_key = "averevoir", 
		threshold = 1, 
		wings = ["averevoir"]
	}, 
	{
		stat = "registered_species", 
		stat_key = "umbrahella", 
		threshold = 1, 
		wings = ["umbrahella"]
	}, 
]

export (Array, String) var hidden_options: Array = []
export (Array, String) var extra_hair_values: Array = []
export (Array, String) var extra_head_values: Array = []
export (Array, String) var extra_body_values: Array = []
export (Array, String) var extra_legs_values: Array = []
export (Array, String) var extra_wings_values: Array = []
export (bool) var initial_randomize: bool = false
export (Color) var dlc_part_color: Color
export (Color) var unlockable_part_color: Color

onready var input_container = find_node("InputContainer")
onready var player_name_edit = find_node("Field_name")
onready var player_pronouns_edit = find_node("Field_pronouns")
onready var world_human_sprite = find_node("WorldHumanSprite")
onready var battle_human_sprite = find_node("BattleHumanSprite")
onready var buttons = find_node("Buttons")
onready var cancel_button = find_node("CancelButton")
onready var randomize_button = find_node("RandomizeButton")

var character: Character = null
var t: float = 0.0

func _ready():
	if character == null:
		character = SaveState.party.player
	
	if character.name == "DEFAULT_PLAYER_NAME":
		character.name = tr(character.name)
	player_name_edit.text = character.name
	
	player_name_edit.max_width = Character.MAX_NAME_WIDTH
	
	player_pronouns_edit.set_selected_value(int(character.pronouns))
	
	var values = {
		hair = [], 
		head = [], 
		body = [], 
		legs = [], 
		wings = []
	}
	var sets = {
		hair = {}, 
		head = {}, 
		body = {}, 
		legs = {}, 
		wings = {}
	}
	var font_color_overrides = {
		hair = {}, 
		head = {}, 
		body = {}, 
		legs = {}, 
		wings = {}
	}
	
	for template in HumanLayersHelper.human_templates:
		_append_unique(values.hair, sets.hair, template.hair_parts)
		_append_unique(values.head, sets.head, template.head_parts)
		_append_unique(values.body, sets.body, template.body_parts)
		_append_unique(values.legs, sets.legs, template.leg_parts)
		_append_unique(values.wings, sets.wings, template.wing_parts)
	
	_append_unique(values.hair, sets.hair, extra_hair_values)
	_append_unique(values.head, sets.head, extra_head_values)
	_append_unique(values.body, sets.body, extra_body_values)
	_append_unique(values.legs, sets.legs, extra_legs_values)
	_append_unique(values.wings, sets.wings, extra_wings_values)
	
	for unlockable in UNLOCKABLE_PARTS:
		if SaveState.stats.get_count(unlockable.stat, unlockable.get("stat_key")) >= unlockable.threshold:
			for key in PART_NAMES:
				if unlockable.has(key):
					_append_unique(values[key], sets[key], unlockable[key], font_color_overrides[key], false, true)
	
	for dlc_id in DLC_PARTS.keys():
		if not Platform.has_dlc(dlc_id) and not DLC.has_dlc(dlc_id):
			continue
		for key in DLC_PARTS[dlc_id].keys():
			_append_unique(values[key], sets[key], DLC_PARTS[dlc_id][key], font_color_overrides[key], true)
	
	for key in COLOR_VALUES.keys():
		setup_option_list_field(key, COLOR_VALUES[key], get_color_code(key), {})
		connect_color_list_field(key)
	setup_option_list_field("hair", values.hair, character.human_part_names.get("hair"), font_color_overrides.hair)
	setup_option_list_field("head", values.head, character.human_part_names.get("head"), font_color_overrides.head)
	setup_option_list_field("body", values.body, character.human_part_names.get("body"), font_color_overrides.body)
	setup_option_list_field("legs", values.legs, character.human_part_names.get("legs"), font_color_overrides.legs)
	setup_option_list_field("wings", values.wings, character.human_part_names.get("wings"), font_color_overrides.wings)
	connect_part_list_field("hair")
	connect_part_list_field("head")
	connect_part_list_field("body")
	connect_part_list_field("legs")
	connect_part_list_field("wings")
	
	if not SaveState.has_ability("glide"):
		var node = find_node("Field_wings")
		if node != null:
			_hide_option(node)
	
	for option in hidden_options:
		var node = find_node("Field_" + option)
		if node == null:
			continue
		_hide_option(node)
	input_container.setup_focus()
	
	if Accessibility:
		call_deferred("_connect_accessibility_signals")
	
	world_human_sprite.idle = "run"
	
	if not cancelable:
		cancel_button.visible = false
	
	if initial_randomize:
		_on_RandomizeButton_pressed()
	
	if AutoSplit.pause_for_character_creation:
		SaveState.timer_paused = true

func _exit_tree():
	if AutoSplit.pause_for_character_creation:
		SaveState.timer_paused = false

func _append_unique(dest: Array, dict: Dictionary, src: Array, font_color_overrides = null, dlc = false, unlockable = false):
	for value in src:
		if not dict.has(value):
			dict[value] = true
			dest.push_back(value)
			if font_color_overrides != null:
				if dlc:
					font_color_overrides[value] = dlc_part_color
				elif unlockable:
					font_color_overrides[value] = unlockable_part_color

func get_color_code(key: String) -> int:
	var color = character.human_colors.get(key, - 1)
	if color == - 1:
		return world_human_sprite.variable_ramps[key]
	return color

func setup_option_list_field(key: String, values: Array, initial_value, font_color_overrides: Dictionary):
	var node = find_node("Field_" + key)
	if node != null:
		node.values = values
		
		var labels = []
		for i in range(values.size()):
			var label_key = "UI_CC_VALUE_" + key + "_" + str(values[i])
			if Loc.key_exists(label_key):
				labels.push_back(tr(label_key))
			else:
				labels.push_back("%02d" % (i + 1))
		
		node.value_labels = labels
		node.value_font_color_overrides = font_color_overrides
		node.selected_value = initial_value
		
		node.adjust_min_size()

func connect_color_list_field(key: String):
	var field = find_node("Field_" + key)
	if field == null:
		return
	field.connect("value_changed", self, "_on_color_changed", [key])
	_on_color_changed(field.selected_value, field.selected_index, key)

func connect_part_list_field(key: String):
	var field = find_node("Field_" + key)
	if field == null:
		return
	field.connect("value_changed", self, "_on_part_changed", [key])
	_on_part_changed(field.selected_value, field.selected_index, key)

func _on_color_changed(value, _index: int, key: String):
	if not (value is int):
		return
	world_human_sprite.colors[key] = value
	world_human_sprite.refresh()
	battle_human_sprite.colors[key] = value
	battle_human_sprite.refresh()

func _on_part_changed(value, _index: int, key: String):
	if not (value is String):
		return
	world_human_sprite.part_names[key] = value
	if key == "body":
		world_human_sprite.part_names["arms"] = value
	world_human_sprite.refresh()
	battle_human_sprite.part_names[key] = value
	if key == "body":
		battle_human_sprite.part_names["arms"] = value
	battle_human_sprite.refresh()

func _hide_option(cell: Control):
	assert (cell.get_parent() == input_container)
	if cell.get_parent() != input_container:
		return
	
	var row = cell.get_index() / input_container.columns
	for _i in range(input_container.columns):
		var index = row * input_container.columns
		if index < input_container.get_child_count():
			var node = input_container.get_child(index)
			input_container.remove_child(node)
			node.queue_free()

func grab_focus():
	input_container.grab_focus()

func _process(delta):
	t += delta
	var rotations = int(t / 2.0) % 4
	world_human_sprite.direction = DIRECTIONS[rotations]

func _on_RandomizeButton_pressed():
	var parts = {}
	var colors = {}
	var template = HumanLayersHelper.randomize_sprite(null, parts, colors)
	find_node("Field_pronouns").set_selected_value(template.pronouns)
	
	for key in parts.keys():
		var node = find_node("Field_" + key)
		if node:
			node.set_selected_value(parts[key])
	for key in colors.keys():
		var node = find_node("Field_" + key)
		if node:
			node.set_selected_value(colors[key])

func _on_CancelButton_pressed():
	cancel()

func _on_SaveButton_pressed():
	if not hidden_options.has("name"):
		if player_name_edit.text == "":
			character.name = tr("DEFAULT_PLAYER_NAME")
		else:
			character.name = player_name_edit.text
	if not hidden_options.has("pronouns"):
		character.pronouns = player_pronouns_edit.selected_value
	character.human_colors = world_human_sprite.colors.duplicate()
	character.human_part_names = world_human_sprite.part_names.duplicate()
	choose_option(true)

func _on_Field_name_focus_entered():
	randomize_button.disabled = true
	# Accessibility: Announce name field
	if Accessibility:
		Accessibility.announce_naming_screen(Loc.tr("UI_CC_LABEL_NAME"), player_name_edit.text)

func _on_Field_name_focus_exited():
	randomize_button.disabled = false

func _on_Field_wings_focus_entered():
	world_human_sprite.idle = "fall"
	world_human_sprite.show_wings()
	# Accessibility: Announce wings field
	if Accessibility:
		Accessibility.announce_focus(find_node("Field_wings"))

func _connect_accessibility_signals() -> void:
	# Accessibility: Announce menu open
	Accessibility.announce_menu(Loc.tr("UI_CHARACTER_CREATION"))
	# ArrowOptionList and ColorArrowOptionList fields already have TTS via
	# on_row_focus_entered() in ArrowOptionList.gd - no extra connections needed
	# Connect focus for bottom buttons only
	var save_btn = find_node("SaveButton")
	var randomize_btn = find_node("RandomizeButton")
	var cancel_btn = find_node("CancelButton")
	if save_btn:
		save_btn.connect("focus_entered", self, "_on_cc_button_focused", [save_btn])
	if randomize_btn:
		randomize_btn.connect("focus_entered", self, "_on_cc_button_focused", [randomize_btn])
	if cancel_btn:
		cancel_btn.connect("focus_entered", self, "_on_cc_button_focused", [cancel_btn])

func _on_cc_button_focused(btn) -> void:
	# Accessibility: Announce button name
	if Accessibility:
		Accessibility.speak(Loc.tr(btn.text), true)

func _on_Field_wings_focus_exited():
	world_human_sprite.idle = "run"
	world_human_sprite.hide_wings()
