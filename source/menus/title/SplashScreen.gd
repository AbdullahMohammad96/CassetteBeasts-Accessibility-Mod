extends CanvasLayer

const TITLE_SCENE_PATH = "res://menus/title/TitleMenu.tscn"
const LOAD_AT_INDEX = 1

export (Array, Resource) var splash_cards: Array

onready var container = $Container
onready var texture_rect = $Container / TextureRect
onready var video_player = $Container / VideoPlayer
onready var mod_warning = $Container / ModWarning
onready var mod_warning_label = $Container / ModWarning / ModWarningLabel
onready var mod_warning_buttons = $Container / ModWarning / Buttons

var card_index: int = 0
var finished: bool = false
var t: float = 0.0
var load_promise: Promise
var mod_warning_done: = false

func _ready():
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
	SceneManager.transition_out()
	
	if DLC.is_load_mods_requested() and not mod_warning_done:
		mod_warning.visible = true
		texture_rect.visible = false
		video_player.visible = false
		mod_warning_label.bbcode_text = Loc.tr("DLC_MOD_WARNING")
		mod_warning_buttons.setup_focus()
		mod_warning_buttons.grab_focus()
		if Accessibility:
			call_deferred("_announce_mod_warning")
		return
	
	mod_warning_done = true
	mod_warning.visible = false
	setup_card()

func setup_card():
	t = 0.0
	video_player.stop()
	
	if card_index == LOAD_AT_INDEX:
		start_full_load()
	
	if card_index >= splash_cards.size():
		finish()
		return
	
	var card = splash_cards[card_index]
	if card is Texture:
		texture_rect.visible = true
		video_player.visible = false
		texture_rect.texture = card
		t = 2.0
		
	elif card is VideoStream:
		texture_rect.visible = false
		video_player.visible = true
		video_player.stream = card
		video_player.play()
		
	elif card is PackedScene:
		texture_rect.visible = false
		video_player.visible = false
		var scene = card.instance()
		assert (scene.has_node("AnimationPlayer"))
		container.add_child(scene)
		scene.get_node("AnimationPlayer").connect("animation_finished", self, "_on_AnimationPlayer_finished", [scene])
	else:
		assert (false)
	

func next():
	card_index += 1
	setup_card()

func _on_AnimationPlayer_finished(_anim_name, scene):
	container.remove_child(scene)
	scene.queue_free()
	next()

func _on_VideoPlayer_finished():
	next()

func _process(delta: float):
	if mod_warning.visible or finished or t <= 0.0:
		return
	t -= delta
	if t < 0.0:
		next()

func _input(event: InputEvent):
	if finished or not mod_warning_done:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		next()
		get_tree().set_input_as_handled()
		return
	
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		next()
		get_tree().set_input_as_handled()
		return

func start_full_load():
	load_promise = Promise.new()
	SceneManager.set_loading(true)
	SceneManager.start_preload("full_load", load_promise)

func _announce_mod_warning() -> void:
	if Accessibility:
		var warning_text = Accessibility._clean_text(mod_warning_label.bbcode_text)
		Accessibility.speak("Mod warning. " + warning_text + ". Use arrow keys to choose an option.", true)

func finish():
	if finished:
		return
	finished = true
	container.visible = false
	
	if not load_promise.ready:
		yield(load_promise, "fulfilled")
	
	SceneManager.change_scene(TITLE_SCENE_PATH, {hide_loading_ui = true})

func _on_ModWarningButton1_pressed():
	
	DLC.load_mods_enabled = true
	Platform.install_ugc()
	mod_warning_done = true
	mod_warning.visible = false
	setup_card()

func _on_ModWarningButton2_pressed():
	
	DLC.load_mods_enabled = false
	mod_warning_done = true
	mod_warning.visible = false
	setup_card()

func _on_ModWarningButton4_pressed():
	Platform.open_url("https://wiki.cassettebeasts.com/wiki/Modding:Mod_User_Guide")

func _on_ModWarningButton3_pressed():
	SceneManager.quit()

