// *******************************************************************************************************************
// ************************************************** STATS SYNC ***************************************************
// *******************************************************************************************************************
// Optional module: pushes stats to a remote API alongside local DB writes.
// Requires ripext extension. All calls are async fire-and-forget.

public void StatsSyncOnPluginStart()
{
	statsSyncRipextAvailable = (GetFeatureStatus(FeatureType_Native, "HTTPRequest.HTTPRequest") == FeatureStatus_Available);
}

// *******************************************************************************************************************
// ************************************************** HELPER *********************************************************
// *******************************************************************************************************************

// Fire-and-forget POST to the sync API
public void StatsSyncPost(const char[] endpoint, JSONObject json)
{
	if (statsSyncEnabled == 0 || !statsSyncRipextAvailable) return;
	if (statsSyncUrl[0] == '\0') return;

	char url[512];
	Format(url, sizeof(url), "%s/api/sync/%s", statsSyncUrl, endpoint);

	HTTPRequest request = new HTTPRequest(url);
	request.SetHeader("User-Agent", "SoccerMod");

	if (statsSyncKey[0] != '\0')
	{
		char authHeader[256];
		Format(authHeader, sizeof(authHeader), "Bearer %s", statsSyncKey);
		request.SetHeader("Authorization", authHeader);
	}

	request.Post(json, StatsSyncCallback);
}

public void StatsSyncCallback(HTTPResponse response, any value, const char[] error)
{
	if (response.Status != HTTPStatus_OK)
	{
		LogMessage("[StatsSync] Sync failed (HTTP %d): %s", view_as<int>(response.Status), error);
	}
}

// *******************************************************************************************************************
// ************************************************** SYNC FUNCTIONS *************************************************
// *******************************************************************************************************************

// Sync player connection
public void StatsSyncPlayer(const char[] steamid, const char[] name, const char[] ip, const char[] serverIp, int lastConnected)
{
	if (statsSyncEnabled == 0) return;

	JSONObject json = new JSONObject();
	json.SetString("steamid", steamid);
	json.SetString("name", name);
	json.SetString("ip", ip);
	json.SetString("server_ip", serverIp);
	json.SetInt("last_connected", lastConnected);

	StatsSyncPost("player", json);
	delete json;
}

// Sync a stat increment (goals, assists, saves, etc.)
public void StatsSyncStat(const char[] steamid, const char[] name, const char[] stat, int points, bool isMatch)
{
	if (statsSyncEnabled == 0) return;

	JSONObject json = new JSONObject();
	json.SetString("steamid", steamid);
	json.SetString("name", name);
	json.SetString("stat", stat);
	json.SetInt("increment", 1);
	json.SetInt("points", points);
	json.SetString("context", isMatch ? "match" : "public");

	StatsSyncPost("stat", json);
	delete json;
}

// Sync match count increment
public void StatsSyncMatchCount(const char[] steamid, const char[] name)
{
	if (statsSyncEnabled == 0) return;

	JSONObject json = new JSONObject();
	json.SetString("steamid", steamid);
	json.SetString("name", name);

	StatsSyncPost("match-count", json);
	delete json;
}

// *******************************************************************************************************************
// ************************************************** FULL SYNC ******************************************************
// *******************************************************************************************************************

// Push entire local database to remote, replacing remote data
public void StatsSyncFullSync(int client)
{
	if (statsSyncEnabled == 0 || !statsSyncRipextAvailable || statsSyncUrl[0] == '\0') return;

	// Query all players with their stats
	char query[1024];
	Format(query, sizeof(query),
		"SELECT p.steamid, p.name, p.last_connected, p.created, p.play_time, p.player_ip, p.server_ip, p.money, "
	...	"ms.goals as m_goals, ms.assists as m_assists, ms.own_goals as m_own_goals, ms.hits as m_hits, "
	...	"ms.passes as m_passes, ms.interceptions as m_interceptions, ms.ball_losses as m_ball_losses, "
	...	"ms.saves as m_saves, ms.rounds_won as m_rounds_won, ms.rounds_lost as m_rounds_lost, "
	...	"ms.points as m_points, ms.mvp as m_mvp, ms.motm as m_motm, ms.matches as m_matches, "
	...	"ps.goals as p_goals, ps.assists as p_assists, ps.own_goals as p_own_goals, ps.hits as p_hits, "
	...	"ps.passes as p_passes, ps.interceptions as p_interceptions, ps.ball_losses as p_ball_losses, "
	...	"ps.saves as p_saves, ps.rounds_won as p_rounds_won, ps.rounds_lost as p_rounds_lost, "
	...	"ps.points as p_points, ps.mvp as p_mvp, ps.motm as p_motm "
	...	"FROM soccer_mod_players p "
	...	"LEFT JOIN soccer_mod_match_stats ms ON p.steamid = ms.steamid "
	...	"LEFT JOIN soccer_mod_public_stats ps ON p.steamid = ps.steamid");

	int userid = 0;
	if (client > 0)
		userid = GetClientUserId(client);

	SQL_TQuery(db, StatsSyncFullSyncCallback, query, userid);
}

