# Soccer Mod Menu Reorganization Plan

## Goal
Eliminate the bloated "Misc Settings" menu (17 items) by distributing items into new focused subcategories, while keeping the existing Admin > Settings structure intact.

---

## Current Admin > Settings Structure

```
Admin > Settings
├── Manage Admins (RCON)
├── Allowed Maps
├── Public Mode
├── Misc Settings ← 17 ITEMS - NEEDS BREAKUP
│   ├── Team Size
│   ├── Class Choice
│   ├── Load Map Defaults
│   ├── Remove Ragdoll
│   ├── DuckJumpBlock
│   ├── Kickoff Wall
│   ├── -> Kickoff Walls Setup
│   ├── Hostname Info
│   ├── First 12 Rule
│   ├── !rank Cooldown
│   ├── Ready Check
│   ├── Damage Sound
│   ├── Killfeed
│   ├── GK saves only
│   ├── Ranking Mode
│   ├── Celebration
│   ├── Join/Leave Notify
│   └── Join/Leave Volume
├── Skin Settings
├── Chat Settings
├── Sound Control
├── Training Settings (RCON)
├── Shout Control
├── Lock Settings
└── Debugging
```

---

## Proposed Admin > Settings Structure

```
Admin > Settings
├── Manage Admins (RCON) ← unchanged
├── Allowed Maps ← unchanged
├── Public Mode ← unchanged
├── Match Settings ← NEW (from Misc)
│   ├── Team Size (2v2-6v6)
│   ├── Ready Check (OFF/AUTO/ON USE)
│   └── First 12 Rule (OFF/ON/Pre-Cap Join)
├── Gameplay Settings ← NEW (from Misc)
│   ├── DuckJumpBlock (OFF/v1/v2/v3)
│   ├── Kickoff Wall (ON/OFF)
│   ├── -> Kickoff Walls Setup
│   ├── Damage Sound (ON/OFF)
│   ├── GK saves only (ON/OFF)
│   └── Celebration (ON/OFF)
├── Visual Settings ← NEW (from Misc)
│   ├── Remove Ragdoll (OFF/Remove/Dissolve)
│   ├── Killfeed (ON/OFF)
│   ├── Hostname Info (ON/OFF)
│   └── Class Choice (ON/OFF)
├── Stats & Ranking ← NEW (from Misc)
│   ├── Ranking Mode (pts/matches, pts/rounds, pts)
│   ├── !rank Cooldown (numeric)
│   └── Load Map Defaults (ON/OFF)
├── Notifications ← NEW (from Misc)
│   ├── Join/Leave Notify (ON/OFF)
│   └── Join/Leave Volume (float)
├── Skin Settings ← unchanged
├── Chat Settings ← unchanged
├── Sound Control ← unchanged
├── Training Settings (RCON) ← unchanged
├── Shout Control ← unchanged
├── Lock Settings ← unchanged
└── Debugging ← unchanged
```

---

## Migration Table

| Current Location | Setting | New Location |
|------------------|---------|--------------|
| Misc Settings | Team Size | Match Settings |
| Misc Settings | Ready Check | Match Settings |
| Misc Settings | First 12 Rule | Match Settings |
| Misc Settings | DuckJumpBlock | Gameplay Settings |
| Misc Settings | Kickoff Wall | Gameplay Settings |
| Misc Settings | Kickoff Walls Setup | Gameplay Settings |
| Misc Settings | Damage Sound | Gameplay Settings |
| Misc Settings | GK saves only | Gameplay Settings |
| Misc Settings | Celebration | Gameplay Settings |
| Misc Settings | Remove Ragdoll | Visual Settings |
| Misc Settings | Killfeed | Visual Settings |
| Misc Settings | Hostname Info | Visual Settings |
| Misc Settings | Class Choice | Visual Settings |
| Misc Settings | Ranking Mode | Stats & Ranking |
| Misc Settings | !rank Cooldown | Stats & Ranking |
| Misc Settings | Load Map Defaults | Stats & Ranking |
| Misc Settings | Join/Leave Notify | Notifications |
| Misc Settings | Join/Leave Volume | Notifications |

---

## Implementation Steps

### 1. Create new menu functions in `settings.sp`
- `OpenMenuMatchSettings(int client)`
- `OpenMenuGameplaySettings(int client)`
- `OpenMenuVisualSettings(int client)`
- `OpenMenuStatsSettings(int client)`
- `OpenMenuNotificationSettings(int client)`

### 2. Create menu handlers for each
- `MenuHandlerMatchSettings`
- `MenuHandlerGameplaySettings`
- `MenuHandlerVisualSettings`
- `MenuHandlerStatsSettings`
- `MenuHandlerNotificationSettings`

### 3. Update `OpenMenuSettings()`
- Remove "miscset" menu item
- Add new menu items: "matchset", "gameplayset", "visualset", "statsset", "notifyset"

### 4. Remove/deprecate `OpenMenuMiscSettings()`
- Can be deleted once migration is complete

### 5. Update back button navigation
- All new submenus should have `ExitBackButton = true`
- Back should return to `OpenMenuSettings(client)`

---

## Files to Modify

- `addons/sourcemod/scripting/soccer_mod/modules/settings.sp`
  - Add 5 new menu functions
  - Add 5 new menu handlers
  - Modify `OpenMenuSettings()` to add new items and remove Misc
  - Remove `OpenMenuMiscSettings()` and `MenuHandlerMiscSettings()`

---

## Status

- [x] Create `OpenSettingsMatch()` + handler (renamed to avoid collision with match.sp)
- [x] Create `OpenSettingsGameplay()` + handler
- [x] Create `OpenSettingsVisual()` + handler
- [x] Create `OpenSettingsStats()` + handler
- [x] Create `OpenSettingsNotifications()` + handler
- [x] Update `OpenMenuSettings()` with new items
- [x] Remove old Misc Settings code
- [ ] Test all menus and navigation
- [x] Update version and changelog (v1.4.22)
