public void ChangeGameDesc()
{
	if (StrEqual(gamevar, "cstrike"))	SteamWorks_SetGameDescription("CS:S Soccer Mod")
	else if (StrEqual(gamevar, "csgo"))		SteamWorks_SetGameDescription("CS:GO Soccer Mod");
}

public void HostName_Change_Status(char type[16])
{
	// Always kill the match timer when changing status
	KillHostnameTimer();

	// Ensure we have a valid handle
	if (g_hostname == null)
	{
		g_hostname = FindConVar("hostname");
		if (g_hostname == null) return;
	}

	if (hostnameToggle != 1)
	{
		g_hostname.SetString(old_hostname);
		return;
	}

	// Reset to original hostname first, then apply new prefix
	if (StrEqual(type, "Public") || StrEqual(type, "Reset"))
	{
		g_hostname.SetString(old_hostname);
	}
	else if (StrEqual(type, "Match"))
	{
		// Match uses a repeating timer for live clock display
		hostnameTimer = CreateTimer(0.0, HostName_Change_Timer);
	}
	else
	{
		// Map type to display tag
		char tag[32];
		if (StrEqual(type, "Specced"))				tag = "PRE-CAP";
		else if (StrEqual(type, "Capfight"))		tag = "CAPFIGHT";
		else if (StrEqual(type, "Voting"))			tag = "VOTING";
		else if (StrEqual(type, "Picking"))			tag = "PICKING";
		else if (StrEqual(type, "Ready-Up"))		tag = "READY UP";
		else if (StrEqual(type, "Ready Check"))		tag = "READY CHECK";
		else if (StrEqual(type, "Periodbreak"))
		{
			Format(new_hostname, sizeof(new_hostname), "[PERIOD BREAK (%d-%d)] %s", matchScoreCT, matchScoreT, old_hostname);
			g_hostname.SetString(new_hostname);
			return;
		}
		else if (StrEqual(type, "Halftime"))
		{
			Format(new_hostname, sizeof(new_hostname), "[HALFTIME (%d-%d)] %s", matchScoreCT, matchScoreT, old_hostname);
			g_hostname.SetString(new_hostname);
			return;
		}
		else if (StrEqual(type, "Pre-Golden Goal"))	tag = "PRE-GOLDEN GOAL";
		else if (StrEqual(type, "Golden"))			tag = "GOLDEN GOAL";
		else										tag = "SOCCER MOD";

		Format(new_hostname, sizeof(new_hostname), "[%s] %s", tag, old_hostname);
		g_hostname.SetString(new_hostname);
	}
}

public Action HostName_Change_Timer(Handle timer)
{
	char timeString[16];
	getTimeString(timeString, matchTime);
	char stoppageTimeString[16];
	getTimeString(stoppageTimeString, matchStoppageTime);

	if(matchTime <= matchPeriodLength && matchStoppageTime == 0)
	{
		Format(new_hostname, sizeof(new_hostname), "[%s (%d-%d)] %s", timeString, matchScoreCT, matchScoreT, old_hostname);
		g_hostname.SetString(new_hostname);
	}
	else if ((matchTime == matchPeriodLength && matchStoppageTime > 0) || (matchTime == matchPeriodLength*2 && matchStoppageTime > 0))
	{
		Format(new_hostname, sizeof(new_hostname), "[%s + %s (%d-%d)] %s", timeString, stoppageTimeString, matchScoreCT, matchScoreT, old_hostname);
		g_hostname.SetString(new_hostname);
	}
	else if (matchTime <= matchPeriodLength*2 && matchStoppageTime == 0)
	{
		Format(new_hostname, sizeof(new_hostname), "[%s (%d-%d)] %s", timeString, matchScoreCT, matchScoreT, old_hostname);
		g_hostname.SetString(new_hostname);
	}
	else if (matchTime > matchPeriodLength*matchPeriods)
	{
		Format(new_hostname, sizeof(new_hostname), "[OT %s (%d-%d)] %s", timeString, matchScoreCT, matchScoreT, old_hostname);
		g_hostname.SetString(new_hostname);
	}

	hostnameTimer = CreateTimer(hostname_update_time, HostName_Change_Timer);
	return Plugin_Continue;
}

public void KillHostnameTimer()
{
	if (hostnameTimer != null)
	{
		KillTimer(hostnameTimer);
		hostnameTimer = null;
	}
}

/*public void AddSoccerTags()
{
	char oldtags[256], newtags[256];
	//char soccertags[64] = "soccer,soccermod,soccer_mod";
	int flags;
	
	ConVar tags = FindConVar("sv_tags");
	flags = GetConVarFlags(tags);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(tags, flags);
	
	tags.GetString(oldtags, sizeof(oldtags));
	//PrintToChatAll(oldtags);
	if(SimpleRegexMatch(oldtags, "soccer\\W", false) == -1)
	{
		Format(newtags, sizeof(newtags), "%s,soccer", oldtags);
		tags.SetString(newtags, false, false);
	}
	if(StrContains(oldtags, "soccermod,", false) == -1)
	{
		Format(newtags, sizeof(newtags), "%s,soccermod", oldtags);
		tags.SetString(newtags, false, false);
	}
	if(StrContains(oldtags, "soccer_mod,", false) == -1)
	{
		Format(newtags, sizeof(newtags), "%s,soccer_mod", oldtags);
		tags.SetString(newtags, false, false);
	}
	
	CloseHandle(tags);
}*/