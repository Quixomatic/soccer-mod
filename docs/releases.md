---
layout: default
title: Releases
nav_order: 9
---

# Releases

Download the latest version of Soccer Mod.
{: .fs-6 .fw-300 }

---

## Latest Release

[Download Latest Release](https://github.com/Quixomatic/soccer-mod/releases/latest){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View All Releases](https://github.com/Quixomatic/soccer-mod/releases){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Installation

1. Download the latest `.zip` from the releases page
2. Extract to your CS:S server's `cstrike/` directory
3. Restart the server

See the [Installation Guide]({% link installation.md %}) for detailed instructions.

---

## What's Included

Each release contains:

```
soccer_mod.zip
├── addons/
│   └── sourcemod/
│       └── plugins/
│           └── soccer_mod.smx    # Compiled plugin
├── cfg/
│   └── sm_soccermod/             # Example configs
├── materials/                     # Textures
├── models/                        # Models
└── sound/                         # Sounds
```

---

## Automatic Updates

Soccer Mod includes a built-in [self-updater]({% link self-updater.md %}) that can download new versions directly from the server. Requires the optional **sm-ripext** extension.

---

## Version History

See the [Changelog]({% link changelog.md %}) for detailed version history.

### Recent Versions

| Version | Highlights |
|---------|------------|
| v1.5.11 | Cache warming menu option, automatic retry on failed downloads |
| v1.5.8 | Remote .smx size check diagnostic tool |
| v1.5.6 | File size verification for self-updater downloads |
| v1.5.3 | Built-in self-updater (replaces GoD-Tony updater) |
| v1.5.0 | Player Vote System (votekick, voteban, votemute, votemap) |
| v1.4.25 | Score in hostname status |
| v1.4.24 | Configurable cap vote duration and prematch countdown |
| v1.4.23 | Pick Pool System and picking HUD |
| v1.4.22 | Reorganized admin settings menu |
| v1.4.16 | Configurable kickoff walls system |
| v1.4.11 | Configurable team size (2v2 to 6v6) |
| v1.4.9 | Join/leave notifications |
| v1.4.8 | WhoIS player tracking |
| v1.4.6 | Ready check system, timeout support |
| v1.4.5 | Auto cap system with voting |

---

## Upgrading

To upgrade an existing installation:

1. **Backup your configs** in `cfg/sm_soccermod/`
2. Download and extract the new release
3. Your configs will be preserved (the plugin doesn't overwrite existing configs)
4. Restart the server or reload the plugin: `sm plugins reload soccer_mod`

{: .note }
If you have the [self-updater]({% link self-updater.md %}) set up, you can update directly from the admin menu without downloading manually.

{: .warning }
Always backup your configuration files before upgrading. While configs are preserved, it's good practice to have a backup.
