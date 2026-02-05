# Ready Check System Enhancement Plan

## Overview

Enhance the existing ready check system to be a reusable utility for multiple contexts:
1. **Post-Picking Ready Check** - After cap picking completes, ready check before match starts
2. **Timeout/Time-in** - `!to` pauses match with ready check, `!ti` or all ready unpauses
3. **Match Pause** - Existing functionality, improved with new panel system

The panel displays all players with their ready/not ready status and refreshes in real-time.

---

## Current System Analysis

### Existing Files
- `modules/readycheck.sp` - Has basic ready panel for pause/unpause
- `modules/match.sp` - `MatchPause()`, `MatchUnpause()` functions
- `globals.sp` - `showPanel`, `matchReadyCheck`, `pauseRdyTimer`, etc.

### Current Ready Check Modes (`matchReadyCheck`)
- `0` = OFF (no ready check)
- `1` = AUTO (all ready = auto unpause)
- `2` = MANUAL (admin must unpause, but still shows panel)

### Limitations of Current System
- Only used for pause/unpause during matches
- No post-picking ready check
- No timeout commands (!to, !ti)
- Limited command aliases (only !rdy)
- No admin force/bypass command
- No countdown timer option
- Panel doesn't auto-refresh on a timer (only on player action)

---

## New System Design

### Ready Check Contexts (Enum)

```sourcepawn
enum ReadyCheckContext
{
    READY_CONTEXT_NONE = 0,      // No active ready check
    READY_CONTEXT_PREMATCH,      // After picking, before match starts
    READY_CONTEXT_TIMEOUT,       // During timeout (!to)
    READY_CONTEXT_PAUSE          // During match pause (existing)
}
```

### Countdown Behavior

The countdown is the **maximum wait time**. The ready check allows the match to start **early** if everyone is ready:

- **Countdown running + NOT all ready** → Keep waiting, show panel
- **Countdown running + ALL ready** → Start match immediately (skip remaining countdown)
- **Countdown expires** → Start match regardless of ready state

This means readying up is a way to **speed up** the pre-match process, not a requirement.

### Flow Diagrams

#### Post-Picking Flow
```
Picking completes (capPicksLeft == 0)
    │
    ▼
┌─────────────────────────────┐
│ Auto-start Ready Check      │
│ Context: READY_CONTEXT_     │
│          PREMATCH           │
│ Countdown: 60 sec (config)  │
└───────────┬─────────────────┘
            │
            ▼
┌─────────────────────────────┐
│ Panel shows all 12 players  │
│ Refreshes every 1 second    │
│ Players type .r to ready    │
│ Countdown ticks down        │
└───────────┬─────────────────┘
            │
      ┌─────┴─────┬──────────────┐
      │           │              │
  All Ready   Admin Force   Countdown=0
  (early!)        │         (time's up)
      │           │              │
      ▼           ▼              ▼
┌─────────────────────────────────────┐
│ Close panels, start match           │
│ MatchStart() called automatically   │
└─────────────────────────────────────┘
```

#### Timeout Flow
```
Player/Admin types !to (or .to)
    │
    ▼
┌─────────────────────────────┐
│ Pause match (if started)    │
│ Start Ready Check           │
│ Context: READY_CONTEXT_     │
│          TIMEOUT            │
│ Store who called timeout    │
└───────────┬─────────────────┘
            │
            ▼
┌─────────────────────────────┐
│ Panel shows all players     │
│ "TIMEOUT - Called by X"     │
│ Players type .r to ready    │
└───────────┬─────────────────┘
            │
      ┌─────┴─────┬──────────────┐
      │           │              │
  All Ready   Admin !ti    Caller !ti
      │           │              │
      ▼           ▼              ▼
┌─────────────────────────────────────┐
│ Close panels, unpause match         │
│ Resume with countdown               │
└─────────────────────────────────────┘
```

---

## Panel Display Format

```
╔═══════════════════════════════╗
║     READY CHECK - PREMATCH    ║
║      5/12 Players Ready       ║
║   Countdown: 45 seconds       ║
║_______________________________║
║                               ║
║ [CT] Counter-Terrorists       ║
║   [✓] PlayerName1             ║
║   [✓] PlayerName2             ║
║   [ ] PlayerName3             ║
║   [ ] PlayerName4             ║
║   [ ] PlayerName5             ║
║   [ ] PlayerName6             ║
║                               ║
║ [T] Terrorists                ║
║   [✓] PlayerName7             ║
║   [✓] PlayerName8             ║
║   [ ] PlayerName9             ║
║   [ ] PlayerName10            ║
║   [✓] PlayerName11            ║
║   [ ] PlayerName12            ║
║_______________________________║
║ ->1. Ready                    ║
║ ->2. Not Ready                ║
╚═══════════════════════════════╝
```

