# CachyOS Multi-Updater

> **Sprache / Language:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](README.md)

Ein einfaches One-Click-Update-Tool für CachyOS, das automatisch System-Pakete, AUR-Pakete, den Cursor Editor und AdGuard Home aktualisiert.

## 🚀 Was macht dieses Script?

Dieses Script aktualisiert automatisch:
- ✅ **CachyOS System-Updates** (via pacman)
- ✅ **AUR-Pakete** (via yay oder paru)
- ✅ **Cursor Editor** (automatischer Download und Update)
- ✅ **AdGuard Home** (automatischer Download und Update)

## ✨ Features

- 🔒 **Lock-File Schutz** - Verhindert mehrere gleichzeitige Ausführungen
- 🎯 **Selektive Updates** - Nur bestimmte Komponenten aktualisieren
- 🔍 **Dry-Run Modus** - Vorschau was aktualisiert würde, ohne Änderungen
- ⚙️ **Konfigurationsdatei** - Verhalten über `config.conf` anpassen
- 📝 **Umfassendes Logging** - Alle Aktionen werden mit Zeitstempel geloggt
- 🛡️ **Fehlerbehandlung** - Setzt mit anderen Updates fort, auch wenn eines fehlschlägt
- 🔄 **Auto Cleanup** - Verwaltet alte Log-Dateien automatisch

## 📋 Voraussetzungen

- CachyOS (oder Arch Linux)
- `sudo`-Berechtigungen
- Einer der AUR-Helper: `yay` oder `paru` (optional, für AUR-Updates)
- Cursor Editor (optional, wird automatisch aktualisiert falls installiert)
- AdGuard Home (optional, wird automatisch aktualisiert falls installiert)

## 🔧 Installation

### Schritt 1: Repository klonen oder herunterladen

```bash
git clone https://github.com/SunnyCueq/cachyos-multi-updater.git
cd cachyos-multi-updater
```

### Schritt 2: Script ausführbar machen

```bash
chmod +x update-all.sh
```

### Schritt 3: Desktop-Verknüpfung installieren (optional)

```bash
# Desktop-Datei kopieren
cp update-all.desktop ~/.local/share/applications/

# Desktop-Datei bearbeiten und den korrekten Pfad zum Script-Verzeichnis setzen
nano ~/.local/share/applications/update-all.desktop
```

**Wichtig:** Aktualisiere die `Exec`-Zeile in der Desktop-Datei mit dem absoluten Pfad zu deinem Script:

```ini
Exec=bash -c "cd '/pfad/zum/cachyos-multi-updater' && ./update-all.sh"
```

### Schritt 4: Konfigurieren (optional)

Kopiere die Beispiel-Konfigurationsdatei und passe sie an:

```bash
cp config.conf.example config.conf
nano config.conf
```

## 💻 Verwendung

### Option 1: Über Desktop-Verknüpfung

1. Suche nach "Update All" im Anwendungsmenü
2. Klicke darauf
3. Ein Terminal öffnet sich und das Update startet automatisch
4. Gib dein sudo-Passwort ein, wenn danach gefragt wird

### Option 2: Über Kommandozeile

#### Standard-Update (alle Komponenten)
```bash
./update-all.sh
```

#### Selektive Updates
```bash
./update-all.sh --only-system      # Nur CachyOS System-Updates
./update-all.sh --only-aur         # Nur AUR-Pakete
./update-all.sh --only-cursor      # Nur Cursor Editor
./update-all.sh --only-adguard     # Nur AdGuard Home
```

#### Dry-Run Modus (Vorschau ohne Änderungen)
```bash
./update-all.sh --dry-run          # Zeigt was aktualisiert würde
```

#### Hilfe
```bash
./update-all.sh --help
```

## ⚙️ Konfiguration

Erstelle eine `config.conf` Datei im Script-Verzeichnis, um das Verhalten anzupassen:

```bash
cp config.conf.example config.conf
```

Verfügbare Optionen:
- `ENABLE_SYSTEM_UPDATE` - System-Updates aktivieren/deaktivieren (true/false)
- `ENABLE_AUR_UPDATE` - AUR-Updates aktivieren/deaktivieren (true/false)
- `ENABLE_CURSOR_UPDATE` - Cursor-Updates aktivieren/deaktivieren (true/false)
- `ENABLE_ADGUARD_UPDATE` - AdGuard Home-Updates aktivieren/deaktivieren (true/false)
- `ENABLE_NOTIFICATIONS` - Desktop-Benachrichtigungen aktivieren (true/false)
- `DRY_RUN` - Dry-Run Modus standardmäßig aktivieren (true/false)
- `MAX_LOG_FILES` - Anzahl der zu behaltenden Log-Dateien (Standard: 10)

