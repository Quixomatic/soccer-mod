# Join/Leave Notification System Plan

## Overview

Add audio and chat notifications when players join or leave the server, showing current player count vs required players. Includes configurable sounds and per-player preferences.

## Features

### 1. Join Notification
- Play a configurable sound when a player joins
- Show chat message: `[Soccer Mod] PlayerName joined (11/12 players)`
- Special message when server becomes full: `(12/12 players) - Ready to play!`

### 2. Leave Notification
- Play a configurable sound when a player leaves
- Show chat message: `[Soccer Mod] PlayerName left (10/12 players)`

### 3. Sound Configuration
- Sounds stored in `sound/soccermod/joinleave/` folder
- Config file: `cfg/sm_soccermod/soccer_mod_joinleave.cfg`
- Admin can set which sound files to use for join/leave events
- Sounds precached on map start

### 4. Per-Player Preferences (Client Cookies)
- Each player can toggle notifications ON/OFF for themselves
- Accessible via `!settings` menu or dedicated command
- Saved per-player using SourceMod cookies (persists across sessions)
- Similar to existing shout preferences

### 5. Server-Wide Settings
- Global toggle to enable/disable the system entirely
- Configurable via admin settings menu

### 6. Player Count Logic
- Required players = `matchMaxPlayers * 2`
- 6v6 maps = 12 players needed
- 4v4 maps = 8 players needed
- Only count real players (not bots, not SourceTV)

---

## Sound Files Structure

```
sound/soccermod/joinleave/
├── join.wav          (default join sound)
├── leave.wav         (default leave sound)
├── ready.wav         (optional: played when server is full)
└── ... (additional sound options)
```

---

## Config File

**Path:** `cfg/sm_soccermod/soccer_mod_joinleave.cfg`

```
"JoinLeave"
{
    "join_sound"    "soccermod/joinleave/join.wav"
    "leave_sound"   "soccermod/joinleave/leave.wav"
    "ready_sound"   "soccermod/joinleave/ready.wav"   // when 12/12
    "volume"        "1.0"
}
```

---

## Implementation

### New Global Variables (globals.sp)
```sourcepawn
// Server-wide settings
int joinLeaveEnabled = 1;           // 0=OFF, 1=ON (global toggle)

// Per-client preferences (cookie-backed)
int pcJoinLeaveSound[MAXPLAYERS+1] = {1, ...};   // Per-client sound toggle
int pcJoinLeaveChat[MAXPLAYERS+1] = {1, ...};    // Per-client chat toggle

// Sound paths from config
char joinLeaveJoinSound[PLATFORM_MAX_PATH];
char joinLeaveLeaveSound[PLATFORM_MAX_PATH];
char joinLeaveReadySound[PLATFORM_MAX_PATH];
float joinLeaveVolume = 1.0;

// Cookie handles
Handle h_JOINLEAVE_SOUND_COOKIE = INVALID_HANDLE;
Handle h_JOINLEAVE_CHAT_COOKIE = INVALID_HANDLE;
```

### Config File Path (globals.sp)
```sourcepawn
char joinLeaveConfigFile[PLATFORM_MAX_PATH] = "cfg/sm_soccermod/soccer_mod_joinleave.cfg";
```

### Cookie Registration (OnPluginStart)
```sourcepawn
h_JOINLEAVE_SOUND_COOKIE = RegClientCookie("sm_joinleave_sound", "Join/Leave sound preference", CookieAccess_Protected);
h_JOINLEAVE_CHAT_COOKIE = RegClientCookie("sm_joinleave_chat", "Join/Leave chat preference", CookieAccess_Protected);
```

### Config Auto-Generation (createconfig.sp pattern)
Add to `ConfigFunc()`:
```sourcepawn
if (!FileExists(joinLeaveConfigFile)) CreateJoinLeaveConfig();
```

