// **************************************************************************************************************
// ********************************************** KICKOFF WALLS v2 **********************************************
// **************************************************************************************************************
// Configurable per-map kickoff wall system with admin calibration menu

// ============================================ MODULE GLOBALS ==================================================
// Note: kickoffWallsConfigFile and kw_* variables are defined in globals.sp

KeyValues kvKickoffWalls;
int kw_calibrateMode[MAXPLAYERS+1];     // Calibration mode per client (0=none, 1=radius, 2=center)

// Standard ball entity names to try
char kw_standardBallNames[][] = {"ball", "ballon", "soccer_ball", "football", "soccerball"};

// ============================================ CONFIG FUNCTIONS ================================================

public void CreateKickoffWallsConfig()
{
    File hFile = OpenFile(kickoffWallsConfigFile, "w");
    hFile.Close();

    kvKickoffWalls = new KeyValues("kickoff_walls");
    kvKickoffWalls.ImportFromFile(kickoffWallsConfigFile);

    // Add example entry for common map
    kvKickoffWalls.JumpToKey("ka_soccer_xsl_stadium_b1", true);
    kvKickoffWalls.SetFloat("center_x", 0.0);
    kvKickoffWalls.SetFloat("center_y", 0.0);
    kvKickoffWalls.SetFloat("center_z", 64.0);
    kvKickoffWalls.SetString("orientation", "x");
    kvKickoffWalls.SetFloat("circle_radius", 252.5);
    kvKickoffWalls.SetString("ball_entity", "");
    kvKickoffWalls.SetNum("enabled", 1);
    kvKickoffWalls.GoBack();

    kvKickoffWalls.Rewind();
    kvKickoffWalls.ExportToFile(kickoffWallsConfigFile);
    kvKickoffWalls.Close();
}

public void LoadKickoffWallsConfig()
{
    if (!FileExists(kickoffWallsConfigFile))
    {
        CreateKickoffWallsConfig();
    }

    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));

    kvKickoffWalls = new KeyValues("kickoff_walls");
    kvKickoffWalls.ImportFromFile(kickoffWallsConfigFile);

    // Check if this map has saved settings
    if (kvKickoffWalls.JumpToKey(mapName, false))
    {
        kw_center[0] = kvKickoffWalls.GetFloat("center_x", 0.0);
        kw_center[1] = kvKickoffWalls.GetFloat("center_y", 0.0);
        kw_center[2] = kvKickoffWalls.GetFloat("center_z", 64.0);

        char orient[8];
        kvKickoffWalls.GetString("orientation", orient, sizeof(orient), "x");
        kw_xorientation = StrEqual(orient, "x", false);

        kw_radius = kvKickoffWalls.GetFloat("circle_radius", 252.5);

        kvKickoffWalls.GetString("ball_entity", kw_ball_entity, sizeof(kw_ball_entity), "");

        kw_enabled = (kvKickoffWalls.GetNum("enabled", 1) == 1);

        kw_configLoaded = true;

        if (debuggingEnabled)
        {
            PrintToServer("[Soccer Mod] Kickoff walls config loaded for %s", mapName);
            PrintToServer("  Center: %.1f, %.1f, %.1f", kw_center[0], kw_center[1], kw_center[2]);
            PrintToServer("  Radius: %.1f, Orientation: %s", kw_radius, kw_xorientation ? "X" : "Y");
        }
    }
    else
    {
        kw_configLoaded = false;
        if (debuggingEnabled)
        {
            PrintToServer("[Soccer Mod] No kickoff walls config for %s, using auto-detection", mapName);
        }
    }

    kvKickoffWalls.Rewind();
    kvKickoffWalls.Close();
}

public void SaveKickoffWallsConfig()
{
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));

    if (!FileExists(kickoffWallsConfigFile))
    {
        CreateKickoffWallsConfig();
    }

    kvKickoffWalls = new KeyValues("kickoff_walls");
    kvKickoffWalls.ImportFromFile(kickoffWallsConfigFile);

    kvKickoffWalls.JumpToKey(mapName, true);
    kvKickoffWalls.SetFloat("center_x", kw_center[0]);
    kvKickoffWalls.SetFloat("center_y", kw_center[1]);
    kvKickoffWalls.SetFloat("center_z", kw_center[2]);
    kvKickoffWalls.SetString("orientation", kw_xorientation ? "x" : "y");
    kvKickoffWalls.SetFloat("circle_radius", kw_radius);
    kvKickoffWalls.SetString("ball_entity", kw_ball_entity);
    kvKickoffWalls.SetNum("enabled", kw_enabled ? 1 : 0);
    kvKickoffWalls.GoBack();

    kvKickoffWalls.Rewind();
    kvKickoffWalls.ExportToFile(kickoffWallsConfigFile);
    kvKickoffWalls.Close();

    kw_configLoaded = true;

    if (debuggingEnabled)
    {
        PrintToServer("[Soccer Mod] Kickoff walls config saved for %s", mapName);
    }
}

