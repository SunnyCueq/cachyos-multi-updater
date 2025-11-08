# Projekt-Kontext: CachyOS Multi-Updater

## 📋 Projekt-Übersicht

**CachyOS Multi-Updater** ist ein Bash-Script, das automatisch System-Updates, AUR-Pakete, Cursor Editor und AdGuard Home in einem Durchlauf aktualisiert.

## 🎯 Hauptfunktionen

- ✅ CachyOS System-Updates (via pacman)
- ✅ AUR-Pakete (via yay/paru)
- ✅ Cursor Editor (automatischer Download und Update)
- ✅ AdGuard Home (automatischer Download und Update)
- ✅ Umfassendes Logging-System
- ✅ Verbessertes Error Handling
- ✅ Desktop-Integration

## 📁 Projekt-Struktur

```
cachyos-multi-updater/
├── update-all.sh          # Haupt-Script
├── update-all.desktop     # Desktop-Verknüpfung (Template)
├── config.conf            # Konfigurationsdatei (optional)
├── README.md              # Haupt-Dokumentation
├── CONTEXT.md             # Diese Datei - Projekt-Kontext
├── IMPROVEMENTS.md        # Verbesserungsvorschläge
├── rules.md               # Entwicklungsregeln
├── .cursorrules           # Cursor-spezifische Regeln
├── claude.md              # Claude AI Kontext
├── .gitignore             # Git-Ignore-Regeln
├── LICENSE                # MIT-Lizenz
└── logs/                  # Log-Dateien (nicht in Git)
```

## 🔧 Wichtige Pfade

### Lokale Installation
- **Script-Pfad:** `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/update-all.sh`
- **Desktop-Datei:** `~/.local/share/applications/update-all.desktop`
- **Log-Verzeichnis:** `logs/` (im Script-Verzeichnis)

### GitHub Repository
- **URL:** https://github.com/SunnyCueq/cachyos-multi-updater
- **Branch:** `main`

## 📝 Entwicklungsregeln

Siehe `rules.md` für detaillierte Entwicklungsregeln und Best Practices.

### Wichtige Regeln:
1. **Desktop-Datei Synchronisation:** Die lokale Desktop-Datei muss immer mit der GitHub-Version synchronisiert werden
2. **Logging:** Alle wichtigen Aktionen müssen geloggt werden
3. **Error Handling:** Fehler sollten nicht das gesamte Script stoppen
4. **Backward Compatibility:** Änderungen sollten bestehende Installationen nicht brechen

## 🚀 Verwendung

### Standard-Update
```bash
./update-all.sh
```

### Selektive Updates
```bash
./update-all.sh --only-system      # Nur System-Updates
./update-all.sh --only-aur         # Nur AUR
./update-all.sh --only-cursor      # Nur Cursor
./update-all.sh --only-adguard     # Nur AdGuard
```

### Dry-Run Modus
```bash
./update-all.sh --dry-run          # Zeigt was gemacht würde, ohne Änderungen
```

## 🔄 Synchronisation

### Desktop-Datei aktualisieren
Nach Änderungen an `update-all.desktop` im Repository:
```bash
# Script-Pfad in Desktop-Datei anpassen und kopieren
cp update-all.desktop ~/.local/share/applications/
# Pfad im Exec-Befehl anpassen falls nötig
```

## 📊 Aktuelle Features

- ✅ Lock-File (verhindert doppelte Ausführung)
- ✅ Selektive Updates (--only-* Flags)
- ✅ Dry-Run Modus (--dry-run)
- ✅ Konfigurationsdatei (config.conf)
- ✅ Umfassendes Logging
- ✅ Verbessertes Error Handling
- ✅ Cursor-Prozess-Management

## 🐛 Bekannte Probleme / Limitationen

- Cursor-Update erfordert manchmal manuelles Eingreifen bei speziellen Installationen
- AdGuard Home muss in `~/AdGuardHome` installiert sein
- AUR-Helper (yay/paru) muss separat installiert sein

## 📚 Weitere Dokumentation

- `README.md` - Benutzer-Dokumentation
- `IMPROVEMENTS.md` - Verbesserungsvorschläge
- `rules.md` - Entwicklungsregeln
- `.cursorrules` - Cursor IDE Regeln
- `claude.md` - Claude AI Kontext

## 🔗 Externe Abhängigkeiten

- **CachyOS/Arch Linux** - Basis-System
- **pacman** - Paketmanager
- **yay oder paru** - AUR-Helper (optional)
- **cursor** - Editor (optional)
- **AdGuard Home** - DNS-Filter (optional)
- **curl** - Downloads
- **systemctl** - Service-Management

## 📅 Changelog

### Version 2.0 (Aktuell)
- Lock-File hinzugefügt
- Selektive Updates implementiert
- Dry-Run Modus hinzugefügt
- Konfigurationsdatei unterstützt
- Verbessertes Logging
- Cursor-Prozess-Management verbessert

### Version 1.0
- Initiale Version mit Basis-Funktionalität

## 👤 Maintainer

- GitHub: [SunnyCueq](https://github.com/SunnyCueq)
- Repository: https://github.com/SunnyCueq/cachyos-multi-updater

---

**Letzte Aktualisierung:** $(date +%Y-%m-%d)
**Version:** 2.0