For timeout context:
```
╔═══════════════════════════════╗
║   TIMEOUT - Called by Admin   ║
║      8/12 Players Ready       ║
...
```

---

## Commands

### Player Commands
| Command | Aliases | Description |
|---------|---------|-------------|
| Ready | `.r`, `!r`, `.rdy`, `!rdy`, `.ready`, `!ready`, `sm_r`, `sm_rdy`, `sm_ready` | Mark yourself as ready |
| Not Ready | `.nr`, `!nr`, `.notready`, `!notready`, `sm_nr`, `sm_notready` | Mark yourself as not ready |
| Timeout | `.to`, `!to`, `sm_to`, `sm_timeout` | Call a timeout (pauses match, starts ready check) |

### Admin Commands
| Command | Description |
|---------|-------------|
| `!ti`, `sm_ti`, `sm_timein` | Force end timeout (admin or timeout caller) |
| `!forceready`, `sm_forceready` | Force all players ready, proceed immediately |
| `!cancelready`, `sm_cancelready` | Cancel current ready check without proceeding |

---

## Global Variables

### New Variables (globals.sp)

```sourcepawn
// Ready Check System
ReadyCheckContext readyCheckContext = READY_CONTEXT_NONE;
bool readyCheckActive = false;
int readyCheckCountdown = 0;           // Countdown timer (0 = no countdown)
int readyCheckTimeoutCaller = 0;       // Client who called timeout (0 = none)
bool playerReady[MAXPLAYERS+1];        // Per-player ready state
bool playerHidePanel[MAXPLAYERS+1];    // Per-player panel visibility preference

Handle readyCheckRefreshTimer = INVALID_HANDLE;
Handle readyCheckCountdownTimer = INVALID_HANDLE;

// Config options
int readyCheckPrematchCountdown = 60;  // Seconds for pre-match countdown (0 = wait forever until all ready)
int readyCheckTimeoutCountdown = 0;    // Seconds for timeout (0 = wait until all ready or admin !ti)
```

---

## Implementation

### Core Functions (modules/readycheck.sp)

