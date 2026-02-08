// ************************************************************************************************************
// ********************************************** READY CHECK SYSTEM ******************************************
// ************************************************************************************************************
// Reusable ready check panel for: pre-match, timeout, pause
// Panel refreshes every 1 second, supports countdown timer

public void ReadycheckOnMapStart()
{
	// Reset ready check state on map change
	readyCheckActive = false;
	readyCheckContext = READY_CONTEXT_NONE;
	readyCheckCountdown = 0;
	readyCheckTimeoutCaller = 0;

	// Kill any active timers
	ReadyCheckKillTimers();
}

public void ReadyCheckKillTimers()
{
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
	if (pauseRdyTimer != INVALID_HANDLE)
	{
		KillTimer(pauseRdyTimer);
		pauseRdyTimer = INVALID_HANDLE;
	}
}

// ************************************************************************************************************
// ********************************************** CORE FUNCTIONS **********************************************
// ************************************************************************************************************

// Start a ready check with specified context
public void ReadyCheckStart(ReadyCheckContext context, int countdown, int caller)
{
	if (readyCheckActive)
	{
		// Already active
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
		{
			CPrintToChatAll("{%s}[%s] {%s}Teams are set! Ready check started.", prefixcolor, prefix, textcolor);
			if (countdown > 0)
				CPrintToChatAll("{%s}[%s] {%s}Match starts in %d seconds. Type .r to ready up!", prefixcolor, prefix, textcolor, countdown);
			else
				CPrintToChatAll("{%s}[%s] {%s}Type .r when ready. Match starts when all players are ready.", prefixcolor, prefix, textcolor);
			HostName_Change_Status("Ready Check");
		}
		case READY_CONTEXT_TIMEOUT:
		{
			if (caller > 0 && IsClientInGame(caller))
				CPrintToChatAll("{%s}[%s] {%s}%N called a timeout!", prefixcolor, prefix, textcolor, caller);
			else
				CPrintToChatAll("{%s}[%s] {%s}Timeout called!", prefixcolor, prefix, textcolor);
			CPrintToChatAll("{%s}[%s] {%s}Type .r when ready to resume.", prefixcolor, prefix, textcolor);
		}
		case READY_CONTEXT_PAUSE:
		{
			CPrintToChatAll("{%s}[%s] {%s}Match paused. Type .r when ready.", prefixcolor, prefix, textcolor);
		}
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
	// Prevent re-entrancy and double-execution
	static bool isEnding = false;
	if (isEnding || !readyCheckActive) return;
	isEnding = true;

	ReadyCheckContext endedContext = readyCheckContext;

	// Mark as inactive FIRST to prevent timer callbacks from re-entering
	readyCheckActive = false;

	// Kill timers
	ReadyCheckKillTimers();

	// Close all panels safely
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			if (GetClientMenu(i) != MenuSource_None)
			{
				CancelClientMenu(i, false);
				InternalShowMenu(i, "\10", 1);
			}
		}
	}
	readyCheckContext = READY_CONTEXT_NONE;
	readyCheckTimeoutCaller = 0;
	readyCheckCountdown = 0;

	if (proceed)
	{
		switch (endedContext)
		{
			case READY_CONTEXT_PREMATCH:
			{
				CPrintToChatAll("{%s}[%s] {%s}Starting match...", prefixcolor, prefix, textcolor);
				// Use existing MatchStart function
				CreateTimer(1.0, Timer_AutoStartMatch);
			}
			case READY_CONTEXT_TIMEOUT:
			{
				CPrintToChatAll("{%s}[%s] {%s}Timeout ended. Resuming match...", prefixcolor, prefix, textcolor);
				MatchUnpause(0);
			}
			case READY_CONTEXT_PAUSE:
			{
				CPrintToChatAll("{%s}[%s] {%s}Match resuming...", prefixcolor, prefix, textcolor);
				MatchUnpause(0);
			}
		}
	}
	else
	{
		CPrintToChatAll("{%s}[%s] {%s}Ready check cancelled.", prefixcolor, prefix, textcolor);
		if (endedContext == READY_CONTEXT_PREMATCH)
		{
			HostName_Change_Status("Public");
		}
	}

	isEnding = false;
}

