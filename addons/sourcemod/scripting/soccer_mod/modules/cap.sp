// ************************************************************************************************************
// ********************************************** CAP CONTROLS ************************************************
// ************************************************************************************************************

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

public void CapStopFight(int client)
{
	if (!capFightStarted)
	{
		if (client > 0) CPrintToChat(client, "{%s}[%s] {%s}No cap fight is currently active.", prefixcolor, prefix, textcolor);
		return;
	}

	// Kill any active timers
	CapKillTimers();

	// Reset state
	capFightStarted = false;

	// Restore sprint if it was enabled before
	if (tempSprint)
	{
		bSPRINT_ENABLED = 1;
		tempSprint = false;
	}

	// Unfreeze all players
	UnfreezeAll();

	// Reset hostname
	HostName_Change_Status("Public");

	// Notify all players
	CPrintToChatAll("{%s}[%s] {%s}Cap fight has been stopped.", prefixcolor, prefix, textcolor);

	// Log action
	if (client > 0) LogAction(client, -1, "\"%L\" stopped cap fight", client);
}

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

	// Restore sprint if needed
	if (tempSprint)
	{
		bSPRINT_ENABLED = 1;
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
	HostName_Change_Status("Public");

	// Notify
	CPrintToChatAll("{%s}[%s] {%s}Cap system has been fully reset.", prefixcolor, prefix, textcolor);

	// Log action
	if (client > 0) LogAction(client, -1, "\"%L\" reset cap system", client);
}

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
		CPrintToChat(client, "{%s}[%s] {%s}Need exactly 1 player on each team to start picking.", prefixcolor, prefix, textcolor);
		CPrintToChat(client, "{%s}[%s] {%s}Currently: %d on T, %d on CT.", prefixcolor, prefix, textcolor, tCount, ctCount);
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
		CPrintToChat(client, "{%s}[%s] {%s}Not enough players. Need %d, have %d.", prefixcolor, prefix, textcolor, totalPlayersNeeded, currentPlayers);
		CPrintToChat(client, "{%s}[%s] {%s}(Map requires %d players per team)", prefixcolor, prefix, textcolor, matchMaxPlayers);
		return;
	}

	if (specCount == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}No players in spectator to pick from.", prefixcolor, prefix, textcolor);
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
	HostName_Change_Status("Picking");

	// Notify
	CPrintToChatAll("{%s}[%s] {%s}Picking phase started!", prefixcolor, prefix, textcolor);
	CPrintToChatAll("{%s}[%s] {%s}T Captain: %N | CT Captain: %N", prefixcolor, prefix, textcolor, capT, capCT);
	CPrintToChatAll("{%s}[%s] {%s}%N is picking first.", prefixcolor, prefix, textcolor, capPicker);

	// Open pick menu for first picker
	OpenCapPickMenu(capPicker);

	// Log action
	LogAction(client, -1, "\"%L\" started picking phase", client);
}

public void CapOnClientDisconnect(int client)
{
	// Check if disconnecting player is a captain during active cap process
	if (client == capT || client == capCT)
	{
		// Check if we're in an active cap phase
		bool inCapPhase = capFightStarted || capPicksLeft > 0;

		if (inCapPhase)
		{
			CPrintToChatAll("{%s}[%s] {%s}Captain %N disconnected. Cap system reset.", prefixcolor, prefix, textcolor, client);
			CapReset(0);  // 0 = system-triggered, not admin
		}
	}
}

// ************************************************************************************************************
// ************************************************** EVENTS **************************************************
// ************************************************************************************************************
public void CapOnPluginStart()
{
}

public void CapEventPlayerDeath(Event event)
{
	if (capFightStarted)
	{
		int attacker = event.GetInt("attacker");

		if (attacker == 0) CPrintToChatAll("{%s}[%s]Cap fight invalid. Please restart the fight.", prefixcolor, prefix);
		else
		{
			if (attacker)
			{
				int attackerid = GetClientOfUserId(attacker);
				capPicker = attackerid;

				int userid = event.GetInt("userid");
				int deadid = GetClientOfUserId(userid);
				int team = GetClientTeam(attackerid);

				if (team == 2)
				{
					capCT = deadid;
					capT = attackerid;
				}
				else if (team == 3)
				{
					capCT = attackerid;
					capT = deadid;
				}
			}
			
			//Check for Cap only mode in ffvote			
			if(ForfeitCapMode == 1) 
			{
				ForfeitEnabled = 1;
				ForfeitRRCheck = true;
				CPrintToChatAll("{%s}[%s]CapFight detected. Forfeit vote will be enabled for the match", prefixcolor, prefix);
				UpdateConfigInt("Forfeit Settings", "soccer_mod_forfeitvote", ForfeitEnabled);
			}
		}
	}
}

