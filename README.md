# CachyOS Multi-Updater

> **Language / Sprache:** [🇬🇧 English](README.md) | [🇩🇪 Deutsch](README.de.md)

A simple one-click update tool for CachyOS that automatically updates system packages, AUR packages, Cursor editor, and AdGuard Home.

## 🚀 What does this script do?

This script automatically updates:
- ✅ **CachyOS System Updates** (via pacman)
- ✅ **AUR Packages** (via yay or paru)
- ✅ **Cursor Editor** (automatic download and update)
- ✅ **AdGuard Home** (automatic download and update)

## ✨ Features

- 🔒 **Lock-File Protection** - Prevents multiple simultaneous executions
- 🎯 **Selective Updates** - Update only specific components
- 🔍 **Dry-Run Mode** - Preview what would be updated without making changes
- ⚙️ **Configuration File** - Customize behavior via `config.conf`
- 📝 **Comprehensive Logging** - All actions are logged with timestamps
- 🛡️ **Error Handling** - Continues with other updates even if one fails
- 🔄 **Auto Cleanup** - Automatically manages old log files

## 📋 Requirements

- CachyOS (or Arch Linux)
- `sudo` privileges
- One of the AUR helpers: `yay` or `paru` (optional, for AUR updates)
- Cursor Editor (optional, will be automatically updated if installed)
- AdGuard Home (optional, will be automatically updated if installed)

## 🔧 Installation

### Step 1: Clone or download the repository

```bash
git clone https://github.com/SunnyCueq/cachyos-multi-updater.git
cd cachyos-multi-updater
```

### Step 2: Make the script executable

```bash
chmod +x update-all.sh
```

### Step 3: Install desktop shortcut (optional)

```bash
# Copy desktop file
cp update-all.desktop ~/.local/share/applications/

# Edit desktop file and set the correct path to your script directory
nano ~/.local/share/applications/update-all.desktop
```

**Important:** Update the `Exec` line in the desktop file with your script's absolute path:

```ini
Exec=bash -c "cd '/path/to/cachyos-multi-updater' && ./update-all.sh"
```

### Step 4: Configure (optional)

Copy the example configuration file and customize it:

```bash
cp config.conf.example config.conf
nano config.conf
```

## 💻 Usage

### Option 1: Via desktop shortcut

1. Search for "Update All" in the application menu
2. Click on it
3. A terminal will open and the update will start automatically
4. Enter your sudo password when prompted

### Option 2: Via command line

#### Standard update (all components)
```bash
./update-all.sh
```

#### Selective updates
```bash
./update-all.sh --only-system      # Only CachyOS system updates
./update-all.sh --only-aur         # Only AUR packages
./update-all.sh --only-cursor      # Only Cursor editor
./update-all.sh --only-adguard     # Only AdGuard Home
```

#### Dry-run mode (preview without changes)
```bash
./update-all.sh --dry-run          # Shows what would be updated
```

#### Help
```bash
./update-all.sh --help
```

## ⚙️ Configuration

Create a `config.conf` file in the script directory to customize behavior:

```bash
cp config.conf.example config.conf
```

Available options:
- `ENABLE_SYSTEM_UPDATE` - Enable/disable system updates (true/false)
- `ENABLE_AUR_UPDATE` - Enable/disable AUR updates (true/false)
- `ENABLE_CURSOR_UPDATE` - Enable/disable Cursor updates (true/false)
- `ENABLE_ADGUARD_UPDATE` - Enable/disable AdGuard Home updates (true/false)
- `ENABLE_NOTIFICATIONS` - Enable desktop notifications (true/false)
- `DRY_RUN` - Enable dry-run mode by default (true/false)
- `MAX_LOG_FILES` - Number of log files to keep (default: 10)

## 📝 Logs

All updates are saved in log files:
- **Log directory:** `logs/` (in the script directory)
- **Log format:** `update-YYYYMMDD-HHMMSS.log`
- **Automatic cleanup:** The last 10 log files are kept (configurable via `MAX_LOG_FILES`)

If you encounter problems, you can check the log files:

```bash
ls -lh logs/
cat logs/update-*.log
tail -f logs/update-*.log  # Watch log in real-time
```

## ⚠️ Important Notes

- **Lock-File:** If the script is already running, a lock file prevents multiple executions. If you're sure no update is running, you can manually delete `.update-all.lock`
- **Cursor will be automatically closed** during the update
- **AdGuard Home will be briefly stopped** during the update
- All changes are documented in log files
- If errors occur, the script will not exit immediately but will try to complete all updates
- The script requires `sudo` privileges for system and AUR updates

## 🐛 Troubleshooting

### Script says "Update läuft bereits!" (Update already running)

- Check if another update process is running: `ps aux | grep update-all.sh`
- If no process is running, delete the lock file: `rm .update-all.lock`

### Cursor is not being updated

- Check the log files in `logs/`
- Make sure Cursor is installed: `which cursor`
- Check your internet connection
- Verify Cursor installation directory permissions

### AUR updates are not working

- Install an AUR helper: `yay` or `paru`
- Check the log files for details
- Verify AUR helper is in PATH: `which yay` or `which paru`

### AdGuard Home is not being updated

- Make sure AdGuard Home is installed in `~/AdGuardHome`
- Check the log files for details
- Verify the AdGuard Home binary exists: `ls -l ~/AdGuardHome/AdGuardHome`

### Permission denied errors

- Make sure the script is executable: `chmod +x update-all.sh`
- Check sudo permissions: `sudo -v`

## 📄 License

This project is open source. You can freely use, modify, and distribute it.

## 🤝 Contributing

Improvements and bug reports are welcome! Please create an issue or pull request on [GitHub](https://github.com/SunnyCueq/cachyos-multi-updater).

## 📧 Support

For questions or problems:
1. First check the log files in `logs/`
2. Check the [Troubleshooting](#-troubleshooting) section
3. Create an issue on [GitHub](https://github.com/SunnyCueq/cachyos-multi-updater)
4. Describe the problem as detailed as possible (include log excerpts)

## 🔗 Links

- **GitHub Repository:** https://github.com/SunnyCueq/cachyos-multi-updater
- **Issues:** https://github.com/SunnyCueq/cachyos-multi-updater/issues

## 📅 Changelog

### Version 2.1.0 (Current)
- Added German README (README.de.md)
- Improved documentation and user experience
- Enhanced configuration file documentation
- Better error messages and troubleshooting

### Version 2.0.0
- Added lock-file protection to prevent multiple simultaneous executions
- Implemented selective updates (`--only-system`, `--only-aur`, `--only-cursor`, `--only-adguard`)
- Added dry-run mode (`--dry-run`)
- Added configuration file support (`config.conf`)
- Improved logging system with timestamps
- Enhanced error handling (continues with other updates if one fails)
- Better Cursor process management (automatic close/restart)

### Version 1.0.0
- Initial release
- Basic update functionality for CachyOS, AUR, Cursor, and AdGuard Home

---

**Good luck with your updates! 🎉**
