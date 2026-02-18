// ************************************************************************************************************
// ********************************************** PLAYER VOTES SYSTEM *****************************************
// ************************************************************************************************************
// Allows any player to initiate votekick, voteban, votemute, votemap
// All vote types are toggled OFF by default and configurable via Admin > Settings > Player Votes

public void PlayerVotesOnPluginStart()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		pvLastVoteTime[i] = 0;
		pvMuted[i] = false;
		pvMuteTimers[i] = null;
		pvPendingVoteType[i] = 0;
	}
	pvActiveVoteType = 0;
	pvMuteExpiry = new StringMap();
}

public void PlayerVotesOnMapStart()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		pvLastVoteTime[i] = 0;
		if (pvMuteTimers[i] != null)
		{
			KillTimer(pvMuteTimers[i]);
			pvMuteTimers[i] = null;
		}
		pvMuted[i] = false;
		pvPendingVoteType[i] = 0;
	}
	pvActiveVoteType = 0;
	pvActiveVoteTarget = 0;

	// Load persistent mutes, clean expired entries
	PV_LoadMuteFile();
	PV_CleanExpiredMutes();

	// Re-apply mutes to any connected players (map changes keep players connected)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			PV_CheckPersistentMute(i);
		}
	}
}

public void PlayerVotesOnClientDisconnect(int client)
{
	pvLastVoteTime[client] = 0;
	pvMuted[client] = false;
	pvPendingVoteType[client] = 0;
	if (pvMuteTimers[client] != null)
	{
		KillTimer(pvMuteTimers[client]);
		pvMuteTimers[client] = null;
	}
	// Note: persistent mute stays in pvMuteExpiry/file — that's the whole point
}

public void PlayerVotesOnClientPostAdminCheck(int client)
{
	PV_CheckPersistentMute(client);
}

// ************************************************************************************************************
// ********************************************** VOTE ENTRY POINT ********************************************
// ************************************************************************************************************

public void PlayerVoteStart(int client, int voteType)
{
	if (client < 1 || !IsClientInGame(client)) return;

	// Check if the specific vote type is enabled
	switch (voteType)
	{
		case 1:
		{
			if (!pvVotekickEnabled)
			{
				CPrintToChat(client, "{%s}[%s] {%s}Votekick is disabled.", prefixcolor, prefix, textcolor);
				return;
			}
		}
		case 2:
		{
			if (!pvVotebanEnabled)
			{
				CPrintToChat(client, "{%s}[%s] {%s}Voteban is disabled.", prefixcolor, prefix, textcolor);
				return;
			}
		}
		case 3:
		{
			if (!pvVotemuteEnabled)
			{
				CPrintToChat(client, "{%s}[%s] {%s}Votemute is disabled.", prefixcolor, prefix, textcolor);
				return;
			}
		}
		case 4:
		{
			if (!pvVotemapEnabled)
			{
				CPrintToChat(client, "{%s}[%s] {%s}Votemap is disabled.", prefixcolor, prefix, textcolor);
				return;
			}
		}
		default: return;
	}

	// Check if a vote is already in progress
	if (IsVoteInProgress() || pvActiveVoteType != 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}A vote is already in progress.", prefixcolor, prefix, textcolor);
		return;
	}

	// Check minimum players
	int playerCount = PV_CountEligiblePlayers();
	if (playerCount < pvMinPlayers)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Not enough players (need %d, have %d).", prefixcolor, prefix, textcolor, pvMinPlayers, playerCount);
		return;
	}

	// Check per-player cooldown
	int currentTime = GetTime();
	int timeSince = currentTime - pvLastVoteTime[client];
	if (pvLastVoteTime[client] > 0 && timeSince < pvVoteCooldown)
	{
		int remaining = pvVoteCooldown - timeSince;
		CPrintToChat(client, "{%s}[%s] {%s}Vote cooldown: %ds remaining.", prefixcolor, prefix, textcolor, remaining);
		return;
	}

	// Open appropriate selection menu
	if (voteType == 4)
	{
		PV_OpenMapMenu(client);
	}
	else
	{
		pvPendingVoteType[client] = voteType;
		PV_OpenPlayerMenu(client, voteType);
	}
}

// ************************************************************************************************************
// ********************************************** TARGET SELECTION *********************************************
// ************************************************************************************************************

