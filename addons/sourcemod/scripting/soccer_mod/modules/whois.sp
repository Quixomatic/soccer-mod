// ************************************************************************************************************
// ************************************************** WHOIS ***************************************************
// ************************************************************************************************************
// Player name tracking with database support - ported from whois_enhanced.sp

public void WhoISOnPluginStart()
{
	// Commands are registered in client_commands.sp
}

public void WhoISCreateTables()
{
	if (db == INVALID_HANDLE)
		return;

	char query[1024];

	// Main player table - stores current info
	Format(query, sizeof(query),
		"CREATE TABLE IF NOT EXISTS whois_players ( \
			steamid VARCHAR(32) PRIMARY KEY NOT NULL, \
			first_name VARCHAR(64) NOT NULL, \
			current_name VARCHAR(64) NOT NULL, \
			alias VARCHAR(64) DEFAULT NULL, \
			ip_address VARCHAR(16) NOT NULL, \
			first_seen INT NOT NULL, \
			last_seen INT NOT NULL, \
			connection_count INT DEFAULT 1 \
		)");
	SQL_FastQuery(db, query);

	// Add alias column to existing tables (will fail silently if already exists)
	SQL_FastQuery(db, "ALTER TABLE whois_players ADD COLUMN alias VARCHAR(64) DEFAULT NULL");

	// Name history table - stores all name changes
	Format(query, sizeof(query),
		"CREATE TABLE IF NOT EXISTS whois_names ( \
			id INT AUTO_INCREMENT PRIMARY KEY, \
			steamid VARCHAR(32) NOT NULL, \
			name VARCHAR(64) NOT NULL, \
			first_used INT NOT NULL, \
			last_used INT NOT NULL, \
			INDEX idx_steamid (steamid) \
		)");
	SQL_FastQuery(db, query);
}

public void WhoISOnClientAuthorized(int client, const char[] auth)
{
	if (db == INVALID_HANDLE)
		return;

	if (IsFakeClient(client))
		return;

	char steamid[32], name[64], escapedName[129], ip[16];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientName(client, name, sizeof(name));
	GetClientIP(client, ip, sizeof(ip));

	SQL_EscapeString(db, name, escapedName, sizeof(escapedName));

	// Check if player exists
	char query[512];
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(steamid);
	pack.WriteString(escapedName);
	pack.WriteString(ip);

	Format(query, sizeof(query),
		"SELECT first_name, current_name, alias FROM whois_players WHERE steamid = '%s'",
		steamid);

	SQL_TQuery(db, WhoISOnPlayerLookup, query, pack);
}

public void WhoISOnPlayerLookup(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();

	char steamid[32], escapedName[129], ip[16];
	pack.ReadString(steamid, sizeof(steamid));
	pack.ReadString(escapedName, sizeof(escapedName));
	pack.ReadString(ip, sizeof(ip));
	delete pack;

	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;

	char currentName[64];
	GetClientName(client, currentName, sizeof(currentName));

	int timestamp = GetTime();
	char query[512];

	if (hndl == INVALID_HANDLE)
	{
		LogError("[WhoIS] Player lookup failed: %s", error);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		// Existing player
		char firstName[64], lastName[64], alias[64];
		SQL_FetchString(hndl, 0, firstName, sizeof(firstName));
		SQL_FetchString(hndl, 1, lastName, sizeof(lastName));
		SQL_FetchString(hndl, 2, alias, sizeof(alias));

		// Update player record
		Format(query, sizeof(query),
			"UPDATE whois_players SET current_name = '%s', ip_address = '%s', \
			 last_seen = %d, connection_count = connection_count + 1 \
			 WHERE steamid = '%s'",
			escapedName, ip, timestamp, steamid);
		SQL_TQuery(db, WhoISOnQueryComplete, query);

		// Check if name changed, add to history
		if (!StrEqual(currentName, lastName))
		{
			WhoISRecordNameChange(steamid, escapedName, timestamp);
		}

		// Announce with alias (preferred) or first known name
		char knownAs[64];
		if (strlen(alias) > 0)
		{
			strcopy(knownAs, sizeof(knownAs), alias);
		}
		else
		{
			strcopy(knownAs, sizeof(knownAs), firstName);
		}

		if (!StrEqual(currentName, knownAs))
		{
			CPrintToChatAll("{%s}[%s] {%s}Player {green}%s {%s}connected. Known as: {green}%s",
				prefixcolor, prefix, textcolor, currentName, textcolor, knownAs);
		}
	}
	else
	{
		// New player - insert
		Format(query, sizeof(query),
			"INSERT INTO whois_players (steamid, first_name, current_name, ip_address, first_seen, last_seen) \
			 VALUES ('%s', '%s', '%s', '%s', %d, %d)",
			steamid, escapedName, escapedName, ip, timestamp, timestamp);
		SQL_TQuery(db, WhoISOnQueryComplete, query);

		// Also add to name history
		WhoISRecordNameChange(steamid, escapedName, timestamp);

		CPrintToChatAll("{%s}[%s] {green}Welcome new player: {%s}%s", prefixcolor, prefix, textcolor, currentName);
	}
}

