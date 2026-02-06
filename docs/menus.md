---
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
│  │  ├─ Start cap fight (weapon)
│  │  ├─ Stop cap fight
│  │  ├─ Start picking
│  │  ├─ Reset cap
│  │  ├─ Snake draft toggle
│  │  └─ Cap weapon choice
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
│     ├─ Misc Settings (^)
│     │  ├─ Class Choice Toggle
│     │  ├─ Load Map Defaults Toggle
│     │  ├─ Remove Ragdoll Toggle
│     │  ├─ Duckjump Block Toggle
│     │  ├─ Kickoff Wall Toggle
│     │  ├─ Hostname Updater Toggle
│     │  ├─ First12 Rule Toggle
│     │  ├─ Team Size
│     │  ├─ Rank Cooldown Setting
│     │  ├─ Readycheck Toggle
│     │  ├─ Damage Sound Toggle
│     │  ├─ Killfeed Toggle
│     │  ├─ GK Saves Only Toggle
│     │  ├─ Rankmode Toggle
│     │  ├─ Celebration Toggle
│     │  └─ Join/Leave Notifications
│     ├─ Skin Settings (^)
│     ├─ Chat Settings (^)
│     ├─ Sound Control (^)
│     ├─ Lock Settings (^)
│     ├─ Shout Settings (^)
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
│  └─ Guide
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
