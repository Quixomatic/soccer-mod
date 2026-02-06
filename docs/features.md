---
layout: default
title: Features
nav_order: 3
---

# Features

A comprehensive list of features included in Soccer Mod.
{: .fs-6 .fw-300 }

---

## Match System

- **Start/Stop/Pause/Unpause** matches with commands or menu
- **Customizable match settings:**
  - Period length (default 15 minutes)
  - Break length between periods
  - Number of periods
  - Golden goal toggle for overtime
  - Forfeit vote system
- **Match event logging** with automatic log file generation
- **Score control** for referees
- **Ready check system** before match start and after timeouts
- **Timeout system** (`!to`) with ready checks to resume

---

## Captain System

- **Auto Cap** (`!autocap` / `!pug`) - Automated captain selection with server-wide voting
- **Captain voting** - Players vote yes/no on proposed captain pairs
- **Auto-retry** - Failed votes automatically try new captain combinations
- **First N Rule** - Only first N players to join are eligible as captains
- **Knife fights** (or other weapons) to determine pick order
- **Snake draft picking** - Fair pick order with compensation picks
- **Positions menu** (`!pos`) - Players indicate preferred positions during picking
- **Server lock** - Automatic password protection during cap fights

---

## Training Mode

- **Global ball cannon** - Shoots balls for goalie training
  - Set position and aim
  - Adjust power, fire rate, randomness
- **Personal cannons** - Each player can have their own cannon
- **Spawnable props:**
  - Extra practice balls
  - Goal targets (single/multi mode)
  - Static and dynamic cones
- **Advanced training mode** with password protection
- **Toggle goal triggers** on/off

---

## Referee Tools

- **Yellow cards** - Warnings with visual indicator
- **Red cards** - Player removal from match
- **Card management** - Remove individual or all cards
- **Score manipulation** - Adjust team scores manually

---

## Sprint System

Customizable speed boost ability:

- **Duration** - How long sprint lasts
- **Cooldown** - Time between sprints
- **Speed multiplier** - How fast players move
- **Auto-bind** option to `+use` key
- **Client-side indicators:**
  - Sound effect
  - Chat message
  - HUD timer (customizable position & color)
  - Defuse bar style

---

## Skins System

- **Team skins** - Different models for CT and T
- **Goalkeeper skins** - Special GK variants
- **In-game skin changing** via admin menu
- **GK toggle** (`!gk`) - Players can switch to goalkeeper skin
- **One GK per team** limit
- **Skin configuration** via `soccer_mod_skins.cfg`

---

## Stats & Ranking

- **Tracked statistics:**
  - Goals, Assists, Own Goals
  - Saves (requires GK area setup)
  - Passes, Interceptions
  - Rounds won/lost
  - MVP awards
- **Two ranking modes:**
  - Match ranking (competitive games only)
  - Public ranking (all play)
- **Database support** for persistence
- **Customizable point values** for each action
- **Top 50 leaderboards**

---

## WhoIS System

- **Player tracking** across sessions
- **Name history** - Tracks all names a player has used
- **Alias support** - Players can set preferred display name
- **Connect announcements** - "Known as: [alias]" for returning players
- **Admin commands:**
  - `!whois` - Look up player info
  - `!whois_history` - View name history

---

## Join/Leave Notifications

- **Chat notifications** when players join or leave
- **Player count display** (e.g., "11/12 players")
- **"Ready to play!"** message when server reaches capacity
- **Per-player preferences** for chat and sound notifications
- **Admin controls** for global toggle and volume

---

## Server Management

- **Public mode settings:**
  - Admin only (0)
  - Public cap/match access (1)
  - Full public menu (2)
- **AFK kicker** during server lock
- **Hostname status updates** showing match state
- **Class selection screen** toggle
- **Duck-jump prevention** toggle
- **Dead chat** (cross-team communication when dead)
- **Damage sounds** toggle
- **Killfeed** toggle
- **Ragdoll handling** options

---

## Shout System

- **Customizable sound effects** players can trigger
- **Shout modes:**
  - Global (everyone hears)
  - Radius-based (nearby players only)
- **Cooldown settings** (global and per-shout)
- **Volume and pitch control**
- **Shout manager** for adding/removing sounds
- **Per-client toggle** to disable hearing shouts

---

## Map Features

- **Per-map defaults** for:
  - Period length
  - Break length
  - Team size (2v2, 3v3, 4v4, 5v5, 6v6)
  - Kickoff walls
- **Kickoff walls** - Invisible barriers at kickoff
- **Grass replacer** - Custom field textures
- **Automatic map orientation detection**

---

## Miscellaneous

- **Join order tracking** (`!lc` / `!late`) with tolerance for reconnects
- **Admin online list** (`!admins`)
- **Steam profile lookup** (`!profile <name>`)
- **Spectate commands** (`!spec me/all/<name>`)
- **Map reload** (`!maprr`)
- **Match restart** (`!matchrr`)
- **Configurable chat prefix and colors**
- **MVP messages** with star indicators
- **Overtime countdown warnings** with sounds

---

{: .note }
This list may not be exhaustive. Soccer Mod is actively developed with new features added regularly. See the [Changelog]({% link changelog.md %}) for recent additions.
