---
title: Home
layout: home
nav_order: 1
---

# Soccer Mod Documentation

A comprehensive SourceMod plugin for Counter-Strike: Source soccer servers.
{: .fs-6 .fw-300 }

[Get Started]({% link installation.md %}){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/Quixomatic/soccer-mod){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Features

- **Match System** - Configurable periods, halftime breaks, overtime, golden goal, ready checks
- **Captain System** - Automated captain selection with voting, knife fights, snake draft picking
- **Training Tools** - Ball cannons, goal targets, cones, spawnable props
- **Referee System** - Yellow/red cards, score management
- **Sprint System** - Customizable speed boost with cooldown and indicators
- **Skins** - Team skins with goalkeeper variants, changeable in-game
- **Stats & Ranking** - Goals, assists, saves, passes tracking with database support
- **WhoIS System** - Player tracking across sessions with alias support
- **Join/Leave Notifications** - Configurable alerts when players connect/disconnect
- **Server Lock** - Automatic password protection during captain picking
- **Shouts** - Customizable sound effects players can trigger

## Quick Start

1. Install [MetaMod:Source](https://www.sourcemm.net/) and [SourceMod](https://www.sourcemod.net/)
2. Download the latest [Soccer Mod release](https://github.com/Quixomatic/soccer-mod/releases)
3. Extract to your CS:S server's `cstrike/` directory
4. Restart the server - config files are generated automatically

See the [Installation Guide]({% link installation.md %}) for detailed instructions.

## Requirements

- Counter-Strike: Source Dedicated Server
- MetaMod:Source 1.12+
- SourceMod 1.12+
- MariaDB/MySQL (optional, for stats persistence)

## Current Version

**{{ site.time | date: '%Y' }}** - See the [Changelog]({% link changelog.md %}) for the latest updates.
