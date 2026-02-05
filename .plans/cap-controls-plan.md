# Cap Controls Enhancement Plan

## Overview

Add admin controls and automated cap system:

### Phase 1: Core Controls (v1.4.4)
1. **Stop Cap Fight** - Cancel an active cap fight
2. **Reset Cap** - Global reset of ALL cap-related state (fight, picking, voting, ready-up)
3. **Start Pick Menu** - Auto-detect captains from teams and start picking
4. **Snake Draft Pick Order** - Fair pick order where 2nd picker gets compensation

### Phase 2: Automated Cap System (v1.5.0)
5. **Auto Cap** - Full automated flow: spec all → random captains → vote → ready-up → knife fight

---

## Current State Analysis

### Cap Fight Lifecycle
```
CapStartFight() → Countdown (3s) → TimerCapFightCountDownEnd() → Fight → CapEventRoundEnd() → Pick Menu
```

### Key State Variables (globals.sp)
- `capFightStarted` (bool) - Whether cap fight is active
- `capPicker` (int) - Current captain picking (client ID)
- `capCT` / `capT` (int) - Captain client IDs
- `capPicksLeft` (int) - Remaining picks
- `tempSprint` (bool) - Sprint state before cap fight
- `capFightHealth` (int) - Starting health
- `capweapon[32]` (char) - Selected weapon
- `matchMaxPlayers` (int) - Players per team (4-6 depending on map, default 6)
- `first12Set` (int) - First 12 rule: 0=OFF, 1=ON, 2=Pre-Cap Join

### Player Minimum System
- `matchMaxPlayers` is set per-map via `soccer_mod_map_defaults.txt`
- Default is 6 (for 6v6 = 12 players total)
- Some maps use 4 (for 4v4 = 8 players total)
- Total players needed = `matchMaxPlayers * 2`
- Total picks = `(matchMaxPlayers - 1) * 2` (excludes the 2 captains)

### Timer Handles to Track
Need to store timer handles so they can be killed on reset:
- Cap fight countdown timers (3 sequential timers)
- Grenade refill timer

---

## Snake Draft Pick Order

### Problem with Current System
Current alternating pick (1-1-1-1...) gives first picker an advantage since they always get first choice of remaining players.

### Solution: Snake Draft (Configurable)
The captain who picks second gets the last 2 picks before it returns to the first picker.

**This is a configurable setting:**
- `capSnakeDraft` (int): 0=OFF (alternating), 1=ON (snake draft)
- Default: ON for 12-player games (6v6), can be toggled via settings menu
- When OFF: Uses classic alternating pick order (1-1-1-1...)
- When ON: Uses snake draft (1-2-2-2...-2-1)

**Pattern for 10 picks (6v6, 12 players - 2 captains = 10 to pick):**
```
Pick #:  1   2   3   4   5   6   7   8   9   10
Captain: T   CT  CT  T   T   CT  CT  T   T   CT
         ^   ^---^   ^---^   ^---^   ^---^   ^
         |   2nd gets 2     alternating 2s   |
      1st pick                           last pick
```

Result: T gets picks 1,4,5,8,9 (5 players) | CT gets picks 2,3,6,7,10 (5 players)

**Pattern for 6 picks (4v4, 8 players - 2 captains = 6 to pick):**
```
Pick #:  1   2   3   4   5   6
Captain: T   CT  CT  T   T   CT
```

Result: T gets picks 1,4,5 (3 players) | CT gets picks 2,3,6 (3 players)

### Implementation

**New global variables** (globals.sp):
```sourcepawn
int capPickNumber = 0;      // Current pick number (1-based)
int capFirstPicker = 0;     // Client ID of captain who picks first (knife winner)
int capSnakeDraft = 1;      // 0=OFF (alternating), 1=ON (snake draft) - default ON
```

**Config read/write** (createconfig.sp):
```sourcepawn
// Write
kvConfig.SetNum("soccer_mod_cap_snake_draft", capSnakeDraft);

// Read
capSnakeDraft = kvConfig.GetNum("soccer_mod_cap_snake_draft", 1);
```

**Menu option** (cap.sp in OpenCapMenu):
```sourcepawn
char snakeString[48];
Format(snakeString, sizeof(snakeString), "Snake draft: %s", capSnakeDraft ? "ON" : "OFF");
menu.AddItem("snakedraft", snakeString);
```

