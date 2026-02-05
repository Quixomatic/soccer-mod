// **************************************************************************************************************
// ********************************************** JOIN/LEAVE NOTIFICATIONS **************************************
// **************************************************************************************************************

public void JoinLeaveOnClientCookiesCached(int client)
{
	char buffer[8];

	GetClientCookie(client, h_JOINLEAVE_SOUND_COOKIE, buffer, sizeof(buffer));
	pcJoinLeaveSound[client] = (buffer[0] == '\0') ? 0 : StringToInt(buffer);  // Default OFF

	GetClientCookie(client, h_JOINLEAVE_CHAT_COOKIE, buffer, sizeof(buffer));
	pcJoinLeaveChat[client] = (buffer[0] == '\0') ? 1 : StringToInt(buffer);   // Default ON
}

public void JoinLeaveNotifyJoin(int client)
{
	if (!joinLeaveEnabled) return;
	if (IsFakeClient(client) || IsClientSourceTV(client)) return;

	int current = GetRealPlayerCount();
	int required = matchMaxPlayers * 2;
	bool isFull = (current >= required);

	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	// Chat notification
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && pcJoinLeaveChat[i])
		{
			if (isFull)
				CPrintToChat(i, "{%s}[%s] {green}%s {%s}joined ({green}%d/%d players{%s}) - {green}Ready to play!",
					prefixcolor, prefix, playerName, textcolor, current, required, textcolor);
			else
				CPrintToChat(i, "{%s}[%s] {green}%s {%s}joined ({green}%d/%d players{%s})",
					prefixcolor, prefix, playerName, textcolor, current, required, textcolor);
		}
	}

	// Sound notification (only if sounds exist and player has it enabled)
	if (joinLeaveSoundsExist)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && pcJoinLeaveSound[i])
			{
				if (isFull && strlen(joinLeaveReadySound) > 0)
					EmitSoundToClient(i, joinLeaveReadySound, _, _, _, _, joinLeaveVolume);
				else if (strlen(joinLeaveJoinSound) > 0)
					EmitSoundToClient(i, joinLeaveJoinSound, _, _, _, _, joinLeaveVolume);
			}
		}
	}
}

public void JoinLeaveNotifyLeave(int client)
{
	if (!joinLeaveEnabled) return;
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client)) return;

	int current = GetRealPlayerCount() - 1;  // -1 because they're leaving
	int required = matchMaxPlayers * 2;

	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	// Chat notification
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client && pcJoinLeaveChat[i])
		{
			CPrintToChat(i, "{%s}[%s] {green}%s {%s}left ({green}%d/%d players{%s})",
				prefixcolor, prefix, playerName, textcolor, current, required, textcolor);
		}
	}

	// Sound notification (only if sounds exist and player has it enabled)
	if (joinLeaveSoundsExist && strlen(joinLeaveLeaveSound) > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && i != client && pcJoinLeaveSound[i])
			{
				EmitSoundToClient(i, joinLeaveLeaveSound, _, _, _, _, joinLeaveVolume);
			}
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

// ********************************************** PLAYER SETTINGS MENU ******************************************

public void OpenMenuJoinLeaveSettings(int client)
{
	Menu menu = new Menu(MenuHandlerJoinLeaveSettings);
	menu.SetTitle("Join/Leave Notifications");

	char soundStatus[48], chatStatus[48];
	Format(soundStatus, sizeof(soundStatus), "Sound notifications: %s", pcJoinLeaveSound[client] ? "ON" : "OFF");
	Format(chatStatus, sizeof(chatStatus), "Chat notifications: %s", pcJoinLeaveChat[client] ? "ON" : "OFF");

	menu.AddItem("sound", soundStatus);
	menu.AddItem("chat", chatStatus);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerJoinLeaveSettings(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(choice, info, sizeof(info));

		if (StrEqual(info, "sound"))
		{
			pcJoinLeaveSound[client] = !pcJoinLeaveSound[client];
			char buffer[8];
			IntToString(pcJoinLeaveSound[client], buffer, sizeof(buffer));
			SetClientCookie(client, h_JOINLEAVE_SOUND_COOKIE, buffer);
		}
		else if (StrEqual(info, "chat"))
		{
			pcJoinLeaveChat[client] = !pcJoinLeaveChat[client];
			char buffer[8];
			IntToString(pcJoinLeaveChat[client], buffer, sizeof(buffer));
			SetClientCookie(client, h_JOINLEAVE_CHAT_COOKIE, buffer);
		}

		OpenMenuJoinLeaveSettings(client);
	}
	else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
	{
		OpenMenuClientSettings(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

// ********************************************** ADMIN VOLUME MENU *********************************************

public void OpenMenuJoinLeaveVolume(int client)
{
	Menu menu = new Menu(MenuHandlerJoinLeaveVolume);
	menu.SetTitle("Join/Leave Volume\nCurrent: %.2f", joinLeaveVolume);

	menu.AddItem("0.25", "0.25 (Quiet)");
	menu.AddItem("0.50", "0.50");
	menu.AddItem("0.75", "0.75");
	menu.AddItem("1.00", "1.00 (Full)");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerJoinLeaveVolume(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(choice, info, sizeof(info));

		joinLeaveVolume = StringToFloat(info);
		UpdateJoinLeaveConfigFloat("Sounds", "volume", joinLeaveVolume);

		CPrintToChat(client, "{%s}[%s] {%s}Join/Leave volume set to %.2f", prefixcolor, prefix, textcolor, joinLeaveVolume);
		OpenMenuJoinLeaveVolume(client);
	}
	else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
	{
		// Back button - let the menu system handle it, user can navigate back via admin menu
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}
