extends Button

export (Color) var focus_modulate: Color = Color.white

func _ready() -> void :
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")

func _on_focus_entered() -> void :
	modulate = focus_modulate
	if Accessibility:
		Accessibility.announce_focus(self)

func _on_focus_exited() -> void :
	modulate = Color.white