**Pick order logic** (cap.sp):
```sourcepawn
// Determine who picks next based on draft mode setting
public int GetNextPicker()
{
    int totalPicks = (matchMaxPlayers - 1) * 2;
    int nextPickNumber = capPickNumber + 1;
    int secondPicker = (capFirstPicker == capT) ? capCT : capT;

    // First pick always goes to knife winner
    if (nextPickNumber == 1)
        return capFirstPicker;

    // Classic alternating mode (snake draft OFF)
    if (!capSnakeDraft)
    {
        // Simple alternation: odd picks = first picker, even picks = second picker
        if (nextPickNumber % 2 == 1)
            return capFirstPicker;
        else
            return secondPicker;
    }

    // Snake draft mode (ON)
    // Pattern: 1-2-2-2-2-...-2-1 (first picker gets 1, then alternate 2s, last goes to 2nd)

    // Last pick goes to second picker
    if (nextPickNumber == totalPicks)
        return secondPicker;

    // Middle picks: alternate in pairs
    // Picks 2-3: second picker
    // Picks 4-5: first picker
    // Picks 6-7: second picker
    // etc.
    int pairIndex = (nextPickNumber - 2) / 2;  // 0 for picks 2-3, 1 for 4-5, etc.

    if (pairIndex % 2 == 0)
        return secondPicker;  // Second picker's turn
    else
        return capFirstPicker;  // First picker's turn
}
```

**Update CapPickMenuHandler:**
```sourcepawn
// After a successful pick:
capPickNumber++;
capPicksLeft--;

if (capPicksLeft > 0)
{
    capPicker = GetNextPicker();
    OpenCapPickMenu(capPicker);
}
```

**Update CapEventRoundEnd (after knife fight):**
```sourcepawn
// Set first picker based on knife fight winner
capFirstPicker = (winner_team == 2) ? capT : capCT;
capPickNumber = 0;
capPicker = capFirstPicker;
```

---

## Phase 1: Core Controls Implementation

### 1. Stop Cap Fight

**Purpose**: Cancel an active cap fight, restore normal state, kill timers

**Function**: `CapStopFight(int client)`

**Admin Command**: `!stopcap` / `sm_stopcap`

```sourcepawn
public void CapStopFight(int client)
{
    if (!capFightStarted)
    {
        CPrintToChat(client, "%s No cap fight is currently active.", CHAT_PREFIX);
        return;
    }

    // Kill any active timers
    CapKillTimers();

    // Reset state
    capFightStarted = false;

    // Restore sprint if it was enabled before
    if (tempSprint)
    {
        sprintEnabled = true;
        tempSprint = false;
    }

    // Unfreeze all players
    UnfreezeAll();

    // Reset hostname
    UpdateHostname("Public");

    // Notify all players
    CPrintToChatAll("%s Cap fight has been stopped.", CHAT_PREFIX);

    // Log action
    LogAction(client, -1, "\"%L\" stopped cap fight", client);
}
```

---

### 2. Reset Cap (Global Reset)

**Purpose**: Full reset of ALL cap-related state - stops any process (fight, picking, voting, ready-up)

**Function**: `CapReset(int client)`

**Admin Command**: `!resetcap` / `sm_resetcap`

```sourcepawn
public void CapReset(int client)
{
    // Kill ALL cap-related timers
    CapKillTimers();

    // Reset all cap state variables
    capFightStarted = false;
    capPicker = 0;
    capT = 0;
    capCT = 0;
    capPicksLeft = 0;
    capPickNumber = 0;
    capFirstPicker = 0;
    capnr = 0;

    // Phase 2 variables (when implemented)
    // capVoteActive = false;
    // capReadyT = false;
    // capReadyCT = false;
    // capAutoActive = false;

    // Restore sprint if needed
    if (tempSprint)
    {
        sprintEnabled = true;
        tempSprint = false;
    }

    // Unfreeze all players
    UnfreezeAll();

    // Close any open cap-related menus for all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            CancelClientMenu(i);
        }
    }

    // Reset hostname
    UpdateHostname("Public");

    // Notify
    CPrintToChatAll("%s Cap system has been fully reset.", CHAT_PREFIX);

    // Log action
    if (client > 0)
        LogAction(client, -1, "\"%L\" reset cap system", client);
}
```