New function in createconfig.sp:
```sourcepawn
public void CreateJoinLeaveConfig()
{
    File hFile = OpenFile(joinLeaveConfigFile, "w");
    hFile.Close();

    KeyValues kv = new KeyValues("JoinLeave");
    kv.ImportFromFile(joinLeaveConfigFile);

    kv.JumpToKey("Sounds", true);
    kv.SetString("join_sound", "soccermod/joinleave/join.wav");
    kv.SetString("leave_sound", "soccermod/joinleave/leave.wav");
    kv.SetString("ready_sound", "soccermod/joinleave/ready.wav");
    kv.SetFloat("volume", 1.0);
    kv.GoBack();

    kv.JumpToKey("Settings", true);
    kv.SetNum("enabled", 1);
    kv.GoBack();

    kv.Rewind();
    kv.ExportToFile(joinLeaveConfigFile);
    kv.Close();
}
```

### Config Read (new function)
```sourcepawn
public void LoadJoinLeaveConfig()
{
    // Auto-create if missing
    if (!FileExists(joinLeaveConfigFile)) CreateJoinLeaveConfig();

    KeyValues kv = new KeyValues("JoinLeave");
    kv.ImportFromFile(joinLeaveConfigFile);

    kv.JumpToKey("Sounds", false);
    kv.GetString("join_sound", joinLeaveJoinSound, sizeof(joinLeaveJoinSound), "soccermod/joinleave/join.wav");
    kv.GetString("leave_sound", joinLeaveLeaveSound, sizeof(joinLeaveLeaveSound), "soccermod/joinleave/leave.wav");
    kv.GetString("ready_sound", joinLeaveReadySound, sizeof(joinLeaveReadySound), "soccermod/joinleave/ready.wav");
    joinLeaveVolume = kv.GetFloat("volume", 1.0);
    kv.GoBack();

    kv.JumpToKey("Settings", false);
    joinLeaveEnabled = kv.GetNum("enabled", 1);
    kv.GoBack();

    kv.Rewind();
    kv.Close();

    // Precache sounds if they exist
    char soundPath[PLATFORM_MAX_PATH];

    Format(soundPath, sizeof(soundPath), "sound/%s", joinLeaveJoinSound);
    if (FileExists(soundPath)) PrecacheSound(joinLeaveJoinSound);

    Format(soundPath, sizeof(soundPath), "sound/%s", joinLeaveLeaveSound);
    if (FileExists(soundPath)) PrecacheSound(joinLeaveLeaveSound);

    Format(soundPath, sizeof(soundPath), "sound/%s", joinLeaveReadySound);
    if (FileExists(soundPath)) PrecacheSound(joinLeaveReadySound);
}
```

### Cookie Read (OnClientCookiesCached)
```sourcepawn
public void JoinLeaveOnClientCookiesCached(int client)
{
    char buffer[8];

    GetClientCookie(client, h_JOINLEAVE_SOUND_COOKIE, buffer, sizeof(buffer));
    pcJoinLeaveSound[client] = (buffer[0] == '\0') ? 1 : StringToInt(buffer);

    GetClientCookie(client, h_JOINLEAVE_CHAT_COOKIE, buffer, sizeof(buffer));
    pcJoinLeaveChat[client] = (buffer[0] == '\0') ? 1 : StringToInt(buffer);
}
```

### Event Hooks (soccer_mod.sp)
Add calls to joinleave module in these existing hooks:

```sourcepawn
// In OnClientPostAdminCheck or after player fully loads
public void OnClientPostAdminCheck(int client)
{
    // ... existing code ...
    JoinLeaveNotifyJoin(client);
}

// In OnClientDisconnect
public void OnClientDisconnect(int client)
{
    // Call BEFORE client is fully disconnected so we can get their name
    JoinLeaveNotifyLeave(client);
    // ... existing code ...
}
```