public void PV_OpenPlayerMenu(int client, int voteType)
{
	Menu menu = new Menu(PV_PlayerMenuHandler);

	char title[64];
	switch (voteType)
	{
		case 1: title = "Votekick - Select Player";
		case 2: title = "Voteban - Select Player";
		case 3: title = "Votemute - Select Player";
	}
	menu.SetTitle(title);

	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i)) continue;
		if (i == client) continue;
		if (PV_IsAdminImmune(i)) continue;
		if (voteType == 3 && pvMuted[i]) continue;

		char name[MAX_NAME_LENGTH];
		GetClientName(i, name, sizeof(name));

		char idStr[8];
		IntToString(i, idStr, sizeof(idStr));
		menu.AddItem(idStr, name);
		count++;
	}

	if (count == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No eligible players to target.", prefixcolor, prefix, textcolor);
		delete menu;
		return;
	}

	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PV_PlayerMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char idStr[8];
		menu.GetItem(choice, idStr, sizeof(idStr));
		int target = StringToInt(idStr);

		if (!IsClientInGame(target))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Target player is no longer in the game.", prefixcolor, prefix, textcolor);
			pvPendingVoteType[client] = 0;
			return 0;
		}

		PV_BeginVote(client, pvPendingVoteType[client], target, "");
		pvPendingVoteType[client] = 0;
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public void PV_OpenMapMenu(int client)
{
	Menu menu = new Menu(PV_MapMenuHandler);
	menu.SetTitle("Votemap - Select Map");

	char currentMap[128];
	GetCurrentMap(currentMap, sizeof(currentMap));

	int count = 0;
	for (int i = 0; i < GetArraySize(allowedMaps); i++)
	{
		char map[128];
		GetArrayString(allowedMaps, i, map, sizeof(map));

		if (StrEqual(map, currentMap)) continue;

		menu.AddItem(map, map);
		count++;
	}

	if (count == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No other maps available.", prefixcolor, prefix, textcolor);
		delete menu;
		return;
	}

	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PV_MapMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char map[128];
		menu.GetItem(choice, map, sizeof(map));
		PV_BeginVote(client, 4, 0, map);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

// ************************************************************************************************************
// ********************************************** VOTE EXECUTION **********************************************
// ************************************************************************************************************

public void PV_BeginVote(int client, int voteType, int target, const char[] mapName)
{
	// Re-validate everything
	if (IsVoteInProgress() || pvActiveVoteType != 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}A vote is already in progress.", prefixcolor, prefix, textcolor);
		return;
	}

	int currentTime = GetTime();
	int timeSince = currentTime - pvLastVoteTime[client];
	if (pvLastVoteTime[client] > 0 && timeSince < pvVoteCooldown)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Vote cooldown active.", prefixcolor, prefix, textcolor);
		return;
	}

	if (PV_CountEligiblePlayers() < pvMinPlayers)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Not enough players.", prefixcolor, prefix, textcolor);
		return;
	}

	if (voteType != 4 && (!IsClientInGame(target) || PV_IsAdminImmune(target)))
	{
		CPrintToChat(client, "{%s}[%s] {%s}Target is no longer available.", prefixcolor, prefix, textcolor);
		return;
	}

	// Set state
	pvActiveVoteType = voteType;
	pvActiveVoteTarget = (voteType != 4) ? GetClientUserId(target) : 0;
	pvLastVoteTime[client] = currentTime;
	strcopy(pvActiveVoteMap, sizeof(pvActiveVoteMap), mapName);

	// Create vote menu
	Menu menu = new Menu(PV_VoteMenuHandler);
	menu.VoteResultCallback = PV_HandleVoteResults;

	char title[128];
	char targetName[MAX_NAME_LENGTH];

	switch (voteType)
	{
		case 1:
		{
			GetClientName(target, targetName, sizeof(targetName));
			Format(title, sizeof(title), "Kick %s?", targetName);
			CPrintToChatAll("{%s}[%s] {%s}%N started a votekick against {green}%s", prefixcolor, prefix, textcolor, client, targetName);
		}
		case 2:
		{
			GetClientName(target, targetName, sizeof(targetName));
			Format(title, sizeof(title), "Ban %s for %d min?", targetName, pvVotebanDuration);
			CPrintToChatAll("{%s}[%s] {%s}%N started a voteban against {green}%s", prefixcolor, prefix, textcolor, client, targetName);
		}
		case 3:
		{
			GetClientName(target, targetName, sizeof(targetName));
			Format(title, sizeof(title), "Mute %s for %d min?", targetName, pvVotemuteDuration);
			CPrintToChatAll("{%s}[%s] {%s}%N started a votemute against {green}%s", prefixcolor, prefix, textcolor, client, targetName);
		}
		case 4:
		{
			Format(title, sizeof(title), "Change map to %s?", mapName);
			CPrintToChatAll("{%s}[%s] {%s}%N started a votemap for {green}%s", prefixcolor, prefix, textcolor, client, mapName);
		}
	}

	menu.SetTitle(title);
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int PV_VoteMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public void PV_HandleVoteResults(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	// Find yes votes (item index 0 = "yes")
	int yesVotes = 0;
	for (int i = 0; i < num_items; i++)
	{
		char item[16];
		menu.GetItem(item_info[i][VOTEINFO_ITEM_INDEX], item, sizeof(item));
		if (StrEqual(item, "yes"))
		{
			yesVotes = item_info[i][VOTEINFO_ITEM_VOTES];
			break;
		}
	}

	float yesPercent = (num_votes > 0) ? (float(yesVotes) / float(num_votes)) * 100.0 : 0.0;

	// Determine threshold
	int threshold;
	switch (pvActiveVoteType)
	{
		case 1: threshold = pvKickThreshold;
		case 2: threshold = pvBanThreshold;
		case 3: threshold = pvMuteThreshold;
		case 4: threshold = pvMapThreshold;
		default: threshold = 51;
	}

	if (yesPercent >= float(threshold))
	{
		CPrintToChatAll("{%s}[%s] {green}Vote passed! {%s}(%.0f%% yes, %d votes)", prefixcolor, prefix, textcolor, yesPercent, num_votes);

		switch (pvActiveVoteType)
		{
			case 1: PV_ExecuteKick();
			case 2: PV_ExecuteBan();
			case 3: PV_ExecuteMute();
			case 4: PV_ExecuteMapChange();
		}
	}
	else
	{
		CPrintToChatAll("{%s}[%s] {red}Vote failed. {%s}(%.0f%% yes, needed %d%%, %d votes)", prefixcolor, prefix, textcolor, yesPercent, threshold, num_votes);
	}

	// Reset state
	pvActiveVoteType = 0;
	pvActiveVoteTarget = 0;
	pvActiveVoteMap[0] = '\0';
}

