# Entwicklungsregeln für CachyOS Multi-Updater

## 🎯 Allgemeine Regeln

### 1. Code-Qualität
- **Bash Best Practices:** Verwende `set -euo pipefail` für sicheres Scripting
- **Fehlerbehandlung:** Alle kritischen Operationen müssen Error Handling haben
- **Logging:** Wichtige Aktionen müssen geloggt werden
- **Kommentare:** Komplexe Logik muss kommentiert sein

### 2. Git & Repository

#### Commit-Regeln
- **Aussagekräftige Commits:** Klare, beschreibende Commit-Messages
- **Atomic Commits:** Jeder Commit sollte eine logische Einheit sein
- **Keine großen Dumps:** Große Änderungen in mehrere Commits aufteilen

#### Branch-Strategie
- **Main Branch:** `main` ist der produktive Branch
- **Feature Branches:** Für größere Features
- **Hotfixes:** Direkt auf `main` wenn kritisch

#### .gitignore
- **Logs:** Niemals Log-Dateien committen
- **Temporäre Dateien:** Alle temporären Dateien ignorieren
- **User-spezifische Dateien:** Keine persönlichen Konfigurationen
- **Lock-Files:** `.update-all.lock` sollte ignoriert werden (optional)

### 3. Desktop-Datei Synchronisation

**WICHTIG:** Die lokale Desktop-Datei muss immer mit der GitHub-Version synchronisiert werden!

#### Regel:
Nach jeder Änderung an `update-all.desktop` im Repository:

1. **Desktop-Datei aktualisieren:**
   ```bash
   # Im Repository-Verzeichnis
   cp update-all.desktop ~/.local/share/applications/
   ```

2. **Pfad anpassen:**
   - Die Desktop-Datei im Repository ist ein Template
   - Lokale Desktop-Datei muss den korrekten Script-Pfad enthalten
   - Aktueller Pfad: `/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/update-all.sh`

3. **Automatisierung:**
   - Bei jedem Pull/Update prüfen ob Desktop-Datei geändert wurde
   - Script `sync-desktop.sh` kann verwendet werden

#### Template-Format:
```ini
[Desktop Entry]
Name=Update All
Comment=One-click update for CachyOS + AUR + Cursor + AdGuard
Exec=bash -c "cd '/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater' && ./update-all.sh"
Icon=system-software-update
Terminal=true
Type=Application
Categories=System;
```

### 4. Dokumentation

#### README.md
- **Immer aktuell halten:** README muss den aktuellen Stand widerspiegeln
- **Installationsanleitung:** Schritt-für-Schritt Anleitung
- **Verwendung:** Klare Beispiele
- **Troubleshooting:** Häufige Probleme dokumentieren

#### CONTEXT.md
- **Projekt-Übersicht:** Aktueller Stand des Projekts
- **Struktur:** Datei- und Verzeichnisstruktur
- **Pfade:** Wichtige Pfade dokumentieren
- **Features:** Aktuelle Features auflisten

#### IMPROVEMENTS.md
- **Verbesserungsvorschläge:** Neue Ideen dokumentieren
- **Prioritäten:** Nach Wichtigkeit sortieren
- **Status:** Implementierte Features markieren

### 5. Script-Entwicklung

#### Lock-File
- **Immer verwenden:** Lock-File verhindert doppelte Ausführung
- **Cleanup:** Lock-File muss bei Exit entfernt werden
- **Fehlerbehandlung:** Prüfen ob Lock-File existiert

#### Error Handling
- **Nicht abbrechen:** Fehler in einem Bereich sollten andere Updates nicht stoppen
- **Logging:** Alle Fehler müssen geloggt werden
- **User-Feedback:** Benutzer über Fehler informieren

#### Logging
- **Strukturiert:** Logs sollten strukturiert sein (Timestamp, Level, Message)
- **Rotation:** Alte Logs automatisch aufräumen
- **Lesbarkeit:** Logs sollten für Debugging nützlich sein

### 6. Testing

#### Vor dem Commit
- **Lokal testen:** Script lokal ausführen
- **Dry-Run:** Mit `--dry-run` testen
- **Edge Cases:** Grenzfälle testen

#### Test-Szenarien
- Normale Ausführung
- Fehlerhafte Netzwerkverbindung
- Fehlende Dependencies
- Bereits laufendes Script (Lock-File)

### 7. Konfiguration

#### config.conf
- **Optional:** Konfigurationsdatei ist optional
- **Defaults:** Sinnvolle Defaults wenn keine Config vorhanden
- **Validierung:** Config-Werte validieren
- **Dokumentation:** Config-Optionen dokumentieren

### 8. Versionierung

#### Versionsnummern
- **Semantic Versioning:** Major.Minor.Patch
- **Changelog:** Änderungen in CONTEXT.md dokumentieren
- **Tags:** Wichtige Versionen taggen

### 9. Sicherheit

#### Sudo-Verwendung
- **Minimal:** Nur wo nötig sudo verwenden
- **Explizit:** Klar machen warum sudo benötigt wird
- **Sicherheit:** Keine Passwörter im Script

#### Downloads
- **Verifizierung:** Downloads verifizieren (Checksums, GPG)
- **Temporäre Dateien:** Sicher löschen
- **Pfade:** Keine unsicheren Pfade

### 10. Performance

#### Optimierung
- **Parallele Operationen:** Wo möglich parallel ausführen
- **Caching:** Versions-Checks cachen
- **Cleanup:** Temporäre Dateien sofort löschen

## 🔄 Workflow

### Neues Feature entwickeln
1. Issue erstellen oder IMPROVEMENTS.md aktualisieren
2. Feature implementieren
3. Tests durchführen
4. Dokumentation aktualisieren
5. Commit und Push

### Bug-Fix
1. Problem identifizieren
2. Fix implementieren
3. Tests durchführen
4. Commit mit "Fix: ..." Message
5. Push

### Dokumentation aktualisieren
1. Änderungen in entsprechende MD-Dateien
2. CONTEXT.md aktualisieren falls nötig
3. Commit mit "Docs: ..." Message
4. Push

## 📋 Checkliste vor jedem Commit

- [ ] Code getestet
- [ ] Error Handling vorhanden
- [ ] Logging hinzugefügt
- [ ] Dokumentation aktualisiert (falls nötig)
- [ ] Desktop-Datei synchronisiert (falls geändert)
- [ ] .gitignore geprüft
- [ ] Keine temporären Dateien committet
- [ ] Aussagekräftige Commit-Message

## 🚫 Was NICHT gemacht werden sollte

- ❌ Log-Dateien committen
- ❌ Temporäre Dateien committen
- ❌ User-spezifische Pfade hardcoden
- ❌ Fehler ignorieren (exit 0 bei Fehlern)
- ❌ Dokumentation vergessen
- ❌ Desktop-Datei vergessen zu synchronisieren
- ❌ Lock-Files committen
- ❌ Passwörter oder Secrets committen

## ✅ Best Practices

- ✅ Immer Lock-File verwenden
- ✅ Strukturiertes Logging
- ✅ Fehlerbehandlung überall
- ✅ Dokumentation aktuell halten
- ✅ Desktop-Datei synchronisieren
- ✅ Tests vor Commit
- ✅ Aussagekräftige Commit-Messages
- ✅ Regelmäßige Updates

---

**Diese Regeln sollten bei jeder Entwicklung befolgt werden!**