public void StatsSyncFullSyncCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = (userid > 0) ? GetClientOfUserId(userid) : 0;

	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[StatsSync] Full sync query failed: %s", error);
		if (client > 0 && IsClientInGame(client))
			CPrintToChat(client, "{%s}[%s] {%s}Full sync failed: database error.", prefixcolor, prefix, textcolor);
		return;
	}

	JSONObject payload = new JSONObject();
	JSONArray players = new JSONArray();
	int count = 0;

	while (SQL_FetchRow(hndl))
	{
		JSONObject player = new JSONObject();

		char steamid[32], name[MAX_NAME_LENGTH], ip[32], serverIp[32];
		SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		SQL_FetchString(hndl, 5, ip, sizeof(ip));
		SQL_FetchString(hndl, 6, serverIp, sizeof(serverIp));

		player.SetString("steamid", steamid);
		player.SetString("name", name);
		player.SetInt("last_connected", SQL_FetchInt(hndl, 2));
		player.SetInt("created", SQL_FetchInt(hndl, 3));
		player.SetInt("play_time", SQL_FetchInt(hndl, 4));
		player.SetString("ip", ip);
		player.SetString("server_ip", serverIp);
		player.SetInt("money", SQL_FetchInt(hndl, 7));

		// Match stats
		JSONObject matchStats = new JSONObject();
		matchStats.SetInt("goals", SQL_FetchInt(hndl, 8));
		matchStats.SetInt("assists", SQL_FetchInt(hndl, 9));
		matchStats.SetInt("own_goals", SQL_FetchInt(hndl, 10));
		matchStats.SetInt("hits", SQL_FetchInt(hndl, 11));
		matchStats.SetInt("passes", SQL_FetchInt(hndl, 12));
		matchStats.SetInt("interceptions", SQL_FetchInt(hndl, 13));
		matchStats.SetInt("ball_losses", SQL_FetchInt(hndl, 14));
		matchStats.SetInt("saves", SQL_FetchInt(hndl, 15));
		matchStats.SetInt("rounds_won", SQL_FetchInt(hndl, 16));
		matchStats.SetInt("rounds_lost", SQL_FetchInt(hndl, 17));
		matchStats.SetInt("points", SQL_FetchInt(hndl, 18));
		matchStats.SetInt("mvp", SQL_FetchInt(hndl, 19));
		matchStats.SetInt("motm", SQL_FetchInt(hndl, 20));
		matchStats.SetInt("matches", SQL_FetchInt(hndl, 21));
		player.Set("match_stats", matchStats);
		delete matchStats;

		// Public stats
		JSONObject publicStats = new JSONObject();
		publicStats.SetInt("goals", SQL_FetchInt(hndl, 22));
		publicStats.SetInt("assists", SQL_FetchInt(hndl, 23));
		publicStats.SetInt("own_goals", SQL_FetchInt(hndl, 24));
		publicStats.SetInt("hits", SQL_FetchInt(hndl, 25));
		publicStats.SetInt("passes", SQL_FetchInt(hndl, 26));
		publicStats.SetInt("interceptions", SQL_FetchInt(hndl, 27));
		publicStats.SetInt("ball_losses", SQL_FetchInt(hndl, 28));
		publicStats.SetInt("saves", SQL_FetchInt(hndl, 29));
		publicStats.SetInt("rounds_won", SQL_FetchInt(hndl, 30));
		publicStats.SetInt("rounds_lost", SQL_FetchInt(hndl, 31));
		publicStats.SetInt("points", SQL_FetchInt(hndl, 32));
		publicStats.SetInt("mvp", SQL_FetchInt(hndl, 33));
		publicStats.SetInt("motm", SQL_FetchInt(hndl, 34));
		player.Set("public_stats", publicStats);
		delete publicStats;

		players.Push(player);
		delete player;
		count++;
	}

	payload.Set("players", players);
	delete players;

	StatsSyncPost("full", payload);
	delete payload;

	LogMessage("[StatsSync] Full sync sent %d players", count);
	if (client > 0 && IsClientInGame(client))
		CPrintToChat(client, "{%s}[%s] {%s}Full sync sent %d players to remote.", prefixcolor, prefix, textcolor, count);
}

// Sync all round stats for a player in one call
public void StatsSyncRoundStats(const char[] steamid, bool isMatch, int goals, int assists, int own_goals, int hits, int passes, int interceptions, int ball_losses, int saves, int rounds_won, int rounds_lost, int points)
{
	if (statsSyncEnabled == 0) return;

	JSONObject json = new JSONObject();
	json.SetString("steamid", steamid);
	json.SetString("context", isMatch ? "match" : "public");
	json.SetInt("goals", goals);
	json.SetInt("assists", assists);
	json.SetInt("own_goals", own_goals);
	json.SetInt("hits", hits);
	json.SetInt("passes", passes);
	json.SetInt("interceptions", interceptions);
	json.SetInt("ball_losses", ball_losses);
	json.SetInt("saves", saves);
	json.SetInt("rounds_won", rounds_won);
	json.SetInt("rounds_lost", rounds_lost);
	json.SetInt("points", points);

	StatsSyncPost("round-stats", json);
	delete json;
}

// Sync MVP or MOTM award
public void StatsSyncAward(const char[] steamid, const char[] name, const char[] award, int points, bool isMatch)
{
	if (statsSyncEnabled == 0) return;

	JSONObject json = new JSONObject();
	json.SetString("steamid", steamid);
	json.SetString("name", name);
	json.SetString("award", award);
	json.SetInt("points", points);
	json.SetString("context", isMatch ? "match" : "public");

	StatsSyncPost("award", json);
	delete json;
}
