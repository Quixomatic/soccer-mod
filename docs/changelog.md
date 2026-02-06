---
title: Changelog
nav_order: 10
---

# Changelog

Version history for Soccer Mod.
{: .fs-6 .fw-300 }

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
- Admin menu: Settings > Misc > Team Size submenu
- Vote menu auto-reopens if closed without voting
- Added `!pug` as alias for `!autocap`

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

---

## 1.4.8

### New
- Integrated WhoIS player tracking system as built-in module
- Tracks player names across sessions with first name, current name, and alias support
- Connect announcements: "Known as: [alias/first name]" for returning players
- Welcome message for new players
- `!whois` / `.whois` - Look up player info
- `!alias <name>` / `.alias` - Set your preferred display alias
- `!whois_history` / `.history` - Admin command to view player name history

---

## 1.4.7

### New
- Added visual HUD display during captain voting with progress bars
- Vote HUD shows: YES/NO bars, percentages, vote counts, countdown timer
- HUD refreshes every second during voting phase

### Changes
- Enhanced chat messages with colors throughout cap system
- Team colors: red for T, blue for CT
- Player names highlighted in green
- Vote pass/fail messages now colored

---

## 1.4.6

### New
- Added reusable Ready Check system with panel display
- Pre-match ready check auto-starts after cap picking completes
- Countdown timer (configurable, default 60s)
- Ready commands: `!r`, `!rdy`, `!ready`
- Not ready commands: `!nr`, `!notready`
- Timeout system: `!to` pauses match and starts ready check
- Time-in commands: `!ti` (caller or admin can end timeout)
- Admin commands: `!forceready`, `!cancelready`
- Panel visibility: `!hide`, `!show`

### Changes
- Fixed snake draft pick order

---

## 1.4.5

### New
- Added Auto Cap system (`!autocap`) - automated captain selection with voting
- Random captain selection from players
- Server-wide vote: "Start cap fight with X vs Y?"
- Vote menu shows current status, allows changing vote
- Ready-up phase for captains (`!k` or `.k` to ready)
- HUD display shows captain ready status

---

## 1.4.4

### New
- Added cap control commands: `!stopcap`, `!resetcap`, `!startpick`
- Added snake draft pick order (configurable)
- Added "Stop cap fight" option in cap menu
- Captain disconnect now auto-resets the cap system

---

## 1.4.3

### New
- Added configurable cap fight starting health via in-game settings menu
- New menu option under Cap settings to set health

---

## 1.4.2

### Changes
- Rebranded from "SoMoE-19" to "Soccer Mod"
- Updated plugin info and repository URLs

---

## 1.4.1

### Changes
- Fixed include paths for cross-platform compatibility
- Added GitHub Actions workflow for automated releases

---

## 1.4.0

### New
- Added `sv_alltalk` automatic toggle: turns off when match starts
- Executes `soccer_match.cfg` on match start and `soccer_public.cfg` on match end

### Changes
- Updated for SourcePawn 1.12 compatibility

---

For older versions, see the [full changelog](https://github.com/Quixomatic/soccer-mod/blob/main/CHANGELOG.md) on GitHub.
