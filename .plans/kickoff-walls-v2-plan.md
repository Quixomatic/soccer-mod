# Kickoff Walls v2 - Implementation Plan

## Overview

Replace the current hardcoded kickoff wall system with a configurable, per-map system that:
1. Auto-generates a config file with detected values
2. Provides an admin menu for calibration
3. Stores map-specific settings (radius, orientation, positions)
4. Builds accurate walls based on stored data

## New Files

| File | Purpose |
|------|---------|
| `modules/kickoffwalls.sp` | New module (replaces logic in `kickoffwall.sp`) |
| `cfg/sm_soccermod/soccer_mod_kickoffwalls.cfg` | Per-map kickoff wall configuration |

## Integration with Existing Config System

Add to `createconfig.sp` in `ConfigFunc()` (around line 28):

```c
if (!FileExists(kickoffWallsConfigFile)) CreateKickoffWallsConfig();
```

Add to `globals.sp`:

```c
char kickoffWallsConfigFile[PLATFORM_MAX_PATH] = "cfg/sm_soccermod/soccer_mod_kickoffwalls.cfg";
KeyValues kvKickoffWalls;
```

## Config File Structure

```
"kickoff_walls"
{
    "ka_soccer_breezeway"
    {
        // Ball/center position (auto-detected or manual)
        "center_x"              "0.0"
        "center_y"              "0.0"
        "center_z"              "64.0"

        // Field orientation: "x" = field runs along Y axis, "y" = field runs along X axis
        "orientation"           "x"

        // Center circle radius (for half-circle walls)
        "circle_radius"         "252.5"

        // Goal positions (auto-detected from triggers)
        "t_goal_y"              "-2048.0"
        "ct_goal_y"             "2048.0"

        // Ball entity name (for maps with non-standard ball names)
        // Leave empty to use auto-detection
        "ball_entity"           ""

        // Optional: manual overrides
        "enabled"               "1"
    }

    "ka_xsl_indoorcup"
    {
        "center_x"              "0.0"
        "center_y"              "0.0"
        "center_z"              "32.0"
        "orientation"           "x"
        "circle_radius"         "175.0"
        "t_goal_y"              "-1500.0"
        "ct_goal_y"             "1500.0"
        "enabled"               "1"
    }
}
```

## Admin Menu Structure

```
Admin Menu → Settings → Kickoff Walls →
    ├── [1] View Current Map Settings
    │       Shows: ball position, orientation, radius, goal positions, ball entity name
    │
    ├── [2] Auto-Detect All
    │       Runs automatic detection and shows results
    │
    ├── [3] Set Center Circle Radius
    │       Instructions: "Walk to the edge of the center circle and press 1"
    │       Calculates distance from ball spawn to player position
    │
    ├── [4] Toggle Orientation (Currently: X)
    │       Switches between X and Y orientation
    │
    ├── [5] Calibrate Ball Position
    │       Instructions: "Stand at the ball spawn point and press 1"
    │       Saves player position as center
    │
    ├── [6] Select Ball Entity →
    │       └── Lists all detected physics entities (func_physbox, prop_physics)
    │           Shows: entity name, model name, position
    │           Select one to use as the ball for this map
    │
    ├── [7] Test Walls (Spawn Temporarily)
    │       Creates walls for 10 seconds so admin can verify positions
    │
    ├── [8] Save to Config
    │       Writes current settings to soccer_mod_kickoffwalls.cfg
    │
    └── [0] Back
```

### Ball Entity Selection Menu

When admin selects "Select Ball Entity", show a menu of all physics entities:

```
Select Ball Entity for ka_soccer_breezeway:
─────────────────────────────────────
[1] "ball" (func_physbox)
    Model: models/soccer_mod/ball_2011.mdl
    Position: 0.0, 0.0, 64.0

[2] "ballon" (prop_physics)
    Model: models/soccer/ball.mdl
    Position: 0.0, 0.0, 64.0

[3] "physics_prop_1" (prop_physics)
    Model: models/props/ball.mdl
    Position: 100.0, 200.0, 32.0

[4] Enter Custom Name...
    Opens chat prompt to type entity name manually

[0] Back
```

## Detection Logic

### Auto-Detection (On Map Start)

```
1. Find ball entity:
   a. Check config for custom "ball_entity" name for this map
   b. If not set, try standard names: "ball", "ballon"
   c. If still not found, search all physics entities for model containing "ball"
   → Store position as center_x, center_y, center_z

2. Find goal triggers (terro_But, goal_t, ct_But, goal_ct, etc.)
   → Store positions as t_goal_x/y and ct_goal_x/y

3. Determine orientation:
   - Calculate xDiff = |t_goal_x - ct_goal_x|
   - Calculate yDiff = |t_goal_y - ct_goal_y|
   - If xDiff < yDiff → orientation = "x" (goals differ in Y, field runs along Y)
   - Else → orientation = "y" (goals differ in X, field runs along X)

4. Check if map exists in config:
   - If yes: load saved values (override auto-detected)
   - If no: use auto-detected values, optionally auto-save
```

