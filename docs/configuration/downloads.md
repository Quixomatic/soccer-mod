---
title: Downloads Config
parent: Configuration
nav_order: 2
---

# soccer_mod_downloads.cfg

Controls which files clients download when joining the server.
{: .fs-6 .fw-300 }

{: .important }
This file **must be edited manually** with a text editor.

---

## How It Works

Each line specifies a directory to add to the download list. All files in that directory (and subdirectories) will be downloaded by connecting clients.

```
soccer_mod_downloads_add_dir <path>
```

---

## Basic Example

```
// Skins - add the folders containing your player models
soccer_mod_downloads_add_dir materials\models\player\soccer_mod
soccer_mod_downloads_add_dir models\player\soccer_mod

// Training ball model
soccer_mod_downloads_add_dir materials\models\soccer_mod
soccer_mod_downloads_add_dir models\soccer_mod
```

---

## Optimized Example

Adding entire folders can make players download unnecessary files. Be specific:

```
// Only the Termi skin set
soccer_mod_downloads_add_dir materials\models\player\soccer_mod\termi
soccer_mod_downloads_add_dir models\player\soccer_mod\termi

// Training ball
soccer_mod_downloads_add_dir materials\models\soccer_mod
soccer_mod_downloads_add_dir models\soccer_mod

// Specific additional skin
soccer_mod_downloads_add_dir materials\models\player\psl
soccer_mod_downloads_add_dir models\player\psl

// Custom sounds for shouts
soccer_mod_downloads_add_dir sound\soccer_mod\shouts

// Join/leave notification sounds
soccer_mod_downloads_add_dir sound\soccer_mod\joinleave
```

---

## Tips

{: .tip }
The more specific your paths, the faster players connect. Don't add entire `models\player` folders if you only use one skin set.

### Path Format
- Use backslashes (`\`) for paths
- Paths are relative to `cstrike/`
- Comments start with `//`

### What to Include
- **Player skins** - models and materials
- **Training ball** - if using custom model
- **Shout sounds** - custom sound effects
- **Join/leave sounds** - notification sounds
- **Any custom content** - textures, decals, etc.

### What NOT to Include
- Map files (use FastDL for large files)
- Unused skins
- Source files or backups

---

## FastDL Alternative

For large files like maps, consider using FastDL instead of direct downloads:

1. Host files on a web server
2. Set `sv_downloadurl "http://your-server.com/fastdl/"`
3. Mirror your `cstrike/` directory structure on the web server

This is much faster for large files and reduces server bandwidth.
