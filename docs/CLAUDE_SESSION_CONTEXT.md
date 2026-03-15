# Cassette Beasts Accessibility Mod - Claude Session Context

**Created:** 2026-02-14
**Last Updated:** 2026-03-15
**Purpose:** Provides context for continuing development in new Claude sessions

---

## PROJECT OVERVIEW

This is an accessibility mod for **Cassette Beasts** (a monster-catching RPG) that adds TTS (text-to-speech) support for blind/visually impaired players. The mod works by modifying the game's PCK file directly (not Steam Workshop, which doesn't support autoload singletons).

### Game Info
- **Game:** Cassette Beasts
- **Engine:** Godot 3.5.1
- **Platform:** Windows (Steam)

---

## DIRECTORY STRUCTURE

| Path | Purpose |
|------|---------| 
| `C:\Users\annbl\Downloads\Cassette.Beasts.v1.8.2\Cassette.Beasts.v1.8.2\Cassette Beasts\` | Game installation directory |
| `C:\CassetteBeasts-Decompiled\` | Decompiled game source (full game files, editable) |
| `C:\CassetteBeasts-AccessibilityMod\` | Git repo for the mod |
| `C:\CassetteBeasts-AccessibilityMod\source\` | Modified source files for the mod |
| `C:\CassetteBeasts-AccessibilityMod\addons\godot-tts\` | TTS addon (godot-tts GDNative) |
| `C:\CassetteBeasts-AccessibilityMod\docs\` | Documentation |

### Tools
- **PCK Explorer:** `C:\Users\annbl\Downloads\GodotPCKExplorer_1.6.0_dotnet-ui-console-win-linux-mac\GodotPCKExplorer.Console.exe`
- **GDRE Tools:** `C:\Users\annbl\Downloads\GDRE_tools-v2.5.0-beta.2-windows\gdre_tools.exe`
- **Downloaded files land in:** `C:\Users\annbl\Downloads\`

---

## REPACK COMMANDS (CMD - each command separate)

```cmd
move /Y "C:\Users\annbl\Downloads\[filename]" "C:\CassetteBeasts-Decompiled\[path]\[filename]"
```
```cmd
cd "C:\Users\annbl\Downloads\GodotPCKExplorer_1.6.0_dotnet-ui-console-win-linux-mac"
```
```cmd
GodotPCKExplorer.Console.exe -p "C:\CassetteBeasts-Decompiled" "C:\Users\annbl\Downloads\Cassette.Beasts.v1.8.2\Cassette.Beasts.v1.8.2\Cassette Beasts\CassetteBeasts_new.pck" "1.3.5.1"
```
```cmd
move /Y "C:\Users\annbl\Downloads\Cassette.Beasts.v1.8.2\Cassette.Beasts.v1.8.2\Cassette Beasts\CassetteBeasts_new.pck" "C:\Users\annbl\Downloads\Cassette.Beasts.v1.8.2\Cassette.Beasts.v1.8.2\Cassette Beasts\CassetteBeasts.pck"
```

---

## TTS SYSTEM

### Engine
- **Primary:** godot-tts GDNative addon for native screen reader integration
- **Supports:** NVDA, JAWS, SAPI, System Access, Window-Eyes
- **Fallback:** PowerShell SAPI if godot-tts fails

### Required DLLs (must be in game directory, NOT in PCK)
- `godot_tts.dll`
- `nvdaControllerClient64.dll`
- `SAAPI64.dll`

### Core File
- `C:\CassetteBeasts-Decompiled\global\Accessibility.gd` - Main TTS singleton
- Registered as autoload in `project.godot`

---

## HOTKEYS

| Key | Action |
|-----|--------|
| **H** | Announce player health (in battle) |
| **Shift+H** | Announce enemy health (in battle) |
| **T** | Announce time of day |
| **G** | Announce gold/money |
| **J** | Announce player AP (in battle) |
| **B** | Announce bestiary info (when in bestiary) |
| **F4** | Toggle accessibility on/off |
| **F5** | Repeat last spoken text |

**Note:** Hotkeys are suppressed when a LineEdit or TextEdit has focus (typing mode).

---

## CODE GUIDELINES

1. **Only add accessibility hooks — never modify game logic**
2. Always check `if Accessibility:` before any TTS call
3. Use `call_deferred()` if the UI isn't ready yet
4. Use `speak(text, false)` for non-interrupting/supplementary speech
5. Use translation keys via `Loc.tr()` — never hardcode display strings
6. Comment every accessibility block with `# Accessibility: [description]`

---

## KEY SYSTEMS TO UNDERSTAND

### Row Focus System (GridContainer/VBoxContainer menus)
- `RowFocusIndicator` polls `container.get_focus_owner()` every frame
- When focus changes it calls `on_row_focus_entered()`/`on_row_focus_exited()` on all siblings in the row
- `ArrowOptionList` and `ColorArrowOptionList` already have TTS in `on_row_focus_entered()`
- For these controls, do NOT connect `focus_entered` — use `on_row_focus_entered()` instead

