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

| File | Type | Description |
|------|------|-------------|
| [soccer_mod.cfg]({% link configuration/main-config.md %}) | Auto/In-game | Main configuration with most settings |
| [soccer_mod_allowed_maps.cfg]({% link configuration/allowed-maps.md %}) | Auto/In-game | Maps that activate Soccer Mod features |
| [soccer_mod_downloads.cfg]({% link configuration/downloads.md %}) | **Manual** | Files clients download on join |
| [soccer_mod_skins.cfg]({% link configuration/skins.md %}) | **Manual** | Available player skins |
| [soccer_mod_GKAreas.cfg]({% link configuration/gk-areas.md %}) | In-game | Goalkeeper zones for save tracking |
| [soccer_mod_mapdefaults.cfg]({% link configuration/map-defaults.md %}) | **Manual** | Per-map default settings |
| soccer_mod_admins.cfg | Auto/In-game | Soccer Mod specific admin access |
| soccer_mod_matchlog.cfg | Auto/In-game | Match logging settings |
| soccer_mod_positions.cfg | Storage | Player position preferences (do not edit) |
| soccer_mod_personal.cfg | Storage | Personal cannon settings (do not edit) |
| soccer_mod_last_match.cfg | Storage | Last match log data (do not edit) |

---

## Configuration Types

### Auto-Generated
Created automatically on first run. Safe to delete - will regenerate with defaults.

### In-Game Editable
Can be changed via `!madmin` > Settings menu. Changes are saved automatically.

### Manual Edit Required
Must be edited with a text editor. These files control content that can't be easily managed in-game.

### Storage Files
Used internally to store data. **Do not edit manually** - you may corrupt data.

---

## Quick Setup Checklist

1. **Add your maps** to `soccer_mod_allowed_maps.cfg`
2. **Configure downloads** in `soccer_mod_downloads.cfg` for skins/sounds
3. **Set up skins** in `soccer_mod_skins.cfg`
4. **Configure GK areas** using `!gksetup` in-game
5. **Set map defaults** in `soccer_mod_mapdefaults.cfg` (optional)

Most other settings can be adjusted in-game via the admin menu.
