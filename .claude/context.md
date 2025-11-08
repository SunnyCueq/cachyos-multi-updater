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
  - `update-all.sh` - Hauptscript
  - `lib/` - Module (statistics, progress, interactive)
  - `config.conf` - Konfiguration
  - `logs/` - Log-Dateien
  - `.stats/` - Statistiken (JSON)
  - `.snapshots/` - Backups (optional)

## Wo läuft es?

- Desktop via Icon: `/home/USER/Schreibtisch/update-all.desktop`
- Terminal: `./update-all.sh [OPTIONS]`
- Installation: `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/`
- GitHub: `SunnyCueq/cachyos-multi-updater`

## Wichtige Dateien

- `update-all.sh` - Hauptscript (SCRIPT_VERSION muss aktuell sein)
- `CHANGELOG.md` - Vollständige Versionshistorie
- `README.md` - Haupt-Dokumentation
- `config.conf.example` - Beispiel-Konfiguration
- `update-all.desktop` - Desktop-Icon Template
- `.github/workflows/test.yml` - CI/CD Pipeline
- `.claude/rules.md` - Projekt-Regeln
- `.claude/context.md` - Diese Datei
- `.cursorrules` - Cursor-Editor Regeln

## Aktuelle Version

**2.7.4**

Letzte größere Änderungen:
- Cache-System komplett entfernt (Einfachheit über Komplexität)
- Cursor-Version wird jetzt aus package.json gelesen (zuverlässig)
- Desktop-Datei verwendet absoluten Pfad (funktioniert zuverlässig)
- ShellCheck-Warnungen behoben (SC2155, SC2034, SC2221/SC2222)
- Syntaxfehler behoben (readonly-Variablen korrekt deklariert)
- Dokumentation aktualisiert (Rules, Context, Improvements)
