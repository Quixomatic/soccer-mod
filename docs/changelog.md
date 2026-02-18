---
layout: default
title: Changelog
nav_order: 10
---

# Changelog

Version history for Soccer Mod.
{: .fs-6 .fw-300 }

---

## 1.5.11

### New
- **Warm Cache menu option**: Downloads all files from CF Workers to verify sizes without applying — pre-warms CDN cache before updating
- **Automatic retry with cache warming**: If download verification fails, waits 5 seconds (first attempt warms CF cache) and retries once before aborting

---

## 1.5.9

### Fixes
- **Cache-busting on all download URLs**: Add `?t=<timestamp>` to all HTTP requests to prevent CDN serving stale/corrupt files

---

## 1.5.8

### New
- **Remote .smx size check**: Admin menu option to verify the remote .smx file size before updating

---

## 1.5.6

### New
- **Self-updater file verification**: Downloaded files are now validated against expected file sizes from the manifest to prevent corrupt/partial updates

---

## 1.5.5

### Changes
- Clean up self-updater debug logging and test code
- Download progress messages now only visible to the admin who initiated the update

---

## 1.5.4

### Changes
- **Self-updater**: Switched file hosting to Cloudflare Workers for reliable downloads (ripext SSL compatibility)
- GitHub Action now deploys release files to Cloudflare Workers for the self-updater

---

## 1.5.3

### New
- **Self-updater**: Built-in update system using ripext extension (replaces broken GoD-Tony updater)
  - Admin menu: Settings > Updater — check for updates, download patch (.smx only) or full update (all files)
  - Fetches manifest from CDN to detect new versions via semver comparison
  - Optional auto-check on map start with configurable interval
  - ripext is an optional dependency — updater silently disabled without it
- **manifest.json**: Release manifest tracks all 87+ release files with repo-to-server path mapping

### Changes
- Removed GoD-Tony Updater plugin dependency (broken on x64 servers)
- Deleted `updater.inc` and `updatefile.txt`

---

## 1.5.1

### New
- **Chat input for vote settings**: Admin settings for thresholds, durations, cooldown, and min players now use chat input instead of cycling through presets
- **Persistent mutes across reconnects**: Vote mutes now survive disconnects and map changes — stored by SteamID with expiry timestamp

---

## 1.5.0

### New
- **Player Vote System**: Any player can initiate votes — no admin required
  - `!votekick` — vote to kick a player
  - `!voteban` — vote to ban a player (default 30 min)
  - `!votemute` — vote to mute a player (default 30 min, auto-unmutes)
  - `!votemap` — vote to change map (from allowed maps list)
  - All vote types disabled by default, enable via Admin > Settings > Player Votes
  - Configurable per-type thresholds, cooldown, and minimum players

---

## 1.4.25

### New
- **Score in hostname status**: Live match score shown in server hostname during matches

---

## 1.4.24

### New
- **Configurable Cap Vote Duration**: Vote timer for captain approval (10-30 seconds)
- **Configurable Prematch Countdown**: Ready check countdown before match start (off/15/20/30/45/60 seconds)

### Fixes
- **Fix hostname status stacking**: Hostname tags no longer stack on repeated state changes

---

## 1.4.23

### New
- **Pick Pool System**: Robust player tracking during picking phase
- **Pick Pool Mode toggle**: Admin > Cap > Pick pool mode (Legacy/Pool System)
- **Late Joiner Handling**: Players who join during picking are flagged with `[LATE]`
- **Pick HUD**: Hint text showing available players during picking phase

### Fixes
- Fixed hardcoded "12" values in cap system now use `matchMaxPlayers * 2`

---

## 1.4.22

### Changes
- Reorganized Admin > Settings menu structure for better navigation
- Replaced bloated "Misc Settings" menu with 5 focused subcategories:
  - Match Settings, Gameplay Settings, Visual Settings, Stats & Ranking, Notifications

---

## 1.4.21

### Fixes
- Fixed ready check countdown timer spam bug
- Ball entities now removed when cap/knife fight starts

---

## 1.4.20

### Changes
- `EnoughPlayers()` uses 80% threshold to handle disconnects near match end

---

## 1.4.19

### Changes
- `EnoughPlayers()` now uses `matchMaxPlayers` setting instead of hardcoded 5v5

---

## 1.4.18

### Fixes
- Fixed all 190 build warnings for clean SourcePawn 1.12 compilation
- Fixed `EnoughPlayers()` function call bug (was always returning true)

---

## 1.4.17

### Fixes
- Fixed kickoff walls for Y-orientation maps

---

## 1.4.16

### New
- Configurable kickoff walls system with per-map settings
- New config file: `soccer_mod_kickoffwalls.cfg`
- Admin menu: Settings > Kickoff Walls Setup
- Commands: `!kickoffwalls`, `!setradius`, `!setcenter`, `!kwinfo`
- Wireframe visualization and test walls feature

---

## 1.4.15

### New
- Added `!fug` as alias for `!forfeit`

### Changes
- Updated help menu with all current commands

---

## 1.4.14

### New
- Stats URL integration for external stats websites
- `!mystats` command opens player's stats page

---

## 1.4.13

### Fixes
- Fixed database config not loading

---

## 1.4.12

### Fixes
- Fixed kickoff walls not loading on maps due to float equality comparison bug

---

## 1.4.11

### New
- Configurable team size (2v2, 3v3, 4v4, 5v5, 6v6)
- `!pug` alias for `!autocap`

### Changes
- Team size affects autocap, picking, join/leave notifications, First N rule

---

## 1.4.10

### New
- Auto-retry failed captain votes with new random captain pairs

---

## 1.4.9

### New
- Join/Leave notification system with per-player preferences
- Configurable sounds via `soccer_mod_joinleave.cfg`

---

## 1.4.8

### New
- WhoIS player tracking system (`!whois`, `!alias`, `!whois_history`)

---

## 1.4.7

### New
- Visual HUD during captain voting with progress bars

---

## 1.4.6

### New
- Ready Check system with panel display
- Timeout system (`!to`, `!ti`)
- Ready commands: `!r`, `!rdy`, `!ready`

---

## 1.4.5

### New
- Auto Cap system with voting (`!autocap`)

---

## 1.4.4

### New
- Cap control commands: `!stopcap`, `!resetcap`, `!startpick`
- Snake draft pick order

---

## 1.4.3

### New
- Configurable cap fight starting health

---

## 1.4.2

### Changes
- Rebranded from "SoMoE-19" to "Soccer Mod"

---

## 1.4.1

### Changes
- Fixed include paths for cross-platform compatibility
- GitHub Actions workflow for automated releases

---

## 1.4.0

### New
- `sv_alltalk` automatic toggle
- Executes `soccer_match.cfg` / `soccer_public.cfg` on match start/end

### Changes
- Updated for SourcePawn 1.12 compatibility

---

For older versions, see the [full changelog](https://github.com/Quixomatic/soccer-mod/blob/main/CHANGELOG.md) on GitHub.
