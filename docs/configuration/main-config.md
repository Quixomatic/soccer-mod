---
title: Main Config
parent: Configuration
nav_order: 1
---

# soccer_mod.cfg

The main configuration file controlling most plugin settings.
{: .fs-6 .fw-300 }

{: .note }
Almost all settings can be changed in-game via `!madmin` > Settings. Manual editing is rarely necessary.

---

## Admin Settings

```
"Admin Settings"
{
    "soccer_mod_pubmode"          "1"
    "soccer_mod_passwordlock"     "1"
    "soccer_mod_passwordlock_max" "12"
    "soccer_mod_afk_time"         "100.0"
    "soccer_mod_afk_menu"         "20"
    "soccer_mod_matchlog"         "0"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_pubmode` | 0, 1, 2 | Menu access: 0=Admin only, 1=Public cap/match, 2=Full public |
| `soccer_mod_passwordlock` | 0, 1 | Auto server lock when cap starts |
| `soccer_mod_passwordlock_max` | Number | Player count before lock activates |
| `soccer_mod_afk_time` | Seconds | Time before AFK captcha appears |
| `soccer_mod_afk_menu` | Seconds | How long captcha menu is shown |
| `soccer_mod_matchlog` | 0, 1 | Enable match event logging |

---

## Chat Settings

```
"Chat Settings"
{
    "soccer_mod_prefix"               "Soccer Mod"
    "soccer_mod_textcolor"            "lightgreen"
    "soccer_mod_prefixcolor"          "green"
    "soccer_mod_mvp"                  "1"
    "soccer_mod_deadchat_mode"        "0"
    "soccer_mod_deadchat_visibility"  "0"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_prefix` | Text | Prefix for chat messages (shown as [Prefix]) |
| `soccer_mod_textcolor` | Color name | Color for message text |
| `soccer_mod_prefixcolor` | Color name | Color for prefix |
| `soccer_mod_mvp` | 0, 1 | Show MVP messages in chat |
| `soccer_mod_deadchat_mode` | 0, 1, 2 | Dead chat: 0=Off, 1=On, 2=Only if alltalk on |
| `soccer_mod_deadchat_visibility` | 0, 1, 2 | Who sees dead chat: 0=Default, 1=Team, 2=Everyone |

---

## Match Settings

```
"Match Settings"
{
    "soccer_mod_match_periods"              "2"
    "soccer_mod_match_period_length"        "900"
    "soccer_mod_match_period_break_length"  "60"
    "soccer_mod_match_golden_goal"          "1"
    "soccer_mod_match_max_players"          "6"
    "soccer_mod_teamnamect"                 "CT"
    "soccer_mod_teamnamet"                  "T"
    "soccer_mod_match_readycheck"           "1"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_match_periods` | Number | Number of periods (halves) |
| `soccer_mod_match_period_length` | Seconds | Duration of each period |
| `soccer_mod_match_period_break_length` | Seconds | Break between periods |
| `soccer_mod_match_golden_goal` | 0, 1 | Enable golden goal on draw |
| `soccer_mod_match_max_players` | 2-6 | Team size (affects autocap, picking, etc.) |
| `soccer_mod_teamnamect` | Text | CT team display name |
| `soccer_mod_teamnamet` | Text | T team display name |
| `soccer_mod_match_readycheck` | 0, 1, 2 | Ready check: 0=Off, 1=Auto unpause, 2=Manual unpause |

---

## Match Info

Controls what's shown in the match start message.

```
"Match Info"
{
    "soccer_mod_period_info"        "1"
    "soccer_mod_break_info"         "1"
    "soccer_mod_golden_info"        "1"
    "soccer_mod_forfeit_info"       "1"
    "soccer_mod_forfeitset_info"    "0"
    "soccer_mod_matchlog_info"      "0"
}
```

All values: `0` = Don't show, `1` = Show

---

## Forfeit Settings

```
"Forfeit Settings"
{
    "soccer_mod_forfeitvote"        "0"
    "soccer_mod_forfeitscore"       "8"
    "soccer_mod_forfeitpublic"      "0"
    "soccer_mod_forfeitautospec"    "0"
    "soccer_mod_forfeitcapmode"     "0"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_forfeitvote` | 0, 1 | Enable forfeit voting |
| `soccer_mod_forfeitscore` | Number | Goal difference required for vote |
| `soccer_mod_forfeitpublic` | 0, 1 | Who can start vote: 0=Admins, 1=Everyone |
| `soccer_mod_forfeitautospec` | 0, 1 | Auto-spec all players after forfeit |
| `soccer_mod_forfeitcapmode` | 0, 1 | Only allow during cap matches |

---

## Misc Settings

```
"Misc Settings"
{
    "soccer_mod_health_godmode"     "1"
    "soccer_mod_respawn_delay"      "10.0"
    "soccer_mod_blockdj_enable"     "1"
    "soccer_mod_blockdj_time"       "0.45"
    "soccer_mod_kickoffwall"        "0"
    "soccer_mod_damagesounds"       "0"
    "soccer_mod_dissolver"          "2"
    "soccer_mod_joinclass"          "0"
    "soccer_mod_hostname"           "1"
    "soccer_mod_rrchecktime"        "90.0"
    "soccer_mod_loaddefaults"       "1"
    "soccer_mod_killfeed"           "0"
    "soccer_mod_celebrate"          "0"
    "soccer_mod_first12"            "0"
    "soccer_mod_otcount"            "1"
    "soccer_mod_otfinal"            "1"
    "soccer_mod_otsound1"           "buttons/bell1.wav"
    "soccer_mod_otsound2"           "ambient/misc/brass_bell_f.wav"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_health_godmode` | 0, 1 | Prevent ball/knife damage |
