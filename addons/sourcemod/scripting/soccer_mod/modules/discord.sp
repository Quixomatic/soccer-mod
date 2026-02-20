// **************************************************************************************************************
// ********************************************** DISCORD WEBHOOKS **********************************************
// **************************************************************************************************************

// Discord embed colors
#define DISCORD_COLOR_BLUE		3447003
#define DISCORD_COLOR_RED		15158332
#define DISCORD_COLOR_GREEN		3066993
#define DISCORD_COLOR_YELLOW	16776960
#define DISCORD_COLOR_PURPLE	10181046

// ************************************************** CORE POST *************************************************

void Discord_Post(JSONObject payload)
{
	if (!suRipextAvailable) return;
	if (strlen(discordWebhookUrl) == 0) return;

	HTTPRequest request = new HTTPRequest(discordWebhookUrl);
	request.Post(payload, Discord_OnPostResponse);
	delete payload;
}

public void Discord_OnPostResponse(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK && response.Status != HTTPStatus_NoContent)
	{
		LogError("[Soccer Mod] Discord webhook POST failed with status %d", response.Status);
	}
}

// ************************************************ EMBED HELPERS ************************************************

JSONObject Discord_CreateEmbed(const char[] title, const char[] description, int color)
{
	JSONObject embed = new JSONObject();
	embed.SetString("title", title);
	if (strlen(description) > 0)
		embed.SetString("description", description);
	embed.SetInt("color", color);

	// Footer: Soccer Mod vX.X.X • map_name
	JSONObject footer = new JSONObject();
	char footerText[128];
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(footerText, sizeof(footerText), "Soccer Mod v%s \xe2\x80\xa2 %s", PLUGIN_VERSION, mapName);
	footer.SetString("text", footerText);
	embed.Set("footer", footer);
	delete footer;

	return embed;
}

void Discord_AddField(JSONArray fields, const char[] name, const char[] value, bool isInline)
{
	JSONObject field = new JSONObject();
	field.SetString("name", name);
	field.SetString("value", value);
	field.SetBool("inline", isInline);
	fields.Push(field);
	delete field;
}

void Discord_SendEmbed(JSONObject embed)
{
	JSONArray embeds = new JSONArray();
	embeds.Push(embed);
	delete embed;

	JSONObject payload = new JSONObject();
	payload.Set("embeds", embeds);
	delete embeds;

	Discord_Post(payload);
}

// ******************************************** EVENT: MATCH START ***********************************************

void Discord_NotifyMatchStart()
{
	if (!discordMatchStart) return;

	JSONObject embed = Discord_CreateEmbed("Match Started", "", DISCORD_COLOR_BLUE);

	JSONArray fields = new JSONArray();

	// Build team rosters as two inline fields
	char ctRoster[512], tRoster[512];
	ctRoster[0] = '\0';
	tRoster[0] = '\0';

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		int team = GetClientTeam(i);
		if (team != CS_TEAM_CT && team != CS_TEAM_T) continue;

		char playerName[MAX_NAME_LENGTH];
		GetClientName(i, playerName, sizeof(playerName));

		char line[72];
		Format(line, sizeof(line), "%s\n", playerName);

		if (team == CS_TEAM_CT)
			StrCat(ctRoster, sizeof(ctRoster), line);
		else
			StrCat(tRoster, sizeof(tRoster), line);
	}

	// Trim trailing newline
	if (strlen(ctRoster) > 0) ctRoster[strlen(ctRoster) - 1] = '\0';
	if (strlen(tRoster) > 0) tRoster[strlen(tRoster) - 1] = '\0';

	char ctHeader[48], tHeader[48];
	Format(ctHeader, sizeof(ctHeader), "%s", custom_name_ct);
	Format(tHeader, sizeof(tHeader), "%s", custom_name_t);

	if (strlen(ctRoster) > 0)
		Discord_AddField(fields, ctHeader, ctRoster, true);
	if (strlen(tRoster) > 0)
		Discord_AddField(fields, tHeader, tRoster, true);

	// Match info as a full-width field
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	int periodMins = matchPeriodLength / 60;
	char info[128];
	Format(info, sizeof(info), "%s \xe2\x80\xa2 %dv%d \xe2\x80\xa2 %d x %dmin", mapName, matchMaxPlayers, matchMaxPlayers, matchPeriods, periodMins);
	Discord_AddField(fields, "Match Info", info, false);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
}