void WhoISRecordNameChange(const char[] steamid, const char[] escapedName, int timestamp)
{
	char query[512];

	// Check if this name already exists for this player
	DataPack pack = new DataPack();
	pack.WriteString(steamid);
	pack.WriteString(escapedName);
	pack.WriteCell(timestamp);

	Format(query, sizeof(query),
		"SELECT id FROM whois_names WHERE steamid = '%s' AND name = '%s'",
		steamid, escapedName);

	SQL_TQuery(db, WhoISOnNameCheck, query, pack);
}

public void WhoISOnNameCheck(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	char steamid[32], escapedName[129];
	pack.ReadString(steamid, sizeof(steamid));
	pack.ReadString(escapedName, sizeof(escapedName));
	int timestamp = pack.ReadCell();
	delete pack;

	char query[512];

	if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		// Name exists, update last_used
		int id = SQL_FetchInt(hndl, 0);
		Format(query, sizeof(query),
			"UPDATE whois_names SET last_used = %d WHERE id = %d",
			timestamp, id);
	}
	else
	{
		// New name, insert
		Format(query, sizeof(query),
			"INSERT INTO whois_names (steamid, name, first_used, last_used) \
			 VALUES ('%s', '%s', %d, %d)",
			steamid, escapedName, timestamp, timestamp);
	}

	SQL_TQuery(db, WhoISOnQueryComplete, query);
}

public void WhoISOnQueryComplete(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[WhoIS] Query failed: %s", error);
	}
}

// ************************************************************************************************************
// ************************************************ COMMANDS **************************************************
// ************************************************************************************************************

public Action Command_Alias(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[WhoIS] This command can only be used in-game.");
		return Plugin_Handled;
	}

	if (db == INVALID_HANDLE)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Database not connected!", prefixcolor, prefix, textcolor);
		return Plugin_Handled;
	}

	if (args < 1)
	{
		// Show current alias
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));

		char query[256];
		Format(query, sizeof(query),
			"SELECT alias FROM whois_players WHERE steamid = '%s'", steamid);

		SQL_TQuery(db, WhoISOnAliasLookup, query, pack);
		return Plugin_Handled;
	}

	// Get the alias they want to set
	char newAlias[64], escapedAlias[129];
	GetCmdArgString(newAlias, sizeof(newAlias));

	// Trim quotes if present
	StripQuotes(newAlias);
	TrimString(newAlias);

	if (strlen(newAlias) == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Usage: {green}!alias <your preferred name>", prefixcolor, prefix, textcolor);
		return Plugin_Handled;
	}

	if (strlen(newAlias) > 32)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Alias too long! Maximum 32 characters.", prefixcolor, prefix, textcolor);
		return Plugin_Handled;
	}

	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	SQL_EscapeString(db, newAlias, escapedAlias, sizeof(escapedAlias));

	char query[256];
	Format(query, sizeof(query),
		"UPDATE whois_players SET alias = '%s' WHERE steamid = '%s'",
		escapedAlias, steamid);

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(newAlias);

	SQL_TQuery(db, WhoISOnAliasSet, query, pack);

	return Plugin_Handled;
}

public void WhoISOnAliasLookup(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	int clientUserId = pack.ReadCell();
	delete pack;

	int client = GetClientOfUserId(clientUserId);
	if (client == 0)
		return;

	if (hndl == INVALID_HANDLE)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Database error!", prefixcolor, prefix, textcolor);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		char alias[64];
		SQL_FetchString(hndl, 0, alias, sizeof(alias));

		if (strlen(alias) > 0)
		{
			CPrintToChat(client, "{%s}[%s] {%s}Your current alias: {green}%s", prefixcolor, prefix, textcolor, alias);
		}
		else
		{
			CPrintToChat(client, "{%s}[%s] {%s}You have no alias set. Use {green}!alias <name> {%s}to set one.", prefixcolor, prefix, textcolor, textcolor);
		}
	}
	else
	{
		CPrintToChat(client, "{%s}[%s] {%s}No player record found. Connect to the server first.", prefixcolor, prefix, textcolor);
	}
}

