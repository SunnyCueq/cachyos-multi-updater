# GitHub Release Guide

## Problem: Fehlende Releases auf GitHub

Aktuell ist nur Version 2.1.0 als Release auf GitHub verfügbar, obwohl bereits Version 2.6.0 existiert.

## Lösung: Releases für alle Versionen erstellen

### Option 1: Mit dem Script (empfohlen)

```bash
# Für jede Version:
./create-release.sh v2.2.0
./create-release.sh v2.3.0
./create-release.sh v2.4.0
./create-release.sh v2.5.0
./create-release.sh v2.6.0
```

**Voraussetzung:** GitHub CLI (`gh`) muss installiert und authentifiziert sein:
```bash
sudo pacman -S github-cli
gh auth login
```

### Option 2: Manuell auf GitHub

1. Gehe zu: https://github.com/SunnyCueq/cachyos-multi-updater/releases/new
2. Für jede Version:
   - Wähle Tag: `v2.2.0`, `v2.3.0`, `v2.4.0`, `v2.5.0`, `v2.6.0`
   - Titel: `Version 2.2.0`, `Version 2.3.0`, etc.
   - Beschreibung: Kopiere den Changelog aus `README.md` für die jeweilige Version
   - Klicke "Publish release"

### Option 3: Mit GitHub CLI direkt

```bash
# Für jede Version (Changelog aus README.md kopieren):
gh release create v2.2.0 --title "Version 2.2.0" --notes "Changelog hier..."
gh release create v2.3.0 --title "Version 2.3.0" --notes "Changelog hier..."
gh release create v2.4.0 --title "Version 2.4.0" --notes "Changelog hier..."
gh release create v2.5.0 --title "Version 2.5.0" --notes "Changelog hier..."
gh release create v2.6.0 --title "Version 2.6.0" --notes "Changelog hier..."
```

## Wichtige Regel

**Nach jedem Tag MUSS ein GitHub Release erstellt werden!**

Dies ist jetzt eine verbindliche Regel in `rules.md`.

## Zukünftige Releases

Für zukünftige Releases:

1. Tag erstellen: `git tag -a vX.Y.Z -m "Version X.Y.Z"`
2. Tag pushen: `git push origin vX.Y.Z`
3. **Release erstellen:**
   - Mit Script: `./create-release.sh vX.Y.Z`
   - Oder manuell auf GitHub
   - Oder mit GitHub CLI

## Changelog aus README extrahieren

Der Changelog für jede Version steht in `README.md` und `README.de.md` im Abschnitt "📅 Changelog".

Kopiere den entsprechenden Abschnitt für die Release-Notizen.

