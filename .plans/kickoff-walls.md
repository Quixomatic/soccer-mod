# Kickoff Wall System Documentation

## Overview

The kickoff wall system creates invisible barriers and laser lines around the ball spawn point at the start of each round. These walls prevent players from crossing into the opponent's half until the ball is kicked.

## Key Files

| File | Purpose |
|------|---------|
| `globals.sp:57` | Defines `mapBallStartPosition[3]` variable |
| `globals.sp:46` | Defines `xorientation` boolean for field orientation |
| `globals.sp:58-59` | Defines `vec_tgoal_origin[3]` and `vec_ctgoal_origin[3]` for goal positions |
| `globals.sp:94` | Defines `KickoffWallSet` toggle (1 = enabled) |
| `gkareas.sp:1-129` | `GetFieldOrientation()` - captures ball position and determines field orientation |
| `kickoffwall.sp` | All wall creation logic: `KickOffWall()`, `CreateInvisWall()`, `CreateInvisWallCircleX()`, `KickOffLaser()`, `KillWalls()` |
| `match.sp:39-80` | `MatchEventRoundStart()` - triggers wall creation |
| `soccer_mod.sp:1584-1619` | `DrawLaser()` - creates `env_beam` entities for visual lines |

## Flow: How Kickoff Walls Are Created

### 1. Map Start - Ball Position Capture

When the map loads, `GetFieldOrientation()` in `gkareas.sp` is called:

```c
// gkareas.sp:31-45
int soccerball_id = GetEntityIndexByName("ball", "func_physbox");
if (soccerball_id == -1) soccerball_id = GetEntityIndexByName("ball", "prop_physics");
if (soccerball_id == -1) soccerball_id = GetEntityIndexByName("ballon", "func_physbox");
if (soccerball_id == -1) soccerball_id = GetEntityIndexByName("ballon", "prop_physics");
if (soccerball_id != -1) GetEntPropVector(soccerball_id, Prop_Send, "m_vecOrigin", mapBallStartPosition);
```

This saves the ball's starting position to `mapBallStartPosition[3]`.

### 2. Map Start - Field Orientation Detection

The same function determines which way the field runs by comparing goal positions:

```c
// gkareas.sp:65-84
GetEntPropVector(goaltrig_t_ref, Prop_Data, "m_vecAbsOrigin", vec_tgoal_origin);
GetEntPropVector(goaltrig_ct_ref, Prop_Data, "m_vecAbsOrigin", vec_ctgoal_origin);

float xDiff = FloatAbs(vec_tgoal_origin[0] - vec_ctgoal_origin[0]);
float yDiff = FloatAbs(vec_tgoal_origin[1] - vec_ctgoal_origin[1]);

// If X coords are similar (goals on same X plane), field runs along Y axis (xorientation)
if (xDiff < yDiff) {
    xorientation = true;  // Field runs along Y axis
} else {
    xorientation = false; // Field runs along X axis
}
```

**Goal detection entity names searched:**
- T goal: `terro_But` (trigger_once), `goal_t` (trigger_once), `Terro_but` (trigger_multiple)
- CT goal: `ct_But` (trigger_once), `goal_ct` (trigger_once), `ct_but` (trigger_multiple)

### 3. Round Start - Wall Creation

When a round starts:

```
EventRoundStart() [soccer_mod.sp:1140]
    └── MatchEventRoundStart() [match.sp:39]
            └── KickOffWall() [kickoffwall.sp:59]
                    ├── CreateInvisWall() [kickoffwall.sp:378]
                    │       └── KickOffLaser() [kickoffwall.sp:565]
                    │               └── DrawLaser() [soccer_mod.sp:1584]
                    └── CreateInvisWallCircleX() [kickoffwall.sp:420] (if wall model exists)
```

### 4. Ball Touch - Walls Destroyed

When the ball is touched (waking the physics entity):

```
MatchOnAwakened() [match.sp:5-17]
    └── KillWalls() [kickoffwall.sp:354]
```

Also destroyed on round end: `MatchEventRoundEnd()` → `KillWalls()`

## Wall Types

### Main Walls (wallminus, wallplus)
- Two large walls spanning the entire field width
- Gap in the middle for the kickoff circle/box
- Colored by defending team (red = T blocked, blue = CT blocked)

### Kickoff Box (boxside1, boxside2, boxback)
- Small box around the ball spawn for the kicking team
- Only kicking team can enter until ball is touched

### Circle Walls (wallcircle)
- If `models/soccer_mod/wall.mdl` exists, uses curved wall segments
- Creates a semicircle instead of rectangular box

## Visual Lasers

All walls call `KickOffLaser()` which draws `env_beam` lines:
- Red (255 0 0) for T-side barriers
- Blue (0 0 255) for CT-side barriers