### Core Functions (modules/joinleave.sp)
```sourcepawn
public void JoinLeaveNotifyJoin(int client)
{
    if (!joinLeaveEnabled) return;
    if (IsFakeClient(client) || IsClientSourceTV(client)) return;

    int current = GetRealPlayerCount();
    int required = matchMaxPlayers * 2;
    bool isFull = (current >= required);

    // Chat notification
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && pcJoinLeaveChat[i])
        {
            if (isFull)
                CPrintToChat(i, "{%s}[%s] {%s}%N joined (%d/%d players) - Ready to play!",
                    prefixcolor, prefix, textcolor, client, current, required);
            else
                CPrintToChat(i, "{%s}[%s] {%s}%N joined (%d/%d players)",
                    prefixcolor, prefix, textcolor, client, current, required);
        }
    }

    // Sound notification
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && pcJoinLeaveSound[i])
        {
            if (isFull && strlen(joinLeaveReadySound) > 0)
                EmitSoundToClient(i, joinLeaveReadySound, _, _, _, _, joinLeaveVolume);
            else
                EmitSoundToClient(i, joinLeaveJoinSound, _, _, _, _, joinLeaveVolume);
        }
    }
}

public void JoinLeaveNotifyLeave(int client)
{
    if (!joinLeaveEnabled) return;
    if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client)) return;

    int current = GetRealPlayerCount() - 1;  // -1 because they're leaving
    int required = matchMaxPlayers * 2;

    // Chat notification
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && i != client && pcJoinLeaveChat[i])
        {
            CPrintToChat(i, "{%s}[%s] {%s}%N left (%d/%d players)",
                prefixcolor, prefix, textcolor, client, current, required);
        }
    }

    // Sound notification
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && i != client && pcJoinLeaveSound[i])
        {
            EmitSoundToClient(i, joinLeaveLeaveSound, _, _, _, _, joinLeaveVolume);
        }
    }
}

public int GetRealPlayerCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
            count++;
    }
    return count;
}
```

### Player Settings Menu
```
!settings or !menu > Settings > Personal Settings >
  ├── Join/Leave sounds: ON/OFF
  └── Join/Leave chat: ON/OFF
```

### Admin Settings Menu
```
!menu > Settings > Server Settings >
  └── Join/Leave notifications: ON/OFF (global)
```

---

### Directory Creation (OnPluginStart)
```sourcepawn
// In JoinLeaveOnPluginStart() or main OnPluginStart
if (!DirExists("sound/soccermod/joinleave"))
    CreateDirectory("sound/soccermod/joinleave", 511, false);
```

### Config Update Function (createconfig.sp)
```sourcepawn
public void UpdateJoinLeaveConfig(char section[32], char type[50], char value[128])
{
    if (!FileExists(joinLeaveConfigFile)) CreateJoinLeaveConfig();

    KeyValues kv = new KeyValues("JoinLeave");
    kv.ImportFromFile(joinLeaveConfigFile);
    kv.JumpToKey(section, true);
    kv.SetString(type, value);

    kv.Rewind();
    kv.ExportToFile(joinLeaveConfigFile);
    kv.Close();
}

public void UpdateJoinLeaveConfigInt(char section[32], char type[50], int value)
{
    if (!FileExists(joinLeaveConfigFile)) CreateJoinLeaveConfig();

    KeyValues kv = new KeyValues("JoinLeave");
    kv.ImportFromFile(joinLeaveConfigFile);
    kv.JumpToKey(section, true);
    kv.SetNum(type, value);

    kv.Rewind();
    kv.ExportToFile(joinLeaveConfigFile);
    kv.Close();
}
```

---

## Files to Modify/Create

1. **globals.sp** - Add variables, cookie handles, config path
2. **createconfig.sp** - Add `CreateJoinLeaveConfig()`, update functions, add to `ConfigFunc()`
3. **soccer_mod.sp** - Add hooks, cookie registration, call LoadJoinLeaveConfig on map start
4. **modules/joinleave.sp** (NEW) - Core notification logic
5. **modules/menus/settings.sp** - Add personal preference toggles
6. **cfg/sm_soccermod/soccer_mod_joinleave.cfg** (AUTO-GENERATED) - Sound config file

---

## Visual Examples

**Player joins (not full):**
```
[Soccer Mod] Arctic joined (11/12 players)
*join sound plays for players with sound enabled*
```

**Player joins (now full):**
```
[Soccer Mod] Arctic joined (12/12 players) - Ready to play!
*ready sound plays*
```

**Player leaves:**
```
[Soccer Mod] Arctic left (10/12 players)
*leave sound plays*
```

---

## Default Sound Suggestions

Need to source or create:
- `join.wav` - Short positive chime/ding
- `leave.wav` - Short neutral tone
- `ready.wav` - More celebratory sound for "server full"

Could use built-in Source sounds as fallback:
- `buttons/button9.wav`
- `buttons/button10.wav`
- `ui/buttonclick.wav`