public void CapEventRoundEnd(Event event)
{
	if (capFightStarted)
	{
		capFightStarted = false;

		HostName_Change_Status("Picking");

		//reenable sprint
		if (tempSprint)		bSPRINT_ENABLED = 1;

		// Initialize snake draft - winner picks first
		capPickNumber = 0;
		int winner = event.GetInt("winner");
		if (winner == 2)
		{
			capFirstPicker = capT;
			capPicker = capT;
			OpenCapPickMenu(capT);
		}
		else if (winner == 3)
		{
			capFirstPicker = capCT;
			capPicker = capCT;
			OpenCapPickMenu(capCT);
		}
	}
}

// **************************************************************************************************************
// ************************************************** CAP MENU **************************************************
// **************************************************************************************************************
public void OpenCapMenu(int client)
{
	Menu menu = new Menu(CapMenuHandler);
	menu.SetTitle("Soccer Mod - Cap");

	// Show start or stop depending on state
	if (capFightStarted)
	{
		menu.AddItem("stopcap", "Stop cap fight");
	}
	else
	{
		char capString[32];
		Format(capString, sizeof(capString), "Start cap fight (%s)", capweapon);
		menu.AddItem("start", capString);
	}

	menu.AddItem("startpick", "Start picking");
	menu.AddItem("resetcap", "Reset cap");

	menu.AddItem("spec", "Put all players to spectator");
	menu.AddItem("random", "Add random player");

	menu.AddItem("capweap", "Weapon selection");

	char healthString[48];
	Format(healthString, sizeof(healthString), "Cap fight health: %i", capFightHealth);
	menu.AddItem("caphealth", healthString);

	char snakeString[48];
	Format(snakeString, sizeof(snakeString), "Snake draft: %s", capSnakeDraft ? "ON" : "OFF");
	menu.AddItem("snakedraft", snakeString);

	//menu.AddItem("autocap", "[BETA] Auto Cap");

	if(publicmode == 0 || publicmode == 2) menu.ExitBackButton = true;
	else if(publicmode == 1) 
	{
		if(CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC) || IsSoccerAdmin(client, "cap")) menu.ExitBackButton = true;
		else menu.ExitBackButton = false;
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int CapMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		// These can be used anytime (even during match for emergencies)
		if (StrEqual(menuItem, "stopcap"))
		{
			CapStopFight(client);
			OpenCapMenu(client);
			return 0;
		}
		else if (StrEqual(menuItem, "resetcap"))
		{
			CapReset(client);
			OpenCapMenu(client);
			return 0;
		}
		else if (StrEqual(menuItem, "snakedraft"))
		{
			capSnakeDraft = capSnakeDraft ? 0 : 1;
			UpdateConfigInt("Cap Settings", "soccer_mod_cap_snake_draft", capSnakeDraft);
			CPrintToChat(client, "{%s}[%s] {%s}Snake draft: %s", prefixcolor, prefix, textcolor, capSnakeDraft ? "ON" : "OFF");
			OpenCapMenu(client);
			return 0;
		}

		if (!matchStarted)
		{
			if (StrEqual(menuItem, "spec"))		 CapPutAllToSpec(client);
			else if (StrEqual(menuItem, "random"))  CapAddRandomPlayer(client);
			else if (StrEqual(menuItem, "capweap"))	OpenWeaponMenu(client);
			else if (StrEqual(menuItem, "caphealth")) OpenCapHealthMenu(client);
			else if (StrEqual(menuItem, "startpick")) CapStartPicking(client);
			else if (StrEqual(menuItem, "start"))
			{
				CapStartFight(client);
				if(GetClientCount() >= PWMAXPLAYERS+1 && passwordlock == 1 && pwchange == true)
				{
					CPrintToChatAll("{%s}[%s] {%s}At least %i players when the capfight started; Changing the pw...", prefixcolor, prefix, textcolor, PWMAXPLAYERS+1);
					RandPass();
				}
			}
			/*else if (StrEqual(menuItem, "autocap"))
			{
				AutoCapStart(client);
				if(GetClientCount() >= PWMAXPLAYERS+1 && passwordlock == 1 && pwchange == true)
				{
					CPrintToChatAll("{%s}[%s] {%s}At least %i players when the capfight started; Changing the pw...", prefixcolor, prefix, textcolor, PWMAXPLAYERS+1);
					RandPass();
				}
			}*/
		}
		else CPrintToChat(client, "{%s}[%s]{%s}You can not use this option during a match", prefixcolor, prefix, textcolor);

		if (!(StrEqual(menuItem, "capweap")) && !(StrEqual(menuItem, "caphealth")) && !(StrEqual(menuItem, "startpick")))	OpenCapMenu(client);
	}
	else if (action == MenuAction_Cancel && choice == -6)   OpenMenuAdmin(client);
	else if (action == MenuAction_End)					  menu.Close();
	return 0;
}


