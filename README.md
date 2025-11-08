# CachyOS Multi-Updater

A simple one-click update tool for CachyOS that automatically updates system packages, AUR packages, Cursor editor, and AdGuard Home.

## 🚀 What does this script do?

This script automatically updates:
- ✅ **CachyOS System Updates** (via pacman)
- ✅ **AUR Packages** (via yay or paru)
- ✅ **Cursor Editor** (automatic download and update)
- ✅ **AdGuard Home** (automatic download and update)

## 📋 Requirements

- CachyOS (or Arch Linux)
- `sudo` privileges
- One of the AUR helpers: `yay` or `paru` (optional)
- Cursor Editor (optional, will be automatically updated if installed)
- AdGuard Home (optional, will be automatically updated if installed)

## 🔧 Installation

### Step 1: Clone or download the repository

```bash
git clone https://github.com/YOUR-USERNAME/cachyos-multi-updater.git
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

# Edit desktop file (path to script directory)
# Open the file and modify the Exec command if needed
nano ~/.local/share/applications/update-all.desktop
```

**Important:** The desktop file must have the correct path to the script directory. The desktop file uses `%k` as a placeholder for the directory, but you can also specify the absolute path:

```
Exec=bash -c "cd '/path/to/script' && ./update-all.sh"
```

## 💻 Usage

### Option 1: Via desktop shortcut

1. Search for "Update All" in the application menu
2. Click on it
3. A terminal will open and the update will start automatically
4. Enter your sudo password when prompted

### Option 2: Via command line

```bash
./update-all.sh
```

## 📝 Logs

All updates are saved in log files:
- **Log directory:** `logs/` (in the script directory)
- **Log format:** `update-YYYYMMDD-HHMMSS.log`
- **Automatic cleanup:** The last 10 log files are kept

If you encounter problems, you can check the log files:

```bash
ls -lh logs/
cat logs/update-*.log
```

## ⚠️ Important Notes

- **Cursor will be automatically closed** during the update
- **AdGuard Home will be briefly stopped** during the update
- All changes are documented in log files
- If errors occur, the script will not exit immediately but will try to complete all updates

## 🐛 Troubleshooting

### Cursor is not being updated

- Check the log files in `logs/`
- Make sure Cursor is installed: `which cursor`
- Check your internet connection

### AUR updates are not working

- Install an AUR helper: `yay` or `paru`
- Check the log files for details

### AdGuard Home is not being updated

- Make sure AdGuard Home is installed in `~/AdGuardHome`
- Check the log files for details

## 📄 License

This project is open source. You can freely use, modify, and distribute it.

## 🤝 Contributing

Improvements and bug reports are welcome! Please create an issue or pull request.

## 📧 Support

For questions or problems:
1. First check the log files in `logs/`
2. Create an issue on GitHub
3. Describe the problem as detailed as possible

---

**Good luck with your updates! 🎉**