public void WhoISOnAliasSet(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	int clientUserId = pack.ReadCell();
	char newAlias[64];
	pack.ReadString(newAlias, sizeof(newAlias));
	delete pack;

	int client = GetClientOfUserId(clientUserId);
	if (client == 0)
		return;

	if (hndl == INVALID_HANDLE)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Failed to set alias: %s", prefixcolor, prefix, textcolor, error);
		return;
	}

	CPrintToChat(client, "{%s}[%s] {%s}Your alias has been set to: {green}%s", prefixcolor, prefix, textcolor, newAlias);
}

public Action Command_WhoIs(int client, int args)
{
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[WhoIS] Database not connected!");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		// No arguments - show player selection menu
		WhoISShowPlayerMenu(client);
		return Plugin_Handled;
	}

	char targetArg[64];
	GetCmdArg(1, targetArg, sizeof(targetArg));

	int target = FindTarget(client, targetArg, true, false);
	if (target == -1)
		return Plugin_Handled;

	WhoISLookupPlayer(client, target);

	return Plugin_Handled;
}

void WhoISShowPlayerMenu(int client)
{
	Menu menu = new Menu(WhoISPlayerMenuHandler);
	menu.SetTitle("WhoIS - Select Player");

	char userid[12], name[64];
	int playerCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		GetClientName(i, name, sizeof(name));
		IntToString(GetClientUserId(i), userid, sizeof(userid));
		menu.AddItem(userid, name);
		playerCount++;
	}

	if (playerCount == 0)
	{
		delete menu;
		CPrintToChat(client, "{%s}[%s] {%s}No players found.", prefixcolor, prefix, textcolor);
		return;
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int WhoISPlayerMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char userid[12];
			menu.GetItem(param2, userid, sizeof(userid));

			int target = GetClientOfUserId(StringToInt(userid));
			if (target == 0)
			{
				CPrintToChat(param1, "{%s}[%s] {%s}Player no longer available.", prefixcolor, prefix, textcolor);
				return 0;
			}

			WhoISLookupPlayer(param1, target);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void WhoISLookupPlayer(int client, int target)
{
	char steamid[32];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(GetClientUserId(target));

	char query[512];
	Format(query, sizeof(query),
		"SELECT first_name, current_name, ip_address, first_seen, last_seen, connection_count, alias \
		 FROM whois_players WHERE steamid = '%s'", steamid);

	SQL_TQuery(db, WhoISOnWhoIsResult, query, pack);
}

public void WhoISOnWhoIsResult(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	int clientUserId = pack.ReadCell();
	int targetUserId = pack.ReadCell();
	delete pack;

	int client = GetClientOfUserId(clientUserId);
	int target = GetClientOfUserId(targetUserId);

	if (client == 0 || target == 0)
		return;

	if (hndl == INVALID_HANDLE)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Database error!", prefixcolor, prefix, textcolor);
		return;
	}

	if (!SQL_FetchRow(hndl))
	{
		CPrintToChat(client, "{%s}[%s] {%s}No data found for this player.", prefixcolor, prefix, textcolor);
		return;
	}

	char firstName[64], currentName[64], ip[16], steamid[32], alias[64];
	int connectionCount;

	SQL_FetchString(hndl, 0, firstName, sizeof(firstName));
	SQL_FetchString(hndl, 1, currentName, sizeof(currentName));
	SQL_FetchString(hndl, 2, ip, sizeof(ip));
	// Skip firstSeen (index 3) and lastSeen (index 4) - not displayed
	connectionCount = SQL_FetchInt(hndl, 5);
	SQL_FetchString(hndl, 6, alias, sizeof(alias));

	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));

	char targetName[64];
	GetClientName(target, targetName, sizeof(targetName));

	bool isAdmin = (GetUserFlagBits(target) != 0);
	bool viewerIsAdmin = (GetUserFlagBits(client) & ADMFLAG_GENERIC) != 0;

	CPrintToChat(client, "{%s}[%s] {green}=== Player Info ===", prefixcolor, prefix);
	CPrintToChat(client, "{%s}[%s] {%s}Name: {green}%s", prefixcolor, prefix, textcolor, targetName);

	// Show alias if set, otherwise show first name
	if (strlen(alias) > 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Alias: {green}%s", prefixcolor, prefix, textcolor, alias);
		CPrintToChat(client, "{%s}[%s] {%s}First Name: {green}%s", prefixcolor, prefix, textcolor, firstName);
	}
	else
	{
		CPrintToChat(client, "{%s}[%s] {%s}First Name: {green}%s", prefixcolor, prefix, textcolor, firstName);
	}

	CPrintToChat(client, "{%s}[%s] {%s}SteamID: {green}%s", prefixcolor, prefix, textcolor, steamid);
	CPrintToChat(client, "{%s}[%s] {%s}Connections: {green}%d", prefixcolor, prefix, textcolor, connectionCount);
	CPrintToChat(client, "{%s}[%s] {%s}Admin: {green}%s", prefixcolor, prefix, textcolor, isAdmin ? "Yes" : "No");

	// Only show IP to admins
	if (viewerIsAdmin)
	{
		CPrintToChat(client, "{%s}[%s] {%s}IP: {green}%s", prefixcolor, prefix, textcolor, ip);
	}
}

