#!/bin/bash
# Synchronisiert die Desktop-Datei mit der GitHub-Version
# Dieses Script sollte nach jedem Pull/Update ausgeführt werden

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_SOURCE="$SCRIPT_DIR/update-all.desktop"
DESKTOP_TARGET="$HOME/.local/share/applications/update-all.desktop"
SCRIPT_PATH="/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater/update-all.sh"

if [ ! -f "$DESKTOP_SOURCE" ]; then
    echo "❌ Desktop-Datei nicht gefunden: $DESKTOP_SOURCE"
    exit 1
fi

# Erstelle Ziel-Verzeichnis falls nicht vorhanden
mkdir -p "$(dirname "$DESKTOP_TARGET")"

# Kopiere Desktop-Datei
cp "$DESKTOP_SOURCE" "$DESKTOP_TARGET"

# Passe den Exec-Befehl an
sed -i "s|Exec=bash -c \"cd '%k' && ./update-all.sh\"|Exec=bash -c \"cd '$SCRIPT_PATH' && ./update-all.sh\"|g" "$DESKTOP_TARGET"
sed -i "s|Exec=bash -c \"cd '/mnt/ssd2/Backup (SSD2)/Tools/CachyOS MultiUpdater' && ./update-all.sh\"|Exec=bash -c \"cd '$SCRIPT_PATH' && ./update-all.sh\"|g" "$DESKTOP_TARGET"

# Setze korrekten Pfad
sed -i "s|Path=%k|Path=$(dirname "$SCRIPT_PATH")|g" "$DESKTOP_TARGET" 2>/dev/null || true

echo "✅ Desktop-Datei synchronisiert: $DESKTOP_TARGET"
echo "📍 Script-Pfad: $SCRIPT_PATH"

