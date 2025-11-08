#!/bin/bash
# Helper-Script zum Erstellen einer Desktop-Verknüpfung für update-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/update-all.sh"
DESKTOP_FILE="$SCRIPT_DIR/update-all.desktop"
TARGET_DIR="${1:-$HOME/Schreibtisch}"

# Prüfe ob Script existiert
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Fehler: update-all.sh nicht gefunden in $SCRIPT_DIR" >&2
    exit 1
fi

# Erstelle Desktop-Datei mit absolutem Pfad
# WICHTIG: Terminal explizit öffnen und Script darin ausführen
# Für KDE/Plasma: konsole -e
# Fallback: xterm oder gnome-terminal
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Update All
Comment=Ein-Klick-Update für CachyOS + AUR + Cursor + AdGuard
Exec=konsole -e bash -c "$SCRIPT_PATH; echo ''; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; read -p 'Drücke Enter zum Beenden...'"
Icon=system-software-update
Terminal=false
Type=Application
Categories=System;
EOF

echo "✅ Desktop-Datei erstellt: $DESKTOP_FILE"
echo "   Script-Pfad: $SCRIPT_PATH"

# Kopiere auf Desktop falls gewünscht
if [ -d "$TARGET_DIR" ]; then
    cp "$DESKTOP_FILE" "$TARGET_DIR/"
    chmod +x "$TARGET_DIR/update-all.desktop"
    echo "✅ Desktop-Verknüpfung erstellt: $TARGET_DIR/update-all.desktop"
else
    echo "⚠️  Ziel-Verzeichnis nicht gefunden: $TARGET_DIR"
    echo "   Desktop-Datei wurde nur im Script-Verzeichnis erstellt"
fi

echo ""
echo "Verwendung:"
echo "  - Im Script-Verzeichnis: $DESKTOP_FILE"
echo "  - Auf Desktop: $TARGET_DIR/update-all.desktop (falls kopiert)"

