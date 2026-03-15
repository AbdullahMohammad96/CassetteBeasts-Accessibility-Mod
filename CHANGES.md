# Cassette Beasts Accessibility Mod - Session Changes

## Session 2026-03-15 (v0.9.0)

### global/Accessibility.gd
- Fixed hotkey suppression during typing — replaced broken `is LineEdit` check with `_any_text_input_focused()` which uses `get_class()` to correctly detect `WidthLimitLineEdit` (the game's custom LineEdit subclass used for the name field in character creation) and any other GDScript subclasses, since Godot 3's `is` keyword does not walk GDScript inheritance chains
- Added `_any_text_input_focused()` helper that recursively scans the full scene tree for any focused node whose engine class is `"LineEdit"` or `"TextEdit"`
- Added `_scan_tree_for_focused_text()` recursive helper used by `_any_text_input_focused()`

### nodes/menus/ArrowOptionList.gd
- Fixed `set_selected_index()` to announce only the value text when a value changes, not the field name — field name is already announced by `on_row_focus_entered()` when focus first lands on the control, so repeating it on every arrow key press was redundant

### menus/title/FileMenu.gd
- Removed redundant "Select save file" menu announcement from `_announce_file_menu_open()` — the first save slot's `focus_entered` announcement already orients the user

### menus/title/FileButton.gd
- Fixed slot announcement interrupting title menu button speech by deferring `_announce_slot()` via `call_deferred()` in `_on_focus_entered_tts()`
- Extracted slot announcement logic into a separate `_announce_slot()` function

---

## Session 2026-03-15 (v0.8.0)

### global/Accessibility.gd
- Added debounce system for `announce_setting_changed()` (0.2s) to prevent rapid-fire announcements when holding arrow keys on sliders
- Added `_translate_label()` helper that tries `Loc.tr()`, then `tr()`, then strips `UI_SETTINGS_`/`UI_` prefixes as fallback for untranslated keys
- Fixed `_get_field_label()` to search parent row containers when no sibling label is found
- Fixed ArrowSlider value text to use `_translate_label()` instead of raw `_clean_text()`
- Fixed `announce_setting_changed()` to use `_translate_label()` for value text
- Added `_setting_debounce_timer` and `_on_setting_debounce_timeout()` for debouncing

### nodes/menus/ArrowOptionList.gd
- Added `_get_accessibility_value_text()` helper that detects color fields by checking "color"/"colour" in field name or node name, and calls `get_color_name_from_palette()` instead of returning raw number labels
- Both `set_selected_index()` and `on_row_focus_entered()` now use this helper

### menus/settings/GameplayPanel.gd
- Fixed play button to use `Loc.tr(play_button.text)` instead of `announce_focus` (which read raw translation key)
- Fixed erase button to use `Loc.tr("UI_LOAD_FILE_ERASE")` instead of hardcoded string
- Fixed back button to use `Loc.tr("UI_BUTTON_BACK")` instead of hardcoded string
- Added `_announce_difficulty_description()` that announces AI Smartness or Level Scaling description text on focus/change, computed directly from slider values
- Description text strips bullet formatting (`- ` and `\n`) for clean screen reader output
- Uses `speak(text, false)` so description doesn't interrupt the value announcement

### menus/settings/AudioPanel.gd
- Added TTS for audio settings controls

### menus/settings/GraphicsPanel.gd
- Added TTS for graphics settings controls

### menus/settings/SettingsMenu.gd
- Added tab switching TTS

### menus/title/TitleMenu.gd
- Added title screen announcement on ready

### menus/title/TitleMenuButton.gd
- Added button focus TTS

### menus/title/FileMenu.gd
- Fixed play button focused handler to use `Loc.tr(play_button.text)` (dynamic — changes between "New Game" and "Continue Game")
- Fixed erase button to use `Loc.tr("UI_LOAD_FILE_ERASE")`
- Fixed back button to use `Loc.tr("UI_BUTTON_BACK")`
- Added `_announce_file_menu_open()` with button signal connections

### menus/title/FileButton.gd
- Added save slot TTS on focus (slot number, player name, level, location, game over state)

### menus/title/SplashScreen.gd
- Fixed `_announce_mod_warning()` to use `Loc.tr("DLC_MOD_WARNING_TITLE")` and `Loc.tr("DLC_MOD_WARNING")`

### menus/title/GameModeMenu.gd (NEW)
- Added menu open announcement using `Loc.tr("UI_NEW_GAME_MODES_TITLE")`
- Added `announce_focus()` for each input on focus

### menus/title/LanguageMenu.gd (NEW)
- Added menu open announcement using `Loc.tr("TITLE_SCREEN_LANGUAGE_BUTTON")`
- Added focus handler for each language button announcing `btn.text`

### menus/character_creation/CharacterCreationMenu.gd (NEW)
- Added `_connect_accessibility_signals()` via `call_deferred` in `_ready()`
- Announces "Character Creation menu" on open
- `ArrowOptionList` and `ColorArrowOptionList` fields handled automatically via existing `on_row_focus_entered()` — no extra connections needed
- `Field_name` announces via existing `_on_Field_name_focus_entered()` using `announce_naming_screen()`
- `Field_wings` announces via existing `_on_Field_wings_focus_entered()` using `announce_focus()`
- Save, Randomize, Cancel buttons announce their translated text on focus

---

## Session 2026-02-14 (v0.6.0)

### global/Accessibility.gd
- Changed hotkeys: H/Shift+H for player/enemy health, T for time, G for gold, J for AP, B for bestiary, F4 toggle, F5 repeat
- Added F hotkey for fusion meter, R hotkey for relationship level
- Added `announce_battle()` for battle events
- Added speech queue system: `speak_queued()`, `set_dialogue_playing()`, `clear_speech_queue()`
- Added `COLOR_NAMES` dictionary and `get_color_name_from_palette()` for runtime color detection from palette.png
- Added `_describe_color()` for HSV-based color description fallback

### battle/ui/BattleToast_Default.gd
- Added damage, heal, AP change, and status effect announcements

### battle/ui/BattleToast_RecordingChance.gd
- Added recording chance announcement when tween completes

### battle/ui/cassette_player/FusionMeter.gd
- Added "Fusion ready!" announcement when meter fills

### battle/ui/TurnTitleBanner.gd
- Added turn action and failure announcements

### battle/ui/StatusEffectIconNode.gd
- Added status effect name, type (buff/debuff), and turns remaining announcement

### battle/ui/FusionLabelBanner.gd
- Added fusion name announcement

### battle/ui/TargetOrderSubmenu.gd
- Added target selection TTS

### menus/party/PartyMemberButton.gd
- Added character name, level, HP, relationship level, and tape info announcement on focus
- Added "ready to level up" indicator

### menus/party/TapeButton.gd
- Added tape name, species, types, HP percent, broken status, bootleg indicator, and grade announcement on focus

### menus/BaseMenu.gd
- Added menu name announcement on open

### menus/camping/CampingMenu.gd
- Added button name and rest cost TTS

### menus/gauntlet/GauntletDifficultyMenu.gd
- Added difficulty option TTS

### menus/illustration/Illustration.gd
- Added illustration description TTS

### menus/net_multiplayer/NetPlayerButton.gd
- Added player name TTS for online play

### menus/noticeboard/NoticeboardQuestButton.gd
- Added quest name, description, and status TTS

### menus/raid/RaidInfoPanel.gd
- Added raid boss name, level, type, and subtitle TTS

### menus/ranger_stamp_card/StampSlot.gd
- Added ranger captain name and defeated status TTS

### menus/spooky_dialog/SpookyDialog.gd
- Added spooky dialog text TTS

### menus/stat_adjust/StatSlider.gd
- Added stat name, value, and adjustment info TTS

### menus/sticker_fusion/StickerFusionAttributeButton.gd
- Added attribute name and compatibility TTS

---

## Session 2026-02-14 (v0.5.0)

### battle/ui/FightOrderSubmenu.gd
- Added move list TTS with description, AP cost, type, and power

### global/Accessibility.gd
- Added runtime color detection from palette.png via `get_color_name_from_palette()`
- Added `_describe_color()` HSV-based fallback color description

---

## Session 2026-02-14 (v0.4.0)

### global/Accessibility.gd
- Added speech queue system to prevent dialogue options cutting off character speech
- Added `announce_cassette_obtained()`, `announce_naming_screen()`

### menus/give_tape/GiveTapeMenu.gd
- Added "Cassette obtained" announcement

### menus/text_input/TextInputMenu.gd
- Added naming screen announcement on ready

### nodes/message_dialog/MenuDialog.gd
- Added dialogue options announcement queued after dialogue finishes

---

## Session 2026-02-14 (v0.3.0)

### global/Accessibility.gd
- Replaced PowerShell SAPI as primary TTS with godot-tts GDNative addon
- Added support for NVDA, JAWS, SAPI, System Access, Window-Eyes via Tolk
- PowerShell SAPI kept as fallback if godot-tts fails to load
- Added `_on_utterance_end()` signal handler

---

## Session 2026-02-14 (v0.2.0)

### global/Accessibility.gd
- Fixed TTS overlap by adding interrupt parameter to `speak()`
- Added `COLOR_NAMES` dictionary for character creation palette
- Fixed dialogue timing to prevent speech cutoff

### battle/ui/cassette_player/CassettePlayer3D.gd
- Added main battle menu button TTS (Fight, Forms, Items, Flee, Fuse)

### battle/ui/cassette_player/CassetteButton.gd
- Added 3D cassette button name TTS

### battle/ui/MoveButton.gd
- Added move name, AP cost, type, and status TTS

### battle/ui/TargetButton.gd
- Added target name and ally/enemy indicator TTS

### nodes/message_dialog/MessageDialog.gd
- Added dialogue text TTS with speaker name

---

## Session 2026-02-13 (v0.1.0)

### global/Accessibility.gd (NEW)
- Initial TTS singleton using PowerShell SAPI
- Basic `speak()`, `stop()` functions
- Hotkeys: H health, T time, G gold, J AP, B bestiary, F4 toggle, F5 repeat
- `announce_focus()`, `announce_dialogue()`, `announce_menu()`

### menus/inventory/ItemButton.gd
- Added item name, quantity, and rarity TTS on focus

### menus/inventory/InventoryTab.gd
- Added tab name TTS when switching tabs

### menus/bestiary/BestiaryListButton.gd
- Added species code, name, and encounter status TTS

### menus/bestiary/BestiaryListButtonFusion.gd
- Added fusion species info TTS

### menus/loot/LootMenu.gd
- Added items obtained summary TTS

### menus/gain_exp/GainExpMenu.gd
- Added EXP gained, level up, and grade up TTS

### nodes/menus/ArrowOptionList.gd
- Added option selection TTS

### project.godot
- Added Accessibility autoload singleton

### addons/godot-tts/ (NEW)
- Added godot-tts GDNative addon with DLLs for NVDA and SAPI support

---

## Installation
Copy all files from source/ into your decompiled game folder at C:\CassetteBeasts-Decompiled\
maintaining the same folder structure, then repack with GodotPCKExplorer.Cassette Beasts Accessibility Mod - Session Changes

## Session 2026-03-15 (v0.8.0)

### global/Accessibility.gd
- Added debounce system for `announce_setting_changed()` (0.2s) to prevent rapid-fire announcements when holding arrow keys on sliders
- Added `_translate_label()` helper that tries `Loc.tr()`, then `tr()`, then strips `UI_SETTINGS_`/`UI_` prefixes as fallback for untranslated keys
- Fixed `_get_field_label()` to search parent row containers when no sibling label is found
- Fixed ArrowSlider value text to use `_translate_label()` instead of raw `_clean_text()`
- Fixed `announce_setting_changed()` to use `_translate_label()` for value text
- Added `_setting_debounce_timer` and `_on_setting_debounce_timeout()` for debouncing
- Fixed hotkeys to be suppressed when a `LineEdit` or `TextEdit` has focus (prevents hotkeys interfering with typing)

### nodes/menus/ArrowOptionList.gd
- Added `_get_accessibility_value_text()` helper that detects color fields by checking "color"/"colour" in field name or node name, and calls `get_color_name_from_palette()` instead of returning raw number labels
- Both `set_selected_index()` and `on_row_focus_entered()` now use this helper

### menus/settings/GameplayPanel.gd
- Fixed play button to use `Loc.tr(play_button.text)` instead of `announce_focus` (which read raw translation key)
- Fixed erase button to use `Loc.tr("UI_LOAD_FILE_ERASE")` instead of hardcoded "Erase save file"
- Fixed back button to use `Loc.tr("UI_BUTTON_BACK")` instead of hardcoded "Back"
- Added `_announce_difficulty_description()` that announces AI Smartness or Level Scaling description text on focus/change, computed directly from slider values (not read from label which may be stale)
- Description text strips bullet formatting (`- ` and `\n`) for clean screen reader output
- Uses `speak(text, false)` so description doesn't interrupt the value announcement

### menus/title/FileMenu.gd
- Fixed play button focused handler to use `Loc.tr(play_button.text)` (dynamic — changes between "New Game" and "Continue Game")
- Fixed erase button to use `Loc.tr("UI_LOAD_FILE_ERASE")`
- Fixed back button to use `Loc.tr("UI_BUTTON_BACK")`

### menus/title/SplashScreen.gd
- Fixed `_announce_mod_warning()` to use `Loc.tr("DLC_MOD_WARNING_TITLE")` and `Loc.tr("DLC_MOD_WARNING")` instead of calling private `Accessibility._clean_text()` directly

### menus/title/GameModeMenu.gd (NEW)
- Added menu open announcement using `Loc.tr("UI_NEW_GAME_MODES_TITLE")`
- Added `announce_focus()` for each input on focus

### menus/title/LanguageMenu.gd (NEW)
- Added menu open announcement using `Loc.tr("TITLE_SCREEN_LANGUAGE_BUTTON")`
- Added focus handler for each language button announcing `btn.text`

### menus/character_creation/CharacterCreationMenu.gd (NEW)
- Added `_connect_accessibility_signals()` via `call_deferred` in `_ready()`
- Announces "Character Creation menu" on open
- `ArrowOptionList` and `ColorArrowOptionList` fields handled automatically via existing `on_row_focus_entered()` — no extra connections needed
- `Field_name` announces via existing `_on_Field_name_focus_entered()` using `announce_naming_screen()`
- `Field_wings` announces via existing `_on_Field_wings_focus_entered()` using `announce_focus()`
- Save, Randomize, Cancel buttons announce their translated text on focus

## Installation
Copy all files from source/ into your decompiled game folder at C:\CassetteBeasts-Decompiled\
maintaining the same folder structure, then repack with GodotPCKExplorer.
