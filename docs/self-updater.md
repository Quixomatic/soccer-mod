---
layout: default
title: Self-Updater
nav_order: 7
---

# Self-Updater Setup
{: .no_toc }

Soccer Mod includes a built-in self-updater that can check for and download new versions directly from your server's admin menu. It requires the **REST in Pawn (ripext)** extension.
{: .fs-6 .fw-300 }

---

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Requirements

- **SourceMod 1.12+**
- **[sm-ripext](https://github.com/ErikMinekus/sm-ripext)** v1.3.2 or later
- **CA certificate bundle** for HTTPS support

The self-updater is **optional** — Soccer Mod works fine without it. If ripext is not installed, the updater menu will show a "ripext extension not loaded" message and all other features remain unaffected.

---

## Step 1: Download ripext

Download the latest release from [sm-ripext Releases](https://github.com/ErikMinekus/sm-ripext/releases).

Choose the package matching your server's OS:
- `sm-ripext-x.x.x-linux.tar.gz` for Linux
- `sm-ripext-x.x.x-windows.zip` for Windows

---

## Step 2: Install ripext

Extract the archive into your `cstrike/` directory. This will place:

```
cstrike/
├── addons/sourcemod/extensions/ripext.ext.so    (Linux)
├── addons/sourcemod/extensions/ripext.ext.dll   (Windows)
```

---

## Step 3: Install CA Certificate Bundle

ripext needs a CA certificate bundle for HTTPS connections. Without it, all HTTPS requests will fail.

1. Download the Mozilla CA bundle from [https://curl.se/ca/cacert.pem](https://curl.se/ca/cacert.pem)
2. Create the directory `cstrike/addons/sourcemod/configs/ripext/` if it doesn't exist
3. Save the file as `ca-bundle.crt`:

```
cstrike/
├── addons/sourcemod/configs/ripext/
│   └── ca-bundle.crt
```

{: .warning }
The file **must** be named `ca-bundle.crt`, not `cacert.pem`. Rename it after downloading.

---

## Step 4: Restart Server

A **full server restart** is required — you cannot load extensions with a simple map change or plugin reload.

```bash
# Docker
docker restart css-server

# Standalone — restart your srcds process
```

---

## Step 5: Verify

1. Join your server and open the admin menu: `!madmin`
2. Navigate to **Settings** > **Updater**
3. You should see the updater menu with options like "Check for Updates"

If you see "ripext extension not loaded", double-check that:
- The `.ext.so` / `.ext.dll` file is in the correct directory
- The server was fully restarted (not just a map change)
- Check `addons/sourcemod/logs/` for any extension loading errors

---

## Using the Updater

### Menu Options

| Option | Description |
|--------|-------------|
| **Check for Updates** | Compares your version against the latest release |
| **Download Patch Update** | Downloads only `soccer_mod.smx` (fastest) |
| **Download Full Update** | Downloads all files (plugin, sounds, models, materials) |
| **Auto-Check** | Toggle automatic version checking on map start |
| **Check Interval** | Set how often auto-check runs (600-86400 seconds) |
| **Check Remote .smx Size** | Verify the remote plugin file size (diagnostic tool) |
| **Warm Cache** | Pre-download all files to warm the CDN cache without applying |

### Update Safety

All downloads are verified before being applied:
- Files are downloaded to temporary paths first
- Each file's size is checked against the expected size in the release manifest
- If **any** file fails verification, **all** downloads are discarded — no files are changed
- If verification fails, the updater automatically retries once after a 5-second delay

### After Updating

After a successful download, change the map or reload the plugin to apply the update:

```
sm plugins reload soccer_mod
```

---

## Troubleshooting

### "ripext extension not loaded"

- Verify the extension file exists in `addons/sourcemod/extensions/`
- Ensure you downloaded the correct OS version (Linux vs Windows)
- The server must be fully restarted after installing extensions

### Update Check Fails

- Verify `ca-bundle.crt` exists at `addons/sourcemod/configs/ripext/ca-bundle.crt`
- The CA bundle must be from a trusted source ([curl.se/ca/cacert.pem](https://curl.se/ca/cacert.pem))
- Check server logs for SSL/TLS errors

### Downloads Fail Size Verification

This can happen if CDN caching hasn't fully propagated after a new release. Use the **Warm Cache** option first, wait a moment, then retry the download.
