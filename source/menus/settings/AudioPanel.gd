extends PanelContainer

onready var inputs = find_node("Inputs")
onready var vocals_input = find_node("VocalsInput")
onready var transform_input = find_node("TransformInput")

var volume_sliders: Dictionary

func _ready():
	var i = 0
	for bus_name in UserSettings.audio_volume.keys():
		var label = Label.new()
		label.text = "UI_SETTINGS_AUDIO_VOLUME_" + bus_name
		label.add_color_override("font_color", Color.black)
		label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
		inputs.add_child(label)
		inputs.move_child(label, i)
		i += 1
		
		var slider = preload("res://nodes/menus/ArrowSlider_Percent.tscn").instance()
		slider.step = 0.05
		slider.rect_min_size.x = 450
		slider.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
		inputs.add_child(slider)
		inputs.move_child(slider, i)
		i += 1
		slider.connect("value_changed", self, "_slider_volume_changed", [bus_name])
		volume_sliders[bus_name] = slider
	
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

func _on_input_value_changed(_value, control) -> void:
	if Accessibility:
		Accessibility.announce_setting_changed(control)

func get_current_volume(bus_name: String) -> float:
	var volume = UserSettings.audio_volume[bus_name]
	if bus_name == "Music" and MusicSystem.user_mute:
		volume = 0.0
	return volume

func set_current_volume(bus_name: String, value: float):
	value = clamp(value, 0.0, 1.0)
	UserSettings.audio_volume[bus_name] = value
	if bus_name == "Music" and MusicSystem.user_mute and value > 0.0:
		MusicSystem.user_mute = false

func is_dirty() -> bool:
	for bus_name in volume_sliders.keys():
		var diff = volume_sliders[bus_name].selected_value - get_current_volume(bus_name)
		if abs(diff) >= volume_sliders[bus_name].step:
			return true
	if vocals_input.selected_value != UserSettings.audio_vocals:
		return true
	if transform_input.selected_value != UserSettings.audio_transform:
		return true
	return false

func apply():
	for bus_name in volume_sliders.keys():
		var diff = volume_sliders[bus_name].selected_value - get_current_volume(bus_name)
		if abs(diff) > abs(volume_sliders[bus_name].step) * 0.99:
			set_current_volume(bus_name, volume_sliders[bus_name].selected_value)
	
	UserSettings.audio_vocals = vocals_input.selected_value
	UserSettings.audio_transform = transform_input.selected_value

func reset():
	for bus_name in volume_sliders.keys():
		volume_sliders[bus_name].selected_value = get_current_volume(bus_name)
	
	vocals_input.selected_value = UserSettings.audio_vocals
	transform_input.selected_value = UserSettings.audio_transform
	
	inputs.setup_focus()

func grab_focus():
	inputs.grab_focus()

func _slider_volume_changed(value: float, bus_name: String):
	value = clamp(value, 0.0, 1.0)
	var i = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(i, linear2db(value * UserSettings.MAX_AUDIO_VOLUME.get(bus_name, 1.0)))
	if bus_name == "Music" and MusicSystem.user_mute and value > 0.0:
		MusicSystem.user_mute = false

func cancel():
	UserSettings.apply_audio_volume()