Laser positions are calculated as offsets from `mapBallStartPosition`:
```c
DrawLaser(targetname, mapBallStartPosition[0]+minX, mapBallStartPosition[1]+minY, ...)
```

---

## Known Issues / Bugs Found

### 1. Y-orientation Circle Walls Not Implemented

**File:** `kickoffwall.sp:214`

```c
else //yorient
{
    // TODO: WallCircle
```

The Y-orientation branch has a TODO comment and only uses rectangular fallbacks, never circle walls. `CreateInvisWallCircleY()` exists (lines 493-562) but is commented out.

### 2. Y-orientation CT Starts - Wrong Wall Coordinates

**File:** `kickoffwall.sp:323`

```c
// When CT starts and matchToss == CS_TEAM_CT in Y-orientation:
CreateInvisWall(130.0, 0.0, -1000.0, 4000.0, 0.0, 3000.0, "wallplus", 1, CS_TEAM_CT);
```

This uses X-axis style coordinates (`130.0, 4000.0` on X-axis) but should use Y-axis style like the rest of the Y-orientation code (`0.0, 130.0` ... `0.0, 4000.0`).

**Compare to correct Y-orientation wall (line 288):**
```c
CreateInvisWall(0.0, 130.0, -1000.0, 0.0, 4000.0, 1300.0, "wallplus", 1, CS_TEAM_T);
```

### 3. Y-orientation T Starts - Inconsistent Team Assignments

**File:** `kickoffwall.sp:305-314`

```c
else if (vec_tgoal_origin[0] > vec_ctgoal_origin[0]) //t- ct
{
    CreateInvisWall(-130.0, -130.0, 0.0, 0.0, -130.0, 1300.0, "boxside1", 2, CS_TEAM_CT);  // <-- Wrong team!
    CreateInvisWall(-130.0, 130.0, 0.0, 0.0, 130.0, 1300.0, "boxside2", 3, CS_TEAM_T);
    CreateInvisWall(-130.0, -130.0, 0.0, -130.0, 130.0, 1300.0, "boxback", 4, CS_TEAM_CT);  // <-- Wrong team!
}
```

When T starts, all box walls should be CS_TEAM_T, not mixed.

### 4. Ball Position Only Captured at Map Start

**File:** `gkareas.sp:45`

The ball position is captured only once at map start. If the ball entity doesn't exist yet or is at the wrong position, `mapBallStartPosition` will be incorrect for the entire map session.

### 5. Map-Specific Overrides May Be Outdated

**File:** `kickoffwall.sp:66-68`

```c
if(StrEqual(map, "ka_xsl_indoorcup"))       radius = 175.0;
else if(StrEqual(map, "ka_parkhead"))        radius = 350.0;
else                                          radius = 252.5;
```

And `gkareas.sp:102`:
```c
if(StrEqual(map, "ka_soccer_pvt4"))  xorientation = false;
```

These hardcoded map overrides may not match all currently used maps.

---

## Version History (from CHANGELOG.md)

### v1.4.12 - Float Equality Fix
> Fixed kickoff walls not loading on maps due to float equality comparison bug
> Map orientation detection now uses tolerance-based comparison (xDiff vs yDiff)

**What was fixed:** The old code used exact float equality (`vec_tgoal_origin[0] == vec_ctgoal_origin[0]`) which almost never works with floating point. Changed to tolerance-based comparison.

### v1.2.9.7 - Initial Implementation
> Added toggleable invisible walls at kickoff
> Improved toggleable walls at kickoff (laser indicating borders, coloring)

---

## Debugging Tips

1. **Check if ball entity is found:**
   Look for server log: `"Entity not found (BL %i, TG %i, CTG %i)"`

2. **Check orientation detection:**
   Look for: `"[Soccer Mod] Map orientation: X (xDiff=%.1f, yDiff=%.1f)"`

3. **Toggle debug mode:**
   Can be toggled from admin menu to enable additional logging

4. **Check `KickoffWallSet`:**
   Must be `1` for walls to be created. Configurable in settings menu.

5. **Verify entity names on your map:**
   Ball entities tried: `ball` (func_physbox/prop_physics), `ballon` (func_physbox/prop_physics)
   Goal triggers tried: `terro_But`, `goal_t`, `Terro_but`, `ct_But`, `goal_ct`, `ct_but`

---

## Recommended Fixes

1. **Fix Y-orientation wallplus coordinates** (line 323) - change to Y-axis pattern
2. **Fix Y-orientation team assignments** (lines 305-314) - make consistent
3. **Implement CreateInvisWallCircleY** or remove commented code
4. **Add fallback ball position capture** - retry in round start if not set
5. **Add debug command** to show current mapBallStartPosition and orientation
