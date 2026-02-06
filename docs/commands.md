---
layout: default
title: Commands
nav_order: 4
---

# Commands Reference

All chat and console commands available in Soccer Mod.
{: .fs-6 .fw-300 }

Commands can be used in chat with `!` or `.` prefix, or in console with `sm_` prefix.

---

## Public Commands

### Menu Commands

| Command | Description |
|---------|-------------|
| `!menu` | Opens the Soccer Mod main menu |
| `!soccer` | Alias for `!menu` |
| `!pick` | Re-opens the pick menu during captain picking |
| `!stats` | Opens the statistics menu |
| `!pos` | Opens the positions menu (during cap) |
| `!help` | Opens the help menu |
| `!admins` | Shows currently active admins |
| `!commands` | Opens the command list menu |
| `!info` | Opens the credits menu |

### Match Commands

| Command | Description |
|---------|-------------|
| `!rank` | Shows your match ranking in chat |
| `!prank` | Shows your public ranking in chat |
| `!forfeit` | Starts a forfeit vote (if enabled) |

### Ready Check Commands

| Command | Description |
|---------|-------------|
| `!r` / `!rdy` / `!ready` | Mark yourself as ready |
| `!nr` / `!notready` | Mark yourself as not ready |
| `!show` | Show the ready check panel |
| `!hide` | Hide the ready check panel |

### Timeout Commands

| Command | Description |
|---------|-------------|
| `!to` | Call a timeout (pauses match, starts ready check) |
| `!ti` | Time-in (end timeout if you called it) |

### Voting Commands

| Command | Description |
|---------|-------------|
| `!vote` | Re-open the captain vote menu |

### Utility Commands

| Command | Description |
|---------|-------------|
| `!gk` | Toggle goalkeeper skin |
| `!lc` / `!late` | Show join order list |
| `!profile <name>` | Open player's Steam profile in MOTD |
| `!spec me/all/<name>` | Spectate yourself, everyone, or a player |
| `!whois` / `!whois <name>` | Look up player info |
| `!alias <name>` | Set your display alias |

---

## Admin Commands

### Menu Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!madmin` | Generic (b/z) or SoccerMod Admin (menu) | Opens the admin menu |
| `!cap` | Generic (b/z) or SoccerMod Admin (cap) | Opens the cap menu |
| `!match` | Generic (b/z) or SoccerMod Admin (match) | Opens the match menu |
| `!training` | Generic (b/z) or SoccerMod Admin (training) | Opens the training menu |
| `!ref` | Generic (b/z) or SoccerMod Admin (referee) | Opens the referee menu |
| `!soccerset` | Generic (b/z) | Opens the settings menu |

### Match Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!start` | Generic (b/z) or SoccerMod Admin (match) | Starts a match |
| `!stop` | Generic (b/z) or SoccerMod Admin (match) | Stops a match |
| `!pause` / `!p` | Generic (b/z) or SoccerMod Admin (match) | Pauses a match |
| `!unpause` / `!unp` / `!up` | Generic (b/z) or SoccerMod Admin (match) | Unpauses a match |
| `!matchrr` | Generic (b/z) or SoccerMod Admin (match) | Restarts the match |
| `!rr` | Generic (b/z) or SoccerMod Admin (match) | Restarts the round |

### Cap Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!autocap` / `!pug` | Generic (b/z) | Starts auto captain selection |
| `!stopcap` | Generic (b/z) | Stops the current cap fight |
| `!resetcap` | Generic (b/z) | Resets the cap system |
| `!startpick` | Generic (b/z) | Skip knife fight, go to picking |

### Ready Check Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!forceready` | Generic (b/z) | Force all players ready |
| `!cancelready` | Generic (b/z) | Cancel ready check |
| `!forcerdy` | RCON (m/z) | Force ready (legacy) |
| `!forceunp` | RCON (m/z) | Force unpause (legacy) |

### General Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!maprr` | Generic (b/z) or SoccerMod Admin (mapchange) | Reloads the current map |

### Password Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!pass <password>` | RCON (m/z) | Set custom server password |
| `!rpass` | RCON (m/z) | Set random server password |
| `!dpass` | RCON (m/z) | Reset to default password |

### Admin Management

| Command | Requires | Description |
|---------|----------|-------------|
| `!addadmin <steamid> <flags> <name>` | RCON (m/z) | Add a SourceMod admin |

### Utility Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!gksetup` | RCON (m/z) | Open GK area setup panel |
| `!ungk <target>` | Generic (b/z) | Remove GK skin from player/team |
| `!spray` | Generic (b/z) | Remove spray logo you're looking at |
| `!aim` | RCON (m/z) | Get coordinates for replacer configs |
| `!whois_history` / `!history` | Generic (b/z) | View player name history |

### Dangerous Commands

| Command | Requires | Description |
|---------|----------|-------------|
| `!wiperanks` | RCON (m/z) | Reset ALL stats to 0. **Not reversible!** |
| `!jumptime <time>` | ROOT (z) | Set duck-jump reset time (default: 0.45) |

---

## Admin Flags Reference

| Flag | Level | Access |
|------|-------|--------|
| `b` | Generic | Most Soccer Mod features |
| `m` | RCON | Password commands, admin management |
| `z` | Root | Full access to everything |

### SoccerMod Admin Modules

For players with limited access (configured via `!madmin` > Settings > Manage Admins):

- `match` - Match controls
- `cap` - Captain system
- `training` - Training mode
- `referee` - Referee tools
- `spec` - Spectate commands
- `mapchange` - Map changing

---

## Command Aliases

Many commands have multiple aliases:

| Primary | Aliases |
|---------|---------|
| `!menu` | `!soccer` |
| `!pause` | `!p` |
| `!unpause` | `!unp`, `!up` |
| `!ready` | `!r`, `!rdy` |
| `!notready` | `!nr` |
| `!late` | `!lc` |
| `!autocap` | `!pug` |
| `!timeout` | `!to` |
| `!timein` | `!ti` |