```sourcepawn
// Start a ready check with specified context
public void ReadyCheckStart(ReadyCheckContext context, int countdown = 0, int caller = 0)
{
    if (readyCheckActive)
    {
        // Already active, ignore or notify
        return;
    }

    readyCheckContext = context;
    readyCheckActive = true;
    readyCheckCountdown = countdown;
    readyCheckTimeoutCaller = caller;

    // Reset all players to not ready
    for (int i = 1; i <= MaxClients; i++)
    {
        playerReady[i] = false;
        playerHidePanel[i] = false;
    }

    // Notify based on context
    switch (context)
    {
        case READY_CONTEXT_PREMATCH:
            CPrintToChatAll("{%s}[%s] {%s}Teams are set! Ready check started.", prefixcolor, prefix, textcolor);
            CPrintToChatAll("{%s}[%s] {%s}Type .r or press 1 when ready.", prefixcolor, prefix, textcolor);
            HostName_Change_Status("Ready Check");

        case READY_CONTEXT_TIMEOUT:
            if (caller > 0 && IsClientInGame(caller))
                CPrintToChatAll("{%s}[%s] {%s}%N called a timeout!", prefixcolor, prefix, textcolor, caller);
            else
                CPrintToChatAll("{%s}[%s] {%s}Timeout called!", prefixcolor, prefix, textcolor);
            CPrintToChatAll("{%s}[%s] {%s}Type .r when ready to resume.", prefixcolor, prefix, textcolor);

        case READY_CONTEXT_PAUSE:
            CPrintToChatAll("{%s}[%s] {%s}Match paused. Type .r when ready.", prefixcolor, prefix, textcolor);
    }

    // Start refresh timer (updates panel every 1 second)
    readyCheckRefreshTimer = CreateTimer(1.0, Timer_ReadyCheckRefresh, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    // Start countdown timer if specified
    if (countdown > 0)
    {
        readyCheckCountdownTimer = CreateTimer(1.0, Timer_ReadyCheckCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    // Show panel to all eligible players
    ReadyCheckUpdatePanel();
}

// End the ready check
public void ReadyCheckEnd(bool proceed)
{
    if (!readyCheckActive) return;

    ReadyCheckContext endedContext = readyCheckContext;

    // Kill timers
    if (readyCheckRefreshTimer != INVALID_HANDLE)
    {
        KillTimer(readyCheckRefreshTimer);
        readyCheckRefreshTimer = INVALID_HANDLE;
    }
    if (readyCheckCountdownTimer != INVALID_HANDLE)
    {
        KillTimer(readyCheckCountdownTimer);
        readyCheckCountdownTimer = INVALID_HANDLE;
    }

    // Close all panels
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientMenu(i) != MenuSource_None)
        {
            CancelClientMenu(i, false);
            InternalShowMenu(i, "\10", 1);
        }
    }

    readyCheckActive = false;
    readyCheckContext = READY_CONTEXT_NONE;
    readyCheckTimeoutCaller = 0;

    if (proceed)
    {
        switch (endedContext)
        {
            case READY_CONTEXT_PREMATCH:
                CPrintToChatAll("{%s}[%s] {%s}All players ready! Starting match...", prefixcolor, prefix, textcolor);
                // Auto-start match
                CreateTimer(2.0, Timer_AutoStartMatch);

            case READY_CONTEXT_TIMEOUT:
                CPrintToChatAll("{%s}[%s] {%s}All players ready! Resuming match...", prefixcolor, prefix, textcolor);
                MatchUnpause(0);

            case READY_CONTEXT_PAUSE:
                CPrintToChatAll("{%s}[%s] {%s}All players ready! Match resuming...", prefixcolor, prefix, textcolor);
                MatchUnpause(0);
        }
    }
    else
    {
        CPrintToChatAll("{%s}[%s] {%s}Ready check cancelled.", prefixcolor, prefix, textcolor);
        HostName_Change_Status("Public");
    }
}

// Check if all players are ready
public bool ReadyCheckAllReady()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;

        int team = GetClientTeam(i);
        if (team != 2 && team != 3) continue;  // Only T and CT

        if (!playerReady[i]) return false;
    }
    return true;
}

// Update/refresh the panel for all players
public void ReadyCheckUpdatePanel()
{
    if (!readyCheckActive) return;

    // Build panel once, send to all
    Panel panel = ReadyCheckBuildPanel();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;

        int team = GetClientTeam(i);
        if (team != 2 && team != 3) continue;

        if (!playerHidePanel[i])
        {
            SendPanelToClient(panel, i, ReadyCheckPanelHandler, 1);
        }
    }

    delete panel;
}

// Build the panel
public Panel ReadyCheckBuildPanel()
{
    Panel panel = new Panel();
    char buffer[256];

    // Title based on context
    switch (readyCheckContext)
    {
        case READY_CONTEXT_PREMATCH:
            panel.SetTitle("READY CHECK - PRE-MATCH");
        case READY_CONTEXT_TIMEOUT:
            if (readyCheckTimeoutCaller > 0 && IsClientInGame(readyCheckTimeoutCaller))
            {
                char callerName[MAX_NAME_LENGTH];
                GetClientName(readyCheckTimeoutCaller, callerName, sizeof(callerName));
                Format(buffer, sizeof(buffer), "TIMEOUT - %s", callerName);
                panel.SetTitle(buffer);
            }
            else
                panel.SetTitle("TIMEOUT");
        case READY_CONTEXT_PAUSE:
            panel.SetTitle("MATCH PAUSED");
    }

    // Ready count
    int readyCount = 0;
    int totalCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        int team = GetClientTeam(i);
        if (team != 2 && team != 3) continue;
        totalCount++;
        if (playerReady[i]) readyCount++;
    }

    Format(buffer, sizeof(buffer), "%d/%d Players Ready", readyCount, totalCount);
    panel.DrawText(buffer);

    // Countdown if active
    if (readyCheckCountdown > 0)
    {
        Format(buffer, sizeof(buffer), "Time: %d seconds", readyCheckCountdown);
        panel.DrawText(buffer);
    }

    panel.DrawText("_______________________");
    panel.DrawText(" ");

    // CT Players
    panel.DrawText("[CT] Counter-Terrorists");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        if (GetClientTeam(i) != 3) continue;

        char name[MAX_NAME_LENGTH];
        GetClientName(i, name, sizeof(name));

        // Truncate long names
        if (strlen(name) > 16)
        {
            name[16] = '\0';
            StrCat(name, sizeof(name), "..");
        }

        Format(buffer, sizeof(buffer), "  %s %s", playerReady[i] ? "[✓]" : "[ ]", name);
        panel.DrawText(buffer);
    }

    panel.DrawText(" ");

    // T Players
    panel.DrawText("[T] Terrorists");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        if (GetClientTeam(i) != 2) continue;

        char name[MAX_NAME_LENGTH];
        GetClientName(i, name, sizeof(name));

        if (strlen(name) > 16)
        {
            name[16] = '\0';
            StrCat(name, sizeof(name), "..");
        }

        Format(buffer, sizeof(buffer), "  %s %s", playerReady[i] ? "[✓]" : "[ ]", name);
        panel.DrawText(buffer);
    }

    panel.DrawText(" ");
    panel.DrawText("_______________________");
    panel.DrawText("->1. Ready");
    panel.DrawText("->2. Not Ready");

    panel.SetKeys((1 << 0) | (1 << 1));

    return panel;
}

// Panel handler
public int ReadyCheckPanelHandler(Handle panel, MenuAction action, int client, int key)
{
    if (action == MenuAction_Select && readyCheckActive)
    {
        if (key == 1)
        {
            playerReady[client] = true;
            CPrintToChat(client, "{%s}[%s] {%s}You are now READY.", prefixcolor, prefix, textcolor);
        }
        else if (key == 2)
        {
            playerReady[client] = false;
            CPrintToChat(client, "{%s}[%s] {%s}You are now NOT READY.", prefixcolor, prefix, textcolor);
        }

        // Check if all ready
        if (ReadyCheckAllReady())
        {
            ReadyCheckEnd(true);
        }
        else
        {
            ReadyCheckUpdatePanel();
        }
    }
    return 0;
}

// Timer: Refresh panel every second
public Action Timer_ReadyCheckRefresh(Handle timer)
{
    if (!readyCheckActive)
    {
        readyCheckRefreshTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }

    ReadyCheckUpdatePanel();
    return Plugin_Continue;
}

// Timer: Countdown (ticks every second)
public Action Timer_ReadyCheckCountdown(Handle timer)
{
    if (!readyCheckActive)
    {
        readyCheckCountdownTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }

    readyCheckCountdown--;

    if (readyCheckCountdown <= 0)
    {
        // Countdown expired - proceed to match regardless of ready state
        CPrintToChatAll("{%s}[%s] {%s}Countdown complete! Starting match...", prefixcolor, prefix, textcolor);
        ReadyCheckEnd(true);
        return Plugin_Stop;
    }

    // Announce at certain intervals
    if (readyCheckCountdown == 30 || readyCheckCountdown == 10 || readyCheckCountdown <= 5)
    {
        CPrintToChatAll("{%s}[%s] {%s}%d seconds remaining. Type .r to ready up!", prefixcolor, prefix, textcolor, readyCheckCountdown);
    }

    return Plugin_Continue;
}

// Timer: Auto-start match after pre-match ready check
public Action Timer_AutoStartMatch(Handle timer)
{
    // Call MatchStart with client 0 (system)
    MatchStart(0);
    return Plugin_Stop;
}
```

