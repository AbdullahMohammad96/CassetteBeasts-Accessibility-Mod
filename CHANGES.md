# Title Screen Accessibility Changes

## Files Modified

### source/global/Accessibility.gd
- Fixed button text reading to use `Loc.tr()` so actual translated button names are spoken instead of raw translation keys

### source/menus/title/TitleMenuButton.gd
- Added `announce_focus(self)` on focus so each title screen button is read aloud when navigated to

### source/menus/title/TitleMenu.gd
- Added startup announcement: "Cassette Beasts. Title screen. Use arrow keys to navigate buttons, Enter to select."

### source/menus/title/FileButton.gd
- Added focus announcement for each save slot
- Reads slot number, player name, level, location for loaded saves
- Reads "empty, press Enter to start new game" for empty slots
- Reads "corrupt" or "loading" states

### source/menus/title/FileMenu.gd
- Announces "Select save file menu" when screen opens
- Announces Play, Erase, and Back button text on focus

### source/menus/title/SplashScreen.gd
- Announces mod warning dialog text if it appears at startup