// ************************************************************************************************************
// ********************************************** VOTE ACTIONS ************************************************
// ************************************************************************************************************

public void PV_ExecuteKick()
{
	int target = GetClientOfUserId(pvActiveVoteTarget);
	if (target == 0 || !IsClientInGame(target))
	{
		CPrintToChatAll("{%s}[%s] {%s}Vote passed but the target already disconnected.", prefixcolor, prefix, textcolor);
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	CPrintToChatAll("{%s}[%s] {%s}%s has been kicked by player vote.", prefixcolor, prefix, textcolor, name);
	KickClient(target, "Kicked by player vote");
}

public void PV_ExecuteBan()
{
	int target = GetClientOfUserId(pvActiveVoteTarget);
	if (target == 0 || !IsClientInGame(target))
	{
		CPrintToChatAll("{%s}[%s] {%s}Vote passed but the target already disconnected.", prefixcolor, prefix, textcolor);
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	CPrintToChatAll("{%s}[%s] {%s}%s has been banned for %d minutes by player vote.", prefixcolor, prefix, textcolor, name, pvVotebanDuration);
	BanClient(target, pvVotebanDuration, BANFLAG_AUTO, "Banned by player vote", "Banned by player vote");
}

public void PV_ExecuteMute()
{
	int target = GetClientOfUserId(pvActiveVoteTarget);
	if (target == 0 || !IsClientInGame(target))
	{
		CPrintToChatAll("{%s}[%s] {%s}Vote passed but the target already disconnected.", prefixcolor, prefix, textcolor);
		return;
	}

	// Use BaseComm if available, otherwise fall back to voice flags
	if (GetFeatureStatus(FeatureType_Native, "BaseComm_SetClientMute") == FeatureStatus_Available)
	{
		BaseComm_SetClientMute(target, true);
		BaseComm_SetClientGag(target, true);
	}
	else
	{
		SetClientListeningFlags(target, VOICE_MUTED);
	}

	pvMuted[target] = true;

	// Save persistent mute (SteamID + expiry timestamp)
	int expiry = GetTime() + (pvVotemuteDuration * 60);
	char steamid[32];
	GetClientAuthId(target, AuthId_Engine, steamid, sizeof(steamid));
	pvMuteExpiry.SetValue(steamid, expiry);
	PV_SaveMuteFile();

	// Auto-unmute timer
	if (pvMuteTimers[target] != null)
	{
		KillTimer(pvMuteTimers[target]);
	}
	pvMuteTimers[target] = CreateTimer(float(pvVotemuteDuration * 60), PV_TimerUnmute, GetClientUserId(target));

	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	CPrintToChatAll("{%s}[%s] {%s}%s has been muted for %d minutes by player vote.", prefixcolor, prefix, textcolor, name, pvVotemuteDuration);
}

public Action PV_TimerUnmute(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0)
	{
		pvMuteTimers[client] = null;
	}

	if (client > 0 && IsClientInGame(client))
	{
		if (GetFeatureStatus(FeatureType_Native, "BaseComm_SetClientMute") == FeatureStatus_Available)
		{
			BaseComm_SetClientMute(client, false);
			BaseComm_SetClientGag(client, false);
		}
		else
		{
			SetClientListeningFlags(client, VOICE_NORMAL);
		}

		pvMuted[client] = false;

		// Remove from persistent store
		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		pvMuteExpiry.Remove(steamid);
		PV_SaveMuteFile();

		CPrintToChatAll("{%s}[%s] {%s}%N's mute has expired.", prefixcolor, prefix, textcolor, client);
	}

	return Plugin_Stop;
}

public void PV_ExecuteMapChange()
{
	CPrintToChatAll("{%s}[%s] {%s}Map changing to {green}%s {%s}in 5 seconds...", prefixcolor, prefix, textcolor, pvActiveVoteMap, textcolor);

	DataPack dp;
	CreateDataTimer(5.0, PV_TimerChangeMap, dp);
	dp.WriteString(pvActiveVoteMap);
}

public Action PV_TimerChangeMap(Handle timer, DataPack dp)
{
	char map[128];
	dp.Reset();
	dp.ReadString(map, sizeof(map));
	ForceChangeLevel(map, "Player votemap");
	return Plugin_Stop;
}

// ************************************************************************************************************
// ********************************************** HELPERS ******************************************************
// ************************************************************************************************************

public int PV_CountEligiblePlayers()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
			count++;
	}
	return count;
}