// ============================================ BALL DETECTION ==================================================

public int KickoffWalls_FindBallEntity()
{
    int ballEntity = -1;

    // 1. Check config for custom entity name
    if (strlen(kw_ball_entity) > 0)
    {
        ballEntity = GetEntityIndexByName(kw_ball_entity, "func_physbox");
        if (ballEntity == -1)
            ballEntity = GetEntityIndexByName(kw_ball_entity, "prop_physics");

        if (ballEntity != -1)
        {
            if (debuggingEnabled)
                PrintToServer("[Soccer Mod] Ball found via config entity name: %s", kw_ball_entity);
            return ballEntity;
        }
    }

    // 2. Try standard names
    for (int i = 0; i < sizeof(kw_standardBallNames); i++)
    {
        ballEntity = GetEntityIndexByName(kw_standardBallNames[i], "func_physbox");
        if (ballEntity == -1)
            ballEntity = GetEntityIndexByName(kw_standardBallNames[i], "prop_physics");

        if (ballEntity != -1)
        {
            if (debuggingEnabled)
                PrintToServer("[Soccer Mod] Ball found via standard name: %s", kw_standardBallNames[i]);
            return ballEntity;
        }
    }

    // 3. Search all physics entities for ball-like models
    int ent = -1;
    char model[128];
    char entName[64];

    while ((ent = FindEntityByClassname(ent, "func_physbox")) != -1)
    {
        GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
        if (StrContains(model, "ball", false) != -1)
        {
            GetEntPropString(ent, Prop_Data, "m_iName", entName, sizeof(entName));
            if (debuggingEnabled)
                PrintToServer("[Soccer Mod] Ball found via model search: %s (func_physbox)", entName);
            return ent;
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "prop_physics")) != -1)
    {
        GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
        if (StrContains(model, "ball", false) != -1)
        {
            GetEntPropString(ent, Prop_Data, "m_iName", entName, sizeof(entName));
            if (debuggingEnabled)
                PrintToServer("[Soccer Mod] Ball found via model search: %s (prop_physics)", entName);
            return ent;
        }
    }

    return -1;
}

// ============================================ AUTO-DETECTION ==================================================

public void KickoffWalls_AutoDetect()
{
    // Find ball entity
    int ballEntity = KickoffWalls_FindBallEntity();
    if (ballEntity != -1)
    {
        GetEntPropVector(ballEntity, Prop_Send, "m_vecOrigin", kw_center);

        // Also update the legacy variable for compatibility
        mapBallStartPosition[0] = kw_center[0];
        mapBallStartPosition[1] = kw_center[1];
        mapBallStartPosition[2] = kw_center[2];
    }
    else
    {
        LogError("[Soccer Mod] Could not find ball entity for kickoff walls!");
        kw_center[0] = 0.0;
        kw_center[1] = 0.0;
        kw_center[2] = 64.0;
    }

    // Find goal triggers and determine orientation
    int t_trigger = GetEntityIndexByName("terro_But", "trigger_once");
    if (t_trigger == -1) t_trigger = GetEntityIndexByName("goal_t", "trigger_once");
    if (t_trigger == -1) t_trigger = GetEntityIndexByName("Terro_but", "trigger_multiple");

    int ct_trigger = GetEntityIndexByName("ct_But", "trigger_once");
    if (ct_trigger == -1) ct_trigger = GetEntityIndexByName("goal_ct", "trigger_once");
    if (ct_trigger == -1) ct_trigger = GetEntityIndexByName("ct_but", "trigger_multiple");

    if (t_trigger != -1 && ct_trigger != -1)
    {
        GetEntPropVector(t_trigger, Prop_Data, "m_vecAbsOrigin", kw_t_goal);
        GetEntPropVector(ct_trigger, Prop_Data, "m_vecAbsOrigin", kw_ct_goal);

        // Also update legacy variables
        vec_tgoal_origin[0] = kw_t_goal[0];
        vec_tgoal_origin[1] = kw_t_goal[1];
        vec_tgoal_origin[2] = kw_t_goal[2];
        vec_ctgoal_origin[0] = kw_ct_goal[0];
        vec_ctgoal_origin[1] = kw_ct_goal[1];
        vec_ctgoal_origin[2] = kw_ct_goal[2];

        // Determine orientation
        float xDiff = FloatAbs(kw_t_goal[0] - kw_ct_goal[0]);
        float yDiff = FloatAbs(kw_t_goal[1] - kw_ct_goal[1]);

        kw_xorientation = (xDiff < yDiff);
        xorientation = kw_xorientation;  // Update legacy variable

        PrintToServer("[Soccer Mod] Kickoff walls auto-detect: Orientation=%s (xDiff=%.1f, yDiff=%.1f)",
            kw_xorientation ? "X" : "Y", xDiff, yDiff);
    }
    else
    {
        LogError("[Soccer Mod] Could not find goal triggers for orientation detection!");
    }

    PrintToServer("[Soccer Mod] Kickoff walls auto-detect: Center=%.1f,%.1f,%.1f Radius=%.1f",
        kw_center[0], kw_center[1], kw_center[2], kw_radius);
}

