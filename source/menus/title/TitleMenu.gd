extends Control

const LanguageMenu = preload("res://menus/title/LanguageMenu.tscn")
const SettingsMenu = preload("res://menus/settings/SettingsMenu.tscn")
const FileMenu = preload("res://menus/title/FileMenu.tscn")

const UPDATE_POPUPS = [
	{
		flag = "update_popup_1.6", 
		title = "UPDATE_POPUP_MP_TITLE", 
		popups = [
			preload("res://menus/tutorial_box/UpdateMPPopUp1.tscn"), 
			preload("res://menus/tutorial_box/UpdateMPPopUp2.tscn")
		]
	}, 
	{
		flag = "update_popup_1.7", 
		title = "UPDATE_POPUP_GAUNTLET_TITLE", 
		popups = [
			preload("res://menus/tutorial_box/UpdateGauntletPopUp1.tscn")
		]
	}, 
	{
		flag = "dlc_fashion", 
		require_dlc = "fashion", 
		title = "DLC_POPUP_FASHION_TITLE", 
		popups = [
			preload("res://menus/tutorial_box/DLCFashionPopUp1.tscn"), 
			preload("res://menus/tutorial_box/DLCFashionPopUp2.tscn")
		]
	}, 
	{
		flag = "update_popup_1.8", 
		title = "UPDATE_POPUP_SUNNY_TITLE", 
		popups = [
			preload("res://menus/tutorial_box/UpdateSunnyPopUp1.tscn")
		]
	}, 
	{
		flag = "dlc_wings", 
		require_dlc = "wings", 
		title = "DLC_POPUP_WINGS_TITLE", 
		popups = [
			preload("res://menus/tutorial_box/DLCWingsPopUp1.tscn"), 
			preload("res://menus/tutorial_box/DLCWingsPopUp2.tscn"), 
		]
	}, 
]

onready var buttons = $Buttons
onready var logo_container = $LogoContainer
onready var logo_anim = $LogoContainer / LogoAnim
onready var version_container = find_node("VersionContainer")
onready var version_label = find_node("VersionLabel")
onready var prompt_label = find_node("PromptLabel")
onready var store_btns = {
	full_ver = $"%FullVersionButton", 
	dlc_list = $"%DLCListButton", 
	dlc_pier = $"%DLCPierButton", 
	dlc_cosplay = $"%DLCCosplayButton", 
	dlc_fashion = $"%DLCFashionButton", 
	dlc_wings = $"%DLCWingsButton"
}

var menu: Control = null

func _ready():
	GlobalUI.manage_visibility(logo_container)
	GlobalUI.manage_visibility(prompt_label)
	GlobalUI.manage_visibility(buttons)
	
	version_container.hide()
	
	if not Platform.has_store():
		for btn in store_btns.values():
			btn.hide()
	else:
		for btn in store_btns.values():
			btn.icon = Platform.get_store_icon()
		
		if Platform.get_id() == "NX":
			store_btns.dlc_list.text = "TITLE_SCREEN_DLC_BTN_NX"
		
		if Platform.is_demo():
			for btn in store_btns.values():
				if btn != store_btns.full_ver:
					btn.hide()
		elif Platform.store_has_dlc_list():
			for btn in store_btns.values():
				if btn != store_btns.dlc_list:
					btn.hide()
		else:
			store_btns.full_ver.hide()
			store_btns.dlc_list.hide()
			
			if Platform.has_dlc("pier"):
				store_btns.dlc_pier.hide()
			if Platform.has_dlc("cosplay"):
				store_btns.dlc_cosplay.hide()
			if Platform.has_dlc("fashion"):
				store_btns.dlc_fashion.hide()
			if Platform.has_dlc("wings"):
				store_btns.dlc_wings.hide()
	
	update_version_label()
	UserSettings.connect("locale_changed", self, "update_version_label")
	
	version_container.setup_focus()
	call_deferred("_on_title_screen_ready")

func _process(_delta):
	if not menu and Net.has_pending_invite():
		buttons.visible = false
		prompt_label.visible = false
		logo_anim.stop()
		logo_container.visible = false
		yield(show_files(true), "completed")
		show_logo()
		buttons.show()

