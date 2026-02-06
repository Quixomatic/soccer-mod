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
├── materials/                     # Textures (if included)
├── models/                        # Models (if included)
└── sound/                         # Sounds (if included)
```

---

## Version History

See the [Changelog]({% link changelog.md %}) for detailed version history.

### Recent Versions

| Version | Highlights |
|---------|------------|
| v1.4.12 | Fixed kickoff wall orientation detection, permission updates |
| v1.4.11 | Configurable team size (2v2 to 6v6), vote menu improvements |
| v1.4.10 | Auto-retry captain votes, improved vote HUD |
| v1.4.9 | Join/leave notifications system |
| v1.4.8 | WhoIS player tracking system |
| v1.4.7 | Visual HUD for captain voting |
| v1.4.6 | Ready check system, timeout support |
| v1.4.5 | Auto cap system with voting |

---

## Upgrading

To upgrade an existing installation:

1. **Backup your configs** in `cfg/sm_soccermod/`
2. Download and extract the new release
3. Your configs will be preserved (the plugin doesn't overwrite existing configs)
4. Restart the server or reload the plugin: `sm plugins reload soccer_mod`

{: .warning }
Always backup your configuration files before upgrading. While configs are preserved, it's good practice to have a backup.
