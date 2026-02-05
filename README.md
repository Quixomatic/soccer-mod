# Soccer Mod

A SourceMod plugin for Counter-Strike: Source soccer servers.

## Features

- Match system with periods, halftime, overtime, and golden goal
- Team captain picking system
- Sprint ability with customizable settings
- Player statistics and ranking
- Referee tools (yellow/red cards, score management)
- Training mode with ball cannon
- Goalkeeper areas and skins
- Dead chat (cross-team communication)
- AFK kicker
- And much more...

## Documentation

- [Installation Guide](documentation/installation-guide.md) - Complete setup and configuration
- [Legacy Documentation](https://somoe-19.readthedocs.io/en/latest/) - Additional reference (from SoMoE-19)

## Installation

1. Download the latest release from the [Releases](../../releases) page
2. Extract the contents to your CS:S server directory
3. Configure the plugin settings in `cfg/sm_soccermod/`

## Requirements

- SourceMod 1.12+
- MetaMod: Source

## Building from Source

```bash
npm install   # No dependencies, but sets up the project
npm run build # Compile and deploy to plugins folder
```

## Commands

| Command | Description |
|---------|-------------|
| `!soccer` | Open the main menu |
| `!settings` | Open settings menu |
| `!start` | Start a match |
| `!stop` | Stop a match |
| `!cap` | Open captain menu |
| `!rank` | View rankings |
| `!training` | Open training menu |

## Credits

Based on work by:
- Marco Boogers - [Original SoccerMod](https://github.com/marcoboogers/soccermod)
- Frenzzy - [Allchat/DeadChat](https://forums.alliedmods.net/showthread.php?t=171734)
- walmar - [ShortSprint](https://forums.alliedmods.net/showthread.php?p=2294299)
- shavit - [AFK Kicker](https://forums.alliedmods.net/showthread.php?p=2409504)

## License

GPL-3.0
