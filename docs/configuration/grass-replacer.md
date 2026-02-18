---
layout: default
title: Grass Replacer
parent: Configuration
nav_order: 11
---

# soccer_mod_replacer.cfg

Controls the grass texture replacement system.
{: .fs-6 .fw-300 }

{: .important }
This file and per-map configs **must be edited manually**.

---

## Purpose

The grass replacer overlays custom grass/turf textures on the map's ground. This gives soccer maps a more realistic field appearance. Players can individually toggle it in their Settings menu.

---

## How It Works

1. The main config (`soccer_mod_replacer.cfg`) enables/disables the system
2. Per-map configs in `cfg/sm_soccermod/grassreplacer/<mapname>.cfg` define texture placement coordinates
3. Players see the replaced textures unless they've toggled it off

---

## Per-Map Configuration

Each map needs its own config file at:
```
cfg/sm_soccermod/grassreplacer/<mapname>.cfg
```

A `readme.cfg` file in the `grassreplacer/` directory provides format documentation and examples.

---

## Finding Coordinates

Use the `!aim` command in-game to display your current aim position coordinates. Walk around the map and note the coordinates to use in your replacer config.

---

## Player Preferences

Players can toggle the grass replacer on/off in their personal Settings menu (Grass Settings). This is a per-client preference — it doesn't affect other players.

---

## Materials

The plugin includes grass replacement materials:
- `materials/decals/soccer_mod/grassreplacer.vmt` / `.vtf` — standard grass
- `materials/decals/soccer_mod/grassreplacer_light.vmt` / `.vtf` — lighter variant

These are included in the full release package.