### Color Names
- `Accessibility.get_color_name_from_palette(ramp_index)` returns color name
- `COLOR_NAMES` dictionary covers indices 0-17 (artificial) and 19-23 (skin)
- `ArrowOptionList._get_accessibility_value_text()` auto-detects color fields by checking "color"/"colour" in field name or node name

### Settings Debounce
- `announce_setting_changed()` is debounced at 0.2 seconds to prevent rapid-fire announcements when holding arrow keys on sliders

### Field Label Detection
- `_get_field_label(control)` finds the label for a control by checking previous sibling, then walking up the tree
- `_translate_label(text)` tries `Loc.tr()` then `tr()` then strips `UI_SETTINGS_`/`UI_` prefixes as fallback

---

## ACCESSIBILITY.GD KEY FUNCTIONS

```gdscript
# Core speech
speak(text: String, interrupt: bool = true)
speak_queued(text: String)
stop()
clear_speech_queue()

# State tracking
set_dialogue_playing(playing: bool)

# Specialized announcers
announce_dialogue(speaker: String, text: String)
announce_menu(menu_name: String)
announce_focus(control: Control)
announce_setting_changed(control: Control)
announce_item(item_name, amount, equipped, rarity)
announce_tape_info(tape_name, species_name, types, hp_percent, is_broken, grade)
announce_cassette_obtained(tape_name, species_name)
announce_naming_screen(title, current_name)
announce_list_item(item, index, total, color_index)
get_color_name_from_palette(ramp_index: int) -> String

# Private helpers (avoid calling from outside Accessibility.gd)
_get_field_label(control: Control) -> String
_translate_label(text: String) -> String
_clean_text(text: String) -> String
```

---

## FILES MODIFIED (as of 2026-03-15)

### Core
- `global/Accessibility.gd` — Main TTS singleton

### Nodes
- `nodes/menus/ArrowOptionList.gd` — Row focus TTS + color name detection
- `nodes/message_dialog/MessageDialog.gd` — Dialogue TTS
- `nodes/message_dialog/MenuDialog.gd` — Dialogue options TTS

### Settings
- `menus/settings/GameplayPanel.gd` — AI Smartness + Level Scaling TTS with description
- `menus/settings/AudioPanel.gd` — Audio settings TTS
- `menus/settings/GraphicsPanel.gd` — Graphics settings TTS
- `menus/settings/SettingsMenu.gd` — Tab switching TTS

### Title Screen
- `menus/title/TitleMenu.gd` — Title screen announcement
- `menus/title/TitleMenuButton.gd` — Button focus TTS
- `menus/title/FileMenu.gd` — Save slot menu TTS
- `menus/title/FileButton.gd` — Save slot info TTS
- `menus/title/SplashScreen.gd` — Mod warning TTS
- `menus/title/GameModeMenu.gd` — Game mode menu TTS
- `menus/title/LanguageMenu.gd` — Language menu TTS

### Character Creation
- `menus/character_creation/CharacterCreationMenu.gd` — Full character creation TTS

### Battle UI
- `battle/ui/cassette_player/CassettePlayer3D.gd`
- `battle/ui/cassette_player/CassetteButton.gd`
- `battle/ui/MoveButton.gd`
- `battle/ui/TargetButton.gd`
- `battle/ui/FightOrderSubmenu.gd`
- `battle/ui/TargetOrderSubmenu.gd`
- `battle/ui/StatusEffectIconNode.gd`
- `battle/ui/FusionLabelBanner.gd`
- `battle/ui/TurnTitleBanner.gd`
- `battle/ui/BattleToast_Default.gd`
- `battle/ui/BattleToast_RecordingChance.gd`
- `battle/ui/cassette_player/FusionMeter.gd`

### Menus
- `menus/BaseMenu.gd`
- `menus/party/TapeButton.gd`
- `menus/party/PartyMemberButton.gd`
- (see ACCESSIBILITY_MOD_STATUS.md for full list)

---

## KNOWN ISSUES / TODO

### Needs Testing
- Character creation TTS (new this session)
- Language menu TTS (new this session)
- Game mode menu TTS (new this session)
- All title screen fixes (new this session)

### Not Yet Implemented
- Intro cutscenes / tutorial TTS (`cutscenes/intro/`)
- Map/pause menu map markers
- Some multiplayer menus (trade, battle request)
- Character creation: colour fields announce correctly via palette lookup

---

## WORKFLOW FOR NEW SESSION

1. **Read this document** to understand the project
2. **Read `ACCESSIBILITY_MOD_STATUS.md`** for detailed status
3. Upload both zip files from the repo so Claude has full context
4. **Make changes** to files in `C:\CassetteBeasts-Decompiled\`
5. **Move changed files** to repo and repack using commands above
6. **Test** by launching the game
7. **Commit** changes to the git repo

---

## VERSION INFO

- **Current Mod Version:** 0.8.0
- **Last Session:** 2026-03-15