### Command Handlers (client_commands.sp)

```sourcepawn
// Ready command
public Action Command_Ready(int client, int args)
{
    if (!readyCheckActive)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    int team = GetClientTeam(client);
    if (team != 2 && team != 3)
    {
        CPrintToChat(client, "{%s}[%s] {%s}Only players on a team can ready up.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    playerReady[client] = true;
    CPrintToChat(client, "{%s}[%s] {%s}You are now READY.", prefixcolor, prefix, textcolor);

    if (ReadyCheckAllReady())
    {
        ReadyCheckEnd(true);
    }
    else
    {
        ReadyCheckUpdatePanel();
    }

    return Plugin_Handled;
}

// Not Ready command
public Action Command_NotReady(int client, int args)
{
    if (!readyCheckActive)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    playerReady[client] = false;
    CPrintToChat(client, "{%s}[%s] {%s}You are now NOT READY.", prefixcolor, prefix, textcolor);
    ReadyCheckUpdatePanel();

    return Plugin_Handled;
}

// Timeout command
public Action Command_Timeout(int client, int args)
{
    if (!matchStarted)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No match is in progress.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    if (matchPaused)
    {
        CPrintToChat(client, "{%s}[%s] {%s}Match is already paused.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    // Pause the match
    MatchPause(client);

    // Start ready check with timeout context
    ReadyCheckStart(READY_CONTEXT_TIMEOUT, readyCheckTimeoutCountdown, client);

    return Plugin_Handled;
}

// Time-in command (end timeout)
public Action Command_Timein(int client, int args)
{
    if (!readyCheckActive || readyCheckContext != READY_CONTEXT_TIMEOUT)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No timeout is active.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    // Check permission: admin or the person who called timeout
    bool canTimein = false;
    if (CheckCommandAccess(client, "sm_timein", ADMFLAG_GENERIC))
        canTimein = true;
    if (client == readyCheckTimeoutCaller)
        canTimein = true;

    if (!canTimein)
    {
        CPrintToChat(client, "{%s}[%s] {%s}Only an admin or the timeout caller can end the timeout.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    ReadyCheckEnd(true);
    return Plugin_Handled;
}

// Force ready (admin)
public Action Command_ForceReady(int client, int args)
{
    if (!readyCheckActive)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    CPrintToChatAll("{%s}[%s] {%s}Admin %N forced ready check to proceed.", prefixcolor, prefix, textcolor, client);
    ReadyCheckEnd(true);

    return Plugin_Handled;
}

// Cancel ready check (admin)
public Action Command_CancelReady(int client, int args)
{
    if (!readyCheckActive)
    {
        CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    CPrintToChatAll("{%s}[%s] {%s}Admin %N cancelled the ready check.", prefixcolor, prefix, textcolor, client);
    ReadyCheckEnd(false);

    return Plugin_Handled;
}

// Hide panel command
public Action Command_HidePanel(int client, int args)
{
    playerHidePanel[client] = true;
    CancelClientMenu(client);
    CPrintToChat(client, "{%s}[%s] {%s}Panel hidden. Type !show to show it again.", prefixcolor, prefix, textcolor);
    return Plugin_Handled;
}

// Show panel command
public Action Command_ShowPanel(int client, int args)
{
    playerHidePanel[client] = false;
    if (readyCheckActive)
    {
        ReadyCheckUpdatePanel();
    }
    return Plugin_Handled;
}
```

