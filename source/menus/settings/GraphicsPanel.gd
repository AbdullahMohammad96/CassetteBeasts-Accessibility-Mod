extends PanelContainer

onready var inputs = find_node("Inputs")
onready var fullscreen_input = find_node("FullscreenInput")
onready var resolution_label = find_node("ResolutionLabel")
onready var resolution_input = find_node("ResolutionInput")
onready var framerate_input = find_node("FrameRateInput")
onready var preset_input = find_node("PresetInput")
onready var antialiasing_input = find_node("AntialiasingInput")
onready var dof_blur_input = find_node("DofBlurInput")
onready var glow_input = find_node("GlowInput")
onready var shadows_input = find_node("ShadowsInput")
onready var world_streaming_input = find_node("WorldStreamingInput")
onready var glitches_input = find_node("GlitchesInput")
onready var color_blind_input = find_node("ColorBlindInput")

onready var presets = {
	0: {
		antialiasing_input: 0, 
		dof_blur_input: false, 
		glow_input: false, 
		shadows_input: true, 
		world_streaming_input: 0
	}, 
	2: {
		antialiasing_input: 2, 
		dof_blur_input: true, 
		glow_input: true, 
		shadows_input: true, 
		world_streaming_input: 1
	}
}

func _ready():
	assert ( not Platform.is_console())
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

func is_dirty() -> bool:
	if not fullscreen_input:
		return false
	if fullscreen_input.selected_value != UserSettings.graphics_fullscreen:
		return true
	if resolution_input.selected_value != UserSettings.graphics_resolution:
		return true
	if framerate_input.selected_value != UserSettings.graphics_framerate:
		return true
	if antialiasing_input.selected_value != UserSettings.graphics_antialiasing:
		return true
	if dof_blur_input.selected_value != UserSettings.graphics_dof_blur:
		return true
	if glow_input.selected_value != UserSettings.graphics_glow:
		return true
	if shadows_input.selected_value != UserSettings.graphics_shadows:
		return true
	if world_streaming_input.selected_value != UserSettings.graphics_world_streaming:
		return true
	if glitches_input.selected_value != UserSettings.graphics_glitch_effects:
		return true
	if color_blind_input.selected_value != UserSettings.graphics_color_blind:
		return true
	return false

func apply():
	UserSettings.graphics_fullscreen = fullscreen_input.selected_value
	UserSettings.graphics_resolution = resolution_input.selected_value
	UserSettings.graphics_framerate = framerate_input.selected_value
	UserSettings.graphics_antialiasing = antialiasing_input.selected_value
	UserSettings.graphics_dof_blur = dof_blur_input.selected_value
	UserSettings.graphics_glow = glow_input.selected_value
	UserSettings.graphics_shadows = shadows_input.selected_value
	UserSettings.graphics_world_streaming = world_streaming_input.selected_value
	UserSettings.graphics_glitch_effects = glitches_input.selected_value
	UserSettings.graphics_color_blind = color_blind_input.selected_value

func reset():
	if not fullscreen_input:
		return
	
	fullscreen_input.selected_value = UserSettings.graphics_fullscreen
	
	resolution_input.values.clear()
	resolution_input.value_labels.clear()
	var had_current_resolution = false
	var had_screen_size = false
	var screen_size = OS.get_screen_size()
	for resolution in UserSettings.VALID_RESOLUTIONS:
		if resolution.x > screen_size.x or resolution.y > screen_size.y:
			continue
		if resolution == UserSettings.graphics_resolution:
			had_current_resolution = true
		if resolution == screen_size:
			had_screen_size = true
		
		resolution_input.values.push_back(resolution)
	if not had_current_resolution:
		var resolution = UserSettings.graphics_resolution
		resolution_input.values.push_back(resolution)
	if not had_screen_size and UserSettings.graphics_resolution != screen_size:
		resolution_input.values.push_back(screen_size)
	_update_resolution_labels()
	resolution_input.selected_value = UserSettings.graphics_resolution
	
	framerate_input.selected_value = UserSettings.graphics_framerate
	antialiasing_input.selected_value = UserSettings.graphics_antialiasing
	dof_blur_input.selected_value = UserSettings.graphics_dof_blur
	glow_input.selected_value = UserSettings.graphics_glow
	shadows_input.selected_value = UserSettings.graphics_shadows
	world_streaming_input.selected_value = UserSettings.graphics_world_streaming
	glitches_input.selected_value = UserSettings.graphics_glitch_effects
	color_blind_input.selected_value = UserSettings.graphics_color_blind
	
	preset_input.selected_value = detect_preset()
	
	inputs.setup_focus()

func _update_resolution_labels():
	if not resolution_input:
		return
	for i in range(resolution_input.values.size()):
		var resolution = resolution_input.values[i]
		if fullscreen_input.selected_value:
			resolution = UserSettings.adjust_fullscreen_res(resolution)
		var res_text = "%dx%d" % [int(resolution.x), int(resolution.y)]
		if i >= resolution_input.value_labels.size():
			resolution_input.value_labels.push_back("")
		resolution_input.value_labels[i] = res_text
	resolution_input.set_selected_index(resolution_input.selected_index)

func detect_preset() -> int:
	for id in presets.keys():
		var preset = presets[id]
		if _is_current_preset(preset):
			return id
	return 3

func _is_current_preset(preset) -> bool:
	for input in preset.keys():
		if input.selected_value != preset[input]:
			return false
	return true

func grab_focus():
	inputs.grab_focus()

func _on_PresetInput_value_changed(value, _index):
	if not presets:
		return
	var preset = presets.get(value)
	if not preset:
		return
	for input in preset.keys():
		input.selected_value = preset[input]

func _redetect_preset(_value, _index):
	if presets:
		var id = detect_preset()
		if preset_input.selected_value != id:
			preset_input.selected_value = id

func _on_FullscreenInput_value_changed(_value, _index):
	_update_resolution_labels()
