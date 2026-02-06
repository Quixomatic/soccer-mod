# Soccer Mod Changelog

## 1.4.15

### New
- Added `!fug` as alias for `!forfeit` command

### Changes
- Updated help menu with all current commands (mystats, autocap/pug, forfeit/fug, ready commands, timeout commands, whois, alias)
- Updated Git URL to https://github.com/Quixomatic/soccer-mod
- Updated documentation URL to https://quixomatic.github.io/soccer-mod/
- Updated credits page URL to https://quixomatic.github.io/soccer-mod/credits.html

---

## 1.4.14

### New
- Added stats URL integration for external stats websites
- Server command `soccer_mod_stats_url` to configure base stats URL
- `!mystats` command opens player's stats page in MOTD panel
- Stats URL uses SteamID3 format: `{baseUrl}/motd/[U:1:XXXXX]`

---

## 1.4.13

### Fixes
- Fixed database config not loading from `cfg/sourcemod/soccer_mod.cfg`
- Added `AutoExecConfig()` to ensure `soccer_mod_database_config` is set on plugin load
- Plugin now properly connects to MariaDB/MySQL when configured

---

## 1.4.12

### Fixes
- Fixed kickoff walls not loading on maps due to float equality comparison bug
- Map orientation detection now uses tolerance-based comparison (xDiff vs yDiff)

---

## 1.4.11

### New
- Configurable team size (2v2, 3v3, 4v4, 5v5, 6v6)
- Config setting: `soccer_mod_match_max_players` in Match Settings
- Map defaults support: `default_max_players` per map
- Admin menu: Settings → Misc → Team Size submenu
- Vote menu auto-reopens if closed without voting

### Changes
- Team size affects autocap, picking, join/leave notifications, First N rule
- Simplified vote HUD (removed percentage numbers)
- Debug mode now bypasses First 12 rule for captain eligibility

---

## 1.4.10

### New
- Auto-retry failed captain votes with new random captain pairs
- Generates all unique captain combinations and shuffles them at start
- Tries each unique pair in random order (no repeats until all tried)
- After all combinations exhausted, switches to purely random selection
- Shows remaining combinations count during voting
- 2-second delay between failed vote and next attempt
- Respects First 12 rule for captain eligibility

### Changes
- Vote HUD now uses ASCII characters for consistent alignment
- Captain selection properly filters by join order (First 12 rule)

---

## 1.4.9

### New
- Added Join/Leave notification system
- Chat notifications when players join or leave the server
- Shows player count vs required players (e.g., "11/12 players")
- Special "Ready to play!" message when server reaches capacity
- Per-player preferences for chat and sound notifications (via Settings menu)
- Sounds off by default (opt-in), chat on by default
- Admin controls in Misc Settings: global toggle and volume control
- Configurable sounds via `cfg/sm_soccermod/soccer_mod_joinleave.cfg`
- Graceful handling when sound files don't exist

### Config
- New config file: `soccer_mod_joinleave.cfg` with sound paths and volume settings
- Updated `EXAMPLE_soccer_mod_downloads.cfg` with joinleave sounds folder

---

## 1.4.8

### New
- Integrated WhoIS player tracking system as built-in module
- Tracks player names across sessions with first name, current name, and alias support
- Connect announcements: "Known as: [alias/first name]" for returning players
- Welcome message for new players
- `!whois` / `.whois` - Look up player info (name, alias, SteamID, connections, admin status)
- `!alias <name>` / `.alias` - Set your preferred display alias
- `!whois_history` / `.history` - Admin command to view player name history (last 10 names)
- Player selection menu when using commands without arguments
- IP address shown only to admins in whois lookup

### Database
- Added `whois_players` table (steamid, first_name, current_name, alias, ip, timestamps, connection count)
- Added `whois_names` table (name history with first/last used timestamps)

---

## 1.4.7

### New
- Added visual HUD display during captain voting with progress bars
- Vote HUD shows: YES/NO bars, percentages, vote counts, countdown timer
- HUD refreshes every second during voting phase

### Changes
- Enhanced chat messages with colors throughout cap system
- Green checkmarks (✓) for success, red X (✗) for failures
- Team colors: red for T, blue for CT
- Player names highlighted in green
- Vote pass/fail messages now colored

---

## 1.4.6

### New
- Added reusable Ready Check system with panel display
- Pre-match ready check auto-starts after cap picking completes
- Countdown timer (configurable, default 60s) - match starts when all ready OR countdown expires
- Ready commands: `!r`, `!rdy`, `!ready`, `.r`, `.rdy`, `.ready` (or press 1 on panel)
- Not ready commands: `!nr`, `.nr`, `.notready` (or press 2 on panel)
- Timeout system: `!to` / `.to` pauses match and starts ready check
- Time-in commands: `!ti` / `.ti` (caller or admin can end timeout)
- Admin commands: `!forceready` (force proceed), `!cancelready` (cancel without proceeding)
- Panel visibility: `!hide` / `.hide` and `!show` / `.show`
- Panel shows all players by team with ready status, refreshes every second