public bool PV_IsAdminImmune(int client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC);
}

// ************************************************************************************************************
// ********************************************** PERSISTENT MUTES *********************************************
// ************************************************************************************************************

#define PV_MUTE_FILE "cfg/sm_soccermod/soccer_mod_mutes.cfg"

public void PV_LoadMuteFile()
{
	pvMuteExpiry.Clear();

	if (!FileExists(PV_MUTE_FILE)) return;

	KeyValues kv = new KeyValues("Mutes");
	if (!kv.ImportFromFile(PV_MUTE_FILE))
	{
		delete kv;
		return;
	}

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char steamid[32];
			kv.GetSectionName(steamid, sizeof(steamid));
			int expiry = kv.GetNum(NULL_STRING, 0);
			if (expiry > 0)
			{
				pvMuteExpiry.SetValue(steamid, expiry);
			}
		}
		while (kv.GotoNextKey(false));
	}

	delete kv;
}

public void PV_SaveMuteFile()
{
	KeyValues kv = new KeyValues("Mutes");

	StringMapSnapshot snap = pvMuteExpiry.Snapshot();
	for (int i = 0; i < snap.Length; i++)
	{
		char steamid[32];
		snap.GetKey(i, steamid, sizeof(steamid));
		int expiry;
		pvMuteExpiry.GetValue(steamid, expiry);
		kv.SetNum(steamid, expiry);
	}
	delete snap;

	kv.ExportToFile(PV_MUTE_FILE);
	delete kv;
}

public void PV_CleanExpiredMutes()
{
	int now = GetTime();
	bool changed = false;

	StringMapSnapshot snap = pvMuteExpiry.Snapshot();
	for (int i = 0; i < snap.Length; i++)
	{
		char steamid[32];
		snap.GetKey(i, steamid, sizeof(steamid));
		int expiry;
		pvMuteExpiry.GetValue(steamid, expiry);
		if (expiry <= now)
		{
			pvMuteExpiry.Remove(steamid);
			changed = true;
		}
	}
	delete snap;

	if (changed) PV_SaveMuteFile();
}