// **************************************************************************************************************
// ************************************************ WEAPON MENU *************************************************
// **************************************************************************************************************
public void OpenWeaponMenu(int client)
{

	Menu menu = new Menu(WeaponMenuHandler);

	menu.SetTitle("Soccer - Cap - Weapons");

	menu.AddItem("knife", 	"Knife");
	//Pistols
	menu.AddItem("glock", 	"Glock 18");
	menu.AddItem("usp", 	"USP Tactical");
	menu.AddItem("p228", 	"P228");
	menu.AddItem("deagle", 	"Desert Eagle .50");
	menu.AddItem("57", 		"Five-seveN");
	menu.AddItem("dual", 	"Dual Elite Berettas");
	//Sub-Machine Guns
	menu.AddItem("mac10", 	"MAC10");
	menu.AddItem("tmp", 	"TMP");
	menu.AddItem("mp5", 	"MP5 Navy");
	menu.AddItem("ump", 	"UMP");
	menu.AddItem("p90", 	"P90");
	//Shotguns
	menu.AddItem("m3", 		"M3 Super 90");
	menu.AddItem("xm1014", 	"XM1014");
	//Rifles
	menu.AddItem("galil", 	"Galil");
	menu.AddItem("famas", 	"FAMAS");
	menu.AddItem("ak47", 	"AK47");
	menu.AddItem("m4a1", 	"M4A1 Carbine");
	menu.AddItem("sg552", 	"SG-552 Commando");
	menu.AddItem("aug", 	"AUG");
	//MG
	menu.AddItem("m249", 	"M249-SAW");
	//Sniper
	menu.AddItem("scout", 	"Scout");
	menu.AddItem("g3sg1", 	"G3/SG-1");
	menu.AddItem("sg550", 	"SG-550 Commando");
	menu.AddItem("awp", 	"AWP");
	//Grenades
	menu.AddItem("he", 		"HE grenade");
	menu.AddItem("flash", 	"Flashbang");
	//menu.AddItem("smoke", 	"Smoke grenade");
	//Misc
	menu.AddItem("randwp", 	"Random");

	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		if (!matchStarted)
		{
			char menuItem[32];
			menu.GetItem(choice, menuItem, sizeof(menuItem));

			if (StrEqual(menuItem, "knife"))		 	capweapon = "knife";
			else if (StrEqual(menuItem, "glock"))  		capweapon = "glock";
			else if (StrEqual(menuItem, "usp"))  		capweapon = "usp";
			else if (StrEqual(menuItem, "p228"))  		capweapon = "p228";
			else if (StrEqual(menuItem, "deagle"))  	capweapon = "deagle";
			else if (StrEqual(menuItem, "57"))  		capweapon = "fiveseven";
			else if (StrEqual(menuItem, "dual"))  		capweapon = "elite";
			else if (StrEqual(menuItem, "mac10"))  		capweapon = "mac10";
			else if (StrEqual(menuItem, "tmp"))  		capweapon = "tmp";
			else if (StrEqual(menuItem, "mp5"))  		capweapon = "mp5navy";
			else if (StrEqual(menuItem, "ump"))  		capweapon = "ump45";
			else if (StrEqual(menuItem, "p90"))  		capweapon = "p90";
			else if (StrEqual(menuItem, "m3"))  		capweapon = "m3";
			else if (StrEqual(menuItem, "xm1014"))  	capweapon = "xm1014";
			else if (StrEqual(menuItem, "galil"))  		capweapon = "galil";
			else if (StrEqual(menuItem, "famas"))  		capweapon = "famas";
			else if (StrEqual(menuItem, "ak47"))  		capweapon = "ak47";
			else if (StrEqual(menuItem, "m4a1"))  		capweapon = "m4a1";
			else if (StrEqual(menuItem, "sg552"))  		capweapon = "sg552";
			else if (StrEqual(menuItem, "aug"))  		capweapon = "aug";
			else if (StrEqual(menuItem, "m249"))  		capweapon = "m249";
			else if (StrEqual(menuItem, "scout"))  		capweapon = "scout";
			else if (StrEqual(menuItem, "g3sg1"))  		capweapon = "g3sg1";
			else if (StrEqual(menuItem, "sg550"))  		capweapon = "sg550";
			else if (StrEqual(menuItem, "awp"))  		capweapon = "awp";
			else if (StrEqual(menuItem, "flash"))  		capweapon = "flashbang";
			//else if (StrEqual(menuItem, "smoke"))  		capweapon = "smokegrenade";
			else if (StrEqual(menuItem, "he"))  		capweapon = "hegrenade";
			else if (StrEqual(menuItem, "randwp"))  	capweapon = "random";

		}
		else CPrintToChat(client, "{%s}[%s]{%s}You can not use this option during a match", prefixcolor, prefix, textcolor);

		OpenCapMenu(client);
	}
	else if (action == MenuAction_Cancel && choice == -6)   OpenCapMenu(client);
	else if (action == MenuAction_End)					  menu.Close();
}