// ********************************************* EVENT: MATCH END ************************************************

void Discord_NotifyMatchEnd()
{
	if (!discordMatchEnd) return;

	char title[128];
	if (matchScoreCT > matchScoreT)
		Format(title, sizeof(title), "Match Over \xe2\x80\x94 %s Wins!", custom_name_ct);
	else if (matchScoreT > matchScoreCT)
		Format(title, sizeof(title), "Match Over \xe2\x80\x94 %s Wins!", custom_name_t);
	else
		Format(title, sizeof(title), "Match Over \xe2\x80\x94 Draw!");

	JSONObject embed = Discord_CreateEmbed(title, "", DISCORD_COLOR_RED);

	JSONArray fields = new JSONArray();

	char score[64];
	Format(score, sizeof(score), "**%s** %d : %d **%s**", custom_name_ct, matchScoreCT, matchScoreT, custom_name_t);
	Discord_AddField(fields, "Final Score", score, false);

	// Top 3 players by points
	Discord_AddMatchTop3(fields);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
}

void Discord_AddMatchTop3(JSONArray fields)
{
	// Uses statsKeygroupMatch (same approach as ShowTop3 in stats.sp)
	int topPoints[3] = {0, 0, 0};
	char topNames[3][MAX_NAME_LENGTH];
	topNames[0][0] = '\0';
	topNames[1][0] = '\0';
	topNames[2][0] = '\0';

	if (!statsKeygroupMatch.GotoFirstSubKey()) return;

	do
	{
		int pts = statsKeygroupMatch.GetNum("points", 0);
		char name[MAX_NAME_LENGTH];
		statsKeygroupMatch.GetString("name", name, sizeof(name));

		for (int j = 0; j < 3; j++)
		{
			if (pts > topPoints[j])
			{
				// Shift down
				for (int k = 2; k > j; k--)
				{
					strcopy(topNames[k], MAX_NAME_LENGTH, topNames[k-1]);
					topPoints[k] = topPoints[k-1];
				}
				strcopy(topNames[j], MAX_NAME_LENGTH, name);
				topPoints[j] = pts;
				break;
			}
		}
	}
	while (statsKeygroupMatch.GotoNextKey());

	statsKeygroupMatch.Rewind();

	char leaderboard[512];
	leaderboard[0] = '\0';
	char medals[3][] = {"\xf0\x9f\xa5\x87", "\xf0\x9f\xa5\x88", "\xf0\x9f\xa5\x89"};
	for (int i = 0; i < 3; i++)
	{
		if (strlen(topNames[i]) > 0)
		{
			char line[128];
			Format(line, sizeof(line), "%s **%s** (%d pts)\n", medals[i], topNames[i], topPoints[i]);
			StrCat(leaderboard, sizeof(leaderboard), line);
		}
	}

	if (strlen(leaderboard) > 0)
	{
		Discord_AddField(fields, "Top Players", leaderboard, false);
	}
}

// ******************************************** EVENT: GOAL SCORED ***********************************************

void Discord_NotifyGoal(int scoringTeam)
{
	if (!discordGoal) return;

	char title[128];
	if (scoringTeam == CS_TEAM_CT)
		Format(title, sizeof(title), "\xe2\x9a\xbd GOAL! %s %d : %d %s", custom_name_ct, matchScoreCT, matchScoreT, custom_name_t);
	else
		Format(title, sizeof(title), "\xe2\x9a\xbd GOAL! %s %d : %d %s", custom_name_ct, matchScoreCT, matchScoreT, custom_name_t);

	int color = (scoringTeam == CS_TEAM_CT) ? DISCORD_COLOR_BLUE : DISCORD_COLOR_RED;

	char desc[256];
	if (strlen(statsScorerName) > 0 && strlen(statsAssisterName) > 0)
		Format(desc, sizeof(desc), "**%s** (Assist: *%s*)", statsScorerName, statsAssisterName);
	else if (strlen(statsScorerName) > 0)
		Format(desc, sizeof(desc), "**%s**", statsScorerName);
	else
		desc = "Unknown Scorer";

	JSONObject embed = Discord_CreateEmbed(title, desc, color);

	JSONArray fields = new JSONArray();

	char period[32];
	Format(period, sizeof(period), "%d / %d", matchPeriod, matchPeriods);
	Discord_AddField(fields, "Period", period, true);

	char timeStr[32];
	int mins = matchTime / 60;
	int secs = matchTime % 60;
	Format(timeStr, sizeof(timeStr), "%d:%02d", mins, secs);
	Discord_AddField(fields, "Time", timeStr, true);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
}