---

### 3. Start Pick Menu

**Purpose**: Auto-detect captains (1 player on each team), validate player count, and start picking phase

**Function**: `CapStartPicking(int client)`

**Admin Command**: `!startpick` / `sm_startpick`

```sourcepawn
public void CapStartPicking(int client)
{
    // Count players on each team and find potential captains
    int tCount = 0, ctCount = 0;
    int tPlayer = 0, ctPlayer = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            int team = GetClientTeam(i);
            if (team == 2) // T
            {
                tCount++;
                tPlayer = i;
            }
            else if (team == 3) // CT
            {
                ctCount++;
                ctPlayer = i;
            }
        }
    }

    // Validate: exactly 1 player on each team
    if (tCount != 1 || ctCount != 1)
    {
        CPrintToChat(client, "%s Need exactly 1 player on each team to start picking.", CHAT_PREFIX);
        CPrintToChat(client, "%s Currently: %d on T, %d on CT.", CHAT_PREFIX, tCount, ctCount);
        return;
    }

    // Count available spectators
    int specCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) < 2)
            specCount++;
    }

    // Calculate required players
    int totalPlayersNeeded = matchMaxPlayers * 2;
    int currentPlayers = tCount + ctCount + specCount;  // 2 + specCount

    if (currentPlayers < totalPlayersNeeded)
    {
        CPrintToChat(client, "%s Not enough players. Need %d, have %d.", CHAT_PREFIX, totalPlayersNeeded, currentPlayers);
        CPrintToChat(client, "%s (Map requires %d players per team)", CHAT_PREFIX, matchMaxPlayers);
        return;
    }

    if (specCount == 0)
    {
        CPrintToChat(client, "%s No players in spectator to pick from.", CHAT_PREFIX);
        return;
    }

    // Set captains
    capT = tPlayer;
    capCT = ctPlayer;

    // Initialize picks - T captain picks first by default (no knife fight winner)
    capPicksLeft = (matchMaxPlayers - 1) * 2;
    capPickNumber = 0;
    capFirstPicker = capT;  // Default to T if no knife fight
    capPicker = capT;

    // Update hostname
    UpdateHostname("Picking");

    // Notify
    CPrintToChatAll("%s Picking phase started!", CHAT_PREFIX);
    CPrintToChatAll("%s T Captain: %N | CT Captain: %N", CHAT_PREFIX, capT, capCT);
    CPrintToChatAll("%s %N is picking first.", CHAT_PREFIX, capPicker);

    // Open pick menu for first picker
    OpenCapPickMenu(capPicker);

    // Log action
    LogAction(client, -1, "\"%L\" started picking phase", client);
}
```

---

### Timer Management

**New globals needed** (globals.sp):
```sourcepawn
// Cap timer handles
Handle capCountdownTimer1 = INVALID_HANDLE;
Handle capCountdownTimer2 = INVALID_HANDLE;
Handle capCountdownTimer3 = INVALID_HANDLE;
Handle capCountdownEndTimer = INVALID_HANDLE;
Handle capGrenadeRefillTimer = INVALID_HANDLE;

// Snake draft variables
int capPickNumber = 0;      // Current pick number (1-based)
int capFirstPicker = 0;     // Client ID of knife fight winner (picks first)
int capSnakeDraft = 1;      // 0=OFF (alternating), 1=ON (snake draft) - saved to config
```

**Timer kill function** (cap.sp):
```sourcepawn
public void CapKillTimers()
{
    if (capCountdownTimer1 != INVALID_HANDLE)
    {
        KillTimer(capCountdownTimer1);
        capCountdownTimer1 = INVALID_HANDLE;
    }
    if (capCountdownTimer2 != INVALID_HANDLE)
    {
        KillTimer(capCountdownTimer2);
        capCountdownTimer2 = INVALID_HANDLE;
    }
    if (capCountdownTimer3 != INVALID_HANDLE)
    {
        KillTimer(capCountdownTimer3);
        capCountdownTimer3 = INVALID_HANDLE;
    }
    if (capCountdownEndTimer != INVALID_HANDLE)
    {
        KillTimer(capCountdownEndTimer);
        capCountdownEndTimer = INVALID_HANDLE;
    }
    if (capGrenadeRefillTimer != INVALID_HANDLE)
    {
        KillTimer(capGrenadeRefillTimer);
        capGrenadeRefillTimer = INVALID_HANDLE;
    }
}
```