// Check if all players are ready
public bool ReadyCheckAllReady()
{
	int totalPlayers = 0;
	int readyPlayers = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;

		int team = GetClientTeam(i);
		if (team != 2 && team != 3) continue;  // Only T and CT

		totalPlayers++;
		if (playerReady[i]) readyPlayers++;
	}

	// Need at least some players
	if (totalPlayers == 0) return false;

	return (readyPlayers == totalPlayers);
}

// Get ready count for display
public void ReadyCheckGetCounts(int &ready, int &total)
{
	ready = 0;
	total = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;

		int team = GetClientTeam(i);
		if (team != 2 && team != 3) continue;

		total++;
		if (playerReady[i]) ready++;
	}
}

// ************************************************************************************************************
// ************************************************** PANEL ***************************************************
// ************************************************************************************************************

// Update/refresh the panel for all players
public void ReadyCheckUpdatePanel()
{
	if (!readyCheckActive) return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;

		int team = GetClientTeam(i);
		if (team != 2 && team != 3) continue;

		if (!playerHidePanel[i])
		{
			ReadyCheckShowPanel(i);
		}
	}
}

// Show panel to a specific client
public void ReadyCheckShowPanel(int client)
{
	Panel panel = new Panel();
	char buffer[256];

	// Title based on context
	switch (readyCheckContext)
	{
		case READY_CONTEXT_PREMATCH:
		{
			panel.SetTitle("READY CHECK - PRE-MATCH");
		}
		case READY_CONTEXT_TIMEOUT:
		{
			if (readyCheckTimeoutCaller > 0 && IsClientInGame(readyCheckTimeoutCaller))
			{
				char callerName[MAX_NAME_LENGTH];
				GetClientName(readyCheckTimeoutCaller, callerName, sizeof(callerName));
				Format(buffer, sizeof(buffer), "TIMEOUT - %s", callerName);
				panel.SetTitle(buffer);
			}
			else
			{
				panel.SetTitle("TIMEOUT");
			}
		}
		case READY_CONTEXT_PAUSE:
		{
			panel.SetTitle("MATCH PAUSED");
		}
		default:
		{
			panel.SetTitle("READY CHECK");
		}
	}

	// Ready count
	int readyCount, totalCount;
	ReadyCheckGetCounts(readyCount, totalCount);

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
	Format(buffer, sizeof(buffer), "[CT] %s", custom_name_ct);
	panel.DrawText(buffer);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		if (GetClientTeam(i) != 3) continue;

		char name[MAX_NAME_LENGTH];
		GetClientName(i, name, sizeof(name));

		// Truncate long names
		if (strlen(name) > 14)
		{
			name[14] = '\0';
			StrCat(name, sizeof(name), "..");
		}

		// Sanitize name (prevent menu exploits)
		ReplaceString(name, sizeof(name), "#", "_");

		Format(buffer, sizeof(buffer), "  %s %s", playerReady[i] ? "[+]" : "[-]", name);
		panel.DrawText(buffer);
	}

	panel.DrawText(" ");

	// T Players
	Format(buffer, sizeof(buffer), "[T] %s", custom_name_t);
	panel.DrawText(buffer);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		if (GetClientTeam(i) != 2) continue;

		char name[MAX_NAME_LENGTH];
		GetClientName(i, name, sizeof(name));

		if (strlen(name) > 14)
		{
			name[14] = '\0';
			StrCat(name, sizeof(name), "..");
		}

		ReplaceString(name, sizeof(name), "#", "_");

		Format(buffer, sizeof(buffer), "  %s %s", playerReady[i] ? "[+]" : "[-]", name);
		panel.DrawText(buffer);
	}

	panel.DrawText(" ");
	panel.DrawText("_______________________");
	panel.DrawText("->1. Ready");
	panel.DrawText("->2. Not Ready");

	panel.SetKeys((1 << 0) | (1 << 1));
	panel.Send(client, ReadyCheckPanelHandler, 1);

	delete panel;
}