// ********************************************* EVENT: HALFTIME *************************************************

void Discord_NotifyHalftime()
{
	if (!discordHalftime) return;

	char title[128];
	Format(title, sizeof(title), "Halftime \xe2\x80\x94 %s %d : %d %s", custom_name_ct, matchScoreCT, matchScoreT, custom_name_t);

	JSONObject embed = Discord_CreateEmbed(title, "", DISCORD_COLOR_YELLOW);

	JSONArray fields = new JSONArray();

	char period[32];
	Format(period, sizeof(period), "End of period %d", matchPeriod - 1);
	Discord_AddField(fields, "Period", period, false);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
}

// ******************************************** EVENT: CAP RESULT ************************************************

void Discord_NotifyCapResult(int winnerTeam)
{
	if (!discordCap) return;

	char title[128];
	char winnerName[MAX_NAME_LENGTH];
	char loserName[MAX_NAME_LENGTH];

	if (winnerTeam == CS_TEAM_T && capT > 0 && IsClientInGame(capT))
	{
		GetClientName(capT, winnerName, sizeof(winnerName));
		if (capCT > 0 && IsClientInGame(capCT))
			GetClientName(capCT, loserName, sizeof(loserName));
		else
			loserName = "Unknown";
	}
	else if (winnerTeam == CS_TEAM_CT && capCT > 0 && IsClientInGame(capCT))
	{
		GetClientName(capCT, winnerName, sizeof(winnerName));
		if (capT > 0 && IsClientInGame(capT))
			GetClientName(capT, loserName, sizeof(loserName));
		else
			loserName = "Unknown";
	}
	else
	{
		winnerName = "Unknown";
		loserName = "Unknown";
	}

	Format(title, sizeof(title), "\xe2\x9a\x94 Cap Won by %s", winnerName);

	JSONObject embed = Discord_CreateEmbed(title, "", DISCORD_COLOR_PURPLE);

	JSONArray fields = new JSONArray();

	Discord_AddField(fields, "Winner", winnerName, true);
	Discord_AddField(fields, "Loser", loserName, true);

	char weaponDisplay[64];
	Format(weaponDisplay, sizeof(weaponDisplay), "%s", capweapon);
	Discord_AddField(fields, "Weapon", weaponDisplay, true);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
}

// ***************************************** CUSTOM ADMIN MESSAGE ************************************************

void Discord_SendCustomMessage(int client, const char[] message)
{
	if (strlen(discordWebhookUrl) == 0 || !suRipextAvailable) return;

	char senderName[MAX_NAME_LENGTH];
	GetClientName(client, senderName, sizeof(senderName));

	JSONObject embed = new JSONObject();
	embed.SetString("description", message);
	embed.SetInt("color", DISCORD_COLOR_BLUE);

	JSONObject author = new JSONObject();
	author.SetString("name", senderName);
	embed.Set("author", author);
	delete author;

	JSONObject footer = new JSONObject();
	char footerText[128];
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(footerText, sizeof(footerText), "Soccer Mod v%s \xe2\x80\xa2 %s", PLUGIN_VERSION, mapName);
	footer.SetString("text", footerText);
	embed.Set("footer", footer);
	delete footer;

	Discord_SendEmbed(embed);

	CPrintToChat(client, "{%s}[%s] {green}Message sent to Discord.", prefixcolor, prefix);
}

// ****************************************** TEST NOTIFICATIONS *************************************************

void Discord_TestMatchStart(int client)
{
	if (strlen(discordWebhookUrl) == 0)
	{
		CPrintToChat(client, "{%s}[%s] {red}No webhook URL set.", prefixcolor, prefix);
		return;
	}

	JSONObject embed = Discord_CreateEmbed("Match Started", "", DISCORD_COLOR_BLUE);
	JSONArray fields = new JSONArray();

	Discord_AddField(fields, "CT", "Player1\nPlayer2\nPlayer3", true);
	Discord_AddField(fields, "T", "Player4\nPlayer5\nPlayer6", true);

	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	char info[128];
	Format(info, sizeof(info), "%s \xe2\x80\xa2 6v6 \xe2\x80\xa2 2 x 15min", mapName);
	Discord_AddField(fields, "Match Info", info, false);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
	CPrintToChat(client, "{%s}[%s] {green}Test Match Start sent.", prefixcolor, prefix);
}