### Command Registration (OnPluginStart)

```sourcepawn
// Ready commands
RegConsoleCmd("sm_r", Command_Ready, "Mark yourself as ready");
RegConsoleCmd("sm_rdy", Command_Ready, "Mark yourself as ready");
RegConsoleCmd("sm_ready", Command_Ready, "Mark yourself as ready");

// Not Ready commands
RegConsoleCmd("sm_nr", Command_NotReady, "Mark yourself as not ready");
RegConsoleCmd("sm_notready", Command_NotReady, "Mark yourself as not ready");

// Timeout commands
RegConsoleCmd("sm_to", Command_Timeout, "Call a timeout");
RegConsoleCmd("sm_timeout", Command_Timeout, "Call a timeout");

// Time-in commands (end timeout - caller or admin)
RegConsoleCmd("sm_ti", Command_Timein, "End the timeout");
RegConsoleCmd("sm_timein", Command_Timein, "End the timeout");

// Admin commands
RegAdminCmd("sm_forceready", Command_ForceReady, ADMFLAG_GENERIC, "Force ready check to proceed");
RegAdminCmd("sm_cancelready", Command_CancelReady, ADMFLAG_GENERIC, "Cancel the ready check");

// Panel visibility
RegConsoleCmd("sm_hide", Command_HidePanel, "Hide the ready panel");
RegConsoleCmd("sm_show", Command_ShowPanel, "Show the ready panel");
```

### Say Command Listener (soccer_mod.sp)

```sourcepawn
// In SayCommandListener, add:
if (StrEqual(cmdArg1, ".r") || StrEqual(cmdArg1, ".rdy") || StrEqual(cmdArg1, ".ready"))
{
    Command_Ready(client, 0);
    return Plugin_Handled;
}
if (StrEqual(cmdArg1, ".nr") || StrEqual(cmdArg1, ".notready"))
{
    Command_NotReady(client, 0);
    return Plugin_Handled;
}
if (StrEqual(cmdArg1, ".to") || StrEqual(cmdArg1, ".timeout"))
{
    Command_Timeout(client, 0);
    return Plugin_Handled;
}
if (StrEqual(cmdArg1, ".ti") || StrEqual(cmdArg1, ".timein"))
{
    Command_Timein(client, 0);
    return Plugin_Handled;
}
if (StrEqual(cmdArg1, ".hide"))
{
    Command_HidePanel(client, 0);
    return Plugin_Handled;
}
if (StrEqual(cmdArg1, ".show"))
{
    Command_ShowPanel(client, 0);
    return Plugin_Handled;
}
```