// ============================================ MAP START HOOK ==================================================

public void KickoffWalls_OnMapStart()
{
    // Load config first (may have saved values)
    LoadKickoffWallsConfig();

    // Run auto-detection
    KickoffWalls_AutoDetect();

    // If config was loaded, override auto-detected values with saved ones
    if (kw_configLoaded)
    {
        LoadKickoffWallsConfig();  // Reload to get saved values

        // Update legacy variables for compatibility with existing wall code
        mapBallStartPosition[0] = kw_center[0];
        mapBallStartPosition[1] = kw_center[1];
        mapBallStartPosition[2] = kw_center[2];
        xorientation = kw_xorientation;
    }
}

// ============================================ ADMIN MENU ======================================================

bool kw_vizEnabled = false;  // Visualization toggle

public void OpenMenuKickoffWalls(int client)
{
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));

    Menu menu = new Menu(MenuHandlerKickoffWalls);
    menu.SetTitle("Kickoff Walls Settings\nMap: %s\n ", mapName);

    char buffer[128];

    // View current settings
    Format(buffer, sizeof(buffer), "View Current Settings");
    menu.AddItem("view", buffer);

    // Toggle visualization
    Format(buffer, sizeof(buffer), "Show Wireframe: %s", kw_vizEnabled ? "ON" : "OFF");
    menu.AddItem("viz", buffer);

    // Auto-detect
    menu.AddItem("detect", "Auto-Detect All");

    // Set radius
    Format(buffer, sizeof(buffer), "Set Center Circle Radius (%.1f)", kw_radius);
    menu.AddItem("radius", buffer);

    // Toggle orientation
    Format(buffer, sizeof(buffer), "Toggle Orientation (Currently: %s)", kw_xorientation ? "X" : "Y");
    menu.AddItem("orient", buffer);

    // Calibrate center
    menu.AddItem("center", "Calibrate Ball Position");

    // Select ball entity
    menu.AddItem("ball", "Select Ball Entity");

    // Test walls
    menu.AddItem("test", "Test Walls (10 seconds)");

    // Save
    Format(buffer, sizeof(buffer), "Save to Config%s", kw_configLoaded ? " [Saved]" : "");
    menu.AddItem("save", buffer);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerKickoffWalls(Menu menu, MenuAction action, int client, int choice)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(choice, info, sizeof(info));

        if (StrEqual(info, "view"))
        {
            KickoffWalls_ShowInfo(client);
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "viz"))
        {
            kw_vizEnabled = !kw_vizEnabled;
            if (kw_vizEnabled)
            {
                KickoffWalls_DrawVisualization();
                CPrintToChat(client, "{%s}[%s] {green}Wireframe visualization ON", prefixcolor, prefix);
                CPrintToChat(client, "{%s}  White cross = center | Green circle = radius", textcolor);
                CPrintToChat(client, "{%s}  Yellow line = midfield | Red = T goal | Blue = CT goal", textcolor);
            }
            else
            {
                KickoffWalls_ClearVisualization();
                CPrintToChat(client, "{%s}[%s] {%s}Wireframe visualization OFF", prefixcolor, prefix, textcolor);
            }
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "detect"))
        {
            KickoffWalls_AutoDetect();
            CPrintToChat(client, "{%s}[%s] {%s}Auto-detection complete. Use 'View' to see results.", prefixcolor, prefix, textcolor);
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "radius"))
        {
            kw_calibrateMode[client] = 1;
            CPrintToChat(client, "{%s}[%s] {green}Walk to the edge of the center circle and type {lightgreen}!setradius", prefixcolor, prefix);
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "orient"))
        {
            kw_xorientation = !kw_xorientation;
            xorientation = kw_xorientation;
            CPrintToChat(client, "{%s}[%s] {%s}Orientation set to: {green}%s", prefixcolor, prefix, textcolor, kw_xorientation ? "X" : "Y");
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "center"))
        {
            kw_calibrateMode[client] = 2;
            CPrintToChat(client, "{%s}[%s] {green}Stand at the ball spawn point and type {lightgreen}!setcenter", prefixcolor, prefix);
            OpenMenuKickoffWalls(client);
        }
        else if (StrEqual(info, "ball"))
        {
            OpenMenuSelectBallEntity(client);
        }
        else if (StrEqual(info, "test"))
        {
            KickoffWalls_TestWalls(client);
        }
        else if (StrEqual(info, "save"))
        {
            SaveKickoffWallsConfig();
            CPrintToChat(client, "{%s}[%s] {green}Kickoff walls config saved!", prefixcolor, prefix);
            OpenMenuKickoffWalls(client);
        }
    }
    else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
    {
        OpenMenuMiscSettings(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

public void KickoffWalls_ShowInfo(int client)
{
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));

    CPrintToChat(client, "{%s}[%s] {green}=== Kickoff Walls Info ===", prefixcolor, prefix);
    CPrintToChat(client, "{%s}Map: {green}%s", textcolor, mapName);
    CPrintToChat(client, "{%s}Center: {green}%.1f, %.1f, %.1f", textcolor, kw_center[0], kw_center[1], kw_center[2]);
    CPrintToChat(client, "{%s}Radius: {green}%.1f", textcolor, kw_radius);
    CPrintToChat(client, "{%s}Orientation: {green}%s", textcolor, kw_xorientation ? "X (field along Y)" : "Y (field along X)");
    CPrintToChat(client, "{%s}Ball Entity: {green}%s", textcolor, strlen(kw_ball_entity) > 0 ? kw_ball_entity : "(auto-detect)");
    CPrintToChat(client, "{%s}Config Loaded: {green}%s", textcolor, kw_configLoaded ? "Yes" : "No (using auto-detect)");
}