void Discord_TestMatchEnd(int client)
{
	if (strlen(discordWebhookUrl) == 0)
	{
		CPrintToChat(client, "{%s}[%s] {red}No webhook URL set.", prefixcolor, prefix);
		return;
	}

	JSONObject embed = Discord_CreateEmbed("Match Over \xe2\x80\x94 CT Wins!", "", DISCORD_COLOR_RED);
	JSONArray fields = new JSONArray();

	Discord_AddField(fields, "Final Score", "**CT** 4 : 2 **T**", false);
	Discord_AddField(fields, "Top Players", "\xf0\x9f\xa5\x87 **PlayerOne** (42 pts)\n\xf0\x9f\xa5\x88 **PlayerTwo** (35 pts)\n\xf0\x9f\xa5\x89 **PlayerThree** (28 pts)\n", false);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
	CPrintToChat(client, "{%s}[%s] {green}Test Match End sent.", prefixcolor, prefix);
}

void Discord_TestGoal(int client)
{
	if (strlen(discordWebhookUrl) == 0)
	{
		CPrintToChat(client, "{%s}[%s] {red}No webhook URL set.", prefixcolor, prefix);
		return;
	}

	JSONObject embed = Discord_CreateEmbed("\xe2\x9a\xbd GOAL! CT 3 : 2 T", "**PlayerOne** (Assist: *PlayerTwo*)", DISCORD_COLOR_GREEN);
	JSONArray fields = new JSONArray();

	Discord_AddField(fields, "Period", "1 / 2", true);
	Discord_AddField(fields, "Time", "8:32", true);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
	CPrintToChat(client, "{%s}[%s] {green}Test Goal sent.", prefixcolor, prefix);
}

void Discord_TestCapResult(int client)
{
	if (strlen(discordWebhookUrl) == 0)
	{
		CPrintToChat(client, "{%s}[%s] {red}No webhook URL set.", prefixcolor, prefix);
		return;
	}

	char testName[MAX_NAME_LENGTH];
	GetClientName(client, testName, sizeof(testName));

	char title[128];
	Format(title, sizeof(title), "\xe2\x9a\x94 Cap Won by %s", testName);

	JSONObject embed = Discord_CreateEmbed(title, "", DISCORD_COLOR_PURPLE);
	JSONArray fields = new JSONArray();

	Discord_AddField(fields, "Winner", testName, true);
	Discord_AddField(fields, "Loser", "Opponent", true);
	Discord_AddField(fields, "Weapon", "knife", true);

	embed.Set("fields", fields);
	delete fields;

	Discord_SendEmbed(embed);
	CPrintToChat(client, "{%s}[%s] {green}Test Cap Result sent.", prefixcolor, prefix);
}

// ******************************************** DISCORD ADMIN MENU ***********************************************

