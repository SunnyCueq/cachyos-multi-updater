# Claude AI Kontext für CachyOS Multi-Updater

## 🤖 Für Claude AI

Dieses Dokument enthält wichtige Kontext-Informationen für die Arbeit mit diesem Projekt.

## 📚 Wichtige Referenzen

**Lies diese Dateien in dieser Reihenfolge:**

1. **`rules.md`** - **HAUPTREGELN** - Entwicklungsregeln und Best Practices (MUSS gelesen werden!)
2. **`CONTEXT.md`** - Projekt-Kontext, aktuelle Features, Struktur
3. **`IMPROVEMENTS.md`** - Verbesserungsvorschläge und Roadmap
4. **`.cursorrules`** - Cursor IDE spezifische Regeln

## 🎯 Projekt-Übersicht

**CachyOS Multi-Updater** ist ein Bash-Script für CachyOS/Arch Linux, das automatisch:
- System-Updates (pacman)
- AUR-Pakete (yay/paru)
- Cursor Editor
- AdGuard Home

in einem Durchlauf aktualisiert.

## 🔧 Aktuelle Features

- ✅ Lock-File (verhindert doppelte Ausführung)
- ✅ Selektive Updates (`--only-system`, `--only-aur`, etc.)
- ✅ Dry-Run Modus (`--dry-run`)
- ✅ Konfigurationsdatei (`config.conf`)
- ✅ Umfassendes Logging-System
- ✅ Verbessertes Error Handling
- ✅ Cursor-Prozess-Management (beenden/starten)

## 📁 Wichtige Pfade

### Lokale Installation
- **Script:** `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/update-all.sh`
- **Desktop-Datei:** `~/.local/share/applications/update-all.desktop`
- **Logs:** `logs/` (im Script-Verzeichnis)

### Repository
- **GitHub:** https://github.com/SunnyCueq/cachyos-multi-updater
- **Branch:** `main`

## ⚠️ KRITISCHE REGELN

### 1. Desktop-Datei Synchronisation
**WICHTIG:** Nach jeder Änderung an `update-all.desktop` im Repository:
- Lokale Desktop-Datei muss aktualisiert werden: `~/.local/share/applications/update-all.desktop`
- Script-Pfad muss korrekt sein: `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/update-all.sh`

### 2. Error Handling
- Fehler sollten nicht das gesamte Script stoppen
- Alle Fehler müssen geloggt werden
- Verwende die vorhandenen Logging-Funktionen

### 3. Lock-File
- Lock-File muss verwendet werden (verhindert doppelte Ausführung)
- Lock-File muss bei Exit entfernt werden (trap)

### 4. Git
- Keine Log-Dateien committen
- Keine temporären Dateien committen
- Desktop-Datei synchronisieren wenn geändert

## 🔄 Workflow

### Beim Bearbeiten von Code:
1. Prüfe `rules.md` für Regeln
2. Implementiere Feature/Bug-Fix
3. Füge Error Handling hinzu
4. Füge Logging hinzu
5. Teste lokal
6. Aktualisiere Dokumentation
7. Desktop-Datei synchronisieren (falls nötig)

### Beim Erstellen neuer Features:
1. Prüfe `IMPROVEMENTS.md` für Ideen
2. Implementiere Feature
3. Füge Tests hinzu
4. Aktualisiere `CONTEXT.md`
5. Aktualisiere `README.md` (falls nötig)

## 📝 Code-Stil

- **Bash Best Practices:** `set -euo pipefail`
- **Funktionen:** Verwende Funktionen für wiederholbare Logik
- **Logging:** Verwende `log_info()`, `log_error()`, `log_success()`, `log_warning()`
- **Error Handling:** Immer Error Handling implementieren
- **Kommentare:** Kommentiere komplexe Logik

## 🧪 Testing

- Teste lokal vor jedem Commit
- Verwende `--dry-run` zum Testen
- Teste Edge Cases (fehlende Dependencies, Netzwerkfehler, etc.)

## 📋 Checkliste

Vor jedem Commit:
- [ ] Code getestet
- [ ] Error Handling vorhanden
- [ ] Logging hinzugefügt
- [ ] Dokumentation aktualisiert
- [ ] Desktop-Datei synchronisiert (falls geändert)
- [ ] .gitignore geprüft
- [ ] Keine temporären Dateien committet

## 🚫 Was NICHT tun

- ❌ Log-Dateien committen
- ❌ Temporäre Dateien committen
- ❌ Desktop-Datei Synchronisation vergessen
- ❌ Fehler ignorieren
- ❌ Dokumentation vergessen

## ✅ Best Practices

- ✅ Immer `rules.md` lesen
- ✅ Lock-File verwenden
- ✅ Strukturiertes Logging
- ✅ Fehlerbehandlung überall
- ✅ Dokumentation aktuell halten
- ✅ Desktop-Datei synchronisieren

## 🔗 Externe Abhängigkeiten

- CachyOS/Arch Linux
- pacman
- yay oder paru (AUR-Helper)
- cursor (optional)
- AdGuard Home (optional)
- curl
- systemctl

## 📚 Weitere Dokumentation

- **`rules.md`** - Vollständige Entwicklungsregeln
- **`CONTEXT.md`** - Projekt-Kontext und Features
- **`README.md`** - Benutzer-Dokumentation
- **`IMPROVEMENTS.md`** - Verbesserungsvorschläge

---

**Bei Fragen: Lies zuerst `rules.md`!**

