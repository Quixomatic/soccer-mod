# Cap Controls Enhancement Plan

## Overview

Add admin controls and automated cap system:

### Phase 1: Core Controls (v1.4.4) ✅ COMPLETE
1. ✅ **Stop Cap Fight** - `!stopcap` / menu option
2. ✅ **Reset Cap** - `!resetcap` / menu option
3. ✅ **Start Pick Menu** - `!startpick` / menu option
4. ✅ **Snake Draft Pick Order** - Configurable toggle in menu
5. ✅ **Captain Disconnect Handling** - Auto-reset on captain leave
6. ✅ **Timer Management** - Proper cleanup on stop/reset

**Implemented in:** v1.4.4 (released)
**Files modified:** globals.sp, createconfig.sp, cap.sp, client_commands.sp, soccer_mod.sp

### Phase 2: Automated Cap System (v1.4.5) ✅ IMPLEMENTED - ⏳ TESTING NEEDED
7. ✅ **Auto Cap** - Full automated flow: spec all → random captains → vote → ready-up → knife fight
   - `!autocap` command and menu option
   - Random captain selection (only real players, never bots)
   - Server-wide vote (>50% threshold)
   - `!vote` to re-open vote menu if missed
   - Vote change support (players can switch yes/no)
   - Early vote ending when outcome determined
   - Ready-up phase with `!k` / `.k`
   - HUD display for ready status
   - Auto knife fight when both ready
   - Debug mode toggle (allows bots to count as players for testing)

**Implemented in:** v1.4.5
**Files modified:** globals.sp, cap.sp, client_commands.sp, soccer_mod.sp

---

## Testing Status

### Phase 1 (v1.4.4) - ✅ TESTED
- [x] `!stopcap` - Stops active cap fight (fixed timer crash bug)
- [x] `!resetcap` - Full reset of cap system
- [x] `!startpick` - Start picking with auto-detected captains
- [x] Snake draft toggle
- [x] Captain disconnect auto-reset

### Phase 2 (v1.4.5) - ⏳ NEEDS TESTING
- [ ] `!autocap` - Full flow test
- [ ] Random captain selection
- [ ] Vote menu display and interaction
- [ ] `!vote` to re-open menu
- [ ] Vote changing (switch yes/no)
- [ ] Early vote ending (guaranteed pass/fail)
- [ ] Ready-up phase (`!k` / `.k`)
- [ ] HUD ready status display
- [ ] Both captains ready → auto knife fight
- [ ] Debug mode with bots
- [ ] `!resetcap` during vote phase
- [ ] `!resetcap` during ready-up phase
- [ ] Captain disconnect during vote/ready-up

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
The loser gets back-to-back picks at the END when 3 players remain, and the winner gets the last pick.

**This is a configurable setting:**
- `capSnakeDraft` (int): 0=OFF (alternating), 1=ON (snake draft)
- Default: ON for 12-player games (6v6), can be toggled via settings menu
- When OFF: Uses classic alternating pick order (W-L-W-L-W-L...)
- When ON: Normal alternating, but loser gets 2 consecutive at the end, winner gets last

**Pattern for 10 picks (6v6, 12 players - 2 captains = 10 to pick):**
```
Pick #:  1   2   3   4   5   6   7   8   9   10
Captain: W   L   W   L   W   L   W   L   L   W
                                     ^---^   ^
                                     loser   winner
                                     gets 2  gets last
```

Result: Winner gets picks 1,3,5,7,10 (5 players) | Loser gets picks 2,4,6,8,9 (5 players)

**Pattern for 6 picks (4v4, 8 players - 2 captains = 6 to pick):**
```
Pick #:  1   2   3   4   5   6
Captain: W   L   W   L   L   W
```

Result: Winner gets picks 1,3,6 (3 players) | Loser gets picks 2,4,5 (3 players)

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
    // Pattern: Normal alternating, but loser gets 2 consecutive picks at the end
    // For 10 picks: W-L-W-L-W-L-W-L-L-W
    // Winner gets last pick, loser gets back-to-back on picks 8-9

    // Last pick goes to winner (first picker)
    if (nextPickNumber == totalPicks)
        return capFirstPicker;

    // Second-to-last pick goes to loser (gives them back-to-back with their previous pick)
    if (nextPickNumber == totalPicks - 1)
        return secondPicker;

    // All other picks: standard alternating
    // Odd picks (1,3,5,7) = first picker (winner)
    // Even picks (2,4,6,8) = second picker (loser)
    if (nextPickNumber % 2 == 1)
        return capFirstPicker;
    else
        return secondPicker;
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

## Phase 2: Automated Cap System (v1.5.0) ⏳ PENDING

### Overview
Full automated captain selection flow with voting and ready-up:
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

