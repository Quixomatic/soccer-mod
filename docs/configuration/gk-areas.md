---
title: GK Areas
parent: Configuration
nav_order: 5
---

# soccer_mod_GKAreas.cfg

Defines goalkeeper zones for save tracking on each map.
{: .fs-6 .fw-300 }

---

## Purpose

Goalkeeper areas determine where "saves" are counted. When a player blocks a shot while standing in the GK area, they earn save points.

{: .tip }
Use the `!gksetup` command in-game for an interactive setup experience.

---

## File Format

```
"gk_areas"
{
    "map_name"
    {
        "ct_min_x"      "-313"
        "ct_max_x"      "313"
        "ct_min_y"      "-1379"
        "ct_max_y"      "-1188"
        "ct_min_z"      "0"
        "ct_max_z"      "120"
        "t_min_x"       "-313"
        "t_max_x"       "313"
        "t_min_y"       "1188"
        "t_max_y"       "1379"
        "t_min_z"       "0"
        "t_max_z"       "120"
    }
}
```

---

## Example Configuration

```
"gk_areas"
{
    "ka_soccer_stadium_2019_b1"
    {
        "ct_min_x"      "-313"
        "ct_max_x"      "313"
        "ct_min_y"      "-1379"
        "ct_max_y"      "-1188"
        "ct_min_z"      "0"
        "ct_max_z"      "120"
        "t_min_x"       "-313"
        "t_max_x"       "313"
        "t_min_y"       "1188"
        "t_max_y"       "1379"
        "t_min_z"       "0"
        "t_max_z"       "120"
    }
    "ka_soccer_xsl_stadium_b1"
    {
        "ct_min_x"      "-400"
        "ct_max_x"      "400"
        "ct_min_y"      "-2000"
        "ct_max_y"      "-1800"
        "ct_min_z"      "0"
        "ct_max_z"      "150"
        "t_min_x"       "-400"
        "t_max_x"       "400"
        "t_min_y"       "1800"
        "t_max_y"       "2000"
        "t_min_z"       "0"
        "t_max_z"       "150"
    }
}
```

---

## Understanding Coordinates

The GK area is a 3D box defined by min/max coordinates:

| Axis | Description |
|------|-------------|
| X | Left/Right (width of goal area) |
| Y | Forward/Back (depth from goal line) |
| Z | Up/Down (height of area) |

### Finding Coordinates

1. Use `!gksetup` in-game (recommended)
2. Use `cl_showpos 1` in console to see your position
3. Stand at corners of desired area and note coordinates

---

## Using !gksetup

The easiest way to configure GK areas:

1. Join the map as admin
2. Type `!gksetup` in chat
3. A panel shows current area settings
4. Stand at corners of the GK box
5. Follow the on-screen prompts to set boundaries

The command draws laser beams to visualize:
- Goal positions
- Current GK area boundaries
- Field orientation

---

## Tips

- GK areas should cover the goal mouth plus a small buffer
- Don't make areas too large or non-GK players will "steal" saves
- Height (Z) should cover jumping goalkeepers
- Each map needs its own configuration

---

## Related Settings

In `soccer_mod.cfg`:

```
"soccer_mod_gksaves_only"    "0"
```

- `0` = Anyone in GK area can earn saves
- `1` = Only players with GK skin earn saves