// Panel handler
public int ReadyCheckPanelHandler(Menu menu, MenuAction action, int client, int key)
{
	if (action == MenuAction_Select && readyCheckActive)
	{
		// Cooldown check
		int currentTime = GetTime();
		if (cooldownTime[client] != -1 && cooldownTime[client] > currentTime)
		{
			// Still on cooldown, just refresh panel
			ReadyCheckShowPanel(client);
			return 0;
		}

		if (key == 1)
		{
			if (!playerReady[client])
			{
				playerReady[client] = true;
				CPrintToChat(client, "{%s}[%s] {%s}You are now READY.", prefixcolor, prefix, textcolor);
			}
		}
		else if (key == 2)
		{
			if (playerReady[client])
			{
				playerReady[client] = false;
				CPrintToChat(client, "{%s}[%s] {%s}You are now NOT READY.", prefixcolor, prefix, textcolor);
			}
		}

		cooldownTime[client] = currentTime + 1;  // 1 second cooldown

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

// ************************************************************************************************************
// ************************************************** TIMERS **************************************************
// ************************************************************************************************************

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
	// Safety check - stop if already inactive or countdown already expired
	if (!readyCheckActive || readyCheckCountdown <= 0)
	{
		readyCheckCountdownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	readyCheckCountdown--;

	if (readyCheckCountdown <= 0)
	{
		// Countdown expired - proceed regardless of ready state
		readyCheckCountdownTimer = INVALID_HANDLE;  // Mark as invalid FIRST
		CPrintToChatAll("{%s}[%s] {%s}Countdown complete!", prefixcolor, prefix, textcolor);
		ReadyCheckEnd(true);
		return Plugin_Stop;
	}

	// Announce at certain intervals
	if (readyCheckCountdown == 30 || readyCheckCountdown == 10 || readyCheckCountdown <= 5)
	{
		int ready, total;
		ReadyCheckGetCounts(ready, total);
		CPrintToChatAll("{%s}[%s] {%s}%d seconds remaining. (%d/%d ready)", prefixcolor, prefix, textcolor, readyCheckCountdown, ready, total);
	}

	return Plugin_Continue;
}

// Timer: Auto-start match after pre-match ready check
public Action Timer_AutoStartMatch(Handle timer)
{
	// Use existing MatchStart with client 0 (system)
	MatchStart(0);
	return Plugin_Stop;
}

// ************************************************************************************************************
// ********************************************** COMMAND HANDLERS ********************************************
// ************************************************************************************************************

public void ReadyCheckSetReady(int client, bool ready)
{
	if (!readyCheckActive)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
		return;
	}

	int team = GetClientTeam(client);
	if (team != 2 && team != 3)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Only players on a team can ready up.", prefixcolor, prefix, textcolor);
		return;
	}

	if (ready)
	{
		if (!playerReady[client])
		{
			playerReady[client] = true;
			CPrintToChat(client, "{%s}[%s] {%s}You are now READY.", prefixcolor, prefix, textcolor);
		}
		else
		{
			CPrintToChat(client, "{%s}[%s] {%s}You are already ready.", prefixcolor, prefix, textcolor);
		}
	}
	else
	{
		if (playerReady[client])
		{
			playerReady[client] = false;
			CPrintToChat(client, "{%s}[%s] {%s}You are now NOT READY.", prefixcolor, prefix, textcolor);
		}
		else
		{
			CPrintToChat(client, "{%s}[%s] {%s}You are already not ready.", prefixcolor, prefix, textcolor);
		}
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

public void ReadyCheckTimeout(int client)
{
	if (!matchStarted)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No match is in progress.", prefixcolor, prefix, textcolor);
		return;
	}

	if (matchPaused)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Match is already paused.", prefixcolor, prefix, textcolor);
		return;
	}

	if (readyCheckActive)
	{
		CPrintToChat(client, "{%s}[%s] {%s}A ready check is already active.", prefixcolor, prefix, textcolor);
		return;
	}

	// Pause the match (existing function)
	MatchPause(client);

	// Start ready check with timeout context
	ReadyCheckStart(READY_CONTEXT_TIMEOUT, readyCheckTimeoutCountdown, client);
}

public void ReadyCheckTimein(int client)
{
	if (!readyCheckActive || readyCheckContext != READY_CONTEXT_TIMEOUT)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No timeout is active.", prefixcolor, prefix, textcolor);
		return;
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
		return;
	}

	ReadyCheckEnd(true);
}

public void ReadyCheckForce(int client)
{
	if (!readyCheckActive)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
		return;
	}

	CPrintToChatAll("{%s}[%s] {%s}Admin %N forced ready check to proceed.", prefixcolor, prefix, textcolor, client);
	ReadyCheckEnd(true);
}