| `soccer_mod_respawn_delay` | Seconds | Respawn delay after death |
| `soccer_mod_blockdj_enable` | 0, 1, 2 | Duck-jump block: 0=Off, 1=On, 2=New mode |
| `soccer_mod_blockdj_time` | Seconds | Duck cooldown after jump (new mode) |
| `soccer_mod_kickoffwall` | 0, 1 | Invisible walls at kickoff |
| `soccer_mod_damagesounds` | 0, 1 | Play sound when hit by ball |
| `soccer_mod_dissolver` | 0, 1, 2 | Ragdolls: 0=Default, 1=Remove, 2=Dissolve |
| `soccer_mod_joinclass` | 0, 1 | Show class selection on join |
| `soccer_mod_hostname` | 0, 1 | Update hostname with match status |
| `soccer_mod_rrchecktime` | Seconds | Reconnect tolerance for join list |
| `soccer_mod_loaddefaults` | 0, 1 | Load per-map defaults |
| `soccer_mod_killfeed` | 0, 1 | Show killfeed messages |
| `soccer_mod_celebrate` | 0, 1 | Give weapons after scoring |
| `soccer_mod_first12` | 0, 1 | Only first 12 players pickable |
| `soccer_mod_otcount` | 0-3 | OT countdown: 0=Off, 1=On, 2=Sound, 3=Text |
| `soccer_mod_otfinal` | 0, 1 | Play sound at OT end |
| `soccer_mod_otsound1` | Path | Countdown tick sound |
| `soccer_mod_otsound2` | Path | Final countdown sound |

---

## Sprint Settings

{: .warning }
These settings are **not** editable in-game. Edit this file directly.

```
"Sprint Settings"
{
    "soccer_mod_sprint_enable"      "1"
    "soccer_mod_sprint_speed"       "1.25"
    "soccer_mod_sprint_time"        "3.0"
    "soccer_mod_sprint_cooldown"    "7.5"
    "soccer_mod_sprint_button"      "1"
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `soccer_mod_sprint_enable` | 0, 1 | Enable sprint ability |
| `soccer_mod_sprint_speed` | Multiplier | Speed during sprint (1.25 = 25% faster) |
| `soccer_mod_sprint_time` | Seconds | Sprint duration |
| `soccer_mod_sprint_cooldown` | Seconds | Cooldown between sprints |
| `soccer_mod_sprint_button` | 0, 1 | Bind sprint to +use key |

---

## Current Skins

```
"Current Skins"
{
    "soccer_mod_skins_model_ct"     "models/player/soccer_mod/termi/2011/away/ct_urban.mdl"
    "soccer_mod_skins_model_t"      "models/player/soccer_mod/termi/2011/home/ct_urban.mdl"
    "soccer_mod_skins_model_ct_gk"  "models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl"
    "soccer_mod_skins_model_t_gk"   "models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl"
}
```

Active skin paths for each team. Changed via `!madmin` > Settings > Skin Settings.

---

## Stats Settings

{: .warning }
Point values are **not** editable in-game. Edit this file directly.

```
"Stats Settings"
{
    "soccer_mod_ranking_points_goal"          "17"
    "soccer_mod_ranking_points_assist"        "12"
    "soccer_mod_ranking_points_own_goal"      "-10"
    "soccer_mod_ranking_points_hit"           "1"
    "soccer_mod_ranking_points_pass"          "5"
    "soccer_mod_ranking_points_interception"  "3"
    "soccer_mod_ranking_points_ball_loss"     "-3"
    "soccer_mod_ranking_points_save"          "6"
    "soccer_mod_ranking_points_round_won"     "10"
    "soccer_mod_ranking_points_round_lost"    "-10"
    "soccer_mod_ranking_points_mvp"           "15"
    "soccer_mod_ranking_points_motm"          "25"
    "soccer_mod_ranking_cdtime"               "300"
    "soccer_mod_gksaves_only"                 "0"
    "soccer_mod_rankmode"                     "0"
}
```

| Setting | Description |
|---------|-------------|
| `soccer_mod_ranking_cdtime` | Cooldown for `!rank` command (seconds) |
| `soccer_mod_gksaves_only` | Only GK skin users earn saves |
| `soccer_mod_rankmode` | Ranking: 0=pts/matches, 1=pts/rounds, 2=pts |

---

## Training Settings

```
"Training Settings"
{
    "soccer_mod_training_model_ball"   "models/soccer_mod/ball_2011.mdl"
    "soccer_mod_training_advpwreq"     "0"
    "soccer_mod_training_advpw"        ""
    "soccer_mod_training_advresettime" "2.0"
}
```

| Setting | Description |
|---------|-------------|
| `soccer_mod_training_model_ball` | Model for training balls |
| `soccer_mod_training_advpwreq` | Require password for advanced training |
| `soccer_mod_training_advpw` | Advanced training password |
| `soccer_mod_training_advresettime` | Ball auto-respawn time in target training |

---

## Debug Settings

```
"Debug Settings"
{
    "soccer_mod_debug"        "0"
    "soccer_mod_scoredebug"   "0"
}
```

Only enable these if troubleshooting issues.