### Changes
- Fixed snake draft pick order: normal alternating (W-L-W-L...), loser gets back-to-back at end, winner gets last pick
- Ready check config options: `readyCheckPrematchCountdown`, `readyCheckTimeoutCountdown`

---

## 1.4.5

### New
- Added Auto Cap system (`!autocap`) - automated captain selection with voting
- Random captain selection from players
- Server-wide vote: "Start cap fight with X vs Y?" (need >50% yes to pass)
- Vote menu shows current status, allows changing vote, can be re-opened with `!vote`
- Early vote ending when outcome is guaranteed
- Ready-up phase for captains (`!k` or `.k` to ready)
- HUD display shows captain ready status
- Knife fight starts automatically when both captains ready

### Changes
- Fixed timer handle crash when stopping/resetting cap fight during countdown
- Improved vote system with vote tracking per player

---

## 1.4.4

### New
- Added cap control commands: `!stopcap`, `!resetcap`, `!startpick`
- Added snake draft pick order (configurable, default ON) - second picker gets compensation picks
- Added "Stop cap fight" option in cap menu (visible when fight is active)
- Added "Start picking" option to skip knife fight and go directly to picking
- Added "Reset cap" option for full cap system reset
- Added "Snake draft: ON/OFF" toggle in cap menu
- Captain disconnect now auto-resets the cap system to prevent stuck states

### Changes
- Refactored pick handler to use snake draft logic
- Timer handles now stored for proper cleanup on reset/stop
- Cap system tracks pick number for snake draft pattern

---

## 1.4.3

### New
- Added configurable cap fight starting health via in-game settings menu
- New menu option under Cap settings to set health (101, 100, 50, 1, or custom value)
- Cap fight health is saved to config file

---

## 1.4.2

### Changes
- Rebranded from "SoMoE-19" to "Soccer Mod"
- Updated plugin info and repository URLs
- Cleaned up README

---

## 1.4.1

### Changes
- Fixed include paths to use forward slashes for cross-platform compatibility (Windows/Linux)
- Fixed `SteamWorks.inc` typeset array syntax for SourcePawn 1.12
- Added GitHub Actions workflow for automated releases

---

## 1.4.0

### New
- Added `sv_alltalk` automatic toggle: turns off when match starts, restores when match ends
- Executes `soccer_match.cfg` on match start and `soccer_public.cfg` on match end/reset

### Changes
- Updated for SourcePawn 1.12 compatibility
- Fixed array parameter syntax in `afkkicker.sp` (`float v1[3]` instead of `float[3] v1`)
- Fixed `GetOffsetPos` in `training_adv.sp` to use output parameter instead of returning array
- Fixed `GetNames` in `savelogs.sp` to use output parameter instead of returning array
- Fixed `Hook_UserMessage` callback signature in `deadchat.sp` for newer SourceMod API
- Fixed int/char type conversions in `client_commands.sp` using `view_as<int>()`

---

## 1.3.7.1

### New
- Added Pre-Cap-Join option to First12 Toggle
- Added notification if a player that shouldn't be allowed to play joins a team / gets forced
- Added `!aim` command to find out coordinates to use with replacer configs
- Added optional (default ON) sound & text notification before a period ends
- Added option to disable the 'overtime-sound' only
- Added option to set custom sounds for the overtime countdown via config
- Added per client toggleable chat/hud information
- Added per client toggleable grassreplacer
- Added per client toggleable shout playing
- Added option to spawn a ball at mapstart if the map features a certain entity

### Changes
- Removed match reset at mapstart - `sm_maprr;sm_start` combination should work again
- Debug mode can be toggled from the menu now
- Main menu now leads to Settings submenu instead of directly to the sprintsettings

### Fixes
- More fixes to joinlist
- Minor fixes

---

## 1.3.1

### New
- Added First 12 Rule toggle
- Added Grassreplacer

### Fixes
- Fixes to joinlist
- Minor fixes

---

## 1.3.0 BETA

### New
- Added Advanced Training Mode (Lockable with a password in settings)
- Added Training Mode
- Added spawnable training props (Can, Hoop, Plate)
- Added option to spawn static or dynamic cones
- Added 2 target training modes (configurable ball respawn)
- Added `!profile <name>` command to quickly display the steamprofile of a target
- Added `!spec` command
- Added built-in Shout support

### Changes
- Minor cleanup
- Added cancel option to some cannon settings

### Fixes
- Fixed Duckjumpblock v3

---

## 1.2.9.x