public void PV_CheckPersistentMute(int client)
{
	if (IsFakeClient(client)) return;

	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));

	int expiry;
	if (!pvMuteExpiry.GetValue(steamid, expiry)) return;

	int now = GetTime();
	if (expiry <= now)
	{
		// Expired, clean up
		pvMuteExpiry.Remove(steamid);
		PV_SaveMuteFile();
		return;
	}

	// Re-apply mute
	if (GetFeatureStatus(FeatureType_Native, "BaseComm_SetClientMute") == FeatureStatus_Available)
	{
		BaseComm_SetClientMute(client, true);
		BaseComm_SetClientGag(client, true);
	}
	else
	{
		SetClientListeningFlags(client, VOICE_MUTED);
	}

	pvMuted[client] = true;

	// Start timer for remaining duration
	int remaining = expiry - now;
	if (pvMuteTimers[client] != null)
	{
		KillTimer(pvMuteTimers[client]);
	}
	pvMuteTimers[client] = CreateTimer(float(remaining), PV_TimerUnmute, GetClientUserId(client));

	int remainingMin = remaining / 60;
	if (remainingMin > 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}You are muted for %d more minutes.", prefixcolor, prefix, textcolor, remainingMin);
	}
	else
	{
		CPrintToChat(client, "{%s}[%s] {%s}You are muted for less than a minute.", prefixcolor, prefix, textcolor);
	}
}

// ************************************************************************************************************
// ********************************************** ADMIN SETTINGS ***********************************************
// ************************************************************************************************************

