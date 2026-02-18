---
layout: default
title: Shouts
parent: Configuration
nav_order: 9
---

# soccer_mod_shoutlist.cfg

Defines available shout/emote sounds players can trigger.
{: .fs-6 .fw-300 }

{: .tip }
Shouts can be managed entirely in-game via Admin > Settings > Shout Settings > Shout Manager.

---

## Purpose

Shouts are short sound clips players can play in-game from the Shouts menu. They are positional (other players hear them from your location) with configurable radius, cooldown, volume, and pitch.

---

## File Format

```
"Shouts"
{
    "Shout Display Name"    "path/to/sound.wav"
    "Another Shout"         "path/to/other.wav"
}
```

Paths are relative to `cstrike/sound/`.

---

## Example

```
"Shouts"
{
    "Goal!"         "soccermod/shouts/goal.wav"
    "Nice Save"     "soccermod/shouts/save.wav"
    "Olé"           "soccermod/shouts/ole.wav"
}
```

---

## Managing Shouts

### In-Game (Recommended)

Admin > Settings > Shout Settings:
- **Shout Manager** — Add, edit, rename, or remove shouts
- **Radius** — How far shouts can be heard
- **Cooldown** — Time between shouts per player
- **Volume** — Shout playback volume
- **Pitch** — Shout playback pitch

### Manual

Edit `soccer_mod_shoutlist.cfg` directly. One entry per shout.

---

## Setup

1. Place sound files in `cstrike/sound/soccermod/shouts/` (or any subdirectory)
2. Add shouts via the in-game manager or edit the config
3. Add the sound directory to `soccer_mod_downloads.cfg`:
   ```
   soccer_mod_downloads_add_dir sound\soccermod\shouts
   ```

---

## Player Settings

Players can toggle shout playback in their personal Settings menu (Shout Toggle).