### New
- Added weaponchoice for capfights (1.2.9.3)
- Added random option to capfight weapon selection (1.2.9.4)
- Added third alternative duckjump-block method (1.2.9.6)
- Added option to enable celebration weapons after scoring a goal (1.2.9.6)
- Added toggleable invisible walls at kickoff (1.2.9.7)
- Added top3 player display at halftime (1.2.9.7)
- Added Mapsound control (Disable / Enable ambient_generic sounds per map) (1.2.9.7)

### Changes
- Caps won't lose their knife if the weapon of choice is a gun (1.2.9.3 fix)
- Cap HP during a HE-Grenade fight set to 98 to allow 1-hit kills (1.2.9.3 fix)
- Removed Smokegrenade from capfight weapon selection (1.2.9.4)
- Improved toggleable walls at kickoff (laser indicating borders, coloring) (1.2.9.7)
- Changed final matchmessage to show top3 instead of only MOTM (1.2.9.7)

### Fixes
- Fixed sprint config section resetting (1.2.9.1)
- Fixed sprint re-enabling itself after a cap fight even if it was disabled (1.2.9.2)
- Fixed "set position"-Spam at capstart if no position set (1.2.9.4)
- Fixed misplaced duckjump-reset function (1.2.9.5)

---

## 1.2.9

### New
- Added option to track only saves done by a player using the gk skin
- Added admin command `!ungk <target>` (`<target>` can be either a player or t/ct)
- Added match tracking for ranking based on matches
- Added 2 alternative commands: `!late` (same as `!lc`), `!up` (same as `!unp` / `!unpause`)
- Added new preferred duckjumpblock-mode with 3 settings: OFF, ON, ON (NEW)
- Added ROOT command to adjust resettime for new duckjumpblock

### Changes
- `!gk` limited to one player per team
- Ranking can now be sorted by either pure pts, pts/matches or pts/rounds
- Changed rank reset options to set every value to 0 instead of deleting the row
- Stats will only count in matches if both teams have 5 players at the end of the round
- Added join number to pick menu
- Added join number message for each player when cap fight starts
- Added GK skin check prior to setting GK skin

### Fixes
- Fixed `!pos` menu being displayed everytime a cap is started
- Fixes to rounds won / lost tracking
- Fixed gk skin being locked if a gk skin user joins spectator before leaving
- Fixed issues with `!spray` command
- Added missing ball entity check

---

## 1.2.8

### New
- Added option to the help menu to print the url of documentation and github project in console
- Added option to the help menu to open documentation in the motd
- Added command to adjust GK areas ingame (`!gksetup`; requires RCON-flag)
- Added option to disable the killfeed (Always enabled during capfights)
- Added command to 'remove' spraylogos (`!spray`; requires GENERIC-flag)

### Changes
- Saves only count if the last hit before the gk's was done by an opponent now
- Reworked credits menu
- Reworked help menu

### Fixes
- Fixed hostname status not being applied after `!matchrr` usage
- Fixed stoppage time not working properly on maps rotated by 90 degrees
- Fixed `!pos` menu being displayed everytime a cap is started

---

## 1.2.7

### New
- Added `!lc` command to provide an accurate overview of the join order
- Adjustable rr tolerance to be used in conjunction with `!lc`
- Added optional hostname statuses displaying various states
- Added optional cooldown for `!rank` usage
- Added (requires Steamworks extension) a custom game description
- Added optional and configurable map defaults for periods, periodlength and breaklength
- Added option to change teamnames for the upcoming match only
- Added optional class selection screen disabler

### Changes
- Reorganized settings and its submenus

### Fixes
- Minor fixes

---

## 1.2.6

### Changes
- `!rank` command divided into 2 commands: `!rank` for match rankings and `!prank` for public rankings

### Fixes
- Various fixes related to ranking & statistics

---

## 1.2.3 - 1.2.5

### Fixes
- Fixes to customizable sprint timer added in 1.2.3

---

## 1.2.2

### New
- Added Duckjump toggle to settings menu

### Changes
- Adjustments to the duckjump toggle command according to the menu changes

---

## 1.2.1

### Changes
- Changes to the admin menu

---

## 1.2.0

### Changes
- Global ballcannon should no longer ask to select a ball if there is a soccer ball found in the map

---

## 1.1.6

### New
- Added modular permissions for soccermod admins

### Fixes
- Various minor fixes

---

## 1.1.5

### Fixes
- Various text fixes
- Other minor fixes

---

## 1.1.4

### New
- Added option to remove ragdolls after playerdeath

### Changes
- Changes to soundhandling
- Changed default lockset value to 0

---

## 1.1.2 - 1.1.3

### Fixes
- Various minor fixes

---

## 1.1.1

### New
- Added customizable Hud-Timer displaying sprint duration & cooldown

### Fixes
- Fixed Unpause not working after pausing the game for 5 minutes
- Other minor fixes