public void OpenSettingsPlayerVotes(int client)
{
	Menu menu = new Menu(SettingsPlayerVotesHandler);
	menu.SetTitle("Soccer Mod - Admin - Settings - Player Votes");

	char kickStr[48], banStr[48], muteStr[48], mapStr[48];
	Format(kickStr, sizeof(kickStr), "Votekick: %s", pvVotekickEnabled ? "ON" : "OFF");
	Format(banStr, sizeof(banStr), "Voteban: %s", pvVotebanEnabled ? "ON" : "OFF");
	Format(muteStr, sizeof(muteStr), "Votemute: %s", pvVotemuteEnabled ? "ON" : "OFF");
	Format(mapStr, sizeof(mapStr), "Votemap: %s", pvVotemapEnabled ? "ON" : "OFF");

	menu.AddItem("votekick", kickStr);
	menu.AddItem("voteban", banStr);
	menu.AddItem("votemute", muteStr);
	menu.AddItem("votemap", mapStr);

	char kickThStr[48], banThStr[48], muteThStr[48], mapThStr[48];
	Format(kickThStr, sizeof(kickThStr), "Kick Threshold: %d%%", pvKickThreshold);
	Format(banThStr, sizeof(banThStr), "Ban Threshold: %d%%", pvBanThreshold);
	Format(muteThStr, sizeof(muteThStr), "Mute Threshold: %d%%", pvMuteThreshold);
	Format(mapThStr, sizeof(mapThStr), "Map Threshold: %d%%", pvMapThreshold);

	menu.AddItem("kickth", kickThStr);
	menu.AddItem("banth", banThStr);
	menu.AddItem("muteth", muteThStr);
	menu.AddItem("mapth", mapThStr);

	char banDurStr[48], muteDurStr[48], cdStr[48], minStr[48];
	Format(banDurStr, sizeof(banDurStr), "Ban Duration: %d min", pvVotebanDuration);
	Format(muteDurStr, sizeof(muteDurStr), "Mute Duration: %d min", pvVotemuteDuration);
	Format(cdStr, sizeof(cdStr), "Cooldown: %ds", pvVoteCooldown);
	Format(minStr, sizeof(minStr), "Min Players: %d", pvMinPlayers);

	menu.AddItem("bandur", banDurStr);
	menu.AddItem("mutedur", muteDurStr);
	menu.AddItem("cooldown", cdStr);
	menu.AddItem("minplayers", minStr);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SettingsPlayerVotesHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		// Toggles
		if (StrEqual(menuItem, "votekick"))
		{
			pvVotekickEnabled = pvVotekickEnabled ? 0 : 1;
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_votekick", pvVotekickEnabled);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "voteban"))
		{
			pvVotebanEnabled = pvVotebanEnabled ? 0 : 1;
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_voteban", pvVotebanEnabled);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "votemute"))
		{
			pvVotemuteEnabled = pvVotemuteEnabled ? 0 : 1;
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_votemute", pvVotemuteEnabled);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "votemap"))
		{
			pvVotemapEnabled = pvVotemapEnabled ? 0 : 1;
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_votemap", pvVotemapEnabled);
			OpenSettingsPlayerVotes(client);
		}
		// Thresholds - chat input (percent)
		else if (StrEqual(menuItem, "kickth"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type kick threshold in percent (1-100), 0 to cancel. Current: %d%%", prefixcolor, prefix, textcolor, pvKickThreshold);
			changeSetting[client] = "PV_KickThreshold";
		}
		else if (StrEqual(menuItem, "banth"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type ban threshold in percent (1-100), 0 to cancel. Current: %d%%", prefixcolor, prefix, textcolor, pvBanThreshold);
			changeSetting[client] = "PV_BanThreshold";
		}
		else if (StrEqual(menuItem, "muteth"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type mute threshold in percent (1-100), 0 to cancel. Current: %d%%", prefixcolor, prefix, textcolor, pvMuteThreshold);
			changeSetting[client] = "PV_MuteThreshold";
		}
		else if (StrEqual(menuItem, "mapth"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type map threshold in percent (1-100), 0 to cancel. Current: %d%%", prefixcolor, prefix, textcolor, pvMapThreshold);
			changeSetting[client] = "PV_MapThreshold";
		}
		// Durations - chat input (minutes)
		else if (StrEqual(menuItem, "bandur"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type ban duration in minutes (1-1440), 0 to cancel. Current: %d", prefixcolor, prefix, textcolor, pvVotebanDuration);
			changeSetting[client] = "PV_BanDuration";
		}
		else if (StrEqual(menuItem, "mutedur"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type mute duration in minutes (1-1440), 0 to cancel. Current: %d", prefixcolor, prefix, textcolor, pvVotemuteDuration);
			changeSetting[client] = "PV_MuteDuration";
		}
		// Cooldown - chat input (seconds)
		else if (StrEqual(menuItem, "cooldown"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type cooldown in seconds (10-600), 0 to cancel. Current: %d", prefixcolor, prefix, textcolor, pvVoteCooldown);
			changeSetting[client] = "PV_Cooldown";
		}
		// Min players - chat input (count)
		else if (StrEqual(menuItem, "minplayers"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type minimum players (2-20), 0 to cancel. Current: %d", prefixcolor, prefix, textcolor, pvMinPlayers);
			changeSetting[client] = "PV_MinPlayers";
		}
	}
	else if (action == MenuAction_Cancel && choice == -6)	OpenMenuSettings(client);
	else if (action == MenuAction_End)						menu.Close();
	return 0;
}

// Chat input handler for player vote settings
public void PlayerVoteSet(int client, char type[32], int value, int min, int max)
{
	if (value == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Cancelled changing this value.", prefixcolor, prefix, textcolor);
		changeSetting[client] = "";
		OpenSettingsPlayerVotes(client);
		return;
	}

	if (value < min || value > max)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Type a value between %d and %d.", prefixcolor, prefix, textcolor, min, max);
		return;
	}

	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));

	if (StrEqual(type, "PV_KickThreshold"))
	{
		pvKickThreshold = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_kick_threshold", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set kick threshold to %d%%.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set kick threshold to %d%%", client, steamid, value);
	}
	else if (StrEqual(type, "PV_BanThreshold"))
	{
		pvBanThreshold = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_ban_threshold", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set ban threshold to %d%%.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set ban threshold to %d%%", client, steamid, value);
	}
	else if (StrEqual(type, "PV_MuteThreshold"))
	{
		pvMuteThreshold = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_mute_threshold", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set mute threshold to %d%%.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set mute threshold to %d%%", client, steamid, value);
	}
	else if (StrEqual(type, "PV_MapThreshold"))
	{
		pvMapThreshold = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_map_threshold", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set map threshold to %d%%.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set map threshold to %d%%", client, steamid, value);
	}
	else if (StrEqual(type, "PV_BanDuration"))
	{
		pvVotebanDuration = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_ban_duration", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set ban duration to %d minutes.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set ban duration to %d minutes", client, steamid, value);
	}
	else if (StrEqual(type, "PV_MuteDuration"))
	{
		pvVotemuteDuration = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_mute_duration", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set mute duration to %d minutes.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set mute duration to %d minutes", client, steamid, value);
	}
	else if (StrEqual(type, "PV_Cooldown"))
	{
		pvVoteCooldown = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_cooldown", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set vote cooldown to %ds.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set vote cooldown to %ds", client, steamid, value);
	}
	else if (StrEqual(type, "PV_MinPlayers"))
	{
		pvMinPlayers = value;
		UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_min_players", value);
		CPrintToChatAll("{%s}[%s] {%s}%N set min players to %d.", prefixcolor, prefix, textcolor, client, value);
		LogMessage("%N <%s> set min players to %d", client, steamid, value);
	}

	changeSetting[client] = "";
	OpenSettingsPlayerVotes(client);
}