// ***************************************************************************************************************
// ************************************************ HEALTH MENU **************************************************
// ***************************************************************************************************************
public void OpenCapHealthMenu(int client)
{
	Menu menu = new Menu(CapHealthMenuHandler);
	menu.SetTitle("Soccer Mod - Cap - Start Health");

	menu.AddItem("101", "101 HP (Default)");
	menu.AddItem("100", "100 HP");
	menu.AddItem("50", "50 HP");
	menu.AddItem("1", "1 HP");
	menu.AddItem("custom", "Custom");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int CapHealthMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		if (!matchStarted)
		{
			char menuItem[32];
			menu.GetItem(choice, menuItem, sizeof(menuItem));

			if (StrEqual(menuItem, "custom"))
			{
				CPrintToChat(client, "{%s}[%s] {%s}Type a value for cap fight health (1-1000), 0 to cancel. Current: %i", prefixcolor, prefix, textcolor, capFightHealth);
				changeSetting[client] = "CustomCapHealth";
			}
			else
			{
				capFightHealth = StringToInt(menuItem);
				UpdateConfigInt("Cap Settings", "soccer_mod_cap_fight_health", capFightHealth);
				CPrintToChatAll("{%s}[%s] {%s}Cap fight health set to: %i", prefixcolor, prefix, textcolor, capFightHealth);
				OpenCapMenu(client);
			}
		}
		else CPrintToChat(client, "{%s}[%s]{%s}You can not use this option during a match", prefixcolor, prefix, textcolor);
	}
	else if (action == MenuAction_Cancel && choice == -6)   OpenCapMenu(client);
	else if (action == MenuAction_End)					  menu.Close();
}

public void CapSet(int client, char type[32], int intnumber, int min, int max)
{
	if (intnumber >= min && intnumber <= max || intnumber == 0)
	{
		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));

		if (StrEqual(type, "CustomCapHealth"))
		{
			if(intnumber != 0)
			{
				capFightHealth = intnumber;
				UpdateConfigInt("Cap Settings", "soccer_mod_cap_fight_health", capFightHealth);

				for (int player = 1; player <= MaxClients; player++)
				{
					if (IsClientInGame(player) && IsClientConnected(player)) CPrintToChat(player, "{%s}[%s] {%s}%N has set cap fight health to %i.", prefixcolor, prefix, textcolor, client, intnumber);
				}

				LogMessage("%N <%s> has set cap fight health to %i", client, steamid, intnumber);

				changeSetting[client] = "";
				OpenCapMenu(client);
			}
			else
			{
				OpenCapHealthMenu(client);
				CPrintToChat(client, "{%s}[%s] {%s}Cancelled changing this value.", prefixcolor, prefix, textcolor);
			}
		}
	}
	else CPrintToChat(client, "{%s}[%s] {%s}Type a value between %i and %i.", prefixcolor, prefix, textcolor, min, max);
}

// ***************************************************************************************************************
// ************************************************** PICK MENU **************************************************
// ***************************************************************************************************************
public void OpenCapPickMenu(int client)
{
	if (client)
	{
		if (client == capT || client == capCT)
		{
			if (client == capPicker)
			{
				int count;
				for (int player = 1; player <= MaxClients; player++)
				{
					if (IsClientInGame(player) && IsClientConnected(player) && GetClientTeam(player) < 2 && !IsClientSourceTV(player)) count++;
				}

				if (count > 0)
				{
					capPicker = client;
					CapCreatePickMenu(client);
				}
				else CPrintToChat(client, "{%s}[%s] {%s}No players available to pick", prefixcolor, prefix, textcolor);
			}
			else CPrintToChat(client, "{%s}[%s] {%s}It is not your turn to pick", prefixcolor, prefix, textcolor);
		}
		else CPrintToChat(client, "{%s}[%s] {%s}You are not a cap", prefixcolor, prefix, textcolor);
	}
}

public int CapPickMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		int target = StringToInt(menuItem);
		if (IsClientInGame(target) && IsClientConnected(target))
		{
			char steamid[32];
			GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));

			char targetSteamid[32];
			GetClientAuthId(target, AuthId_Engine, targetSteamid, sizeof(targetSteamid));

			// Track pick progress
			capPickNumber++;
			capPicksLeft--;

			// Move player to picker's team
			int team = GetClientTeam(client);
			ChangeClientTeam(target, team);

			// Close any open menu on the picked player
			if(GetClientMenu(target) != MenuSource_None)
			{
				CancelClientMenu(target, false);
				InternalShowMenu(target, "\10", 1);
			}

			// Notify all players
			for (int player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player) && IsClientConnected(player)) CPrintToChat(player, "{%s}[%s] {%s}%N has picked %N", prefixcolor, prefix, textcolor, client, target);
			}

			LogMessage("%N <%s> has picked %N <%s>", client, steamid, target, targetSteamid);

			// Determine next picker using snake draft logic
			if (capPicksLeft > 0)
			{
				capPicker = GetNextPicker();
				OpenCapPickMenu(capPicker);
			}
		}
		else
		{
			CPrintToChat(client, "{%s}[%s] {%s}Player is no longer on the server", prefixcolor, prefix, textcolor);

			if (client == capCT) OpenCapPickMenu(capCT);
			else if (client == capT) OpenCapPickMenu(capT);
		}
	}
	else if (action == MenuAction_End) menu.Close();
}