// ============================================ BALL ENTITY SELECTION ===========================================

public void OpenMenuSelectBallEntity(int client)
{
    Menu menu = new Menu(MenuHandlerSelectBallEntity);
    menu.SetTitle("Select Ball Entity\n ");

    // Find all physics entities
    int ent = -1;
    char entName[64];
    char model[128];
    char display[256];
    char info[64];
    int count = 0;

    // Search func_physbox
    while ((ent = FindEntityByClassname(ent, "func_physbox")) != -1)
    {
        GetEntPropString(ent, Prop_Data, "m_iName", entName, sizeof(entName));
        GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));

        if (strlen(entName) > 0)
        {
            Format(display, sizeof(display), "%s (func_physbox)", entName);
            Format(info, sizeof(info), "physbox:%s", entName);
            menu.AddItem(info, display);
            count++;
        }
    }

    // Search prop_physics
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "prop_physics")) != -1)
    {
        GetEntPropString(ent, Prop_Data, "m_iName", entName, sizeof(entName));
        GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));

        if (strlen(entName) > 0)
        {
            Format(display, sizeof(display), "%s (prop_physics)", entName);
            Format(info, sizeof(info), "physics:%s", entName);
            menu.AddItem(info, display);
            count++;
        }
    }

    if (count == 0)
    {
        menu.AddItem("", "No physics entities found", ITEMDRAW_DISABLED);
    }

    // Option to clear/use auto-detect
    menu.AddItem("auto", "Use Auto-Detection");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerSelectBallEntity(Menu menu, MenuAction action, int client, int choice)
{
    if (action == MenuAction_Select)
    {
        char info[64];
        menu.GetItem(choice, info, sizeof(info));

        if (StrEqual(info, "auto"))
        {
            kw_ball_entity[0] = '\0';
            CPrintToChat(client, "{%s}[%s] {%s}Ball entity set to auto-detection", prefixcolor, prefix, textcolor);
        }
        else if (strlen(info) > 0)
        {
            // Parse "type:name" format
            char parts[2][64];
            ExplodeString(info, ":", parts, sizeof(parts), sizeof(parts[]));
            strcopy(kw_ball_entity, sizeof(kw_ball_entity), parts[1]);
            CPrintToChat(client, "{%s}[%s] {%s}Ball entity set to: {green}%s", prefixcolor, prefix, textcolor, kw_ball_entity);

            // Re-detect with new entity name
            KickoffWalls_AutoDetect();
        }

        OpenMenuKickoffWalls(client);
    }
    else if (action == MenuAction_Cancel && choice == MenuCancel_ExitBack)
    {
        OpenMenuKickoffWalls(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

// ============================================ CALIBRATION COMMANDS ============================================

public Action Command_SetRadius(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    float playerPos[3];
    GetClientAbsOrigin(client, playerPos);

    // Calculate 2D distance from center (ignore Z)
    float dx = playerPos[0] - kw_center[0];
    float dy = playerPos[1] - kw_center[1];
    kw_radius = SquareRoot(dx * dx + dy * dy);

    CPrintToChat(client, "{%s}[%s] {green}Center circle radius set to: %.1f units", prefixcolor, prefix, kw_radius);
    CPrintToChat(client, "{%s}Don't forget to save the config!", textcolor);

    kw_calibrateMode[client] = 0;
    return Plugin_Handled;
}

public Action Command_SetCenter(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    GetClientAbsOrigin(client, kw_center);

    // Update legacy variable
    mapBallStartPosition[0] = kw_center[0];
    mapBallStartPosition[1] = kw_center[1];
    mapBallStartPosition[2] = kw_center[2];

    CPrintToChat(client, "{%s}[%s] {green}Ball center position set to: %.1f, %.1f, %.1f", prefixcolor, prefix, kw_center[0], kw_center[1], kw_center[2]);
    CPrintToChat(client, "{%s}Don't forget to save the config!", textcolor);

    kw_calibrateMode[client] = 0;
    return Plugin_Handled;
}

public Action Command_KickoffWallsInfo(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    KickoffWalls_ShowInfo(client);
    return Plugin_Handled;
}

// ============================================ TEST WALLS ======================================================

public void KickoffWalls_TestWalls(int client)
{
    // Temporarily force walls enabled for test
    int savedKickoffWallSet = KickoffWallSet;
    KickoffWallSet = 1;

    // Create walls using current kw_ values (which update the legacy variables)
    KickOffWall();

    // Restore setting
    KickoffWallSet = savedKickoffWallSet;

    CPrintToChat(client, "{%s}[%s] {green}Test walls spawned for 10 seconds...", prefixcolor, prefix);
    CPrintToChat(client, "{%s}Center: %.0f, %.0f, %.0f | Radius: %.0f | Orient: %s",
        textcolor, kw_center[0], kw_center[1], kw_center[2], kw_radius, kw_xorientation ? "X" : "Y");

    CreateTimer(10.0, Timer_KillTestWalls);
}

public Action Timer_KillTestWalls(Handle timer)
{
    KillWalls();
    KickoffWalls_ClearVisualization();  // Also clear viz if enabled
    return Plugin_Stop;
}

// ============================================ VISUALIZATION ===================================================

public void KickoffWalls_DrawVisualization()
{
    // Kill existing visualization beams
    int index;
    while ((index = GetEntityIndexByName("kw_viz_beam", "env_beam")) != -1)
        AcceptEntityInput(index, "Kill");

    float z = kw_center[2] + 50.0;  // Slightly above ground

    // Draw center cross (white)
    float crossSize = 50.0;
    DrawLaser("kw_viz_beam", kw_center[0] - crossSize, kw_center[1], z, kw_center[0] + crossSize, kw_center[1], z, "255 255 255");
    DrawLaser("kw_viz_beam", kw_center[0], kw_center[1] - crossSize, z, kw_center[0], kw_center[1] + crossSize, z, "255 255 255");

    // Draw vertical line at center
    DrawLaser("kw_viz_beam", kw_center[0], kw_center[1], kw_center[2], kw_center[0], kw_center[1], kw_center[2] + 150.0, "255 255 255");

    // Draw center circle (green) using line segments
    float pi = 3.14159265359;
    int segments = 24;
    float prevX, prevY;
    float currX, currY;

    for (int i = 0; i <= segments; i++)
    {
        float angle = (float(i) / float(segments)) * 2.0 * pi;
        currX = kw_center[0] + kw_radius * Cosine(angle);
        currY = kw_center[1] + kw_radius * Sine(angle);

        if (i > 0)
        {
            DrawLaser("kw_viz_beam", prevX, prevY, z, currX, currY, z, "0 255 0");
        }

        prevX = currX;
        prevY = currY;
    }

    // Draw midfield line based on orientation (yellow)
    float lineLength = 2000.0;
    if (kw_xorientation)
    {
        // Field runs along Y, so midfield line is along X
        DrawLaser("kw_viz_beam", kw_center[0] - lineLength, kw_center[1], z, kw_center[0] + lineLength, kw_center[1], z, "255 255 0");
    }
    else
    {
        // Field runs along X, so midfield line is along Y
        DrawLaser("kw_viz_beam", kw_center[0], kw_center[1] - lineLength, z, kw_center[0], kw_center[1] + lineLength, z, "255 255 0");
    }

    // Draw line to T goal (red)
    if (kw_t_goal[0] != 0.0 || kw_t_goal[1] != 0.0)
    {
        DrawLaser("kw_viz_beam", kw_center[0], kw_center[1], z, kw_t_goal[0], kw_t_goal[1], z, "255 0 0");
        // Draw X at T goal
        DrawLaser("kw_viz_beam", kw_t_goal[0] - 50.0, kw_t_goal[1] - 50.0, z, kw_t_goal[0] + 50.0, kw_t_goal[1] + 50.0, z, "255 0 0");
        DrawLaser("kw_viz_beam", kw_t_goal[0] - 50.0, kw_t_goal[1] + 50.0, z, kw_t_goal[0] + 50.0, kw_t_goal[1] - 50.0, z, "255 0 0");
    }

    // Draw line to CT goal (blue)
    if (kw_ct_goal[0] != 0.0 || kw_ct_goal[1] != 0.0)
    {
        DrawLaser("kw_viz_beam", kw_center[0], kw_center[1], z, kw_ct_goal[0], kw_ct_goal[1], z, "0 0 255");
        // Draw X at CT goal
        DrawLaser("kw_viz_beam", kw_ct_goal[0] - 50.0, kw_ct_goal[1] - 50.0, z, kw_ct_goal[0] + 50.0, kw_ct_goal[1] + 50.0, z, "0 0 255");
        DrawLaser("kw_viz_beam", kw_ct_goal[0] - 50.0, kw_ct_goal[1] + 50.0, z, kw_ct_goal[0] + 50.0, kw_ct_goal[1] - 50.0, z, "0 0 255");
    }
}

public void KickoffWalls_ClearVisualization()
{
    int index;
    while ((index = GetEntityIndexByName("kw_viz_beam", "env_beam")) != -1)
        AcceptEntityInput(index, "Kill");
}

// ============================================ PLUGIN START HOOK ===============================================

public void KickoffWalls_OnPluginStart()
{
    // Register calibration commands
    RegConsoleCmd("sm_setradius", Command_SetRadius, "Set kickoff wall radius from current position");
    RegConsoleCmd("sm_setcenter", Command_SetCenter, "Set kickoff wall center from current position");
    RegConsoleCmd("sm_kwinfo", Command_KickoffWallsInfo, "Show kickoff walls info");
    RegConsoleCmd("sm_kickoffwalls", Command_KickoffWallsMenu, "Open kickoff walls admin menu");
}

public Action Command_KickoffWallsMenu(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    // Check for admin access
    if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
    {
        CPrintToChat(client, "{%s}[%s] {%s}You don't have permission to use this command.", prefixcolor, prefix, textcolor);
        return Plugin_Handled;
    }

    OpenMenuKickoffWalls(client);
    return Plugin_Handled;
}
