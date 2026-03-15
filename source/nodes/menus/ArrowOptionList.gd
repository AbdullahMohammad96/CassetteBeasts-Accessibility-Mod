extends HBoxContainer

signal value_changed(value, index)

const TEXT_MARGIN = 10.0

export (Array) var values: Array
export (Array, String) var value_labels: Array
export (Dictionary) var value_font_color_overrides: Dictionary
export (Color) var font_color_selected: Color = Color.white
export (Color) var font_color_normal: Color = Color.black

onready var left_arrow = $LeftArrow
onready var value_label = $ValueLabel
onready var right_arrow = $RightArrow

var selected_index: int = 0 setget set_selected_index
var selected_value = null setget set_selected_value
var row_focused: bool

func _ready():
	set_selected_index(selected_index)
	adjust_min_size()

func get_value_label(index: int) -> String:
	if index < 0 or index >= value_labels.size():
		return ""
	var text = value_labels[index]
	if index >= 0 and index < values.size():
		text = Loc.trf(text, values[index])
	else:
		text = Loc.tr(text)
	return text

func adjust_min_size():
	if value_label:
		var width = 0
		var font = value_label.get_font("font")
		for i in range(value_labels.size()):
			width = max(width, font.get_string_size(get_value_label(i)).x)
		value_label.rect_min_size.x = width + TEXT_MARGIN

func _on_LeftArrow_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == 1 and not event.pressed:
		move_selection( - 1)

func _on_RightArrow_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and not event.pressed:
		move_selection(1)

func _on_ArrowOptionList_gui_input(event):
	if event.is_action_pressed("ui_left"):
		move_selection( - 1)
	elif event.is_action_pressed("ui_right"):
		move_selection(1)

func move_selection(delta: int):
	if values.size() <= 0:
		return
	set_selected_index(posmod(selected_index + delta, values.size()))

func set_selected_index(value: int):
	if value < 0 or value >= values.size():
		value = 0
	selected_index = value
	selected_value = values[selected_index] if selected_index >= 0 and selected_index < values.size() else null
	value_label.text = get_value_label(selected_index)
	_update_color()
	emit_signal("value_changed", selected_value, selected_index)
	if Accessibility and is_inside_tree():
		# Accessibility: Announce only the value on change, not the field name.
		# Field name is already announced by on_row_focus_entered() on focus.
		var field_name = Accessibility._get_field_label(self)
		var value_text = _get_accessibility_value_text(field_name)
		Accessibility.speak(value_text, true)

func set_selected_value(value):
	value = _validate_value(value)
	set_selected_index(values.find(value))

func _validate_value(value):
	return value

func _on_ArrowOptionList_mouse_entered():
	grab_focus()

func on_row_focus_entered():
	row_focused = true
	_update_color()
	if Accessibility:
		var field_name = Accessibility._get_field_label(self)
		var value_text = _get_accessibility_value_text(field_name)
		if field_name.empty():
			Accessibility.speak(value_text, true)
		else:
			Accessibility.speak(field_name + ", " + value_text, true)

func _get_accessibility_value_text(field_name: String) -> String:
	# Accessibility: Use color name from palette if this is a color field
	# Check both "color" and "colour" to handle different locales
	var fname_lower = field_name.to_lower()
	if selected_value is int and ("color" in fname_lower or "colour" in fname_lower):
		return Accessibility.get_color_name_from_palette(selected_value)
	# Also detect by node name as fallback (Field_skin_color, Field_hair_color etc.)
	if selected_value is int and "color" in name.to_lower():
		return Accessibility.get_color_name_from_palette(selected_value)
	return Accessibility._clean_text(get_value_label(selected_index))

func on_row_focus_exited():
	row_focused = false
	_update_color()

func _update_color():
	if value_font_color_overrides.has(selected_value):
		_set_color(value_font_color_overrides[selected_value])
	else:
		_set_color(font_color_selected if row_focused else font_color_normal)

func _set_color(color: Color):
	left_arrow.get("custom_styles/panel").bg_color = color
	right_arrow.get("custom_styles/panel").bg_color = color
	value_label.add_color_override("font_color", color)