public void ReadyCheckCancel(int client)
{
	if (!readyCheckActive)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No ready check is active.", prefixcolor, prefix, textcolor);
		return;
	}

	CPrintToChatAll("{%s}[%s] {%s}Admin %N cancelled the ready check.", prefixcolor, prefix, textcolor, client);
	ReadyCheckEnd(false);
}

public void ReadyCheckHidePanel(int client)
{
	playerHidePanel[client] = true;
	CancelClientMenu(client);
	CPrintToChat(client, "{%s}[%s] {%s}Panel hidden. Type !show to show it again.", prefixcolor, prefix, textcolor);
}

public void ReadyCheckShowPanelCmd(int client)
{
	playerHidePanel[client] = false;
	CPrintToChat(client, "{%s}[%s] {%s}Panel restored.", prefixcolor, prefix, textcolor);
	if (readyCheckActive)
	{
		ReadyCheckShowPanel(client);
	}
}

// ************************************************************************************************************
// ********************************************** CLIENT DISCONNECT *******************************************
// ************************************************************************************************************

public void ReadyCheckOnClientDisconnect(int client)
{
	// Reset player state
	playerReady[client] = false;
	playerHidePanel[client] = false;

	// If in active ready check, update panel for everyone
	if (readyCheckActive)
	{
		// Small delay to let the disconnect fully process
		CreateTimer(0.1, Timer_ReadyCheckDisconnectRefresh);
	}
}

public Action Timer_ReadyCheckDisconnectRefresh(Handle timer)
{
	if (readyCheckActive)
	{
		// Check if all remaining players are ready
		if (ReadyCheckAllReady())
		{
			ReadyCheckEnd(true);
		}
		else
		{
			ReadyCheckUpdatePanel();
		}
	}
	return Plugin_Stop;
}

// ************************************************************************************************************
// ******************************************** LEGACY COMPATIBILITY ******************************************
// ************************************************************************************************************
// These functions maintain compatibility with existing code that uses the old ready check

public void OpenReadyPanel(int client)
{
	// Legacy function - redirect to new system
	if (readyCheckActive)
	{
		ReadyCheckShowPanel(client);
	}
}

public void RefreshPanel()
{
	// Legacy function - redirect to new system
	if (readyCheckActive)
	{
		ReadyCheckUpdatePanel();
	}
}

public bool AreAllReady()
{
	// Legacy function - redirect to new system
	return ReadyCheckAllReady();
}

public void UnpauseCheck(int client)
{
	// Legacy function - if ready check is active, check if all ready
	if (readyCheckActive)
	{
		if (ReadyCheckAllReady())
		{
			ReadyCheckEnd(true);
		}
		else
		{
			CPrintToChat(client, "{%s}[%s] {%s}Not everyone is ready!", prefixcolor, prefix, textcolor);
		}
	}
	else if (matchReadyCheck == 0)
	{
		MatchUnpause(client);
	}
}

public void GetStartPlayers()
{
	startplayers = 0;

	if (GetTeamClientCount(2) == GetTeamClientCount(3))
	{
		startplayers = GetTeamClientCount(2) + GetTeamClientCount(3);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3))
				startplayers++;
		}
	}
}

public void recreateTempKV()
{
	// Legacy - no longer needed but kept for compatibility
}

public void KillPauseReadyTimer()
{
	ReadyCheckKillTimers();
}

// Legacy pause timer - tracks pause duration and displays to players
public Action pauseReadyTimer(Handle timer, any time)
{
	char timestamp[32];
	FormatTime(timestamp, sizeof(timestamp), "%M:%S", time);

	totalpausetime = timestamp;

	int newplayernum;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			newplayernum++;
		}
	}

	if (newplayernum != pauseplayernum)
	{
		if (readyCheckActive)
		{
			ReadyCheckUpdatePanel();
		}
		pauseplayernum = newplayernum;
	}

	PrintCenterTextAll("Pause Time: %s", timestamp);

	// After 5 minutes, switch to manual unpause mode
	if (time == 300 && matchReadyCheck == 1)
	{
		matchReadyCheck = 2;
		tempUnpause = true;
		CPrintToChatAll("{%s}[%s] {%s}Manual Unpausing is enabled now.", prefixcolor, prefix, textcolor);
		if (readyCheckActive)
		{
			ReadyCheckUpdatePanel();
		}
	}

	if (!matchStopPauseTimer)
	{
		pauseRdyTimer = CreateTimer(1.0, pauseReadyTimer, time + 1);
	}

	return Plugin_Stop;
}
