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
		// Thresholds (cycle: 51 -> 60 -> 67 -> 75 -> 80 -> 51)
		else if (StrEqual(menuItem, "kickth"))
		{
			pvKickThreshold = PV_CycleThreshold(pvKickThreshold);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_kick_threshold", pvKickThreshold);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "banth"))
		{
			pvBanThreshold = PV_CycleThreshold(pvBanThreshold);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_ban_threshold", pvBanThreshold);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "muteth"))
		{
			pvMuteThreshold = PV_CycleThreshold(pvMuteThreshold);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_mute_threshold", pvMuteThreshold);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "mapth"))
		{
			pvMapThreshold = PV_CycleThreshold(pvMapThreshold);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_map_threshold", pvMapThreshold);
			OpenSettingsPlayerVotes(client);
		}
		// Durations (cycle: 15 -> 30 -> 60 -> 120 -> 1440 -> 15)
		else if (StrEqual(menuItem, "bandur"))
		{
			pvVotebanDuration = PV_CycleDuration(pvVotebanDuration);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_ban_duration", pvVotebanDuration);
			OpenSettingsPlayerVotes(client);
		}
		else if (StrEqual(menuItem, "mutedur"))
		{
			pvVotemuteDuration = PV_CycleDuration(pvVotemuteDuration);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_mute_duration", pvVotemuteDuration);
			OpenSettingsPlayerVotes(client);
		}
		// Cooldown (cycle: 30 -> 60 -> 120 -> 180 -> 300 -> 30)
		else if (StrEqual(menuItem, "cooldown"))
		{
			pvVoteCooldown = PV_CycleCooldown(pvVoteCooldown);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_cooldown", pvVoteCooldown);
			OpenSettingsPlayerVotes(client);
		}
		// Min players (cycle: 2 -> 3 -> 4 -> 6 -> 8 -> 2)
		else if (StrEqual(menuItem, "minplayers"))
		{
			pvMinPlayers = PV_CycleMinPlayers(pvMinPlayers);
			UpdateConfigInt("Player Vote Settings", "soccer_mod_pv_min_players", pvMinPlayers);
			OpenSettingsPlayerVotes(client);
		}
	}
	else if (action == MenuAction_Cancel && choice == -6)	OpenMenuSettings(client);
	else if (action == MenuAction_End)						menu.Close();
	return 0;
}

// Cycle helpers
int PV_CycleThreshold(int current)
{
	if (current < 60) return 60;
	if (current < 67) return 67;
	if (current < 75) return 75;
	if (current < 80) return 80;
	return 51;
}

int PV_CycleDuration(int current)
{
	if (current < 30) return 30;
	if (current < 60) return 60;
	if (current < 120) return 120;
	if (current < 1440) return 1440;
	return 15;
}

int PV_CycleCooldown(int current)
{
	if (current < 60) return 60;
	if (current < 120) return 120;
	if (current < 180) return 180;
	if (current < 300) return 300;
	return 30;
}

int PV_CycleMinPlayers(int current)
{
	if (current < 3) return 3;
	if (current < 4) return 4;
	if (current < 6) return 6;
	if (current < 8) return 8;
	return 2;
}
