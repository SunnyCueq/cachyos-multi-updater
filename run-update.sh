#!/bin/bash
# Wrapper-Script zum Ausführen von update-all.sh mit Terminal offen halten
# Wird von Desktop-Dateien verwendet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/update-all.sh"
UPDATE_MODE="${1:-}"

# Führe das Update-Script aus
if [ -n "$UPDATE_MODE" ]; then
    "$UPDATE_SCRIPT" "$UPDATE_MODE"
else
    "$UPDATE_SCRIPT"
fi

EXIT_CODE=$?

# Terminal offen halten - IMMER
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Update erfolgreich abgeschlossen!"
else
    echo "❌ Update mit Fehler beendet (Exit-Code: $EXIT_CODE)"
fi
echo ""
read -p "Drücke Enter zum Beenden..." || sleep 5

exit $EXIT_CODE

