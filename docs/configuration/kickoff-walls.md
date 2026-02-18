---
layout: default
title: Kickoff Walls
parent: Configuration
nav_order: 7
---

# soccer_mod_kickoffwalls.cfg

Per-map kickoff wall positions and radius settings.
{: .fs-6 .fw-300 }

{: .tip }
Use the `!kickoffwalls` command or Admin > Settings > Gameplay > Kickoff Walls Setup to configure interactively.

---

## Purpose

Kickoff walls are invisible barriers that prevent players from crossing the midfield line during kickoff. Each map needs its own calibration since field dimensions vary.

---

## File Format

```
"KickoffWalls"
{
    "ka_soccer_stadium_2019_b1"
    {
        "center_x"      "0.0"
        "center_y"      "0.0"
        "center_z"      "0.0"
        "radius"        "500.0"
        "ball_entity"   "ball"
    }
}
```

| Setting | Description |
|---------|-------------|
| `center_x/y/z` | Center of the kickoff circle (ball spawn position) |
| `radius` | Radius of the kickoff circle |
| `ball_entity` | Entity name of the ball on this map |

---

## Setup Commands

| Command | Description |
|---------|-------------|
| `!kickoffwalls` | Open kickoff walls configuration menu |
| `!setcenter` | Stand at ball spawn, set center position |
| `!setradius` | Walk to circle edge, set radius from center |
| `!kwinfo` | Display current wall settings for this map |

---

## Setup Process

1. Load the map and type `!kickoffwalls`
2. Stand at the ball spawn point and use `!setcenter`
3. Walk to the edge of the center circle and use `!setradius`
4. Use "Test Walls" from the menu to preview the walls for 10 seconds
5. Enable kickoff walls in Admin > Settings > Gameplay > Kickoff Wall

---

## Tips

- Wireframe visualization shows center point, radius circle, and midfield line during setup
- The plugin auto-detects the ball entity, with fallback search by model
- Half-circle walls work on both X-orientation and Y-orientation maps
- Each map stores its own configuration independently