**Update timer creation** in `CapStartFight()`:
```sourcepawn
// Instead of:
CreateTimer(0.0, TimerCapFightCountDown, 3);
// Use:
capCountdownTimer1 = CreateTimer(0.0, TimerCapFightCountDown, 3);
capCountdownTimer2 = CreateTimer(1.0, TimerCapFightCountDown, 2);
capCountdownTimer3 = CreateTimer(2.0, TimerCapFightCountDown, 1);
capCountdownEndTimer = CreateTimer(3.0, TimerCapFightCountDownEnd);
```

---

## Phase 2: Automated Cap System (Future)

### Overview
Full automated captain selection flow:
1. Admin triggers `!autocap`
2. All players moved to spectator
3. Validate minimum player count (`matchMaxPlayers * 2`)
4. Two random players selected as potential captains
5. Server-wide vote: "Start cap fight with [Player1] vs [Player2]?" (50%+ threshold)
6. If passed: Captains moved to teams, ready-up phase starts
7. Players type `!k` or `.k` to ready up
8. Once both captains ready, normal knife fight begins
9. Winner picks first using snake draft

### Player Minimum Validation
```sourcepawn
public bool CapValidatePlayerCount()
{
    int playerCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
            playerCount++;
    }

    int required = matchMaxPlayers * 2;  // e.g., 12 for 6v6, 8 for 4v4

    if (playerCount < required)
    {
        CPrintToChatAll("%s Not enough players for auto cap.", CHAT_PREFIX);
        CPrintToChatAll("%s Need %d players, have %d.", CHAT_PREFIX, required, playerCount);
        return false;
    }
    return true;
}
```

### New State Variables (globals.sp)
```sourcepawn
bool capAutoActive = false;      // Auto cap process is running
bool capVoteActive = false;      // Vote is in progress
bool capReadyT = false;          // T captain is ready
bool capReadyCT = false;         // CT captain is ready
int capVotesYes = 0;             // Yes votes
int capVotesNo = 0;              // No votes
int capVotesNeeded = 0;          // Votes needed to pass
Handle capVoteTimer = INVALID_HANDLE;
Handle capReadyTimer = INVALID_HANDLE;
```

### Auto Cap Flow

```
!autocap
    │
    ▼
┌─────────────────────────────┐
│ Validate player count       │
│ (matchMaxPlayers * 2 min)   │
└───────────┬─────────────────┘
            │
            ▼
┌─────────────────────────┐
│ Move all to spectator   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Select 2 random players │
│ as potential captains   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Start vote (30 seconds) │
│ "Cap fight: X vs Y?"    │
│ Need 50%+ yes votes     │
└───────────┬─────────────┘
            │
      ┌─────┴─────┐
      │           │
    Pass        Fail
      │           │
      ▼           ▼
┌───────────┐  ┌──────────────┐
│ Move caps │  │ Notify fail  │
│ to teams  │  │ Reset state  │
└─────┬─────┘  └──────────────┘
      │
      ▼
┌─────────────────────────┐
│ Ready-up phase          │
│ "Type !k when ready"    │
│ Show ready status HUD   │
└───────────┬─────────────┘
            │
      Both ready (!k)
            │
            ▼
┌─────────────────────────┐
│ Start knife fight       │
│ (existing CapStartFight)│
└───────────┬─────────────┘
            │
      Knife fight ends
            │
            ▼
┌─────────────────────────┐
│ Winner = capFirstPicker │
│ Snake draft picking     │
└─────────────────────────┘
```

### Ready-Up Commands
- `!k` or `.k` - Mark yourself as ready (captains only)
- Shows HUD: "T Captain: [READY/NOT READY] | CT Captain: [READY/NOT READY]"

### Key Point: Reset Stops Everything
`CapReset()` must be able to stop the auto cap process at ANY stage:
- During voting
- During ready-up
- During knife fight
- During picking

This is why we track all timers and state variables.

---

## Captain Disconnect Handling

### Problem
If a captain disconnects during cap fight, picking, or ready-up phase, the system gets stuck.