// *******************************************************************************************************************
// ************************************************** POSITION MENU **************************************************
// *******************************************************************************************************************
public void OpenCapPositionMenu(int client)
{
	KeyValues keygroup = new KeyValues("capPositions");
	keygroup.ImportFromFile(pathCapPositionsFile);
	char langString[64], langString1[64], langString2[64];
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	keygroup.JumpToKey(steamid, true);

	Menu menu = new Menu(CapPositionMenuHandler);

	menu.SetTitle("Soccer Mod - Cap - Positions");

	int keyValue = keygroup.GetNum("gk", 0);
	Format(langString1, sizeof(langString1), "Goalkeeper", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("gk", langString);

	keyValue = keygroup.GetNum("lb", 0);
	Format(langString1, sizeof(langString1), "Left back", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("lb", langString);

	keyValue = keygroup.GetNum("rb", 0);
	Format(langString1, sizeof(langString1), "Right back", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("rb", langString);

	keyValue = keygroup.GetNum("mf", 0);
	Format(langString1, sizeof(langString1), "Midfielder", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("mf", langString);

	keyValue = keygroup.GetNum("lw", 0);
	Format(langString1, sizeof(langString1), "Left wing", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("lw", langString);

	keyValue = keygroup.GetNum("rw", 0);
	Format(langString1, sizeof(langString1), "Right wing", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("rw", langString);

	keyValue = keygroup.GetNum("spec", 0);
	Format(langString1, sizeof(langString1), "Spec only", client);
	if (keyValue) Format(langString2, sizeof(langString2), "Yes", client);
	else Format(langString2, sizeof(langString2), "No", client);
	Format(langString, sizeof(langString), "%s: %s", langString1, langString2);
	menu.AddItem("spec", langString);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	keygroup.Close();
}

public int CapPositionMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));

		KeyValues keygroup = new KeyValues("capPositions");
		keygroup.ImportFromFile(pathCapPositionsFile);

		keygroup.JumpToKey(steamid, true);

		int keyValue = keygroup.GetNum(menuItem, 0);
		if (keyValue) keygroup.SetNum(menuItem, 0);
		else keygroup.SetNum(menuItem, 1);

		keygroup.Rewind();
		keygroup.ExportToFile(pathCapPositionsFile);
		keygroup.Close();

		OpenCapPositionMenu(client);
	}
	else if (action == MenuAction_Cancel && choice == -6)   OpenMenuSoccer(client);
	else if (action == MenuAction_End)					  menu.Close();
}

// ************************************************************************************************************
// ************************************************** TIMERS **************************************************
// ************************************************************************************************************
public Action TimerCapFightCountDown(Handle timer, any seconds)
{
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player) && IsClientConnected(player)) PrintCenterText(player, "Cap fight will start in %i seconds", seconds);
	}
}

public Action TimerCapFightCountDownEnd(Handle timer)
{
	//Prepare selected weapon
	if (StrEqual(capweapon, "random"))
	{
		int randint = GetRandomInt(0, sizeof(capwparray[])-1);
		capweapon = capwparray[randint];
		Format(weaponName, sizeof(weaponName), "weapon_%s", capweapon);
		capweapon = "random";
	}
	else 
	{
		Format(weaponName, sizeof(weaponName), "weapon_%s", capweapon);
	}

	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player) && IsClientConnected(player))
		{
			PrintCenterText(player, "[%s] FIGHT!", prefix);
			if (GetClientTeam(player) > 1  && IsPlayerAlive(player)) 
			{
				SetEntProp(player, Prop_Data, "m_takedamage", 2, 1);
				//Set Armor to 0 and cancel Timer
				SetEntProp(player, Prop_Send, "m_ArmorValue", 0.0);
				//Remove weapon/knife
				int iWeapon = -1;
				while((iWeapon = GetPlayerWeaponSlot(player, CS_SLOT_KNIFE)) != -1)
				{
					if(iWeapon > 0)
					{
						RemovePlayerItem(player, iWeapon);
						AcceptEntityInput(iWeapon, "kill");
					}
				}				
				//If weapon == grenade refill whenever it's thrown
				if (StrEqual(weaponName, "weapon_smokegrenade") || StrEqual(weaponName, "weapon_flashbang") || StrEqual(weaponName, "weapon_hegrenade"))
				{
					//Refill
					GivePlayerItem(player, weaponName);
					// Only create refill timer once (not per player)
					if (capGrenadeRefillTimer == INVALID_HANDLE)
					{
						capGrenadeRefillTimer = CreateTimer(0.5, GrenadeRefillTimer, _, TIMER_REPEAT);
					}
				}
				else if (StrEqual(weaponName, "weapon_knife")) 
				{
					GivePlayerItem(player, weaponName);
				}
				else
				{
					GivePlayerItem(player, "weapon_knife");
					GivePlayerItem(player, weaponName);
				}
				
				if (StrEqual(weaponName, "weapon_smokegrenade") || StrEqual(weaponName, "weapon_flashbang"))	SetEntProp(player, Prop_Send, "m_iHealth", 1)
				else if (StrEqual(weaponName, "weapon_hegrenade")) SetEntProp(player, Prop_Send, "m_iHealth", 98)
				else	SetEntProp(player, Prop_Send, "m_iHealth", capFightHealth)
			}
		}
	}

	UnfreezeAll();
}

