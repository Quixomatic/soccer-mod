---
title: Installation
nav_order: 2
---

# Installation Guide

Complete setup and configuration guide for Soccer Mod on Counter-Strike: Source servers.
{: .fs-6 .fw-300 }

---

## Requirements

### Server Requirements
- MetaMod:Source 1.12+
- SourceMod 1.12+

### Optional Dependencies
- **SteamWorks** - Changes game name in server browser to "CS:S Soccer Mod"
- **MariaDB/MySQL** - For persistent stats and ranking across server restarts

### Files You Need
- Soccer Mod plugin (from [GitHub Releases](https://github.com/Quixomatic/soccer-mod/releases))
- Soccer maps (e.g., `ka_soccer_stadium_2019_b1.bsp`)
- Player skins (optional)

---

## Step 1: Download Release

Download the latest release from [GitHub Releases](https://github.com/Quixomatic/soccer-mod/releases).

---

## Step 2: Extract Files

Extract the release zip to your CS:S server's `cstrike/` directory:

```
cstrike/
├── addons/sourcemod/plugins/soccer_mod.smx
├── cfg/sm_soccermod/
├── materials/
├── models/
└── sound/
```

---

## Step 3: Install Maps

Copy soccer maps to your `maps/` directory. Popular maps include:
- `ka_soccer_stadium_2019_b1`
- `ka_soccer_xsl_stadium_b1`
- `ka_soccer_indoor_2014`

---

## Step 4: Configure Database (Optional)

For persistent stats, configure your database in `addons/sourcemod/configs/databases.cfg`:

```
"soccer_mod"
{
    "driver"    "mysql"
    "host"      "localhost"
    "database"  "sourcemod"
    "user"      "sourcemod"
    "pass"      "your_password"
}
```

---

## Step 5: Restart Server

```bash
# Docker
docker restart css-server

# Standalone
./srcds_run -game cstrike +map ka_soccer_stadium_2019_b1
```

Soccer Mod automatically generates config files on first start.

---

## Step 6: Verify Installation

In-game console:
```
sm plugins list
```

Should show `soccer_mod.smx` loaded.

Type `!menu` in chat to open the Soccer Mod menu.

---

## First Run Configuration

On first run, Soccer Mod creates these files in `cfg/sm_soccermod/`:

| File | Purpose |
|------|---------|
| `soccer_mod.cfg` | Main configuration |
| `soccer_mod_allowed_maps.cfg` | Maps that activate Soccer Mod |
| `soccer_mod_downloads.cfg` | Files clients download |
| `soccer_mod_skins.cfg` | Available player skins |
| `soccer_mod_GKAreas.cfg` | Goalkeeper zones per map |
| `soccer_mod_mapdefaults.cfg` | Per-map default settings |

See [Configuration]({% link configuration/index.md %}) for detailed explanations of each file.

---

## Troubleshooting

### Plugin Not Loading

Check logs for errors:
```bash
# Docker
docker logs css-server | grep -i "soccer\|error"

# Standalone
cat cstrike/addons/sourcemod/logs/errors_*.log
```

### Skins Not Showing

1. Set `sv_pure 0` in server.cfg
2. Verify model files exist in `models/player/soccer_mod/`
3. Check `soccer_mod_downloads.cfg` includes skin paths

### Stats Not Saving

1. Verify database connection in `databases.cfg`
2. Check SourceMod logs for SQL errors
3. Ensure database user has CREATE/INSERT/UPDATE permissions

### Commands Not Working

1. Verify you're on an allowed map (listed in `soccer_mod_allowed_maps.cfg`)
2. Check your admin permissions
3. Check public mode setting (`!madmin` > Settings > Public Mode)
