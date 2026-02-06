---
layout: default
title: Skins Config
parent: Configuration
nav_order: 3
---

# soccer_mod_skins.cfg

Defines player skins available for selection in-game.
{: .fs-6 .fw-300 }

{: .important }
This file **must be edited manually** with a text editor.

---

## File Format

```
"Skins"
{
    "Skin Name"
    {
        "CT"    "path/to/ct/model.mdl"
        "T"     "path/to/t/model.mdl"
        "CTGK"  "path/to/ct/goalkeeper.mdl"
        "TGK"   "path/to/t/goalkeeper.mdl"
    }
}
```

---

## Example Configuration

```
"Skins"
{
    "Termi 2011"
    {
        "CT"    "models/player/soccer_mod/termi/2011/away/ct_urban.mdl"
        "T"     "models/player/soccer_mod/termi/2011/home/ct_urban.mdl"
        "CTGK"  "models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl"
        "TGK"   "models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl"
    }
    "PSL Blue"
    {
        "CT"    "models/player/psl/blue/ct_urban.mdl"
        "T"     "models/player/psl/red/ct_urban.mdl"
        "CTGK"  "models/player/psl/blue_gk/ct_urban.mdl"
        "TGK"   "models/player/psl/red_gk/ct_urban.mdl"
    }
    "Classic"
    {
        "CT"    "models/player/soccer_mod/classic/away/ct_urban.mdl"
        "T"     "models/player/soccer_mod/classic/home/ct_urban.mdl"
        "CTGK"  "models/player/soccer_mod/classic/gkaway/ct_urban.mdl"
        "TGK"   "models/player/soccer_mod/classic/gkhome/ct_urban.mdl"
    }
}
```

---

## Key Descriptions

| Key | Description |
|-----|-------------|
| `CT` | Counter-Terrorist team player model |
| `T` | Terrorist team player model |
| `CTGK` | CT goalkeeper model (used with `!gk`) |
| `TGK` | T goalkeeper model (used with `!gk`) |

---

## Adding New Skins

1. **Install the model files** to your server:
   - Models go in `cstrike/models/player/...`
   - Materials go in `cstrike/materials/models/player/...`

2. **Add to skins config** with a descriptive name

3. **Add to downloads config** so clients get the files:
   ```
   soccer_mod_downloads_add_dir materials\models\player\your_skin
   soccer_mod_downloads_add_dir models\player\your_skin
   ```

4. **Select in-game** via `!madmin` > Settings > Skin Settings

---

## Troubleshooting

### Skins Not Showing

1. Verify `sv_pure 0` is set in server.cfg
2. Check model paths are correct (case-sensitive on Linux)
3. Ensure files are in downloads config
4. Verify model files exist on server

### Players See ERROR Model

- Model file is missing or path is wrong
- Check server console for "model not precached" errors

### GK Skin Not Working

- Verify CTGK/TGK paths are set
- Only one player per team can use GK skin
- Player must use `!gk` command to toggle
