extends PanelContainer

signal option_chosen(option_index)

export (Array, String) var options: Array setget set_options
export (int) var initial_index: int = 0 setget set_initial_index
export (int) var default_index: int = - 1
export (bool) var valign_center: bool = true setget set_valign_center

onready var buttons_panel = $ScrollContainer / PanelContainer
onready var buttons = $ScrollContainer / PanelContainer / Buttons

var t: float = 0.0

func _ready():
	set_options(options)
	set_process(false)

func set_valign_center(value: bool):
	valign_center = value
	if buttons_panel:
		buttons_panel.size_flags_vertical = SIZE_EXPAND | (SIZE_SHRINK_CENTER if valign_center else SIZE_SHRINK_END)

func set_options(value: Array):
	options = value
	if buttons:
		for button in buttons.get_children():
			buttons.remove_child(button)
			button.queue_free()
		for i in range(options.size()):
			var option = options[i]
			var button = preload("MenuDialogButton.tscn").instance()
			button.set_bbcode("[center]{0}[/center]".format([tr(option)]))
			buttons.add_child(button)
			button.connect("pressed", self, "_button_pressed", [i])
			button.connect("focus_entered", self, "_on_button_focused", [i])
		buttons.setup_focus()
		set_initial_index(initial_index)

func _on_button_focused(index: int) -> void:
	if Accessibility and index >= 0 and index < options.size():
		var option_text = Accessibility._clean_text(tr(options[index]))
		var position = str(index + 1) + " of " + str(options.size())
		Accessibility.speak(option_text + ", " + position, false)

func set_initial_index(value: int):
	initial_index = value
	if buttons and initial_index >= 0 and initial_index < buttons.focusable_children.size():
		var initial_btn = buttons.focusable_children[initial_index]
		buttons.initial_focus = buttons.get_path_to(initial_btn)

func _process(delta: float):
	t += delta
	if Input.is_action_pressed("fast_mode") and UserSettings.show_timer:
		if t > 0.1:
			_button_pressed(initial_index)

func grab_focus():
	buttons.grab_focus()
	if visible:
		t = 0.0
		set_process(true)
		if Accessibility:
			call_deferred("_announce_options")

func _announce_options() -> void:
	if Accessibility and options.size() > 0:
		var announcement = "Choose: "
		for i in range(options.size()):
			if i > 0:
				announcement += ", "
			announcement += str(i + 1) + ") " + Accessibility._clean_text(tr(options[i]))
		Accessibility.speak_queued(announcement)

func _button_pressed(option_index):
	set_process(false)
	emit_signal("option_chosen", option_index)

func _input(event):
	if not visible or GlobalUI.is_input_blocked() or not buttons.has_focus():
		return
	if event.is_action_pressed("ui_cancel") and default_index >= 0:
		if buttons.get_focus_owner() == buttons.get_child(default_index):
			set_process(false)
			emit_signal("option_chosen", default_index)
		else:
			buttons.get_child(default_index).grab_focus()
		get_tree().set_input_as_handled()

func cancel():
	set_process(false)
	if default_index >= 0:
		emit_signal("option_chosen", default_index)
	else:
		emit_signal("option_chosen", 0)