void OpenMenuDiscord(int client)
{
	if (!suRipextAvailable)
	{
		CPrintToChat(client, "{%s}[%s] {red}Discord webhooks require the ripext extension.", prefixcolor, prefix);
		OpenMenuSettings(client);
		return;
	}

	Menu menu = new Menu(MenuHandlerDiscord);

	// Show truncated URL in title
	char urlDisplay[48];
	if (strlen(discordWebhookUrl) > 0)
	{
		// Show first 20 and last 6 chars
		char first[21], last[7];
		strcopy(first, sizeof(first), discordWebhookUrl);
		strcopy(last, sizeof(last), discordWebhookUrl[strlen(discordWebhookUrl) - 6]);
		Format(urlDisplay, sizeof(urlDisplay), "%s...%s", first, last);
	}
	else
	{
		urlDisplay = "Not Set";
	}

	menu.SetTitle("Discord Webhooks\nWebhook: %s", urlDisplay);

	menu.AddItem("seturl", "Set Webhook URL");
	menu.AddItem("clearurl", "Clear Webhook URL");
	menu.AddItem("sendmsg", "Send Message to Discord");
	menu.AddItem("", "", ITEMDRAW_SPACER);

	char matchStartStr[48], matchEndStr[48], goalStr[48], halftimeStr[48], capStr[48];
	Format(matchStartStr, sizeof(matchStartStr), "Match Start: %s", discordMatchStart ? "ON" : "OFF");
	Format(matchEndStr, sizeof(matchEndStr), "Match End: %s", discordMatchEnd ? "ON" : "OFF");
	Format(goalStr, sizeof(goalStr), "Goal Scored: %s", discordGoal ? "ON" : "OFF");
	Format(halftimeStr, sizeof(halftimeStr), "Halftime: %s", discordHalftime ? "ON" : "OFF");
	Format(capStr, sizeof(capStr), "Cap Result: %s", discordCap ? "ON" : "OFF");

	menu.AddItem("togglestart", matchStartStr);
	menu.AddItem("toggleend", matchEndStr);
	menu.AddItem("togglegoal", goalStr);
	menu.AddItem("togglehalf", halftimeStr);
	menu.AddItem("togglecap", capStr);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("tests", "Test Notifications...");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerDiscord(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		if (StrEqual(menuItem, "seturl"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Paste your Discord webhook URL in chat:", prefixcolor, prefix, textcolor);
			changeSetting[client] = "DiscordWebhook";
		}
		else if (StrEqual(menuItem, "clearurl"))
		{
			discordWebhookUrl[0] = '\0';
			UpdateConfigString("Discord Settings", "soccer_mod_discord_webhook", discordWebhookUrl);
			CPrintToChat(client, "{%s}[%s] {%s}Webhook URL cleared.", prefixcolor, prefix, textcolor);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "sendmsg"))
		{
			if (strlen(discordWebhookUrl) == 0)
			{
				CPrintToChat(client, "{%s}[%s] {red}Set a webhook URL first.", prefixcolor, prefix);
				OpenMenuDiscord(client);
			}
			else
			{
				CPrintToChat(client, "{%s}[%s] {%s}Type your message in chat:", prefixcolor, prefix, textcolor);
				changeSetting[client] = "DiscordMessage";
			}
		}
		else if (StrEqual(menuItem, "togglestart"))
		{
			discordMatchStart = !discordMatchStart;
			UpdateConfigInt("Discord Settings", "soccer_mod_discord_match_start", discordMatchStart);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "toggleend"))
		{
			discordMatchEnd = !discordMatchEnd;
			UpdateConfigInt("Discord Settings", "soccer_mod_discord_match_end", discordMatchEnd);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "togglegoal"))
		{
			discordGoal = !discordGoal;
			UpdateConfigInt("Discord Settings", "soccer_mod_discord_goal", discordGoal);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "togglehalf"))
		{
			discordHalftime = !discordHalftime;
			UpdateConfigInt("Discord Settings", "soccer_mod_discord_halftime", discordHalftime);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "togglecap"))
		{
			discordCap = !discordCap;
			UpdateConfigInt("Discord Settings", "soccer_mod_discord_cap", discordCap);
			OpenMenuDiscord(client);
		}
		else if (StrEqual(menuItem, "tests"))
		{
			OpenMenuDiscordTests(client);
		}
	}
	else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
	{
		OpenMenuSettings(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

// ******************************************** DISCORD TEST MENU ************************************************

void OpenMenuDiscordTests(int client)
{
	Menu menu = new Menu(MenuHandlerDiscordTests);
	menu.SetTitle("Discord Webhooks - Test");

	menu.AddItem("teststart", "Test: Match Start");
	menu.AddItem("testend", "Test: Match End");
	menu.AddItem("testgoal", "Test: Goal Scored");
	menu.AddItem("testcap", "Test: Cap Result");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerDiscordTests(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		if (StrEqual(menuItem, "teststart"))		Discord_TestMatchStart(client);
		else if (StrEqual(menuItem, "testend"))		Discord_TestMatchEnd(client);
		else if (StrEqual(menuItem, "testgoal"))	Discord_TestGoal(client);
		else if (StrEqual(menuItem, "testcap"))		Discord_TestCapResult(client);

		OpenMenuDiscordTests(client);
	}
	else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
	{
		OpenMenuDiscord(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}