public Action GrenadeRefillTimer(Handle timer)
{
	if (capFightStarted)
	{
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player))
			{
				if (GetClientTeam(player) > 1  && IsPlayerAlive(player))
				{
					char playerweapon[64];
					GetClientWeapon(player, playerweapon, sizeof(playerweapon));
					if (!(StrEqual(playerweapon, "weapon_smokegrenade") || StrEqual(playerweapon, "weapon_flashbang") || StrEqual(playerweapon, "weapon_hegrenade")))
					{
						GivePlayerItem(player, weaponName);
					}
				}
			}
		}
		return Plugin_Continue;
	}
	else
	{
		capGrenadeRefillTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

// ***************************************************************************************************************
// ************************************************** FUNCTIONS **************************************************
// ***************************************************************************************************************
public void CapPutAllToSpec(int client)
{
	if(trainingModeEnabled) trainingModeEnabled = false;
	
	if(!matchStarted)
	{
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player))
			{
				CPrintToChat(player, "{%s}[%s] {%s}%N has put all players to spectator", prefixcolor, prefix, textcolor, client);
				if (GetClientTeam(player) != 1) ChangeClientTeam(player, 1);
			}
		}
		
		HostName_Change_Status("Specced");
		if(first12Set == 1)				CapPrep = true;

		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		LogMessage("%N <%s> has put all players to spectator", client, steamid);
	}
}

public void CapAddRandomPlayer(int client)
{
	int players[32], count;
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player) && IsClientConnected(player) && GetClientTeam(player) < 2 && !IsClientSourceTV(player))
		{
			players[count] = player;
			count++;
		}
	}

	if (count)
	{
		int randomPlayer = players[GetRandomInt(0, count - 1)];
		if (GetTeamClientCount(2) < GetTeamClientCount(3)) ChangeClientTeam(randomPlayer, 2);
		else ChangeClientTeam(randomPlayer, 3);

		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player)) CPrintToChat(player, "{%s}[%s] {%s}%N has forced %N as random player", prefixcolor, prefix, textcolor, client, randomPlayer);
		}

		char steamid[32], targetSteamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		GetClientAuthId(client, AuthId_Engine, targetSteamid, sizeof(targetSteamid));
		LogMessage("%N <%s> has forced %N <%s> as random player", client, steamid, randomPlayer, targetSteamid);
		
		if((first12Set == 1) && CapPrep)
		{
			if (ImportJoinNumber(targetSteamid) > 12) CPrintToChatAll("{%s}[%s] {%s}NOTICE: %N joined on position %i.", prefixcolor, prefix, textcolor, randomPlayer, ImportJoinNumber(targetSteamid));
		}
		if((first12Set == 2) && CapPrep)
		{
			if (ImportJoinNumber(targetSteamid) > capnr) CPrintToChatAll("{%s}[%s] {%s}NOTICE: %N joined on position %i.", prefixcolor, prefix, textcolor, randomPlayer, ImportJoinNumber(targetSteamid));
		}
	}
	else CPrintToChat(client, "{%s}[%s] {%s}No players in spectator", prefixcolor, prefix, textcolor);
}

