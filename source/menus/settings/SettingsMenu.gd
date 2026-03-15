extends "res://menus/BaseMenu.gd"

const TABS = [
	{
		name = "UI_SETTINGS_GRAPHICS", 
		scene = preload("GraphicsPanel.tscn"), 
		console_scene = preload("ConsoleGraphicsPanel.tscn")
	}, 
	{
		name = "UI_SETTINGS_AUDIO", 
		scene = preload("AudioPanel.tscn")
	}, 
	{
		name = "UI_SETTINGS_GAMEPLAY", 
		scene = preload("GameplayPanel.tscn")
	}, 
	{
		name = "UI_SETTINGS_NETWORK", 
		scene = preload("NetworkPanel.tscn"), 
		require_net = true
	}, 
	{
		name = "UI_SETTINGS_KEYBOARD", 
		scene = preload("KeyboardPanel.tscn"), 
		deny_console = true
	}
]

onready var title_label = find_node("TitleLabel")
onready var prev_category_label = find_node("PrevCategoryLabel")
onready var prev_category_panel = find_node("PrevCategoryPanel")
onready var next_category_label = find_node("NextCategoryLabel")
onready var next_category_panel = find_node("NextCategoryPanel")
onready var content_container = find_node("ContentContainer")

onready var defaults_button = find_node("DefaultsButton")
onready var rebind_button = find_node("RebindButton")
onready var action_icon_buttons = [
	find_node("PrevCategoryButton"), 
	find_node("NextCategoryButton"), 
	defaults_button, 
	rebind_button, 
	find_node("ExitButton"), 
	find_node("SaveButton")
]

var tabs: Array
var current_index: int = 0

func _ready():
	for tab in TABS:
		if tab.get("deny_console", false) and Platform.is_console():
			continue
		if tab.get("require_net", false) and not Net.is_enabled():
			continue
		
		var node
		if tab.has("console_scene") and Platform.is_console():
			node = tab.console_scene.instance()
		elif tab.scene:
			node = tab.scene.instance()
		else:
			node = Panel.new()
		content_container.add_child(node)
		node.visible = false
		
		tabs.push_back({
			name = tab.name, 
			node = node
		})
	
	setup_tab()

func setup_tab():
	for child in content_container.get_children():
		child.visible = false
	
	prev_category_panel.visible = current_index > 0
	next_category_panel.visible = current_index < tabs.size() - 1
	defaults_button.set_visible_override(false)
	rebind_button.set_visible_override(false)
	
	if current_index < 0 or current_index >= tabs.size():
		title_label.text = "UI_SETTINGS"
		return
	
	title_label.text = tabs[current_index].name
	if current_index > 0:
		prev_category_label.text = tabs[current_index - 1].name
	if current_index < tabs.size() - 1:
		next_category_label.text = tabs[current_index + 1].name
	
	var node = tabs[current_index].node
	if node:
		node.visible = true
		if node.has_method("reset_to_defaults"):
			defaults_button.set_visible_override(null)
		if node.has_method("rebind"):
			rebind_button.set_visible_override(null)
		if node.has_method("grab_focus"):
			node.grab_focus()
	
	if Accessibility:
		var tab_name = Loc.tr(tabs[current_index].name)
		var position = str(current_index + 1) + " of " + str(tabs.size())
		Accessibility.speak("Settings, " + tab_name + ", " + position, true)

func grab_focus():
	var node = tabs[current_index].node
	if node and node.has_method("grab_focus"):
		node.grab_focus()

func _on_NextCategoryButton_pressed():
	current_index += 1
	setup_tab()

func _on_PrevCategoryButton_pressed():
	current_index -= 1
	setup_tab()

func _on_SaveButton_pressed():
	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab.node.has_method("check_valid"):
			var err = tab.node.check_valid()
			if err != "":
				current_index = i
				setup_tab()
				GlobalMessageDialog.clear_state()
				return GlobalMessageDialog.show_message(err)
	
	var focus_owner = get_focus_owner()
	
	for tab in tabs:
		if tab.node.has_method("apply"):
			tab.node.apply()
	UserSettings.apply_settings()
	UserSettings.save_settings()
	
	for button in action_icon_buttons:
		button.update_icon()
	
	GlobalMessageDialog.clear_state()
	yield(GlobalMessageDialog.show_message("UI_SETTINGS_SAVED"), "completed")
	
	if focus_owner:
		focus_owner.grab_focus()

func is_dirty() -> bool:
	for tab in tabs:
		if tab.node.has_method("is_dirty") and tab.node.is_dirty():
			return true
	return false

func _on_ExitButton_pressed():
	var focus_owner = get_focus_owner()
	if is_dirty():
		if not yield(MenuHelper.confirm("UI_SETTINGS_CLOSE_CONFIRM"), "completed"):
			if focus_owner:
				focus_owner.grab_focus()
			return
	for tab in tabs:
		if tab.node.has_method("cancel"):
			tab.node.cancel()
	cancel()

func _on_DefaultsButton_pressed():
	for tab in tabs:
		if tab.node.has_method("reset_to_defaults"):
			tab.node.reset_to_defaults()

func _on_RebindButton_pressed():
	for tab in tabs:
		if tab.node.has_method("rebind"):
			tab.node.rebind()
