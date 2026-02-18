---
layout: default
title: Admins
parent: Configuration
nav_order: 10
---

# soccer_mod_admins.cfg

Soccer Mod's own admin management system, separate from SourceMod's built-in admin system.
{: .fs-6 .fw-300 }

{: .tip }
Admins are managed in-game via `!madmin` > Settings > Manage Admins (requires RCON flag).

---

## Purpose

Soccer Mod has its own admin system that works alongside SourceMod's native admin system. This allows you to grant Soccer Mod-specific permissions without giving full SourceMod admin access.

---

## Managing Admins

### In-Game (Recommended)

Admin > Settings > Manage Admins:
- Add new admins by selecting connected players
- Assign admin groups/permissions
- Remove admins
- View current admin list

### Manual

Edit `soccer_mod_admins.cfg` directly. The plugin also modifies SourceMod's `configs/admins.cfg` when adding admins (backs up to `configs/admins.cfg.presoccermod` before changes).

---

## Admin Permission Levels

| Level | Description |
|-------|-------------|
| Generic flag | Access to Settings menu (skins, chat, sounds, etc.) |
| RCON flag | Full access including Manage Admins and Debugging |

---

## Notes

- The plugin backs up `configs/admins.cfg` before modifying it
- Soccer Mod admins are immune from vote targeting (votekick, voteban, etc.)
- Public mode settings can grant menu access to non-admins
