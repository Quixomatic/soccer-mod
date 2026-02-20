---
layout: default
title: Discord Webhooks
nav_order: 8
---

# Discord Webhooks
{: .no_toc }

Post match events and custom messages to a Discord channel automatically. Uses the same ripext extension as the [Self-Updater]({% link self-updater.md %}).
{: .fs-6 .fw-300 }

---

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Requirements

- **[sm-ripext](https://github.com/ErikMinekus/sm-ripext)** extension installed (see [Self-Updater Setup]({% link self-updater.md %}))
- A **Discord webhook URL** from your Discord server

If ripext is not installed, the Discord menu will show an error message. All other Soccer Mod features remain unaffected.

---

## Step 1: Create a Discord Webhook

1. Open your Discord server and go to the channel where you want match updates
2. Click the gear icon (Edit Channel) > **Integrations** > **Webhooks**
3. Click **New Webhook**
4. Give it a name (e.g., "Soccer Mod") and optionally set an avatar
5. Click **Copy Webhook URL**

The URL will look like:
```
https://discord.com/api/webhooks/1234567890/abcdefg...
```

---

## Step 2: Set the Webhook URL

**Option A: In-game menu**

1. Open `!madmin` > **Settings** > **Discord Webhooks**
2. Click **Set Webhook URL**
3. Paste the URL in chat

**Option B: Edit config directly**

Add or edit the `"Discord Settings"` section in `cfg/sm_soccermod/soccer_mod.cfg`:

```
"Discord Settings"
{
    "soccer_mod_discord_webhook"        "https://discord.com/api/webhooks/your/url"
    "soccer_mod_discord_match_start"    "0"
    "soccer_mod_discord_match_end"      "0"
    "soccer_mod_discord_goal"           "0"
    "soccer_mod_discord_halftime"       "0"
    "soccer_mod_discord_cap"            "0"
}
```

{: .warning }
The webhook URL contains a secret token. It is shown truncated in the admin menu and never printed in full to chat.

---

## Step 3: Enable Events

Toggle individual events ON/OFF from the **Discord Webhooks** menu, or set them to `1` in the config file.

| Event | Config Key | Description |
|-------|-----------|-------------|
| Match Start | `soccer_mod_discord_match_start` | Team rosters, map, match format |
| Match End | `soccer_mod_discord_match_end` | Final score, top 3 players with points |
| Goal Scored | `soccer_mod_discord_goal` | Scorer, assister, current score, period & time |
| Halftime | `soccer_mod_discord_halftime` | Score at the break |
| Cap Result | `soccer_mod_discord_cap` | Knife fight winner/loser, weapon used |

All events default to **OFF**.

---

## Step 4: Test

Use the **Test Notifications** submenu to send sample embeds with fake data. This verifies your webhook URL is working without needing to start a real match.

---

## Embed Examples

### Match Start

Shows both team lineups side by side with match details.

| Field | Content |
|-------|---------|
| **CT** (inline) | Player roster |
| **T** (inline) | Player roster |
| **Match Info** | Map, team size, period format |

Color: Blue

### Match End

| Field | Content |
|-------|---------|
| **Final Score** | Team names and score |
| **Top Players** | Medal emoji leaderboard with points |

Color: Red

### Goal Scored

| Field | Content |
|-------|---------|
| **Title** | Goal! with current score |
| **Description** | **Scorer** (Assist: *Assister*) |
| **Period** | Current period |
| **Time** | Match clock |

Color: Blue (CT goal) or Red (T goal)

### Halftime

Score at the end of the period.

Color: Yellow

### Cap Result

Winner, loser, and weapon used.

Color: Purple

---

## Chat Command

Admins can send a quick message to Discord without opening the menu:

```
!discord need 1 more for pug
!discord server restarting in 10 min
```

This posts an embed with the admin's in-game name as the author.

{: .note }
The `!discord` command is **admin-only**. Non-admin players will see an error message.

---

## Custom Messages via Menu

1. Open `!madmin` > **Settings** > **Discord Webhooks**
2. Click **Send Message to Discord**
3. Type your message in chat

The message is posted as an embed with your in-game name.

---

## Troubleshooting

### "Discord webhook not configured"

Set a webhook URL first via the menu or config file.

### "ripext extension not loaded"

Follow the [Self-Updater Setup]({% link self-updater.md %}) guide to install ripext.

### Messages not appearing in Discord

- Verify the webhook URL is correct (test it with the Test Notifications menu)
- Check that the webhook hasn't been deleted in Discord
- Check `addons/sourcemod/logs/` for HTTP error messages
- Ensure `ca-bundle.crt` is installed (required for HTTPS)

### Webhook URL too long for chat

CSS chat has a 128-byte limit. Most webhook URLs fit (~95-100 chars), but if yours gets truncated, edit `soccer_mod.cfg` directly instead.
