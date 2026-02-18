// *******************************************************************************************************************
// ************************************************** SELF-UPDATER *************************************************
// *******************************************************************************************************************

#define SU_MANIFEST_URL "https://soccer-mod.jfreund18.workers.dev/manifest.json"
#define SU_RAW_BASE_URL "https://soccer-mod.jfreund18.workers.dev/"

// ************************************************** LIFECYCLE ****************************************************

public void SelfUpdaterOnPluginStart()
{
	suRipextAvailable = (GetFeatureStatus(FeatureType_Native, "HTTPRequest.HTTPRequest") == FeatureStatus_Available);
}

public void SelfUpdaterOnMapStart()
{
	if (!suRipextAvailable || !suAutoCheck)
		return;

	int now = GetTime();
	if (now - suLastCheckTime >= suCheckInterval)
	{
		SU_CheckForUpdate(0);
	}
}

// ************************************************** CORE *********************************************************

public void SU_CheckForUpdate(int client)
{
	if (!suRipextAvailable)
	{
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}Updater requires the ripext extension.", prefixcolor, prefix, textcolor);
		return;
	}

	if (suDownloading)
	{
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}A download is already in progress.", prefixcolor, prefix, textcolor);
		return;
	}

	HTTPRequest request = new HTTPRequest(SU_MANIFEST_URL);
	request.SetHeader("User-Agent", "SoccerMod");

	int userid = 0;
	if (client > 0)
		userid = GetClientUserId(client);

	LogMessage("[Soccer Mod] Fetching manifest: %s", SU_MANIFEST_URL);
	request.Get(SU_OnManifestResponse, userid);
	suLastCheckTime = GetTime();

	if (client > 0 && IsClientInGame(client))
		CPrintToChat(client, "{%s}[%s] {%s}Checking for updates...", prefixcolor, prefix, textcolor);
}

public void SU_OnManifestResponse(HTTPResponse response, any userid, const char[] error)
{
	if (response.Status != HTTPStatus_OK)
	{
		int client = (userid > 0) ? GetClientOfUserId(userid) : 0;
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}Update check failed (HTTP %d): %s", prefixcolor, prefix, textcolor, view_as<int>(response.Status), error);
		LogMessage("[Soccer Mod] Update check failed: HTTP %d | %s", view_as<int>(response.Status), error);
		return;
	}

	JSONObject manifest = view_as<JSONObject>(response.Data);
	if (manifest == null)
	{
		LogMessage("[Soccer Mod] Update check failed: invalid JSON response");
		return;
	}

	char remoteVersion[32];
	manifest.GetString("version", remoteVersion, sizeof(remoteVersion));

	if (SU_IsNewerVersion(remoteVersion, PLUGIN_VERSION))
	{
		suUpdateAvailable = true;
		strcopy(suLatestVersion, sizeof(suLatestVersion), remoteVersion);

		int client = (userid > 0) ? GetClientOfUserId(userid) : 0;
		if (client > 0 && IsClientInGame(client))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Update available: v%s (current: v%s)", prefixcolor, prefix, textcolor, remoteVersion, PLUGIN_VERSION);
		}
		else if (userid == 0)
		{
			CPrintToChatAll("{%s}[%s] {%s}Soccer Mod update available: v%s (current: v%s)", prefixcolor, prefix, textcolor, remoteVersion, PLUGIN_VERSION);
		}
	}
	else
	{
		suUpdateAvailable = false;
		int client = (userid > 0) ? GetClientOfUserId(userid) : 0;
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}Soccer Mod is up to date (v%s).", prefixcolor, prefix, textcolor, PLUGIN_VERSION);
	}
}

// ************************************************** DOWNLOAD *****************************************************

public void SU_StartUpdate(int client, bool fullUpdate)
{
	if (!suRipextAvailable)
	{
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}Updater requires the ripext extension.", prefixcolor, prefix, textcolor);
		return;
	}

	if (!suUpdateAvailable)
	{
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}No update available. Check for updates first.", prefixcolor, prefix, textcolor);
		return;
	}

	if (suDownloading)
	{
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}A download is already in progress.", prefixcolor, prefix, textcolor);
		return;
	}

	suDownloading = true;
	suFullUpdate = fullUpdate;
	suDownloadCount = 0;
	suDownloadErrors = 0;
	suRequestingUser = (client > 0) ? GetClientUserId(client) : 0;

	// Fetch manifest again to get file list
	HTTPRequest request = new HTTPRequest(SU_MANIFEST_URL);
	request.SetHeader("User-Agent", "SoccerMod");

	int userid = 0;
	if (client > 0)
		userid = GetClientUserId(client);

	request.Get(SU_OnDownloadManifestResponse, userid);

	if (client > 0 && IsClientInGame(client))
		CPrintToChat(client, "{%s}[%s] {%s}Downloading Soccer Mod v%s (%s update)...", prefixcolor, prefix, textcolor, suLatestVersion, fullUpdate ? "full" : "patch");
}

