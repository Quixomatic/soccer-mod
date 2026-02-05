# Soccer Mod Complete Installation & Configuration Guide

A comprehensive guide for installing and configuring Soccer Mod on Counter-Strike: Source servers.

## Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Configuration Files](#configuration-files)
5. [Admin Setup](#admin-setup)
6. [Match System](#match-system)
7. [Cap Fights](#cap-fights)
8. [Training Features](#training-features)
9. [Skins](#skins)
10. [Stats & Ranking](#stats--ranking)
11. [Commands Reference](#commands-reference)
12. [Troubleshooting](#troubleshooting)

---

## Overview

Soccer Mod transforms Counter-Strike: Source into a soccer/football game with extensive features:

- **Match Mode**: Configurable periods, breaks, golden goal, readychecks
- **Cap Fights**: Team picking system with knife fights
- **Training Tools**: Ball cannons, goal targets, cones, spawnable props
- **Referee System**: Yellow/red cards, score manipulation
- **Sprint System**: Customizable speed boost with cooldown
- **Skins**: Team skins with goalkeeper variants, changeable in-game
- **Stats & Ranking**: Goals, assists, saves, passes tracking
- **Server Lock**: Automatic password protection during caps
- **Shouts**: Customizable sound effects players can trigger

**GitHub**: https://github.com/Quixomatic/soccer-mod

---

## Requirements

### Server Requirements
- MetaMod:Source 1.12+
- SourceMod 1.12+

### Optional Dependencies
- **SteamWorks** - Changes game name in server browser to "CS:S Soccer Mod"

### Files You Need
- Soccer Mod plugin and assets (from GitHub releases)
- Soccer maps (e.g., `ka_soccer_stadium_2019_b1.bsp`)
- Player skins

---

## Installation

### Step 1: Download Release

Download the latest release from [GitHub Releases](https://github.com/Quixomatic/soccer-mod/releases).

### Step 2: Extract Files

Extract the release zip to your CS:S server's `cstrike/` directory:

```
cstrike/
├── addons/sourcemod/plugins/soccer_mod.smx
├── cfg/sm_soccermod/
├── materials/
├── models/
└── sound/
```

### Step 3: Install Maps

Copy soccer maps to your `maps/` directory.

### Step 4: Restart Server

```bash
# Docker
docker restart css-server

# Standalone
./srcds_run -game cstrike +map ka_soccer_stadium_2019_b1
```

Soccer Mod automatically generates config files on first start.

### Step 5: Verify Installation

In-game console:
```
sm plugins list
```
Should show `soccer_mod.smx` loaded.

---

## Configuration Files

All configs are auto-generated in `cfg/sm_soccermod/` on first run.

### Main Config: `soccer_mod.cfg`

Controls most plugin settings:

| Section | Purpose |
|---------|---------|
| Admin Settings | Public mode, server lock, AFK kick, matchlog |
| Chat Settings | Prefix, colors, MVP messages, dead chat |
| Match Settings | Period length, break length, golden goal, team names |
| Sprint Settings | Speed, duration, cooldown |
| Current Skins | Active skin paths for CT/T/GK |
| Stats Settings | Point values for ranking |
| Training Settings | Ball model, advanced training options |

**Most settings are editable in-game via `!madmin` > Settings.**

### Map List: `soccer_mod_allowed_maps.cfg`

Maps listed here activate Soccer Mod features and appear in the map change menu:

```
ka_soccer_stadium_2019_b1
ka_soccer_trainer
ka_soccer_xsl_stadium_b1
```

### Downloads: `soccer_mod_downloads.cfg`

Controls what files clients download on join:

```cfg
// Skins
soccer_mod_downloads_add_dir materials\models\player\soccer_mod
soccer_mod_downloads_add_dir models\player\soccer_mod

// Training ball model
soccer_mod_downloads_add_dir materials\models\soccer_mod
soccer_mod_downloads_add_dir models\soccer_mod
```

### GK Areas: `soccer_mod_GKAreas.cfg`

Defines goalkeeper zones for save tracking. Use `!gksetup` in-game or manually edit:

```cfg
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
}
```

### Skins: `soccer_mod_skins.cfg`

Defines selectable skins:

```cfg
"Skins"
{
    "Termi"
    {
        "CT"        "models/player/soccer_mod/termi/2011/away/ct_urban.mdl"
        "T"         "models/player/soccer_mod/termi/2011/home/ct_urban.mdl"
        "CTGK"      "models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl"
        "TGK"       "models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl"
    }
}
```

---

## Admin Setup

### SourceMod Admins

Edit `addons/sourcemod/configs/admins_simple.ini`:

```ini
"STEAM_0:1:12345678" "99:z"  // Full Admin (z = root)
```

Flags:
- `b` - Generic admin (access most Soccer Mod features)
- `m` - RCON level (password commands, admin management)
- `z` - Root (full access)

### Soccer Mod Admins

For players with limited access. Add via `!madmin` > Settings > Manage Admins.

Modules: match, cap, training, referee, spec, mapchange

### Public Mode

Controls who can access admin features:
- `0` - Admin only
- `1` - Public cap/match access (recommended)
- `2` - Full public menu

---

## Match System

### Starting a Match

1. `!match` - Open match menu
2. Configure settings (period length, break, golden goal)
3. Select "Start Match"

Or use `!start` command.

### Match Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Period Length | 900s (15min) | Duration of each half |
| Break Length | 60s | Halftime break |
| Periods | 2 | Number of periods |
| Golden Goal | On | Continue if tied |

### Match Controls

| Command | Description |
|---------|-------------|
| `!start` | Start match |
| `!stop` | Stop match |
| `!pause` / `!p` | Pause match |
| `!unpause` / `!up` | Unpause match |
| `!matchrr` | Restart match |

---

## Cap Fights

Team picking system where captains fight to determine pick order.

### Starting a Cap

1. `!cap` - Open cap menu
2. "Put all players to spectator"
3. "Add random player" (x2) - Assigns captains
4. "Start cap fight" - Begins knife fight

### How It Works

1. Captains spawn with knives, 101 HP
2. First to kill opponent wins
3. Winner picks first from player list
4. Players use `!pos` to indicate preferred position
5. Captains alternate picking

---

## Training Features

Access via `!training` or `!madmin` > Training.

### Ball Cannon

Shoots balls for goalie training:
- Set position and aim
- Adjust power, fire rate, randomness

### Spawnable Props

- Extra practice balls
- Goal targets
- Static/dynamic cones

---

## Skins

### Changing Skins

Admins: `!madmin` > Settings > Skin Settings
Players: `!gk` to toggle goalkeeper skin

### Installing Skins

1. Copy models/ and materials/ to server
2. Add to `soccer_mod_skins.cfg`
3. Add to `soccer_mod_downloads.cfg`

---

## Stats & Ranking

### Point Values

| Action | Points |
|--------|--------|
| Goal | +17 |
| Assist | +12 |
| Own Goal | -10 |
| Save | +6 |
| MVP | +15 |

### Commands

| Command | Description |
|---------|-------------|
| `!stats` | View statistics |
| `!rank` | Match rank |
| `!prank` | Public rank |

---

## Commands Reference

### Public Commands

| Command | Description |
|---------|-------------|
| `!soccer` | Main menu |
| `!pos` | Select position (during cap) |
| `!stats` | View statistics |
| `!gk` | Toggle GK skin |
| `!rank` | Show rank |
| `!help` | Help menu |

### Admin Commands

| Command | Description |
|---------|-------------|
| `!madmin` | Admin menu |
| `!match` | Match menu |
| `!cap` | Cap menu |
| `!training` | Training menu |
| `!ref` | Referee menu |
| `!start` | Start match |
| `!stop` | Stop match |

---

## Troubleshooting

### Plugin Not Loading

Check logs for errors:
```bash
docker logs css-server | grep -i "soccer\|error"
```

### Skins Not Showing

1. Set `sv_pure 0`
2. Verify files exist
3. Check `soccer_mod_downloads.cfg`

### Saves Not Tracking

1. Set up GK areas via `!gksetup`
2. Verify map entry in `soccer_mod_GKAreas.cfg`

### Commands Not Working

1. Verify you're on an allowed map
2. Check admin permissions
3. Check public mode setting