### Phase 1 ✅ COMPLETE
All changes implemented in v1.4.4:
- globals.sp - Timer handles, snake draft variables
- createconfig.sp - Snake draft config
- cap.sp - All control functions, menu updates, pick handler
- client_commands.sp - Admin commands
- soccer_mod.sp - Disconnect handler

### Phase 2 Implementation Tasks
1. **globals.sp**
   - Add: `capAutoActive`, `capVoteActive`, `capReadyT`, `capReadyCT`
   - Add: `capVotesYes`, `capVotesNo`, `capVotesNeeded`
   - Add: `capVoteTimer`, `capReadyTimer` handles

2. **cap.sp**
   - Add `CapAutoStart(int client)` - Main entry point for !autocap
   - Add `CapValidatePlayerCount()` - Check minimum players
   - Add `CapSelectRandomCaptains()` - Pick 2 random players
   - Add `CapVoteStart()` - Start the vote with menu
   - Add `CapVoteHandler()` - Handle vote responses
   - Add `CapVoteEnd()` - Tally votes, proceed or fail
   - Add `CapReadyStart()` - Begin ready-up phase
   - Add `CapReadyCommand()` - Handle !k command
   - Add `CapReadyCheck()` - Check if both ready, start fight
   - Update `CapReset()` - Reset new state variables
   - Update `CapKillTimers()` - Kill vote/ready timers
   - Update `CapOnClientDisconnect()` - Handle during vote/ready phases
   - Add "Auto cap" menu option in `OpenCapMenu()`

3. **client_commands.sp**
   - Add `sm_autocap` command registration
   - Add `sm_k` / `say .k` command for ready-up

---

## Version Plan

- **v1.4.4**: ✅ Phase 1 - Core controls (stop, reset, start pick, snake draft, admin commands)
- **v1.4.5**: ✅ Phase 2 - Automated cap system (auto cap, voting, ready-up)
- **v1.5.x**: ⏳ Phase 3 - Auto-retry failed votes with new random captains

---

## Phase 3: Auto-Retry Failed Votes (v1.5.x) ⏳ PENDING

