# WhoIS Integration Plan

## Overview

Integrate player name tracking system (WhoIS) into Soccer Mod. This tracks player names across sessions, allows players to set aliases, and announces returning players by their known names.

---

## Features to Integrate

### 1. Player Name Tracking
- Store first name ever seen for each player
- Track current name on each connection
- Record all name changes with timestamps
- Track connection count and timestamps

### 2. Alias System
- Players can set a preferred alias with `!alias <name>`
- Alias is displayed instead of first name in "Known as" announcements
- `!alias` with no args shows current alias

### 3. Connect Announcements
- When player connects: "Player CurrentName connected. Known as: Alias/FirstName"
- New players: "Welcome new player: PlayerName"
- Only shows "Known as" if name differs from alias/first name

### 4. WhoIS Lookup Commands
- `!whois` - Opens player selection menu
- `!whois <player>` - Direct lookup
- Shows: Name, Alias, First Name, SteamID, Connections, Admin status
- IP shown only to admins

### 5. Name History (Admin)
- `!whois_history` - Opens player selection menu
- `!whois_history <player>` - Direct lookup
- Shows last 10 names with dates

---

## Database Schema

### Table: `whois_players`
```sql
CREATE TABLE IF NOT EXISTS whois_players (
    steamid VARCHAR(32) PRIMARY KEY NOT NULL,
    first_name VARCHAR(64) NOT NULL,
    current_name VARCHAR(64) NOT NULL,
    alias VARCHAR(64) DEFAULT NULL,
    ip_address VARCHAR(16) NOT NULL,
    first_seen INT NOT NULL,
    last_seen INT NOT NULL,
    connection_count INT DEFAULT 1
)
```

### Table: `whois_names`
```sql
CREATE TABLE IF NOT EXISTS whois_names (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steamid VARCHAR(32) NOT NULL,
    name VARCHAR(64) NOT NULL,
    first_used INT NOT NULL,
    last_used INT NOT NULL,
    INDEX idx_steamid (steamid)
)
```

---

## Implementation Plan

### Phase 1: Database Tables
**Files:** `modules/database.sp` or new `modules/whois.sp`

1. Add table creation queries to database initialization
2. Handle ALTER TABLE for adding alias column to existing tables
3. Use existing `soccermod` database connection

### Phase 2: Player Connection Tracking
**Files:** `soccer_mod.sp` (OnClientAuthorized hook), `modules/whois.sp`

1. On player connect (OnClientAuthorized):
   - Check if player exists in database
   - If exists: Update current_name, ip, last_seen, increment connection_count
   - If name changed: Add to whois_names history
   - Announce with "Known as" if alias/first_name differs
   - If new: Insert player record and announce welcome

2. Name change tracking:
   - Check if name exists in history
   - If exists: Update last_used
   - If new: Insert name record

### Phase 3: Commands
**Files:** `client_commands.sp`, `soccer_mod.sp` (say listener), `modules/whois.sp`

1. Register commands in OnPluginStart:
   - `sm_whois` - Console command
   - `sm_alias` - Console command
   - `sm_whois_history` - Admin command

2. Add say listeners for:
   - `.whois` / `.alias` / `.history`

3. Implement command handlers:
   - `Command_WhoIs` - Player lookup with menu fallback
   - `Command_Alias` - Set/view alias
   - `Command_WhoIsHistory` - Admin name history lookup

### Phase 4: Menu Integration
**Files:** `modules/whois.sp`

1. Player selection menu for `!whois`
2. Player selection menu for `!whois_history` (admin)

### Phase 5: Config Options
**Files:** `globals.sp`, `createconfig.sp`

1. Add config options:
   - `whois_enabled` (bool) - Enable/disable WhoIS system
   - `whois_announce_connect` (bool) - Show connect announcements
   - `whois_announce_new_player` (bool) - Show new player announcements

---

## File Structure

### Option A: Single Module File
```
modules/whois.sp
├── WhoISOnPluginStart()
├── WhoISCreateTables()
├── WhoISOnClientAuthorized()
├── WhoISRecordNameChange()
├── Command_WhoIs()
├── Command_Alias()
├── Command_WhoIsHistory()
├── WhoISShowPlayerMenu()
├── WhoISLookupPlayer()
└── WhoISLookupHistory()
```

### Option B: Subfolder Structure (if complex)
```
modules/whois/
├── database.sp    - Table creation, queries
├── tracking.sp    - Connection tracking, name changes
├── commands.sp    - Command handlers
└── menu.sp        - Menu handlers
```

**Recommendation:** Option A (single file) - similar complexity to other modules

---

## Commands Summary

| Command | Aliases | Access | Description |
|---------|---------|--------|-------------|
| `!whois` | `.whois` | All | Look up player info |
| `!alias` | `.alias` | All | Set/view your alias |
| `!whois_history` | `.history` | Admin | View player name history |

---

## Integration Points

### 1. Database Connection
Soccer Mod already has database support. Reuse existing connection:
- Check if `g_Database` or similar exists
- If not, check how stats/ranking connects

### 2. OnClientAuthorized Hook
Add call to `WhoISOnClientAuthorized(client, auth)` in main hook

### 3. OnPluginStart
Add call to `WhoISOnPluginStart()` for command registration

### 4. Config
Add to `ReadFromConfig()` and `CreateSoccerModConfig()`

---

## Color Scheme (using morecolors.inc)

```sourcepawn
// Announcement
CPrintToChatAll("{%s}[%s] {%s}Player {green}%s {%s}connected. Known as: {green}%s",
    prefixcolor, prefix, textcolor, currentName, textcolor, knownAs);

// New player
CPrintToChatAll("{%s}[%s] {green}Welcome new player: {%s}%s",
    prefixcolor, prefix, textcolor, currentName);

// WhoIS output
CPrintToChat(client, "{%s}[%s] {green}=== Player Info ===", prefixcolor, prefix);
CPrintToChat(client, "{%s}[%s] {%s}Name: {green}%s", prefixcolor, prefix, textcolor, name);
```

---

## Testing Checklist

- [ ] Tables created on first run
- [ ] New player recorded correctly
- [ ] Returning player updated correctly
- [ ] Name change recorded in history
- [ ] Connect announcement shows "Known as" when different
- [ ] New player welcome announcement
- [ ] `!alias` sets alias
- [ ] `!alias` shows current alias
- [ ] `!whois` opens menu
- [ ] `!whois <name>` direct lookup
- [ ] `!whois_history` works (admin only)
- [ ] IP only shown to admins
- [ ] Config options work

---

## Future Enhancements

1. **Country/Region** - GeoIP lookup for player location
2. **Playtime tracking** - Total time on server
3. **Ban history** - Integration with ban system
4. **Admin notes** - Admins can add notes to players
5. **VPN detection** - Flag suspicious IPs

---

## Version Target

**v1.4.8** or **v1.5.0** depending on scope
