---
title: Allowed Maps
parent: Configuration
nav_order: 4
---

# soccer_mod_allowed_maps.cfg

Lists maps where Soccer Mod features are active.
{: .fs-6 .fw-300 }

---

## File Format

One map name per line (without `.bsp` extension):

```
ka_soccer_stadium_2019_b1
ka_soccer_xsl_stadium_b1
ka_soccer_xsl_stadium_b2
ka_soccer_indoor_2014
ka_soccer_titans_club_v4
soccer_psl_breezeway_fix
```

---

## Purpose

Maps listed here:
- Activate Soccer Mod features (menus, commands, etc.)
- Appear in the in-game map change menu
- Can have per-map defaults in `soccer_mod_mapdefaults.cfg`

Maps **not** listed:
- Soccer Mod features are disabled
- Standard CS:S gameplay

---

## Managing Maps

### In-Game Method

`!madmin` > Settings > Allowed Maps
- Add Map
- Remove Map

### Manual Method

Edit the file directly, one map per line.

---

## Tips

- Map names are case-sensitive on Linux servers
- Don't include the `.bsp` extension
- Blank lines and extra whitespace are ignored
- You can add comments with `//` (may not work in all versions)