public void SU_OnDownloadManifestResponse(HTTPResponse response, any userid, const char[] error)
{
	if (response.Status != HTTPStatus_OK)
	{
		suDownloading = false;
		LogMessage("[Soccer Mod] Failed to fetch manifest for download: HTTP %d", view_as<int>(response.Status));
		return;
	}

	JSONObject manifest = view_as<JSONObject>(response.Data);
	if (manifest == null)
	{
		suDownloading = false;
		LogMessage("[Soccer Mod] Failed to parse manifest for download");
		return;
	}

	char arrayKey[8];
	if (suFullUpdate)
		strcopy(arrayKey, sizeof(arrayKey), "full");
	else
		strcopy(arrayKey, sizeof(arrayKey), "patch");

	JSONArray files = view_as<JSONArray>(manifest.Get(arrayKey));
	if (files == null)
	{
		suDownloading = false;
		LogMessage("[Soccer Mod] Manifest missing '%s' array", arrayKey);
		return;
	}

	suDownloadCount = files.Length;
	if (suDownloadCount == 0)
	{
		suDownloading = false;
		LogMessage("[Soccer Mod] No files to download in '%s' array", arrayKey);
		delete files;
		return;
	}

	for (int i = 0; i < files.Length; i++)
	{
		JSONObject fileObj = view_as<JSONObject>(files.Get(i));
		if (fileObj == null)
		{
			suDownloadCount--;
			continue;
		}

		char repoPath[PLATFORM_MAX_PATH];
		char destPath[PLATFORM_MAX_PATH];
		fileObj.GetString("repo", repoPath, sizeof(repoPath));
		fileObj.GetString("dest", destPath, sizeof(destPath));
		delete fileObj;

		// Construct download URL
		char url[512];
		Format(url, sizeof(url), "%s%s", SU_RAW_BASE_URL, repoPath);

		// Ensure parent directory exists
		SU_EnsureDirectoryExists(destPath);

		int reqClient = (suRequestingUser > 0) ? GetClientOfUserId(suRequestingUser) : 0;
		if (reqClient > 0 && IsClientInGame(reqClient))
			CPrintToChat(reqClient, "{%s}[%s] {%s}Downloading: %s", prefixcolor, prefix, textcolor, destPath);

		HTTPRequest dlRequest = new HTTPRequest(url);
		dlRequest.SetHeader("User-Agent", "SoccerMod");
		dlRequest.DownloadFile(destPath, SU_OnFileDownloaded);
	}

	delete files;
}

public void SU_OnFileDownloaded(HTTPStatus status, any data, const char[] error)
{
	suDownloadCount--;

	int reqClient = (suRequestingUser > 0) ? GetClientOfUserId(suRequestingUser) : 0;

	if (status != HTTPStatus_OK)
	{
		suDownloadErrors++;
		LogMessage("[Soccer Mod] Download failed (HTTP %d): %s", view_as<int>(status), error);
		if (reqClient > 0 && IsClientInGame(reqClient))
			CPrintToChat(reqClient, "{%s}[%s] {red}Download failed (HTTP %d): %s", prefixcolor, prefix, view_as<int>(status), error);
	}

	if (suDownloadCount <= 0)
	{
		suDownloading = false;

		if (suDownloadErrors == 0)
		{
			if (reqClient > 0 && IsClientInGame(reqClient))
				CPrintToChat(reqClient, "{%s}[%s] {%s}Soccer Mod updated to v%s. Change map or reload plugin to apply.", prefixcolor, prefix, textcolor, suLatestVersion);
			suUpdateAvailable = false;
		}
		else
		{
			if (reqClient > 0 && IsClientInGame(reqClient))
				CPrintToChat(reqClient, "{%s}[%s] {%s}Update completed with %d error(s). Check server logs.", prefixcolor, prefix, textcolor, suDownloadErrors);
		}

		// Reopen menu for the admin who triggered the download
		if (reqClient > 0 && IsClientInGame(reqClient))
			OpenMenuUpdater(reqClient);
		suRequestingUser = 0;
	}
}

// ************************************************** HELPERS ******************************************************

public void SU_EnsureDirectoryExists(const char[] filePath)
{
	char dir[PLATFORM_MAX_PATH];
	strcopy(dir, sizeof(dir), filePath);

	// Walk through path and create each directory level
	int len = strlen(dir);
	for (int i = 0; i < len; i++)
	{
		if (dir[i] == '/')
		{
			dir[i] = '\0';
			if (strlen(dir) > 0 && !DirExists(dir))
				CreateDirectory(dir, 511);
			dir[i] = '/';
		}
	}
}

