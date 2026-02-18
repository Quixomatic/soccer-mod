---
layout: default
title: Menu Structure
nav_order: 6
---

# Menu Structure

Overview of the Soccer Mod menu system.
{: .fs-6 .fw-300 }

Open the menu with `!menu` or `!soccer` in chat.

---

## Menu Legend

- (*) Requires admin privileges OR public mode enabled
- (^) Requires SourceMod admin (generic flag)
- (°) Requires SourceMod admin (RCON flag)

---

## Full Menu Tree

```
!menu
├─ Admins (*)
│  ├─ Match (*)
│  │  ├─ Start / Stop
│  │  ├─ Pause / Unpause
│  │  ├─ Match Settings
│  │  │  ├─ Period Length
│  │  │  ├─ Break Length
│  │  │  ├─ Golden Goal
│  │  │  ├─ Matchlog Settings
│  │  │  ├─ Forfeit Vote Settings
│  │  │  ├─ Team Name Settings
│  │  │  └─ Match Info Settings
│  │  ├─ Match Log (*)
│  │  └─ Current Match Settings
│  │
│  ├─ Cap (*)
│  │  ├─ Put all players to spectator
│  │  ├─ Add random player
│  │  ├─ Auto Cap
│  │  ├─ Start cap fight (weapon)
│  │  ├─ Stop cap fight
│  │  ├─ Reset cap
│  │  └─ Debug Cap Mode
│  │
│  ├─ Referee (*)
│  │  ├─ Yellow Card
│  │  ├─ Red Card
│  │  ├─ Remove Yellow Card
│  │  ├─ Remove Red Card
│  │  ├─ Remove All Cards
│  │  └─ Score
│  │
│  ├─ Training (*)
│  │  ├─ Cannon
│  │  │  ├─ Set Cannon position
│  │  │  ├─ Set Cannon aim
│  │  │  ├─ Cannon on/off
│  │  │  └─ Settings (randomness, rate, power)
│  │  ├─ Personal Cannon
│  │  ├─ Toggle Goals
│  │  ├─ Spawn / Remove Ball
│  │  ├─ Prop Menu
│  │  └─ Advanced Training
│  │     ├─ Training Mode
│  │     ├─ Goal targets
│  │     └─ Cone Manager
│  │
│  ├─ Spec Player (*)
│  ├─ Change Map (*)
│  │
│  └─ Settings (^)
│     ├─ Manage Admins (°)
│     ├─ Allowed Maps (^)
│     ├─ Public Mode (^)
│     ├─ Match Settings (^)
│     │  ├─ Team Size (2v2 to 6v6)
│     │  ├─ Ready Check (OFF / Auto / Manual)
│     │  ├─ First 12 Rule (OFF / ON / Pre-Cap Join)
│     │  ├─ Cap Fight Health
│     │  ├─ Snake Draft toggle
│     │  ├─ Pick Pool Mode (Pool / Legacy)
│     │  ├─ Disallow Late Joiners
│     │  ├─ Cap Vote Duration
│     │  └─ Prematch Countdown
│     ├─ Gameplay Settings (^)
│     │  ├─ DuckJumpBlock (OFF / v1 / v2 / v3)
│     │  ├─ Kickoff Wall Toggle
│     │  ├─ Kickoff Walls Setup
│     │  ├─ Damage Sound Toggle
│     │  ├─ GK Saves Only Toggle
│     │  └─ Celebration Toggle
│     ├─ Visual Settings (^)
│     │  ├─ Remove Ragdoll (OFF / Remove / Dissolve)
│     │  ├─ Killfeed Toggle
│     │  ├─ Hostname Info Toggle
│     │  └─ Class Choice Toggle
│     ├─ Stats & Ranking (^)
│     │  ├─ Ranking Mode (pts/matches, pts/rounds, pts)
│     │  ├─ !rank Cooldown
│     │  └─ Load Map Defaults Toggle
│     ├─ Notifications (^)
│     │  ├─ Join/Leave Notify Toggle
│     │  └─ Join/Leave Volume
│     ├─ Skin Settings (^)
│     ├─ Chat Settings (^)
│     │  ├─ Chat Style (Prefix, Prefix Color, Text Color)
│     │  ├─ MVP Messages Toggle
│     │  └─ Deadchat Settings
│     ├─ Sound Control (^)
│     │  ├─ Disable / Enable Sounds
│     │  ├─ OT Warning (OFF / ON / Sound / Text)
│     │  └─ OT Sound Toggle
│     ├─ Training Settings (^)
│     │  ├─ Password Required Toggle
│     │  ├─ Set Password
│     │  └─ Reset Time
│     ├─ Lock Settings (^)
│     │  ├─ Enable / Disable
│     │  ├─ Player Threshold
│     │  ├─ Captcha Timer
│     │  └─ Menu Timer
│     ├─ Shout Settings (^)
│     │  ├─ Shout Manager (Add / Edit / Rename / Remove)
│     │  ├─ Radius / Cooldown / Volume / Pitch
│     │  └─ Shout Path List / Help
│     ├─ Player Votes (^)
│     │  ├─ Votekick / Voteban / Votemute / Votemap Toggles
│     │  ├─ Per-type Thresholds
│     │  ├─ Ban / Mute Duration
│     │  ├─ Vote Cooldown
│     │  └─ Min Players
│     ├─ Updater (^)
│     │  ├─ Check for Updates
│     │  ├─ Download Patch Update (.smx only)
│     │  ├─ Download Full Update (all files)
│     │  ├─ Auto-Check Toggle
│     │  ├─ Check Interval
│     │  ├─ Check Remote .smx Size
│     │  └─ Warm Cache (full)
│     └─ Debugging (°)
│
├─ Ranking
│  ├─ Match Top 50
│  ├─ Public Top 50
│  ├─ Match Personal
│  ├─ Public Personal
│  ├─ Last Connected
│  └─ Reset Rank
│
├─ Statistics
│  ├─ Team CT
│  ├─ Team T
│  ├─ Player
│  ├─ Current Round
│  └─ Current Match
│
├─ Positions
│
├─ Help
│  ├─ Chat Commands
│  │  ├─ Admin Commands
│  │  └─ Public Commands
│  ├─ Open Documentation
│  └─ Print URLs
│
├─ Settings (Player)
│  ├─ Grass Replacer Toggle
│  ├─ Shout Toggle
│  ├─ Join/Leave Notifications
│  │  ├─ Chat Notifications
│  │  └─ Sound Notifications
│  └─ Sprint Settings
│     └─ Timer Settings
│
├─ Shouts
│
└─ Credits
```

---

## Quick Access Commands

Instead of navigating the menu, use these shortcuts:

| Command | Opens |
|---------|-------|
| `!madmin` | Admin menu |
| `!match` | Match menu |
| `!cap` | Cap menu |
| `!training` | Training menu |
| `!ref` | Referee menu |
| `!stats` | Statistics menu |
| `!pos` | Positions menu |
| `!help` | Help menu |
| `!soccerset` | Settings menu |
| `!rank` | Personal match ranking |
| `!prank` | Personal public ranking |
| `!autocap` / `!pug` | Start auto captain selection |
