---
layout: default
title: Configuration
nav_order: 5
has_children: true
---

# Configuration Files

Soccer Mod creates configuration files automatically on first start.
{: .fs-6 .fw-300 }

All config files are located in `cfg/sm_soccermod/`.

---

## File Overview

### Editable Configuration Files

| File | Type | Description |
|------|------|-------------|
| [soccer_mod.cfg]({% link configuration/main-config.md %}) | Auto/In-game | Main configuration with most settings |
| [soccer_mod_allowed_maps.cfg]({% link configuration/allowed-maps.md %}) | Auto/In-game | Maps that activate Soccer Mod features |
| [soccer_mod_downloads.cfg]({% link configuration/downloads.md %}) | **Manual** | Files clients download on join |
| [soccer_mod_skins.cfg]({% link configuration/skins.md %}) | **Manual** | Available player skins |
| [soccer_mod_GKAreas.cfg]({% link configuration/gk-areas.md %}) | In-game | Goalkeeper zones for save tracking |
| [soccer_mod_mapdefaults.cfg]({% link configuration/map-defaults.md %}) | **Manual** | Per-map default settings |
| [soccer_mod_kickoffwalls.cfg]({% link configuration/kickoff-walls.md %}) | In-game | Per-map kickoff wall positions and radius |
| [soccer_mod_joinleave.cfg]({% link configuration/joinleave.md %}) | **Manual** | Join/leave notification sound paths |
| [soccer_mod_shoutlist.cfg]({% link configuration/shouts.md %}) | In-game | Available shout/emote sounds |
| [soccer_mod_admins.cfg]({% link configuration/admins.md %}) | Auto/In-game | Soccer Mod specific admin access |
| [soccer_mod_replacer.cfg]({% link configuration/grass-replacer.md %}) | **Manual** | Grass replacer texture settings |

### Storage Files (Do Not Edit)

These files are used internally to store data. **Do not edit manually.**

| File | Description |
|------|-------------|
| soccer_mod_matchlogsettings.cfg | Match logging settings |
| soccer_mod_personalCannonSettings.cfg | Personal cannon user preferences |
| soccer_mod_shoutsettings.cfg | Shout system settings (radius, cooldown, volume, pitch) |
| soccer_mod_mutes.cfg | Active vote mutes (SteamID + expiry) |
| soccer_mod_cap_positions.txt | Captain position data |
| soccer_mod_referee_cards.txt | Referee card records |
| soccer_mod_last_match.txt | Last match log |
| soccer_mod_dclist.txt | Disconnect tracking list |

### Subdirectories

| Directory | Description |
|-----------|-------------|
| `logs/` | Match log files (`match_<teams>_<timestamp>.txt`) |
| `grassreplacer/` | Per-map grass replacer configs (`<mapname>.cfg`) |

### Optional Server Config Files

These are standard CS:S server configs that Soccer Mod will execute if they exist:

| File | When Executed |
|------|---------------|
| `cfg/soccer.cfg` | When loading an allowed soccer map |
| `cfg/non_soccer.cfg` | When loading a non-soccer map |
| `cfg/soccer_match.cfg` | When a match starts |
| `cfg/soccer_public.cfg` | When a match ends/resets |

---

## Configuration Types

### Auto-Generated
Created automatically on first run. Safe to delete — will regenerate with defaults.

### In-Game Editable
Can be changed via `!madmin` > Settings menu. Changes are saved automatically.

### Manual Edit Required
Must be edited with a text editor. These files control content that can't be easily managed in-game.

### Storage Files
Used internally to store data. **Do not edit manually** — you may corrupt data.

---

## Quick Setup Checklist

1. **Add your maps** to `soccer_mod_allowed_maps.cfg`
2. **Configure downloads** in `soccer_mod_downloads.cfg` for skins/sounds
3. **Set up skins** in `soccer_mod_skins.cfg`
4. **Configure GK areas** using `!gksetup` in-game
5. **Set map defaults** in `soccer_mod_mapdefaults.cfg` (optional)
6. **Configure kickoff walls** using `!kickoffwalls` in-game (optional)

Most other settings can be adjusted in-game via the admin menu.