### Ball Entity Detection (Fallback Search)

If standard ball names ("ball", "ballon") aren't found, search for physics entities:

```c
void KickoffWalls_FindBallEntity()
{
    // 1. Check config for custom entity name
    char customName[64];
    kvKickoffWalls.GetString("ball_entity", customName, sizeof(customName), "");
    if (strlen(customName) > 0)
    {
        int ent = GetEntityIndexByName(customName, "func_physbox");
        if (ent == -1) ent = GetEntityIndexByName(customName, "prop_physics");
        if (ent != -1) { /* found, use it */ return; }
    }

    // 2. Try standard names
    char standardNames[][] = {"ball", "ballon", "soccer_ball", "football"};
    for (int i = 0; i < sizeof(standardNames); i++)
    {
        int ent = GetEntityIndexByName(standardNames[i], "func_physbox");
        if (ent == -1) ent = GetEntityIndexByName(standardNames[i], "prop_physics");
        if (ent != -1) { /* found */ return; }
    }

    // 3. Search all physics entities for ball-like models
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "func_physbox")) != -1)
    {
        char model[128];
        GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
        if (StrContains(model, "ball", false) != -1)
        {
            // Found a ball! Store entity name for future use
            return;
        }
    }
    // Also check prop_physics...
}
```

### Manual Radius Calibration

```
1. Admin opens "Set Center Circle Radius" menu
2. Panel shows: "Walk to the edge of the center circle, then press 1"
3. On press:
   - Get admin's current position
   - Calculate 2D distance from ball spawn (ignore Z)
   - radius = sqrt((player_x - center_x)^2 + (player_y - center_y)^2)
   - Show: "Radius set to: 252.5 units"
   - Offer to save
```

## Wall Creation Logic (Simplified)

```c
void CreateKickoffWalls(int kickingTeam)
{
    // Load map settings (from config or auto-detected)
    float center[3] = {center_x, center_y, center_z};
    float radius = circle_radius;
    bool xOrient = (orientation == "x");

    // 1. Create center line wall (blocks non-kicking team from crossing)
    if (xOrient) {
        // Wall along X axis at center_y
        CreateLineWall(center, -fieldWidth, 0, fieldWidth, 0, kickingTeam);
    } else {
        // Wall along Y axis at center_x
        CreateLineWall(center, 0, -fieldWidth, 0, fieldWidth, kickingTeam);
    }

    // 2. Create half-circle opening for kicking team
    CreateHalfCircleWall(center, radius, kickingTeam, xOrient);

    // 3. Draw laser lines matching wall positions
    DrawWallLasers(...);
}
```

## Module Structure

```c
// ============ GLOBALS ============
char kickoffWallsConfigFile[PLATFORM_MAX_PATH] = "cfg/sm_soccermod/soccer_mod_kickoffwalls.cfg";
KeyValues kvKickoffWalls;

// Per-map cached values
float kw_center[3];
float kw_radius;
bool kw_xorientation;
float kw_t_goal[3];
float kw_ct_goal[3];
bool kw_enabled;
bool kw_configLoaded;

// ============ FUNCTIONS ============

// Called on map start
void KickoffWalls_OnMapStart()
{
    KickoffWalls_AutoDetect();
    KickoffWalls_LoadConfig();  // Override with saved values if exist
}

// Auto-detect values from map entities
void KickoffWalls_AutoDetect()

// Load/save config
void KickoffWalls_LoadConfig()
void KickoffWalls_SaveConfig()

// Wall creation (replaces old KickOffWall())
void KickoffWalls_Create(int kickingTeam)
void KickoffWalls_Destroy()

// Admin menu
void KickoffWalls_OpenMenu(int client)
void KickoffWalls_CalibrateRadius(int client)
void KickoffWalls_TestWalls(int client)

// Debug
void KickoffWalls_PrintInfo(int client)
```

## Migration Path

1. Create new `kickoffwalls.sp` module
2. Add to includes in `soccer_mod.sp`
3. Hook into existing events (map start, round start, ball touch)
4. Keep old `kickoffwall.sp` temporarily with toggle
5. Add cvar `soccer_mod_kickoffwalls_version` (1 = old, 2 = new)
6. Once tested, remove old code

## Commands

| Command | Access | Description |
|---------|--------|-------------|
| `!kickoffwalls` | Admin | Opens kickoff walls settings menu |
| `!kw_info` | Admin | Prints current map's kickoff wall settings to chat |
| `!kw_test` | Admin | Spawns test walls for 10 seconds |
| `!kw_detect` | Admin | Re-runs auto-detection |
| `!kw_save` | Admin | Saves current settings to config |

## Future Enhancements

- Store 6-yard box dimensions for GK area visualization
- Store penalty box dimensions
- Field width/length for accurate wall sizing
- Support for non-rectangular fields
- Visual calibration mode (show laser at player position in real-time)