public Action Command_WhoIsHistory(int client, int args)
{
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[WhoIS] Database not connected!");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		// No arguments - show player selection menu for history
		WhoISShowHistoryMenu(client);
		return Plugin_Handled;
	}

	char targetArg[64];
	GetCmdArg(1, targetArg, sizeof(targetArg));

	int target = FindTarget(client, targetArg, true, false);
	if (target == -1)
		return Plugin_Handled;

	WhoISLookupPlayerHistory(client, target);

	return Plugin_Handled;
}

void WhoISShowHistoryMenu(int client)
{
	Menu menu = new Menu(WhoISHistoryMenuHandler);
	menu.SetTitle("WhoIS History - Select Player");

	char userid[12], name[64];
	int playerCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		GetClientName(i, name, sizeof(name));
		IntToString(GetClientUserId(i), userid, sizeof(userid));
		menu.AddItem(userid, name);
		playerCount++;
	}

	if (playerCount == 0)
	{
		delete menu;
		CPrintToChat(client, "{%s}[%s] {%s}No players found.", prefixcolor, prefix, textcolor);
		return;
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int WhoISHistoryMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char userid[12];
			menu.GetItem(param2, userid, sizeof(userid));

			int target = GetClientOfUserId(StringToInt(userid));
			if (target == 0)
			{
				CPrintToChat(param1, "{%s}[%s] {%s}Player no longer available.", prefixcolor, prefix, textcolor);
				return 0;
			}

			WhoISLookupPlayerHistory(param1, target);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void WhoISLookupPlayerHistory(int client, int target)
{
	char steamid[32], targetName[64];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientName(target, targetName, sizeof(targetName));

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(targetName);

	char query[256];
	Format(query, sizeof(query),
		"SELECT name, first_used, last_used FROM whois_names \
		 WHERE steamid = '%s' ORDER BY first_used DESC LIMIT 10", steamid);

	SQL_TQuery(db, WhoISOnHistoryResult, query, pack);
}

public void WhoISOnHistoryResult(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
	pack.Reset();
	int clientUserId = pack.ReadCell();
	char targetName[64];
	pack.ReadString(targetName, sizeof(targetName));
	delete pack;

	int client = GetClientOfUserId(clientUserId);
	if (client == 0)
		return;

	if (hndl == INVALID_HANDLE)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Database error!", prefixcolor, prefix, textcolor);
		return;
	}

	CPrintToChat(client, "{%s}[%s] {green}=== Name History for %s ===", prefixcolor, prefix, targetName);

	int count = 0;
	while (SQL_FetchRow(hndl))
	{
		char name[64];
		SQL_FetchString(hndl, 0, name, sizeof(name));
		int firstUsed = SQL_FetchInt(hndl, 1);

		char timeStr[32];
		FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d", firstUsed);

		CPrintToChat(client, "{%s}[%s] {%s}%d. {green}%s {%s}(%s)", prefixcolor, prefix, textcolor, ++count, name, textcolor, timeStr);
	}

	if (count == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No name history found.", prefixcolor, prefix, textcolor);
	}
}