func update_version_label():
	version_label.text = preload("res://version.tres").get_full_string()
	if Platform.has_dlc("cosplay") and not DLC.has_dlc("cosplay"):
		version_label.text += "\n" + Loc.trf("TITLE_SCREEN_CONTENT_LIST_DLC", {
			content_name = "DLC_00_COSPLAY_NAME"
		})
	if Platform.has_dlc("fashion") and not DLC.has_dlc("fashion"):
		version_label.text += "\n" + Loc.trf("TITLE_SCREEN_CONTENT_LIST_DLC", {
			content_name = "DLC_02_FASHION_NAME"
		})
	if Platform.has_dlc("wings") and not DLC.has_dlc("wings"):
		version_label.text += "\n" + Loc.trf("TITLE_SCREEN_CONTENT_LIST_DLC", {
			content_name = "DLC_03_WINGS_NAME"
		})
	for dlc in DLC.dlcs:
		version_label.text += "\n" + Loc.trf("TITLE_SCREEN_CONTENT_LIST_DLC", {
			content_name = dlc.name
		})
	for mod in DLC.mods:
		var key = "TITLE_SCREEN_CONTENT_LIST_MOD_WITH_AUTHOR" if mod.author != "" else "TITLE_SCREEN_CONTENT_LIST_MOD"
		version_label.text += "\n" + Loc.trf(key, {
			content_name = mod.name, 
			content_version = mod.version_string, 
			content_author = mod.author
		})

func _on_title_screen_ready() -> void:
	if Accessibility:
		Accessibility.speak("Cassette Beasts. Title screen. Use arrow keys to navigate buttons, Enter to select.", true)

func _on_PromptLabel_hiding():
	if not Platform.is_demo():
		for update in UPDATE_POPUPS:
			if update.has("require_dlc") and not Platform.has_dlc(update.require_dlc) and not DLC.has_dlc(update.require_dlc):
				continue
			if not UserSettings.misc_data.has(update.flag):
				yield(MenuHelper.show_tutorial_box(update.title, update.popups), "completed")
				UserSettings.misc_data[update.flag] = true
				UserSettings.save_settings()

	for content in DLC.dlcs + DLC.mods:
		var co = content.on_title_screen()
		if co is GDScriptFunctionState:
			yield(co, "completed")
	version_container.show()
	buttons.show()

func _on_Buttons_chose_option(option):
	if option == "play":
		hide_logo()
		yield(show_files(), "completed")
		show_logo()
	
	if option == "settings":
		hide_logo()
		yield(show_settings(), "completed")
		show_logo()
		
	elif option == "language":
		hide_logo()
		yield(show_language(), "completed")
		show_logo()
	
	elif option == "credits":
		SceneManager.change_scene("res://cinematics/credits/MainCredits.tscn")
		return
	
	elif option == "quit":
		yield(SceneManager.quit(), "completed")
		return
	
	buttons.show()

func hide_logo():
	logo_anim.play("hide")
	yield(logo_anim, "animation_finished")
	yield(Co.next_frame(), "completed")

func show_logo():
	logo_anim.play("show")
	yield(logo_anim, "animation_finished")

func show_settings():
	menu = SettingsMenu.instance()
	menu.get_node("Blur").visible = false
	add_child(menu)
	yield(menu.run_menu(), "completed")
	menu.queue_free()
	menu = null

func show_language():
	menu = LanguageMenu.instance()
	add_child(menu)
	menu.show()
	yield(menu, "hidden")
	menu.queue_free()
	menu = null

func show_files(immediate: bool = false):
	menu = FileMenu.instance()
	add_child(menu)
	if immediate:
		menu.show_immediate()
	else:
		menu.show()
	yield(menu, "hidden")
	menu.queue_free()
	menu = null

func grab_focus():
	if menu:
		menu.grab_focus()
	elif buttons.visible:
		buttons.grab_focus()

func _on_ModesCodeListener_cheat_code_detected():
	var focus_owner = get_focus_owner()
	
	if not UserSettings.enable_custom_modes and not Platform.is_demo():
		UserSettings.enable_custom_modes = true
		UserSettings.apply_settings()
		UserSettings.save_settings()
		GlobalMessageDialog.clear_state()
		yield(GlobalMessageDialog.show_message("UI_NEW_GAME_MODES_NOTIFICATION"), "completed")
		
		if focus_owner:
			focus_owner.grab_focus()

func _on_ExpoCodeListener_cheat_code_detected():
	Debug.start_expo_mode()

func _on_FullVersionButton_pressed():
	Platform.open_store()

func _on_DLCListButton_pressed():
	Platform.open_store_dlc()

func _on_dlc_button_pressed(dlc_id: String) -> void :
	Platform.open_store_dlc(dlc_id)

func _on_WorkshopButton_pressed():
	Platform.open_ugc_workshop()