public void CapStartFight(int client)
{
	if (!capFightStarted)
	{
		if(passwordlock == 1)
		{
			pwchange = true;
			CPrintToChatAll("{%s}[%s] {%s}AFK Kick enabled.", prefixcolor, prefix, textcolor);
			AFKKick();
		}
		
		if(bSPRINT_ENABLED == 1)
		{
			bSPRINT_ENABLED = 0;
			tempSprint = true;
		}
		else tempSprint = false;
		
		// count players
		capnr = GetClientCount();
		if(first12Set == 1)
		{
			if(nrhelper >= capnr)
			{
				first12Set = 2;
				tempRule = true;
			}
		}
		if(first12Set == 2)
		{
			if (capnr < 12)	capnr = 12;
		}
		nrhelper = 0;
		
		capFightStarted = true;
		capPicksLeft = (matchMaxPlayers - 1) * 2;
		
		bool noPos[MAXPLAYERS+1] = false;
		int posnr[MAXPLAYERS+1];
		
		// Store timer handles so they can be killed on reset
		capCountdownTimer1 = CreateTimer(0.0, TimerCapFightCountDown, 3);
		capCountdownTimer2 = CreateTimer(1.0, TimerCapFightCountDown, 2);
		capCountdownTimer3 = CreateTimer(2.0, TimerCapFightCountDown, 1);
		capCountdownEndTimer = CreateTimer(3.0, TimerCapFightCountDownEnd);

		KeyValues keygroup = new KeyValues("capPositions");
		keygroup.ImportFromFile(pathCapPositionsFile);

		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player))
			{
				char playerSteamid[32];
				GetClientAuthId(player, AuthId_Engine, playerSteamid, sizeof(playerSteamid));
				
				if (GetClientTeam(player) > 1  && IsPlayerAlive(player)) SetEntityMoveType(player, MOVETYPE_NONE);
				else
				{
					noPos[player] = false;
					
					
					keygroup.JumpToKey(playerSteamid, true);

					int gk = keygroup.GetNum("gk", 0);
					int lb = keygroup.GetNum("lb", 0);
					int rb = keygroup.GetNum("rb", 0);
					int mf = keygroup.GetNum("mf", 0);
					int lw = keygroup.GetNum("lw", 0);
					int rw = keygroup.GetNum("rw", 0);
					int spec = keygroup.GetNum("spec", 0);

					if (spec == 1 || (!gk && !lb && !rb && !mf && !lw && !rw))
					{
						noPos[player] = true; // array + clear array function
					}
				}
				
				posnr[player] = ImportJoinNumber(playerSteamid)
			}
		}

		keygroup.Close();
		
		if (noPos[client] == true) 
		{
			CPrintToChat(client, "{%s}[%s] {%s}Please set your position to help the caps with picking", prefixcolor, prefix, textcolor);
			OpenCapPositionMenu(client);
		}

		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player)) 
			{
				//PrintToServer("%N : %i", player, posnr[player]); 
				CPrintToChat(player, "{%s}[%s] {%s}%N has started a cap fight", prefixcolor, prefix, textcolor, client);
				CPrintToChat(player, "{%s}[%s] {%s}You joined this cap on position number {%s}%i.", prefixcolor, prefix, textcolor, prefixcolor, posnr[player]);
			}
		}

		HostName_Change_Status("Capfight");

		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		LogMessage("%N <%s> has started a cap fight", client, steamid);
	}
	else CPrintToChat(client, "{%s}[%s] {%s}Cap fight already started", prefixcolor, prefix, textcolor);
}

