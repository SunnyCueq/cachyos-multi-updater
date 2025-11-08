# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [2.7.0] - 2025-11-08

### Hinzugefügt
- **🎮 Interaktiver Modus:** `--interactive` / `-i` zum manuellen Auswählen der Updates
- **📊 Update-Statistiken:** Tracking von Updates mit `--stats` Option
  - Gesamt-Updates, Erfolgsrate, durchschnittliche Dauer
  - Automatische Speicherung nach jedem Update in JSON-Format
  - Persistente Statistiken über alle Updates hinweg
- **⏱️ Geschätzte Dauer:** Anzeige der geschätzten Update-Dauer basierend auf historischen Daten
- **📈 Fortschritts-Indikator:** Text-basierte Fortschrittsanzeige `[1/4] ✅ Component (25%)`
- **📦 Modularisierung:** Code in Module aufgeteilt
  - `lib/statistics.sh` - Statistik-Funktionen
  - `lib/progress.sh` - Fortschritts-Anzeige
  - `lib/interactive.sh` - Interaktiver Modus
- **✅ Fehlercode-Definitionen:** Klare Exit-Codes (EXIT_LOCK_EXISTS, EXIT_CONFIG_ERROR, EXIT_DOWNLOAD_ERROR, EXIT_UPDATE_ERROR)
- **🔒 Input-Validierung:** Config-Werte werden jetzt validiert (true/false, Zahlen)
- **💾 Snapshot/Rollback-System:** Automatische Backups vor Cursor & AdGuard Updates
- **⏰ Update-Zeitplanung:** Warnung wenn System > 14 Tage nicht aktualisiert wurde
- **📝 Fehler-Report Generator:** Automatische Erstellung detaillierter Fehler-Reports
- **🖥️ System-Info Logging:** Systemdetails werden bei jedem Update geloggt
- **⚡ Cache-Optimierung:** CACHE_MAX_AGE ist jetzt konfigurierbar
- **🧪 BATS-Tests:** Unit-Tests für Config-Validierung und Snapshot/Rollback
- **🤖 GitHub Actions:** Umfangreiche CI/CD Pipeline
  - ShellCheck Linting
  - Bash Syntax Check
  - BATS Tests
  - Dry-Run Test
  - Config Validation
  - Documentation Check
  - Version Consistency Check

### Geändert
- **🔐 Temporäre Dateien:** Verwenden jetzt `mktemp` für sichere temporäre Verzeichnisse
- **📊 Paket-Counting:** Zählt Pakete jetzt VOR dem Update (korrekte Anzahl)
- **🔄 AdGuard Version-Vergleich:** Semantischer Versionsvergleich statt String-Vergleich
- **🔍 Cursor Process Detection:** Verwendet -x Flag für genaues Matching
- **🔐 Konstanten:** SCRIPT_VERSION, SCRIPT_DIR, LOG_DIR etc. sind jetzt `readonly`
- **📦 Best Practices:** Alle Funktions-Variablen verwenden jetzt `local`
- **🧹 Snapshot-Cleanup:** Alte Snapshots werden automatisch bereinigt (max. 5)
- **🏗️ Code-Struktur:** Aufgeteilt in lib/-Module für bessere Wartbarkeit

### Behoben
- Paket-Zählung zeigte nach Update falsche Werte
- AdGuard-Versionvergleich funktionierte nicht richtig bei manchen Versionen
- Cursor-Prozess-Detection matche manchmal falsche Prozesse
- Temporäre Dateien in unsicheren Verzeichnissen

## [2.6.0] - 2024-12-15

### Geändert
- Automatisches Cursor-Schließen/Starten entfernt (warnt nur noch)
- Bessere Benutzerkontrolle über Cursor
- Dokumentation aktualisiert

### Hinzugefügt
- FAQ-Eintrag zu update-all.1 (Man-Page)

## [2.5.0] - 2024-12-10

### Hinzugefügt
- Retry-Mechanismus für Downloads (konfigurierbar, Standard: 3 Versuche)
- Detaillierte Zusammenfassung am Ende (Dauer, Status, Paketanzahl)
- Farbige Terminal-Ausgabe (optional, über ENABLE_COLORS)
- Automatisches Script-Update (optional, mit Bestätigung)
- Versionsprüfung-Caching (Performance, 1 Stunde Cache)
- Neue Config-Optionen: ENABLE_COLORS, DOWNLOAD_RETRIES, ENABLE_AUTO_UPDATE

## [2.4.0] - 2024-12-05

### Hinzugefügt
- Verbesserte Version-Prüfung (prüft Releases und Tags)
- Semantischer Versionsvergleich (wie WoltLab)
- Erweiterte Desktop-Icon-Dokumentation
- Neue Regel: Versionierung und Release-Prüfung

## [2.3.0] - 2024-11-30

### Hinzugefügt
- Cursor-Update komplett überarbeitet:
  - Prüfung ob Cursor über pacman installiert ist (überspringt dann Update)
  - Versionsprüfung vor Download (überspringt wenn bereits aktuell)
  - Verbessertes Cursor-Kill (pkill statt killall)
  - Cleanup wird immer durchgeführt (auch bei Fehlern)
  - Besseres Output-Format mit Trennern
  - Verbesserte Fehlerbehandlung
- Neue Regel: Kontinuierliche Aktualisierung aller Dokumentation
- Verbesserte Release-Checkliste

## [2.2.0] - 2024-11-25

### Hinzugefügt
- Automatisches Update-Check für Script selbst
- Progress-Bar für Downloads
- Health-Check nach Updates (Service-Status-Prüfung)
- Umfassende Dokumentation für Laien (EN + DE, 1200+ Zeilen)
- FAQ-Sektion (EN + DE)
- GitHub Issue Templates

## [2.1.0] - 2024-11-20

### Hinzugefügt
- Deutsche README (README.de.md)
- Versionsnummer-Anzeige (--version Flag)
- Verbesserte Dokumentation
- GitHub Actions CI/CD Workflow
- Man-Page

## [2.0.0] - 2024-11-15

### Hinzugefügt
- Lock-File (verhindert doppelte Ausführung)
- Selektive Updates (--only-* Flags)
- Dry-Run Modus (--dry-run)
- Konfigurationsdatei (config.conf)
- Verbessertes Logging
- Cursor-Prozess-Management

## [1.0.0] - 2024-11-01

### Hinzugefügt
- Initiale Version
- CachyOS System-Updates (pacman)
- AUR-Updates (yay/paru)
- Cursor Editor Updates
- AdGuard Home Updates
- Basis-Logging
- Desktop-Integration

---

## Legende

- **Hinzugefügt** - Neue Features
- **Geändert** - Änderungen an bestehender Funktionalität
- **Veraltet** - Features die bald entfernt werden
- **Entfernt** - Entfernte Features
- **Behoben** - Bug-Fixes
- **Sicherheit** - Sicherheits-relevante Änderungen