---

## Integration Points

### 1. After Picking Completes (cap.sp)

In `CapPickMenuHandler`, after the last pick:

```sourcepawn
// After a successful pick:
capPickNumber++;
capPicksLeft--;

if (capPicksLeft > 0)
{
    capPicker = GetNextPicker();
    OpenCapPickMenu(capPicker);
}
else
{
    // All picks done - start ready check
    CPrintToChatAll("{%s}[%s] {%s}Picking complete!", prefixcolor, prefix, textcolor);

    // Reset cap state but keep teams
    capAutoActive = false;
    capPicker = 0;

    // Start pre-match ready check
    ReadyCheckStart(READY_CONTEXT_PREMATCH, readyCheckPrematchCountdown, 0);
}
```

### 2. CapReset Integration

`CapReset()` should also cancel any active ready check:

```sourcepawn
public void CapReset(int client)
{
    // ... existing reset code ...

    // Cancel active ready check if in pre-match context
    if (readyCheckActive && readyCheckContext == READY_CONTEXT_PREMATCH)
    {
        ReadyCheckEnd(false);
    }
}
```

### 3. Match Start Override

When ready check completes in pre-match context, it calls `MatchStart(0)`. The existing `MatchStart` function handles starting the match.

---

## Config Options

Add to `createconfig.sp` under a new section:

```sourcepawn
kvConfig.JumpToKey("Ready Check Settings", true);
kvConfig.SetNum("soccer_mod_readycheck_prematch_countdown", readyCheckPrematchCountdown);
kvConfig.SetNum("soccer_mod_readycheck_timeout_countdown", readyCheckTimeoutCountdown);
kvConfig.GoBack();
```

Read:
```sourcepawn
kvConfig.JumpToKey("Ready Check Settings", true);
readyCheckPrematchCountdown = kvConfig.GetNum("soccer_mod_readycheck_prematch_countdown", 60);
readyCheckTimeoutCountdown = kvConfig.GetNum("soccer_mod_readycheck_timeout_countdown", 0);
kvConfig.GoBack();
```

---

## Files to Modify

1. **globals.sp**
   - Add `ReadyCheckContext` enum
   - Add new ready check variables
   - Add config variables for countdown times

2. **modules/readycheck.sp** (MAJOR REWRITE)
   - Rewrite with new context-aware system
   - Add timer-based refresh
   - Add countdown support
   - New panel building function

3. **client_commands.sp**
   - Register new commands (sm_r, sm_to, sm_ti, etc.)
   - Add command handlers

4. **soccer_mod.sp**
   - Add say command listeners for .r, .to, .ti, etc.

5. **modules/cap.sp**
   - Integrate ready check start after picking completes
   - Update CapReset to cancel ready check

6. **createconfig.sp**
   - Add ready check config options

---

## Testing Checklist

### Pre-Match Ready Check
- [ ] After picking completes, ready check auto-starts
- [ ] Panel shows all 12 players with ready status
- [ ] Panel refreshes every 1 second
- [ ] .r / !r / press 1 marks player as ready
- [ ] .nr / !nr / press 2 marks player as not ready
- [ ] When all ready, match auto-starts
- [ ] Countdown expires → match starts anyway
- [ ] !forceready → proceeds immediately
- [ ] !cancelready → cancels without starting match
- [ ] !resetcap cancels ready check

### Timeout System
- [ ] !to / .to pauses match and starts ready check
- [ ] Panel shows "TIMEOUT - [PlayerName]"
- [ ] Only caller or admin can use !ti / .ti
- [ ] All ready → match resumes
- [ ] !ti ends timeout and resumes

### Panel Behavior
- [ ] !hide hides panel for that player
- [ ] !show brings panel back
- [ ] Panel doesn't block other critical actions
- [ ] No panel flicker (smooth refresh)

---

## Future Enhancements

1. **Sound effects** - Play sound when player readies, countdown beeps
2. **KeyHintText for spectators** - Show ready count for spectators
3. **Timeout limits** - Max timeouts per team per match
4. **Ready check for half-time** - Auto ready check during period break

---

## Version

Target: v1.4.6 or v1.5.0 (depending on scope)