public void CapCreatePickMenu(int client)
{
	Menu menu = new Menu(CapPickMenuHandler);

	menu.SetTitle("[Join Nr] Name [Positions]");

	KeyValues keygroup = new KeyValues("capPositions");
	keygroup.ImportFromFile(pathCapPositionsFile);

	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player) && IsClientConnected(player) && !IsFakeClient(player) && !IsClientSourceTV(player))
		{
			int team = GetClientTeam(player);
			if (team < 2)
			{
				char playerid[4];
				IntToString(player, playerid, sizeof(playerid));

				char playerName[MAX_NAME_LENGTH];
				GetClientName(player, playerName, sizeof(playerName));

				char steamid[32];
				GetClientAuthId(player, AuthId_Engine, steamid, sizeof(steamid));
				keygroup.JumpToKey(steamid, true);

				char positions[32] = "";
				if (keygroup.GetNum("gk", 0)) Format(positions, sizeof(positions), "%s[GK]", positions);
				if (keygroup.GetNum("lb", 0)) Format(positions, sizeof(positions), "%s[LB]", positions);
				if (keygroup.GetNum("rb", 0)) Format(positions, sizeof(positions), "%s[RB]", positions);
				if (keygroup.GetNum("mf", 0)) Format(positions, sizeof(positions), "%s[MF]", positions);
				if (keygroup.GetNum("lw", 0)) Format(positions, sizeof(positions), "%s[LW]", positions);
				if (keygroup.GetNum("rw", 0)) Format(positions, sizeof(positions), "%s[RW]", positions);
				if (keygroup.GetNum("spec", 0)) Format(positions, sizeof(positions), "[SPEC ONLY]");

				int posnr = ImportJoinNumber(steamid);

				char menuString[64];
				if (positions[0]) Format(menuString, sizeof(menuString), "[%i] %s %s", posnr, playerName, positions);
				else Format(menuString, sizeof(menuString), "[%i] %s", posnr, playerName);
				//menuString = playerName;
				if(first12Set == 1)
				{
					if(posnr > 12)	menu.AddItem(playerid, menuString, ITEMDRAW_DISABLED);
					else			menu.AddItem(playerid, menuString);
				}
				else if (first12Set == 2)
				{
					if(posnr > capnr)	menu.AddItem(playerid, menuString, ITEMDRAW_DISABLED);
					else				menu.AddItem(playerid, menuString);
				}
				else				menu.AddItem(playerid, menuString);
				keygroup.Rewind();
			}
		}
	}

	delete keygroup;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int ImportJoinNumber(char steamid[32])
{
	int nr = 0;
	int entries = 0;
	char buffer[32];
	
	//kvConnectlist = new KeyValues("connectlist");
	kvConnectlist.ImportFromFile(DCListKV);
	
	if (kvConnectlist.GotoFirstSubKey())
	{
		entries++;
		while (kvConnectlist.GotoNextKey())
		{
			entries++;
		}
	}
	kvConnectlist.Rewind();
	
	kvConnectlist.GotoFirstSubKey();
	kvConnectlist.SavePosition();
	
	for (int i = 1; i <= entries; i++)
	{
		kvConnectlist.GetSectionName(buffer, sizeof(buffer));
		
		if(bIsOnServer(buffer))	nr++;
		
		kvConnectlist.GotoNextKey();
		kvConnectlist.SavePosition();
		
		if (StrEqual(buffer, steamid)) 
		{
			kvConnectlist.Rewind();
			//kvConnectlist.Close();
			return nr; 
		}
	}
	kvConnectlist.Rewind();
	//kvConnectlist.Close();
	
	return 0;
}


/*public void AutoCapStart(int client)
{
	if (!capFightStarted)
	{
		if(passwordlock == 1)
		{
			pwchange = true;
			CPrintToChatAll("{%s}[%s] {%s}AFK Kick enabled.", prefixcolor, prefix, textcolor);
			AFKKick();
		}
		
		// count players
		capnr = GetClientCount();
		if(first12Set == 1)
		{
			if(nrhelper >= capnr)
			{
				first12Set = 2;
				tempRule = true;
			}
		}
		if(first12Set == 2)
		{
			if (capnr < 12)	capnr = 12;
		}
		nrhelper = 0;
		
		capFightStarted = true;
		capPicksLeft = (matchMaxPlayers - 1) * 2;
		
		int posnr[MAXPLAYERS+1];
		gkArray.Clear();
		dfArray.Clear();
		mfArray.Clear();
		wgArray.Clear();
		nPArray.Clear();
		
		KeyValues keygroup = new KeyValues("capPositions");
		keygroup.ImportFromFile(pathCapPositionsFile);

		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player) && IsClientConnected(player))
			{
				char playerSteamid[32];
				GetClientAuthId(player, AuthId_Engine, playerSteamid, sizeof(playerSteamid));
				
				noPos[player] = false;
					
				keygroup.JumpToKey(playerSteamid, true);

				int gk = keygroup.GetNum("gk", 0);
				int lb = keygroup.GetNum("lb", 0);
				int rb = keygroup.GetNum("rb", 0);
				int mf = keygroup.GetNum("mf", 0);
				int lw = keygroup.GetNum("lw", 0);
				int rw = keygroup.GetNum("rw", 0);
				int spec = keygroup.GetNum("spec", 0);
				
				//Fill arrays
				if(gk == 1)
				{
					gkArray.Push(player);
				}
				if((lb == 1 && rb == 1) || lb == 1 || rb == 1)
				{
					dfArray.Push(player);
				}
				if(mf = 1)
				{
					mfArray.Push(player);
				}
				if((lw == 1 && rw == 1) || lw == 1 || rw == 1)
				{
					wgArray.Push(player);
				}
				if(gk == 0 && lb == 0 && rb == 0 && mf == 0 && lw == 0 && rw == 0)
				{
					nPArray.Push(player);
				}
				
				posnr[player] = ImportJoinNumber(playerSteamid)
			}
		}

		//Pick Team
		PickTeams();
	}
	else CPrintToChat(client, "{%s}[%s] {%s}Cap fight already started", prefixcolor, prefix, textcolor);
}


public void PickTeams()
{
	//CoinToss for starting team
	int firstpick = GetRandomInt(2, 3);
	int secondpick, picker;
	if(firstpick == CS_TEAM_T) secondpick = CS_TEAM_CT;
	else secondpick = CS_TEAM_T;
	
	ArrayList priorityList = CreateArray(MAXPLAYERS+1);
	priorityList.ClearArray();
	
	for(int player = 0
}*/