### Solution
Auto-reset the cap system when a captain disconnects. They can rejoin, join the proper team, and restart.

**Location**: `soccer_mod.sp` line 937 has the main `OnClientDisconnect` hook.

It follows a pattern of calling module-specific handlers:
```sourcepawn
public void OnClientDisconnect(int client)
{
    DatabaseCheckPlayer(client);
    RespawnOnClientDisconnect(client);
    TrainingOnClientDisconnect(client);
    GKSkinOnClientDisconnect(client);
    RadioCommandsOnClientDisconnect(client);
    // ... etc
}
```

**Add to cap.sp**:
```sourcepawn
public void CapOnClientDisconnect(int client)
{
    // Check if disconnecting player is a captain during active cap process
    if (client == capT || client == capCT)
    {
        // Check if we're in an active cap phase
        bool inCapPhase = capFightStarted || capPicksLeft > 0;
        // Phase 2: || capVoteActive || capReadyT || capReadyCT

        if (inCapPhase)
        {
            CPrintToChatAll("{%s}[%s] {%s}Captain %N disconnected. Cap system reset.", prefixcolor, prefix, textcolor, client);
            CapReset(0);  // 0 = system-triggered, not admin
        }
    }
}
```

**Add call in soccer_mod.sp `OnClientDisconnect`**:
```sourcepawn
CapOnClientDisconnect(client);
```

### User Flow After Captain Disconnect
1. Captain leaves → System auto-resets
2. Message: "Captain [Name] disconnected. Cap system has been reset."
3. Captain rejoins server
4. Captain joins their team (T or CT)
5. Admin runs `!startpick` or `!autocap` again

---

## Menu Structure

### Updated `OpenCapMenu()` Structure
```
Soccer Mod - Cap Menu
├── Auto cap (Phase 2)
├── Start cap fight
├── Stop cap fight (if capFightStarted)
├── Start picking
├── Reset cap
├── ─────────────
├── Set T captain
├── Set CT captain
├── Weapon selection
├── Cap fight health: X
├── Position menu
└── Back
```

---

## Admin Commands Summary

| Command | Description |
|---------|-------------|
| `!stopcap` | Stop active cap fight |
| `!resetcap` | Full reset of all cap state |
| `!startpick` | Start picking (auto-detect captains, validate player count) |
| `!autocap` | Start automated cap flow (Phase 2) |
| `!k` / `.k` | Ready up (Phase 2, captains only) |

---

## Files to Modify

### Phase 1
1. **globals.sp**
   - Add timer handles for cap countdown/grenade timers
   - Add `capPickNumber`, `capFirstPicker`, and `capSnakeDraft` for snake draft

2. **createconfig.sp**
   - Add read/write for `soccer_mod_cap_snake_draft` in Cap Settings section

3. **cap.sp**
   - Add `CapStopFight()` function
   - Add `CapReset()` function
   - Add `CapStartPicking()` function
   - Add `CapKillTimers()` function
   - Add `GetNextPicker()` function for snake draft
   - Add "Snake draft: ON/OFF" menu option in `OpenCapMenu()`
   - Update `CapMenuHandler()` to toggle snake draft setting
   - Update `CapPickMenuHandler()` to use `GetNextPicker()`
   - Update `CapEventRoundEnd()` to set `capFirstPicker`
   - Update timer creation to store handles

4. **server_commands.sp** or **client_commands.sp**
   - Add `sm_stopcap` command
   - Add `sm_resetcap` command
   - Add `sm_startpick` command

5. **soccer_mod.sp** (line ~950, in OnClientDisconnect)
   - Add call to `CapOnClientDisconnect(client)`

### Phase 2
1. **globals.sp**
   - Add auto cap state variables

2. **cap.sp** (or new **autocap.sp** module)
   - Add `CapAutoStart()` function
   - Add `CapValidatePlayerCount()` function
   - Add `CapVoteStart()` / `CapVoteEnd()` functions
   - Add `CapReadyUp()` function
   - Add `!k` command handler
   - Update `CapReset()` to handle all new states
   - Update `CapKillTimers()` for new timers

---

## Version Plan

- **v1.4.4**: Phase 1 - Core controls (stop, reset, start pick, snake draft, admin commands)
- **v1.5.0**: Phase 2 - Automated cap system (auto cap, voting, ready-up)