## 📝 Logs

Alle Updates werden in Log-Dateien gespeichert:
- **Log-Verzeichnis:** `logs/` (im Script-Verzeichnis)
- **Log-Format:** `update-YYYYMMDD-HHMMSS.log`
- **Automatische Bereinigung:** Die letzten 10 Log-Dateien werden behalten (konfigurierbar über `MAX_LOG_FILES`)

Bei Problemen kannst du die Log-Dateien überprüfen:

```bash
ls -lh logs/
cat logs/update-*.log
tail -f logs/update-*.log  # Log in Echtzeit beobachten
```

## ⚠️ Wichtige Hinweise

- **Lock-File:** Wenn das Script bereits läuft, verhindert eine Lock-Datei mehrere Ausführungen. Wenn du sicher bist, dass kein Update läuft, kannst du `.update-all.lock` manuell löschen
- **Cursor wird automatisch geschlossen** während des Updates
- **AdGuard Home wird kurz gestoppt** während des Updates
- Alle Änderungen werden in Log-Dateien dokumentiert
- Wenn Fehler auftreten, beendet sich das Script nicht sofort, sondern versucht alle Updates abzuschließen
- Das Script benötigt `sudo`-Berechtigungen für System- und AUR-Updates

## 🐛 Fehlerbehebung

### Script meldet "Update läuft bereits!"

- Prüfe ob ein anderer Update-Prozess läuft: `ps aux | grep update-all.sh`
- Wenn kein Prozess läuft, lösche die Lock-Datei: `rm .update-all.lock`

### Cursor wird nicht aktualisiert

- Prüfe die Log-Dateien in `logs/`
- Stelle sicher, dass Cursor installiert ist: `which cursor`
- Prüfe deine Internetverbindung
- Überprüfe die Berechtigungen des Cursor-Installationsverzeichnisses

### AUR-Updates funktionieren nicht

- Installiere einen AUR-Helper: `yay` oder `paru`
- Prüfe die Log-Dateien für Details
- Überprüfe ob der AUR-Helper im PATH ist: `which yay` oder `which paru`

### AdGuard Home wird nicht aktualisiert

- Stelle sicher, dass AdGuard Home in `~/AdGuardHome` installiert ist
- Prüfe die Log-Dateien für Details
- Überprüfe ob die AdGuard Home Binary existiert: `ls -l ~/AdGuardHome/AdGuardHome`

### Permission denied Fehler

- Stelle sicher, dass das Script ausführbar ist: `chmod +x update-all.sh`
- Prüfe sudo-Berechtigungen: `sudo -v`

## 📄 Lizenz

Dieses Projekt ist Open Source. Du kannst es frei verwenden, modifizieren und verteilen.

## 🤝 Beitragen

Verbesserungen und Fehlerberichte sind willkommen! Bitte erstelle ein Issue oder Pull Request auf [GitHub](https://github.com/SunnyCueq/cachyos-multi-updater).

## 📧 Support

Bei Fragen oder Problemen:
1. Prüfe zuerst die Log-Dateien in `logs/`
2. Schaue in den Abschnitt [Fehlerbehebung](#-fehlerbehebung)
3. Erstelle ein Issue auf [GitHub](https://github.com/SunnyCueq/cachyos-multi-updater)
4. Beschreibe das Problem so detailliert wie möglich (inklusive Log-Auszüge)

## 🔗 Links

- **GitHub Repository:** https://github.com/SunnyCueq/cachyos-multi-updater
- **Issues:** https://github.com/SunnyCueq/cachyos-multi-updater/issues

## 📅 Changelog

### Version 2.1.0 (Aktuell)
- Deutsche README hinzugefügt (README.de.md)
- Verbesserte Dokumentation und Benutzerfreundlichkeit
- Erweiterte Konfigurationsdatei-Dokumentation
- Bessere Fehlermeldungen und Fehlerbehebung

### Version 2.0.0
- Lock-File Schutz hinzugefügt (verhindert mehrere gleichzeitige Ausführungen)
- Selektive Updates implementiert (`--only-system`, `--only-aur`, `--only-cursor`, `--only-adguard`)
- Dry-Run Modus hinzugefügt (`--dry-run`)
- Konfigurationsdatei-Unterstützung hinzugefügt (`config.conf`)
- Verbessertes Logging-System mit Zeitstempeln
- Verbesserte Fehlerbehandlung (setzt mit anderen Updates fort, auch wenn eines fehlschlägt)
- Besseres Cursor-Prozess-Management (automatisches Schließen/Neustarten)

### Version 1.0.0
- Erste Veröffentlichung
- Basis-Update-Funktionalität für CachyOS, AUR, Cursor und AdGuard Home

---

**Viel Erfolg mit deinen Updates! 🎉**

