#!/bin/bash
# Script zum Erstellen eines GitHub Releases
# Verwendung: ./create-release.sh v2.6.0

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "❌ Fehler: Keine Version angegeben"
    echo "Verwendung: ./create-release.sh v2.6.0"
    exit 1
fi

VERSION="$1"
# Entferne 'v' Präfix falls vorhanden
VERSION_NUMBER=$(echo "$VERSION" | sed 's/^v//')
REPO="SunnyCueq/cachyos-multi-updater"

echo "📦 Erstelle GitHub Release für Version $VERSION..."

# Prüfe ob Tag existiert
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Fehler: Tag $VERSION existiert nicht!"
    echo "Erstelle zuerst den Tag: git tag -a $VERSION -m 'Version $VERSION_NUMBER'"
    exit 1
fi

# Prüfe ob Tag bereits gepusht wurde
if ! git ls-remote --tags origin | grep -q "refs/tags/$VERSION"; then
    echo "❌ Fehler: Tag $VERSION wurde noch nicht zu GitHub gepusht!"
    echo "Pushe zuerst den Tag: git push origin $VERSION"
    exit 1
fi

# Extrahiere Changelog aus CHANGELOG.md
echo "📝 Extrahiere Changelog aus CHANGELOG.md..."
CHANGELOG=$(awk "/^## \[$VERSION_NUMBER\]/,/^## \[/" CHANGELOG.md | head -n -1 || echo "Version $VERSION_NUMBER")

if [ -z "$CHANGELOG" ] || [ "$CHANGELOG" = "Version $VERSION_NUMBER" ]; then
    echo "⚠️  Warnung: Changelog nicht gefunden, verwende Standard-Text"
    CHANGELOG="Version $VERSION_NUMBER

Siehe CHANGELOG.md für vollständigen Changelog."
fi

# Erstelle Release mit GitHub CLI (gh) falls verfügbar
if command -v gh >/dev/null 2>&1; then
    echo "✅ Verwende GitHub CLI (gh)..."
    gh release create "$VERSION" \
        --title "Version $VERSION_NUMBER" \
        --notes "$CHANGELOG" \
        --repo "$REPO"
    echo "✅ Release erstellt!"
else
    echo "⚠️  GitHub CLI (gh) nicht gefunden"
    echo ""
    echo "Option 1: GitHub CLI installieren und verwenden:"
    echo "  sudo pacman -S github-cli"
    echo "  gh auth login"
    echo "  gh release create $VERSION --title 'Version $VERSION_NUMBER' --notes '$CHANGELOG'"
    echo ""
    echo "Option 2: Manuell auf GitHub erstellen:"
    echo "  1. Gehe zu: https://github.com/$REPO/releases/new"
    echo "  2. Wähle Tag: $VERSION"
    echo "  3. Titel: Version $VERSION_NUMBER"
    echo "  4. Beschreibung: Kopiere Changelog aus CHANGELOG.md"
    echo "  5. Klicke 'Publish release'"
    echo ""
    echo "Option 3: Mit curl (benötigt GitHub Token):"
    echo "  export GITHUB_TOKEN=dein_token"
    echo "  curl -X POST https://api.github.com/repos/$REPO/releases \\"
    echo "    -H \"Authorization: token \$GITHUB_TOKEN\" \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -d '{\"tag_name\":\"$VERSION\",\"name\":\"Version $VERSION_NUMBER\",\"body\":\"$CHANGELOG\"}'"
fi

