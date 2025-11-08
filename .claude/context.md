# Projekt-Kontext: CachyOS Multi-Updater

## Meta-Regel: Kontext aktuell halten!

**WICHTIG:** Bei JEDER größeren Änderung am Projekt:
1. Diese Datei `.claude/context.md` aktualisieren
2. Die Datei `.claude/rules.md` aktualisieren
3. Die Datei `.cursorrules` aktualisieren
4. Alle drei Dateien müssen synchron bleiben!

## Was ist das Projekt?

Ein Bash-Script für CachyOS Linux, das mit einem Klick mehrere Komponenten aktualisiert:
- System-Pakete (pacman)
- AUR-Pakete (yay/paru)
- Cursor Editor (manueller Download/Installation)
- AdGuard Home (manueller Download/Installation)

## Zielgruppe

- CachyOS Linux User
- Technisch versierte Linux-Nutzer
- User die mehrere Komponenten mit einem Befehl updaten wollen

## Hauptfeatures

1. **Ein-Klick Updates** via Desktop-Icon
2. **Konfigurierbar** via `config.conf`
3. **Verschiedene Modi**:
   - Normal: Alle Updates
   - Selective: Nur bestimmte Komponenten (`--only-system`, etc.)
   - Dry-Run: Zeigt was passieren würde
   - Interactive: User wählt Komponenten aus
4. **Logging** mit Zeitstempeln
5. **Statistiken** über Update-Historie
6. **Fortschrittsanzeige** `[1/4] 🔄 ...`

## Technische Details

- **Sprache:** Bash
- **Abhängigkeiten:**
  - pacman (CachyOS Paketmanager)
  - yay oder paru (AUR Helper)
  - curl oder wget (Downloads)
  - Optional: notify-send (Desktop-Benachrichtigungen)
- **Struktur:**
  - `setup.sh` - Setup-Script für Erstinstallation (v2.7.5+)
  - `update-all.sh` - Hauptscript
  - `create-desktop-shortcut.sh` - Helper-Script für Desktop-Verknüpfungen
  - `lib/` - Module (statistics, progress, interactive)
  - `config.conf` - Konfiguration
  - `logs/` - Log-Dateien
  - `.stats/` - Statistiken (JSON)

## Wo läuft es?

- Desktop via Icon: `/home/USER/Schreibtisch/update-all.desktop`
- Terminal: `./update-all.sh [OPTIONS]`
- Installation: `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/`
- GitHub: `SunnyCueq/cachyos-multi-updater`

## Wichtige Dateien

- `setup.sh` - Setup-Script für Erstinstallation (v2.7.5+)
- `update-all.sh` - Hauptscript (SCRIPT_VERSION muss aktuell sein)
- `create-desktop-shortcut.sh` - Helper-Script für Desktop-Verknüpfungen
- `CHANGELOG.md` - Vollständige Versionshistorie
- `README.md` - Haupt-Dokumentation (EN)
- `README.de.md` - Haupt-Dokumentation (DE)
- `config.conf.example` - Beispiel-Konfiguration
- `update-all.desktop` - Desktop-Icon Template
- `.github/workflows/test.yml` - CI/CD Pipeline
- `.claude/rules.md` - Projekt-Regeln
- `.claude/context.md` - Diese Datei
- `.cursorrules` - Cursor-Editor Regeln

## Aktuelle Version

**2.8.0** (STABLE RELEASE)

Letzte größere Änderungen:
- **🎉 STABLE RELEASE v2.8.0:** Erste stabile Version - produktionsreif und vollständig getestet
- **Cursor-Versionsprüfung OHNE Download:** HTTP HEAD Request statt vollständigem Download
  - Version wird aus Location-Header extrahiert (`cursor_2.0.69_amd64.deb` → `2.0.69`)
  - Download nur wenn Update verfügbar ist (132MB → wenige KB)
  - Deutlich schneller und spart Bandbreite
  - Fallback: Alte Methode (Download + Extraktion) wenn HTTP HEAD fehlschlägt
- **AdGuard Home Versionsprüfung funktioniert perfekt:** Nutzt GitHub Releases API
  - Prüft Version VOR Download, überspringt Download wenn aktuell
  - Nutzt offiziellen Download-Link von AdGuard
- **Desktop-Integration:** Wrapper-Scripts für zuverlässiges Terminal offen halten
  - `run-update.sh` - hält Terminal offen
  - `launch-update.sh` - Parameter-Handling
  - `konsole --hold` für KDE/Plasma
  - **WICHTIG:** Desktop-Icon wird NUR über `setup.sh` oder `create-desktop-shortcut.sh` erstellt, NICHT automatisch
- **Bugfixes:** 
  - SYSTEM_PACKAGES Newline-Problem behoben
  - Syntaxfehler korrigiert
  - Interactive Mode COLOR_BOLD Fehler behoben
  - Cursor Extraktion funktioniert jetzt korrekt (ar x, tar mit ./ Pfaden)
- **Cleanup:** Alle temporären Dateien werden automatisch gelöscht
- **Dokumentation:** Alle MD-Dateien aktualisiert
