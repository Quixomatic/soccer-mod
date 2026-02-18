---
layout: default
title: Join/Leave Sounds
parent: Configuration
nav_order: 8
---

# soccer_mod_joinleave.cfg

Configures sounds played when players join or leave the server.
{: .fs-6 .fw-300 }

{: .important }
This file **must be edited manually** with a text editor.

---

## Purpose

When enabled (Admin > Settings > Notifications), the plugin plays sounds and shows chat messages when players connect or disconnect. This file defines which sound files to use.

---

## File Format

```
"JoinLeave"
{
    "join_sound"    "soccermod/joinleave/join.wav"
    "leave_sound"   "soccermod/joinleave/leave.wav"
}
```

| Setting | Description |
|---------|-------------|
| `join_sound` | Sound file path played when a player joins (relative to `cstrike/sound/`) |
| `leave_sound` | Sound file path played when a player leaves (relative to `cstrike/sound/`) |

---

## Setup

1. Place your sound files in `cstrike/sound/soccermod/joinleave/` (or any `sound/` subdirectory)
2. Edit this config to point to the files
3. Add the sound directory to `soccer_mod_downloads.cfg`:
   ```
   soccer_mod_downloads_add_dir sound\soccermod\joinleave
   ```
4. Enable in-game: Admin > Settings > Notifications > Join/Leave Notify

---

## Player Preferences

Players can individually toggle join/leave notifications in their Settings menu:
- Chat notifications (on by default)
- Sound notifications (off by default)

Volume is controlled by the admin via Settings > Notifications > Join/Leave Volume.

---

## Tips

- Sounds are off by default for players (opt-in)
- If a sound file doesn't exist, the plugin handles it gracefully (no errors)
- Keep sound files short — they play on every connect/disconnect