public bool SU_IsNewerVersion(const char[] remote, const char[] local)
{
	int rMajor, rMinor, rPatch;
	int lMajor, lMinor, lPatch;

	SU_ParseVersion(remote, rMajor, rMinor, rPatch);
	SU_ParseVersion(local, lMajor, lMinor, lPatch);

	if (rMajor > lMajor) return true;
	if (rMajor < lMajor) return false;
	if (rMinor > lMinor) return true;
	if (rMinor < lMinor) return false;
	return (rPatch > lPatch);
}

public void SU_ParseVersion(const char[] version, int &major, int &minor, int &patch)
{
	char parts[3][16];
	ExplodeString(version, ".", parts, 3, 16);
	major = StringToInt(parts[0]);
	minor = StringToInt(parts[1]);
	patch = StringToInt(parts[2]);
}

// ************************************************** ADMIN MENU ***************************************************

public void OpenMenuUpdater(int client)
{
	Menu menu = new Menu(MenuHandlerUpdater);

	char titleBuf[256];
	if (suUpdateAvailable)
		Format(titleBuf, sizeof(titleBuf), "Soccer Mod - Updater\nCurrent: v%s | Latest: v%s", PLUGIN_VERSION, suLatestVersion);
	else if (strlen(suLatestVersion) > 0)
		Format(titleBuf, sizeof(titleBuf), "Soccer Mod - Updater\nCurrent: v%s | Up to date", PLUGIN_VERSION);
	else
		Format(titleBuf, sizeof(titleBuf), "Soccer Mod - Updater\nCurrent: v%s | Latest: Unknown", PLUGIN_VERSION);

	menu.SetTitle(titleBuf);

	menu.AddItem("check", "Check for Updates");

	if (suUpdateAvailable && !suDownloading)
	{
		menu.AddItem("patch", "Download Patch Update (.smx only)");
		menu.AddItem("full", "Download Full Update (all files)");
	}
	else if (suDownloading)
	{
		menu.AddItem("downloading", "Downloading...", ITEMDRAW_DISABLED);
	}

	char autoString[48];
	Format(autoString, sizeof(autoString), "Auto-Check: %s", suAutoCheck ? "ON" : "OFF");
	menu.AddItem("autocheck", autoString);

	char intervalString[48];
	Format(intervalString, sizeof(intervalString), "Check Interval: %ds", suCheckInterval);
	menu.AddItem("interval", intervalString);

	if (!suRipextAvailable)
	{
		menu.AddItem("noripext", "ripext extension not loaded!", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerUpdater(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(choice, menuItem, sizeof(menuItem));

		if (StrEqual(menuItem, "check"))
		{
			SU_CheckForUpdate(client);
			// Re-open menu after a short delay so the check can complete
			CreateTimer(2.0, SU_TimerReopenMenu, GetClientUserId(client));
		}
		else if (StrEqual(menuItem, "patch"))
		{
			SU_StartUpdate(client, false);
		}
		else if (StrEqual(menuItem, "full"))
		{
			SU_StartUpdate(client, true);
		}
		else if (StrEqual(menuItem, "autocheck"))
		{
			suAutoCheck = suAutoCheck ? 0 : 1;
			UpdateConfigInt("Updater Settings", "soccer_mod_su_autocheck", suAutoCheck);
			CPrintToChat(client, "{%s}[%s] {%s}Auto-check: %s", prefixcolor, prefix, textcolor, suAutoCheck ? "ON" : "OFF");
			OpenMenuUpdater(client);
		}
		else if (StrEqual(menuItem, "interval"))
		{
			CPrintToChat(client, "{%s}[%s] {%s}Type the check interval in seconds (600-86400). 0 to cancel.", prefixcolor, prefix, textcolor);
			changeSetting[client] = "SU_Interval";
		}
	}
	else if (action == MenuAction_Cancel && choice == -6)	OpenMenuSettings(client);
	else if (action == MenuAction_End)						menu.Close();
	return 0;
}

public Action SU_TimerReopenMenu(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
		OpenMenuUpdater(client);
	return Plugin_Stop;
}

// ************************************************** CHAT INPUT ***************************************************

public void SelfUpdaterSet(int client, char[] type, int value, int min, int max)
{
	if (value == 0)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Cancelled.", prefixcolor, prefix, textcolor);
		changeSetting[client] = "";
		OpenMenuUpdater(client);
		return;
	}

	if (value < min || value > max)
	{
		CPrintToChat(client, "{%s}[%s] {%s}Please enter a value between %d and %d.", prefixcolor, prefix, textcolor, min, max);
		return;
	}

	if (StrEqual(type, "SU_Interval"))
	{
		suCheckInterval = value;
		UpdateConfigInt("Updater Settings", "soccer_mod_su_check_interval", suCheckInterval);
		CPrintToChat(client, "{%s}[%s] {%s}Check interval set to %d seconds.", prefixcolor, prefix, textcolor, value);
	}

	changeSetting[client] = "";
	OpenMenuUpdater(client);
}

