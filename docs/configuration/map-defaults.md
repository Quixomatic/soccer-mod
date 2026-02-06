---
layout: default
title: Map Defaults
parent: Configuration
nav_order: 6
---

# soccer_mod_mapdefaults.cfg

Set default match settings for specific maps.
{: .fs-6 .fw-300 }

{: .important }
This file **must be edited manually** with a text editor.

---

## Purpose

Different maps may need different settings:
- Indoor maps → shorter periods, smaller teams
- Large stadiums → full 6v6, 15-minute halves
- Training maps → different configurations

When a map loads, Soccer Mod applies the defaults from this file.

---

## File Format

```
"Map Defaults"
{
    "map_name"
    {
        "default_max_players"       "6"
        "default_periodlength"      "900"
        "default_breaklength"       "5"
        "default_periods"           "2"
        "default_kickoffwall"       "0"
    }
}
```

---

## Available Settings

| Setting | Description | Example |
|---------|-------------|---------|
| `default_max_players` | Team size (2-6) | `"6"` for 6v6 |
| `default_periodlength` | Period length in seconds | `"900"` for 15 min |
| `default_breaklength` | Break between periods in seconds | `"60"` |
| `default_periods` | Number of periods | `"2"` |
| `default_kickoffwall` | Enable kickoff walls | `"0"` or `"1"` |

---

## Example Configuration

```
"Map Defaults"
{
    "ka_soccer_stadium_2019_b1"
    {
        "default_max_players"       "6"
        "default_periodlength"      "900"
        "default_breaklength"       "5"
        "default_periods"           "2"
        "default_kickoffwall"       "0"
    }
    "ka_soccer_indoor_2014"
    {
        "default_max_players"       "4"
        "default_periodlength"      "600"
        "default_breaklength"       "5"
        "default_periods"           "2"
        "default_kickoffwall"       "0"
    }
    "ka_soccer_xsl_stadium_b1"
    {
        "default_max_players"       "6"
        "default_periodlength"      "900"
        "default_breaklength"       "5"
        "default_periods"           "2"
        "default_kickoffwall"       "0"
    }
}
```

---

## Team Size Effects

The `default_max_players` setting affects:

- **Auto Cap** - Waits for correct number of players
- **Captain Picking** - Pick pool size
- **Join/Leave Notifications** - Shows "X/12 players" correctly
- **First N Rule** - Eligibility for captain selection

Common configurations:
- `"6"` = 6v6 (12 players total)
- `"5"` = 5v5 (10 players total)
- `"4"` = 4v4 (8 players total) - good for indoor maps
- `"3"` = 3v3 (6 players total)
- `"2"` = 2v2 (4 players total)

---

## Enabling Map Defaults

Make sure this is enabled in `soccer_mod.cfg`:

```
"soccer_mod_loaddefaults"    "1"
```

---

## Tips

- Only include settings you want to override
- Map names must match exactly (case-sensitive on Linux)
- Settings not specified use the global defaults from `soccer_mod.cfg`
- Test each map to verify settings apply correctly