### Overview
When a cap vote fails (doesn't reach >50% yes votes), the system should automatically:
1. Try the next unique captain pair from a pre-shuffled list
2. Once all unique pairs have been tried, switch to purely random selection
3. Continue indefinitely until a vote passes (no max attempts)

### Current Behavior (v1.4.5)
When vote fails:
- `CapVoteEnd()` resets state: `capT=0`, `capCT=0`, `capAutoActive=false`
- Hostname changes to "Public"
- No automatic retry - players must manually trigger `!autocap` again

### Proposed Behavior
When `!autocap` starts:
1. Generate all unique pairs of players (N players = N*(N-1)/2 pairs)
2. Shuffle the pairs into random order
3. Pop pairs from the list for each vote attempt

When vote fails:
- Wait 5 seconds (brief pause for players to see result)
- If pairs remain in shuffled list: use next pair (guaranteed unique)
- If list exhausted: switch to purely random (can repeat any pair)
- Continue until vote passes

### Pair Counts
- 12 players = 66 unique pairs
- 10 players = 45 unique pairs
- 8 players = 28 unique pairs

### New State Variables (globals.sp)
```sourcepawn
ArrayList capCaptainPairs = null;          // Shuffled list of {client1, client2} pairs
int capPairIndex = 0;                      // Current position in pairs list
bool capPairsExhausted = false;            // True when all unique pairs tried
Handle capRetryTimer = INVALID_HANDLE;     // Timer for retry delay
```

### Implementation

**Generate and shuffle all pairs on `!autocap`:**
```sourcepawn
public void CapGenerateCaptainPairs()
{
    if (capCaptainPairs != null)
        delete capCaptainPairs;

    // ArrayList of 2-element arrays: [client1, client2]
    capCaptainPairs = new ArrayList(2);
    capPairIndex = 0;
    capPairsExhausted = false;

    // Get all eligible players
    ArrayList players = new ArrayList();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
            players.Push(i);
    }

    // Generate all unique pairs
    int count = players.Length;
    for (int i = 0; i < count - 1; i++)
    {
        for (int j = i + 1; j < count; j++)
        {
            int pair[2];
            pair[0] = players.Get(i);
            pair[1] = players.Get(j);
            capCaptainPairs.PushArray(pair, 2);
        }
    }

    delete players;

    // Fisher-Yates shuffle
    int n = capCaptainPairs.Length;
    for (int i = n - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        if (i != j)
            capCaptainPairs.SwapAt(i, j);
    }
}
```

**Get next captain pair:**
```sourcepawn
public bool CapGetNextCaptainPair()
{
    // Phase 1: Use pre-generated unique pairs
    if (!capPairsExhausted && capCaptainPairs != null && capPairIndex < capCaptainPairs.Length)
    {
        int pair[2];
        capCaptainPairs.GetArray(capPairIndex, pair, 2);
        capPairIndex++;

        // Validate both players still connected
        if (IsClientInGame(pair[0]) && IsClientInGame(pair[1]))
        {
            capT = pair[0];
            capCT = pair[1];
            return true;
        }

        // Player disconnected, try next pair
        return CapGetNextCaptainPair();
    }

    // Phase 2: All unique pairs exhausted, switch to purely random
    capPairsExhausted = true;
    return CapSelectPurelyRandomCaptains();
}

public bool CapSelectPurelyRandomCaptains()
{
    ArrayList eligible = new ArrayList();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
            eligible.Push(i);
    }

    if (eligible.Length < 2)
    {
        delete eligible;
        return false;
    }

    // Purely random - can pick same pair again
    int idx1 = GetRandomInt(0, eligible.Length - 1);
    capT = eligible.Get(idx1);
    eligible.Erase(idx1);

    int idx2 = GetRandomInt(0, eligible.Length - 1);
    capCT = eligible.Get(idx2);

    delete eligible;
    return true;
}
```

**Update `CapVoteEnd()` on vote failure:**
```sourcepawn
if (percentYes <= 50)
{
    // Vote failed
    CPrintToChatAll("%s Vote failed (%d%% yes).", CHAT_PREFIX, percentYes);

    int pairsRemaining = capCaptainPairs != null ? (capCaptainPairs.Length - capPairIndex) : 0;

    if (capPairsExhausted)
        CPrintToChatAll("%s Selecting random captains in 5 seconds...", CHAT_PREFIX);
    else
        CPrintToChatAll("%s Trying next pair in 5 seconds... (%d combinations remaining)", CHAT_PREFIX, pairsRemaining);

    capRetryTimer = CreateTimer(5.0, TimerCapVoteRetry);
}
```

**Timer callback:**
```sourcepawn
public Action TimerCapVoteRetry(Handle timer)
{
    capRetryTimer = INVALID_HANDLE;

    // Re-validate player count
    if (!CapValidatePlayerCount())
    {
        CPrintToChatAll("%s Auto cap cancelled - not enough players.", CHAT_PREFIX);
        CapResetVoteState();
        return Plugin_Stop;
    }

    // Get next captain pair
    if (!CapGetNextCaptainPair())
    {
        CPrintToChatAll("%s Auto cap cancelled - could not select captains.", CHAT_PREFIX);
        CapResetVoteState();
        return Plugin_Stop;
    }

    // Start new vote
    CapVoteStart();
    return Plugin_Stop;
}
```

**Reset function:**
```sourcepawn
public void CapResetVoteState()
{
    capT = 0;
    capCT = 0;
    capAutoActive = false;
    capVoteActive = false;
    capPairIndex = 0;
    capPairsExhausted = false;

    if (capCaptainPairs != null)
    {
        delete capCaptainPairs;
        capCaptainPairs = null;
    }

    if (capRetryTimer != INVALID_HANDLE)
    {
        KillTimer(capRetryTimer);
        capRetryTimer = INVALID_HANDLE;
    }

    UpdateHostname("Public");
}
```

### Timer Management
Add to `CapKillTimers()`:
```sourcepawn
if (capRetryTimer != INVALID_HANDLE)
{
    KillTimer(capRetryTimer);
    capRetryTimer = INVALID_HANDLE;
}
```

### User Experience Flow
```
!autocap (12 players = 66 unique pairs, shuffled)
    │
    ▼
Vote #1: "Cap fight: Alice vs Bob?" (pair 1/66)
    │
  FAIL (45% yes)
    │
    ▼
"Trying next pair in 5 seconds... (65 combinations remaining)"
    │
    ▼
Vote #2: "Cap fight: Charlie vs Dave?" (pair 2/66)
    │
  FAIL (40% yes)
    │
    ▼
... (continues through all 66 unique pairs) ...
    │
    ▼
Vote #67: "Cap fight: Eve vs Frank?" (purely random, may repeat)
    │
  PASS (65% yes)
    │
    ▼
Ready-up phase → knife fight → picking
```

### Edge Cases
- **Player disconnects mid-process**: Skip pairs containing that player, continue to next
- **Not enough players**: Cancel auto cap, notify players
- **`!resetcap` during retry**: Kill timer, clear pair list, reset state
- **Same pair wins after exhaustion**: Purely random can select previously-rejected pairs

### Testing Checklist
- [ ] Vote fails → auto-retry with next unique pair
- [ ] Pairs are shuffled (not predictable order)
- [ ] Shows "X combinations remaining" during unique phase
- [ ] After all pairs tried, switches to purely random
- [ ] Purely random message shown (no "remaining" count)
- [ ] Player disconnect skips affected pairs gracefully
- [ ] 5 second delay between failed vote and new vote
- [ ] `!resetcap` during retry delay cancels the process
- [ ] Works with different player counts (8, 10, 12 players)
