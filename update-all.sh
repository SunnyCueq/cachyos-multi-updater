#!/bin/bash
# Smarter Update: CachyOS + AUR + Cursor + AdGuardHome
# Verbesserte Version mit Logging und Error Handling

set -euo pipefail

# ========== Version ==========
SCRIPT_VERSION="2.5.0"
GITHUB_REPO="SunnyCueq/cachyos-multi-updater"

# ========== Konfiguration ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"
MAX_LOG_FILES=10
LOCK_FILE="$SCRIPT_DIR/.update-all.lock"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Default-Werte
UPDATE_SYSTEM=true
UPDATE_AUR=true
UPDATE_CURSOR=true
UPDATE_ADGUARD=true
DRY_RUN=false
ENABLE_NOTIFICATIONS=true
ENABLE_COLORS=true
DOWNLOAD_RETRIES=3
ENABLE_AUTO_UPDATE=false

# Tracking-Variablen für Zusammenfassung
START_TIME=$(date +%s)
SYSTEM_UPDATED=false
AUR_UPDATED=false
CURSOR_UPDATED=false
ADGUARD_UPDATED=false
SYSTEM_PACKAGES=0
AUR_PACKAGES=0

# Cache-Verzeichnis für Versions-Checks
CACHE_DIR="$SCRIPT_DIR/.cache"
VERSION_CACHE_FILE="$CACHE_DIR/version_cache.json"
CACHE_MAX_AGE=3600  # 1 Stunde

# Log-Verzeichnis erstellen
mkdir -p "$LOG_DIR"
mkdir -p "$CACHE_DIR"

# ========== Lock-File prüfen ==========
if [ -f "$LOCK_FILE" ]; then
    echo "❌ Update läuft bereits! Lock-File gefunden: $LOCK_FILE"
    echo "   Falls kein Update läuft, lösche die Lock-Datei manuell."
    exit 1
fi

# Lock-File erstellen
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# ========== Konfigurationsdatei laden ==========
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source config file (sicher laden)
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Ignoriere Kommentare und leere Zeilen
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Entferne führende/trailing Whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Setze Variablen
            case "$key" in
                ENABLE_SYSTEM_UPDATE) UPDATE_SYSTEM=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ENABLE_AUR_UPDATE) UPDATE_AUR=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ENABLE_CURSOR_UPDATE) UPDATE_CURSOR=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ENABLE_ADGUARD_UPDATE) UPDATE_ADGUARD=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                DRY_RUN) DRY_RUN=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ENABLE_NOTIFICATIONS) ENABLE_NOTIFICATIONS=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                MAX_LOG_FILES) MAX_LOG_FILES="$value" ;;
                ENABLE_COLORS) ENABLE_COLORS=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                DOWNLOAD_RETRIES) DOWNLOAD_RETRIES="$value" ;;
                ENABLE_AUTO_UPDATE) ENABLE_AUTO_UPDATE=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
            esac
        done < "$CONFIG_FILE"
    fi
}

load_config

# ========== Kommandozeilen-Argumente ==========
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --only-system)
                UPDATE_AUR=false
                UPDATE_CURSOR=false
                UPDATE_ADGUARD=false
                shift
                ;;
            --only-aur)
                UPDATE_SYSTEM=false
                UPDATE_CURSOR=false
                UPDATE_ADGUARD=false
                shift
                ;;
            --only-cursor)
                UPDATE_SYSTEM=false
                UPDATE_AUR=false
                UPDATE_ADGUARD=false
                shift
                ;;
            --only-adguard)
                UPDATE_SYSTEM=false
                UPDATE_AUR=false
                UPDATE_CURSOR=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                echo "CachyOS Multi-Updater"
                echo "Version: $SCRIPT_VERSION"
                echo ""
                echo "Verwendung: $0 [OPTIONEN]"
                echo ""
                echo "Optionen:"
                echo "  --only-system      Nur System-Updates (CachyOS)"
                echo "  --only-aur         Nur AUR-Updates"
                echo "  --only-cursor      Nur Cursor-Update"
                echo "  --only-adguard     Nur AdGuard Home-Update"
                echo "  --dry-run          Zeigt was gemacht würde, ohne Änderungen"
                echo "  --version, -v      Zeigt die Versionsnummer"
                echo "  --help, -h         Zeigt diese Hilfe"
                echo ""
                exit 0
                ;;
            --version|-v)
                echo "CachyOS Multi-Updater Version $SCRIPT_VERSION"
                exit 0
                ;;
            *)
                echo "❌ Unbekannte Option: $1"
                echo "Verwende --help für Hilfe"
                exit 1
                ;;
        esac
    done
}

parse_args "$@"

# ========== Dry-Run Anzeige ==========
if [ "$DRY_RUN" = "true" ]; then
    echo "🔍 DRY-RUN MODUS: Es werden keine Änderungen vorgenommen!"
    echo ""
    echo "Geplante Updates:"
    [ "$UPDATE_SYSTEM" = "true" ] && echo "  ✅ System-Updates (CachyOS)"
    [ "$UPDATE_AUR" = "true" ] && echo "  ✅ AUR-Updates"
    [ "$UPDATE_CURSOR" = "true" ] && echo "  ✅ Cursor-Update"
    [ "$UPDATE_ADGUARD" = "true" ] && echo "  ✅ AdGuard Home-Update"
    echo ""
fi

# ========== Farben (optional) ==========
if [ "$ENABLE_COLORS" = "true" ] && [ -t 1 ]; then
    COLOR_RESET='\033[0m'
    COLOR_INFO='\033[0;36m'      # Cyan
    COLOR_SUCCESS='\033[0;32m'   # Green
    COLOR_ERROR='\033[0;31m'     # Red
    COLOR_WARNING='\033[0;33m'   # Yellow
    COLOR_BOLD='\033[1m'         # Bold
else
    COLOR_RESET=''
    COLOR_INFO=''
    COLOR_SUCCESS=''
    COLOR_ERROR=''
    COLOR_WARNING=''
    COLOR_BOLD=''
fi

# ========== Logging-Funktionen ==========
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
    echo -e "${COLOR_INFO}ℹ️  $*${COLOR_RESET}"
}

log_success() {
    log "SUCCESS" "$@"
    echo -e "${COLOR_SUCCESS}✅ $*${COLOR_RESET}"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${COLOR_ERROR}❌ $*${COLOR_RESET}" >&2
}

log_warning() {
    log "WARNING" "$@"
    echo -e "${COLOR_WARNING}⚠️  $*${COLOR_RESET}"
}

# ========== Error Handling ==========
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script wurde mit Fehler beendet (Exit-Code: $exit_code)"
        notify-send "Update fehlgeschlagen!" "Bitte Logs prüfen: $LOG_FILE" 2>/dev/null || true
    fi
    return $exit_code
}

trap cleanup_on_error EXIT

# ========== Retry-Funktion für Downloads ==========
download_with_retry() {
    local url="$1"
    local output_file="$2"
    local max_retries="${DOWNLOAD_RETRIES:-3}"
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -L -f --progress-bar -o "$output_file" "$url" 2>&1 | tee -a "$LOG_FILE"; then
            return 0
        fi
        
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            log_warning "Download fehlgeschlagen, Versuch $retry/$max_retries..."
            sleep 2
        else
            log_error "Download nach $max_retries Versuchen fehlgeschlagen!"
            return 1
        fi
    done
}

# ========== Cache-Funktionen für Versions-Checks ==========
get_cached_version() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/${cache_key}_version.cache"
    if [ -f "$cache_file" ]; then
        local cache_time=$(head -1 "$cache_file" 2>/dev/null || echo "0")
        local cached_version=$(tail -n +2 "$cache_file" 2>/dev/null || echo "")
        local current_time=$(date +%s)
        if [ -n "$cached_version" ] && [ $((current_time - cache_time)) -lt $CACHE_MAX_AGE ]; then
            echo "$cached_version"
        fi
    fi
}

set_cached_version() {
    local cache_key="$1"
    local version="$2"
    local cache_file="$CACHE_DIR/${cache_key}_version.cache"
    echo "$(date +%s)" > "$cache_file"
    echo "$version" >> "$cache_file"
}

# ========== Alte Logs aufräumen ==========
cleanup_old_logs() {
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "update-*.log" -type f | sort -r | tail -n +$((MAX_LOG_FILES + 1)) | xargs rm -f 2>/dev/null || true
    fi
}

cleanup_old_logs

log_info "CachyOS Multi-Updater Version $SCRIPT_VERSION"
log_info "Update gestartet..."
log_info "Log-Datei: $LOG_FILE"
[ "$DRY_RUN" = "true" ] && log_info "DRY-RUN Modus aktiviert"
[ "$ENABLE_COLORS" = "true" ] && log_info "Farbige Ausgabe aktiviert"
echo -e "${COLOR_BOLD}🛡️  Update gestartet... (Passwort für sudo eingeben)${COLOR_RESET}"

# ========== CachyOS updaten ==========
if [ "$UPDATE_SYSTEM" = "true" ]; then
    log_info "Starte CachyOS-Update..."
    echo "📦 CachyOS-Repos updaten..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Würde ausführen: sudo pacman -Syu --noconfirm"
        echo "🔍 [DRY-RUN] System-Update würde durchgeführt"
    else
        if sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"; then
            SYSTEM_UPDATED=true
            # Zähle Pakete, die Updates haben (nach dem Update sollten es 0 sein, aber wir prüfen vorher)
            SYSTEM_PACKAGES=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
            # Wenn 0, bedeutet das alles ist aktuell
            if [ "$SYSTEM_PACKAGES" -eq 0 ]; then
                SYSTEM_PACKAGES="0 (bereits aktuell)"
            fi
            log_success "CachyOS-Update erfolgreich"
        else
            log_error "Pacman-Update fehlgeschlagen!"
            exit 1
        fi
    fi
else
    log_info "System-Update übersprungen (deaktiviert)"
fi

# ========== AUR updaten ==========
if [ "$UPDATE_AUR" = "true" ]; then
    log_info "Starte AUR-Update..."
    echo "🔧 AUR updaten..."
    
    if [ "$DRY_RUN" = "true" ]; then
        if command -v yay >/dev/null 2>&1; then
            log_info "[DRY-RUN] Würde ausführen: yay -Syu --noconfirm"
        elif command -v paru >/dev/null 2>&1; then
            log_info "[DRY-RUN] Würde ausführen: paru -Syu --noconfirm"
        else
            log_warning "[DRY-RUN] Kein AUR-Helper gefunden"
        fi
        echo "🔍 [DRY-RUN] AUR-Update würde durchgeführt"
    else
        if command -v yay >/dev/null 2>&1; then
            log_info "Verwende yay als AUR-Helper"
            if yay -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE" | grep -v "error occurred" || true; then
                AUR_UPDATED=true
                AUR_PACKAGES=$(yay -Qu 2>/dev/null | wc -l || echo "0")
                log_success "AUR-Update mit yay erfolgreich"
            else
                log_warning "AUR-Update mit yay hatte Warnungen"
            fi
        elif command -v paru >/dev/null 2>&1; then
            log_info "Verwende paru als AUR-Helper"
            if paru -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE" | grep -v "error occurred" || true; then
                AUR_UPDATED=true
                AUR_PACKAGES=$(paru -Qu 2>/dev/null | wc -l || echo "0")
                log_success "AUR-Update mit paru erfolgreich"
            else
                log_warning "AUR-Update mit paru hatte Warnungen"
            fi
        else
            log_warning "Kein AUR-Helper (yay/paru) gefunden – überspringe AUR."
        fi
    fi
else
    log_info "AUR-Update übersprungen (deaktiviert)"
fi

# ========== Cursor updaten ==========
if [ "$UPDATE_CURSOR" = "true" ]; then
    log_info "Starte Cursor-Update..."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🖱️  Cursor Update"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$DRY_RUN" = "true" ]; then
        if command -v cursor >/dev/null 2>&1; then
            CURRENT_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unbekannt")
            log_info "[DRY-RUN] Aktuelle Cursor-Version: $CURRENT_VERSION"
            log_info "[DRY-RUN] Würde Cursor herunterladen und aktualisieren"
            echo "🔍 [DRY-RUN] Cursor-Update würde durchgeführt"
        else
            log_warning "[DRY-RUN] Cursor nicht gefunden"
        fi
    elif ! command -v cursor >/dev/null 2>&1; then
        log_warning "Cursor nicht gefunden – bitte manuell installieren!"
        echo "⚠️  Cursor nicht gefunden – bitte manuell installieren!"
    else
        # Prüfe, ob Cursor über pacman installiert ist
        if pacman -Q cursor 2>/dev/null | grep -q cursor; then
            CURSOR_PACMAN_VERSION=$(pacman -Q cursor | awk '{print $2}')
            log_info "Cursor ist über pacman installiert (Version: $CURSOR_PACMAN_VERSION)"
            echo "ℹ️  Cursor ist über pacman installiert (Version: $CURSOR_PACMAN_VERSION)"
            echo "   → Cursor wird automatisch über System-Updates aktualisiert"
            echo "   → Manuelles Update nicht nötig (deaktiviere ENABLE_CURSOR_UPDATE in config.conf)"
            log_info "Cursor-Update übersprungen (wird über pacman verwaltet)"
        else
            # Cursor-Pfad finden
            CURSOR_PATH=$(which cursor)
            CURSOR_INSTALL_DIR=$(dirname "$(readlink -f "$CURSOR_PATH")")
            
            log_info "Cursor gefunden in: $CURSOR_INSTALL_DIR"
            echo "📍 Installationspfad: $CURSOR_INSTALL_DIR"
            
            # Aktuelle Version ermitteln
            CURRENT_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unbekannt")
            log_info "Aktuelle Cursor-Version: $CURRENT_VERSION"
            echo "📌 Aktuelle Version: $CURRENT_VERSION"
            
            # Prüfe neueste verfügbare Version (ohne Download)
            log_info "Prüfe verfügbare Cursor-Version..."
            echo "🔍 Prüfe verfügbare Version..."
            LATEST_VERSION_INFO=$(curl -sL "https://api2.cursor.sh/updates/check?platform=linux-x64-deb&version=$CURRENT_VERSION" 2>/dev/null || echo "")
            if [ -n "$LATEST_VERSION_INFO" ]; then
                LATEST_VERSION=$(echo "$LATEST_VERSION_INFO" | grep -oP '"version":\s*"\K[0-9.]+' | head -1 || echo "")
                if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
                    echo "📥 Verfügbare Version: $LATEST_VERSION"
                    log_info "Neue Version verfügbar: $CURRENT_VERSION → $LATEST_VERSION"
                elif [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
                    echo "✅ Cursor ist bereits auf dem neuesten Stand ($CURRENT_VERSION)"
                    log_info "Cursor ist bereits aktuell, Update übersprungen"
                else
                    echo "⚠️  Versionsprüfung fehlgeschlagen, fahre mit Update fort..."
                    log_warning "Versionsprüfung fehlgeschlagen"
                fi
            fi
            
            # Download .deb in Script-Ordner
            DEB_FILE="$SCRIPT_DIR/cursor_latest_amd64.deb"
            DOWNLOAD_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.0"
            
            log_info "Lade Cursor .deb von: $DOWNLOAD_URL"
            echo "⬇️  Lade Cursor .deb..."
            
            if ! download_with_retry "$DOWNLOAD_URL" "$DEB_FILE"; then
                log_error "Cursor-Download fehlgeschlagen!"
                echo "❌ Download fehlgeschlagen!"
                rm -f "$DEB_FILE"
            else
                # Prüfe Download
                if [[ -f "$DEB_FILE" ]] && [[ $(stat -c%s "$DEB_FILE") -gt 50000000 ]]; then
                    DEB_SIZE=$(du -h "$DEB_FILE" | cut -f1)
                    log_success "Download erfolgreich: $DEB_SIZE"
                    echo "✅ Download erfolgreich: $DEB_SIZE"
                    
                    # Cursor-Prozesse sicher beenden
                    log_info "Beende Cursor-Prozesse..."
                    echo "🔒 Schließe Cursor..."
                    
                    # Besseres Cursor-Kill mit pkill
                    CURSOR_PIDS=$(pgrep -f "cursor" | grep -v "$$" || true)
                    if [ -n "$CURSOR_PIDS" ]; then
                        log_info "Gefundene Cursor-Prozesse: $CURSOR_PIDS"
                        # Versuche sanftes Beenden
                        pkill -TERM -f "cursor" 2>/dev/null || true
                        
                        # Warte bis Prozesse beendet sind (max. 10 Sekunden)
                        for i in {1..10}; do
                            if ! pgrep -f "cursor" >/dev/null 2>&1; then
                                log_success "Alle Cursor-Prozesse beendet"
                                echo "✅ Cursor geschlossen"
                                break
                            fi
                            sleep 1
                        done
                        
                        # Falls noch Prozesse laufen, force kill
                        if pgrep -f "cursor" >/dev/null 2>&1; then
                            log_warning "Force-Kill von Cursor-Prozessen..."
                            echo "⚠️  Force-Kill erforderlich..."
                            pkill -9 -f "cursor" 2>/dev/null || true
                            sleep 2
                        fi
                    else
                        log_info "Keine laufenden Cursor-Prozesse gefunden"
                        echo "ℹ️  Cursor läuft nicht"
                    fi
                    
                    # Extrahiere .deb
                    EXTRACT_DIR="$SCRIPT_DIR/cursor-extract"
                    rm -rf "$EXTRACT_DIR"
                    mkdir -p "$EXTRACT_DIR"
                    
                    log_info "Extrahiere Cursor .deb..."
                    echo "📦 Extrahiere .deb-Archiv..."
                    cd "$EXTRACT_DIR"
                    
                    if ! ar x "$DEB_FILE" 2>&1 | tee -a "$LOG_FILE"; then
                        log_error "Fehler beim Extrahieren des .deb-Archivs"
                        echo "❌ Fehler beim Extrahieren!"
                        rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                    elif ! tar -xf data.tar.* 2>&1 | tee -a "$LOG_FILE"; then
                        log_error "Fehler beim Extrahieren der Daten"
                        echo "❌ Fehler beim Extrahieren der Daten!"
                        rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                    else
                        # Finde Cursor-Binary und Ressourcen
                        INSTALL_SUCCESS=false
                        
                        if [[ -d "opt/Cursor" ]]; then
                            log_info "Installiere Cursor-Update (opt/Cursor)..."
                            echo "📦 Installiere Update..."
                            if sudo cp -rf opt/Cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert"
                                INSTALL_SUCCESS=true
                            elif sudo cp -rf opt/Cursor/* "$(dirname "$CURSOR_INSTALL_DIR")/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$(dirname "$CURSOR_INSTALL_DIR")/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert (alternativer Pfad)"
                                INSTALL_SUCCESS=true
                            elif sudo cp -rf opt/Cursor /opt/ 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x /opt/Cursor/cursor 2>/dev/null || true
                                log_success "Cursor-Update installiert (nach /opt)"
                                INSTALL_SUCCESS=true
                            fi
                        elif [[ -d "usr/share/cursor" ]]; then
                            log_info "Installiere Cursor-Update (usr/share/cursor)..."
                            echo "📦 Installiere Update (usr-Variante)..."
                            if sudo cp -rf usr/share/cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert"
                                INSTALL_SUCCESS=true
                            fi
                        fi
                        
                        # Cleanup IMMER durchführen
                        log_info "Bereinige temporäre Dateien..."
                        rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                        log_info "Temporäre Dateien gelöscht"
                        
                        if [ "$INSTALL_SUCCESS" = "true" ]; then
                            # Neue Version prüfen
                            sleep 1
                            NEW_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "installiert")
                            CURSOR_UPDATED=true
                            log_success "Cursor updated: $CURRENT_VERSION → $NEW_VERSION"
                            echo "✅ Cursor aktualisiert: $CURRENT_VERSION → $NEW_VERSION"
                            
                            # Cursor neu starten (optional, nicht blockierend)
                            log_info "Starte Cursor neu..."
                            echo "🚀 Starte Cursor..."
                            sleep 1
                            if command -v cursor >/dev/null 2>&1; then
                                nohup cursor > /dev/null 2>&1 &
                                sleep 2
                                if pgrep -f "cursor" >/dev/null 2>&1; then
                                    log_success "Cursor gestartet"
                                    echo "✅ Cursor gestartet"
                                else
                                    log_warning "Cursor konnte nicht automatisch gestartet werden (bitte manuell starten)"
                                    echo "⚠️  Cursor konnte nicht automatisch gestartet werden"
                                fi
                            fi
                        else
                            log_error "Cursor-Dateien nicht gefunden im .deb oder Installation fehlgeschlagen!"
                            echo "❌ Installation fehlgeschlagen!"
                        fi
                    fi
                else
                    log_error "Download zu klein oder fehlgeschlagen!"
                    echo "❌ Download zu klein oder fehlgeschlagen!"
                    rm -f "$DEB_FILE"
                fi
            fi
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
fi

# ========== AdGuardHome updaten ==========
if [ "$UPDATE_ADGUARD" = "true" ]; then
    log_info "Starte AdGuardHome-Update..."
    echo "🛡️ AdGuardHome updaten..."
    AGH_DIR="$HOME/AdGuardHome"
    TEMP_DIR="/tmp/AdGuardHome-$(date +%s)"
    
    if [ "$DRY_RUN" = "true" ]; then
        if [[ -f "$AGH_DIR/AdGuardHome" ]]; then
            CURRENT_VERSION=$(./AdGuardHome --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
            log_info "[DRY-RUN] Aktuelle AdGuard-Version: v$CURRENT_VERSION"
            log_info "[DRY-RUN] Würde AdGuard Home aktualisieren"
            echo "🔍 [DRY-RUN] AdGuard Home-Update würde durchgeführt"
        else
            log_warning "[DRY-RUN] AdGuard Home nicht gefunden"
        fi
    elif [[ -f "$AGH_DIR/AdGuardHome" ]]; then
        mkdir -p "$TEMP_DIR"
        cd "$AGH_DIR"
        
        log_info "Stoppe AdGuardHome-Service..."
        systemctl --user stop AdGuardHome 2>&1 | tee -a "$LOG_FILE" || log_warning "AdGuardHome-Service konnte nicht gestoppt werden"
        
        CURRENT_VERSION=$(./AdGuardHome --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
        log_info "Aktuelle AdGuard-Version: v$CURRENT_VERSION"
        echo "Aktuelle AdGuard-Version: v$CURRENT_VERSION"
        
        BACKUP_DIR="$AGH_DIR-backup-$(date +%Y%m%d)"
        mkdir -p "$BACKUP_DIR"
        cp AdGuardHome.yaml data/* "$BACKUP_DIR/" 2>/dev/null || log_warning "Backup konnte nicht erstellt werden"
        log_info "Backup erstellt in: $BACKUP_DIR"
        
        DOWNLOAD_URL="https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz"
        log_info "Lade AdGuardHome von: $DOWNLOAD_URL"
        
        if download_with_retry "$DOWNLOAD_URL" "$TEMP_DIR/AdGuardHome.tar.gz"; then
            if [[ -f "$TEMP_DIR/AdGuardHome.tar.gz" ]]; then
                if tar -C "$TEMP_DIR" -xzf "$TEMP_DIR/AdGuardHome.tar.gz" 2>&1 | tee -a "$LOG_FILE"; then
                    NEW_BINARY="$TEMP_DIR/AdGuardHome/AdGuardHome"
                    if [[ -f "$NEW_BINARY" ]]; then
                        NEW_VERSION=$("$NEW_BINARY" --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
                        if [[ "$NEW_VERSION" > "$CURRENT_VERSION" ]]; then
                            if cp "$NEW_BINARY" "$AGH_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                ADGUARD_UPDATED=true
                                log_success "AdGuardHome updated: v$CURRENT_VERSION → v$NEW_VERSION"
                                echo "✅ AdGuardHome updated: v$CURRENT_VERSION → v$NEW_VERSION"
                            else
                                log_error "Fehler beim Kopieren der neuen AdGuardHome-Binary"
                            fi
                        else
                            log_info "AdGuardHome ist bereits aktuell (v$NEW_VERSION)"
                            echo "ℹ️ AdGuardHome ist aktuell (v$NEW_VERSION)."
                        fi
                    else
                        log_error "AdGuardHome-Binary nicht im Archiv gefunden"
                    fi
                else
                    log_error "Fehler beim Extrahieren von AdGuardHome"
                fi
            fi
            rm -rf "$TEMP_DIR"
        else
            log_error "AdGuardHome-Download fehlgeschlagen!"
            rm -rf "$TEMP_DIR"
        fi
        
        log_info "Starte AdGuardHome-Service..."
        if systemctl --user start AdGuardHome 2>&1 | tee -a "$LOG_FILE"; then
            sleep 2
            if systemctl --user is-active --quiet AdGuardHome; then
                log_success "AdGuardHome-Service läuft erfolgreich"
            else
                log_warning "AdGuardHome-Service gestartet, aber Status unklar"
            fi
        else
            log_warning "AdGuardHome-Service konnte nicht gestartet werden"
        fi
    else
        log_warning "AdGuardHome Binary nicht gefunden in: $AGH_DIR"
        echo "⚠️ AdGuardHome Binary nicht gefunden."
    fi
else
    log_info "AdGuard Home-Update übersprungen (deaktiviert)"
fi

# ========== Cleanup ==========
if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Würde System-Cleanup durchführen"
    echo "🔍 [DRY-RUN] Cleanup würde durchgeführt"
else
    log_info "Starte System-Cleanup..."
    echo "🧹 Cleanup..."
    paccache -rk3 2>&1 | tee -a "$LOG_FILE" || log_warning "Paccache fehlgeschlagen"
    sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null 2>&1 | tee -a "$LOG_FILE" || log_warning "Orphan-Pakete konnten nicht entfernt werden"
fi

# ========== Zusammenfassung ==========
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

if [ "$DRY_RUN" = "true" ]; then
    log_info "DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
    echo "🔍 DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${COLOR_BOLD}📊 Update-Zusammenfassung${COLOR_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Dauer
    if [ $MINUTES -gt 0 ]; then
        echo -e "⏱️  ${COLOR_INFO}Dauer:${COLOR_RESET} ${MINUTES}m ${SECONDS}s"
    else
        echo -e "⏱️  ${COLOR_INFO}Dauer:${COLOR_RESET} ${SECONDS}s"
    fi
    echo ""
    
    # System-Updates
    if [ "$UPDATE_SYSTEM" = "true" ]; then
        if [ "$SYSTEM_UPDATED" = "true" ]; then
            echo -e "✅ ${COLOR_SUCCESS}System-Updates:${COLOR_RESET} Erfolgreich"
            if [ "$SYSTEM_PACKAGES" != "0 (bereits aktuell)" ] && [ "$SYSTEM_PACKAGES" -gt 0 ]; then
                echo "   📦 $SYSTEM_PACKAGES Pakete aktualisiert"
            else
                echo "   ℹ️  Bereits auf dem neuesten Stand"
            fi
        else
            echo -e "❌ ${COLOR_ERROR}System-Updates:${COLOR_RESET} Fehlgeschlagen oder übersprungen"
        fi
    else
        echo -e "⏭️  ${COLOR_WARNING}System-Updates:${COLOR_RESET} Deaktiviert"
    fi
    echo ""
    
    # AUR-Updates
    if [ "$UPDATE_AUR" = "true" ]; then
        if [ "$AUR_UPDATED" = "true" ]; then
            echo -e "✅ ${COLOR_SUCCESS}AUR-Updates:${COLOR_RESET} Erfolgreich"
            if [ -n "$AUR_PACKAGES" ] && [ "$AUR_PACKAGES" -gt 0 ] 2>/dev/null; then
                echo "   📦 $AUR_PACKAGES Pakete aktualisiert"
            else
                echo "   ℹ️  Bereits auf dem neuesten Stand"
            fi
        else
            echo -e "❌ ${COLOR_ERROR}AUR-Updates:${COLOR_RESET} Fehlgeschlagen oder übersprungen"
        fi
    else
        echo -e "⏭️  ${COLOR_WARNING}AUR-Updates:${COLOR_RESET} Deaktiviert"
    fi
    echo ""
    
    # Cursor
    if [ "$UPDATE_CURSOR" = "true" ]; then
        if [ "$CURSOR_UPDATED" = "true" ]; then
            echo -e "✅ ${COLOR_SUCCESS}Cursor:${COLOR_RESET} Aktualisiert"
        else
            echo -e "⏭️  ${COLOR_WARNING}Cursor:${COLOR_RESET} Übersprungen oder bereits aktuell"
        fi
    else
        echo -e "⏭️  ${COLOR_WARNING}Cursor:${COLOR_RESET} Deaktiviert"
    fi
    echo ""
    
    # AdGuard Home
    if [ "$UPDATE_ADGUARD" = "true" ]; then
        if [ "$ADGUARD_UPDATED" = "true" ]; then
            echo -e "✅ ${COLOR_SUCCESS}AdGuard Home:${COLOR_RESET} Aktualisiert"
        else
            echo -e "⏭️  ${COLOR_WARNING}AdGuard Home:${COLOR_RESET} Übersprungen oder bereits aktuell"
        fi
    else
        echo -e "⏭️  ${COLOR_WARNING}AdGuard Home:${COLOR_RESET} Deaktiviert"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_success "Alle Updates abgeschlossen!"
    echo -e "${COLOR_BOLD}🎉 Alles up-to-date!${COLOR_RESET}"
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "Update fertig!" "Dauer: ${MINUTES}m ${SECONDS}s" 2>/dev/null || true
    fi
fi

# ========== Script-Update-Check ==========
check_script_update() {
    if [ "$DRY_RUN" = "true" ]; then
        return 0
    fi
    
    log_info "Prüfe auf Script-Updates..."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Script-Version prüfen..."
    
    # Prüfe Cache zuerst
    CACHED_VERSION=$(get_cached_version "script")
    
    if [ -n "$CACHED_VERSION" ]; then
        LATEST_VERSION="$CACHED_VERSION"
        log_info "Verwende gecachte Version: $LATEST_VERSION"
    else
        # Versuche zuerst Releases, dann Tags
        LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null | grep -oP '"tag_name":\s*"v?\K[0-9.]+' | head -1 || echo "")
        
        # Falls kein Release, prüfe Tags direkt
        if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/git/refs/tags" 2>/dev/null | grep -oP '"ref":\s*"refs/tags/v?\K[0-9.]+' | sort -V | tail -1 || echo "")
        fi
        
        # Cache die Version
        if [ -n "$LATEST_VERSION" ]; then
            set_cached_version "script" "$LATEST_VERSION"
        fi
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        log_warning "Konnte neueste Version nicht abrufen"
        echo "⚠️  Versionsprüfung fehlgeschlagen (keine Internetverbindung?)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 0
    fi
    
    # Entferne 'v' Präfix falls vorhanden
    LATEST_VERSION=$(echo "$LATEST_VERSION" | sed 's/^v//')
    
    # Versionsvergleich (Semantic Versioning wie WoltLab: Major.Minor.Patch)
    if [ "$LATEST_VERSION" != "$SCRIPT_VERSION" ]; then
        # Prüfe ob neue Version wirklich neuer ist (semantischer Vergleich)
        if printf '%s\n%s\n' "$SCRIPT_VERSION" "$LATEST_VERSION" | sort -V | head -1 | grep -q "^$SCRIPT_VERSION$"; then
            log_warning "Neue Script-Version verfügbar: $SCRIPT_VERSION → $LATEST_VERSION"
            echo -e "${COLOR_WARNING}⚠️  Neue Script-Version verfügbar: $SCRIPT_VERSION → $LATEST_VERSION${COLOR_RESET}"
            echo ""
            
            if [ "$ENABLE_AUTO_UPDATE" = "true" ]; then
                echo "   Automatisches Update ist aktiviert."
                read -p "   Script jetzt aktualisieren? (j/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[JjYy]$ ]]; then
                    log_info "Starte automatisches Script-Update..."
                    cd "$SCRIPT_DIR"
                    if git pull origin main 2>&1 | tee -a "$LOG_FILE"; then
                        log_success "Script erfolgreich aktualisiert!"
                        echo -e "${COLOR_SUCCESS}✅ Script erfolgreich aktualisiert!${COLOR_RESET}"
                        echo "   Bitte Script erneut ausführen, um die neue Version zu verwenden."
                    else
                        log_error "Automatisches Update fehlgeschlagen!"
                        echo -e "${COLOR_ERROR}❌ Automatisches Update fehlgeschlagen!${COLOR_RESET}"
                        echo "   Bitte manuell aktualisieren."
                    fi
                else
                    echo "   Update übersprungen."
                fi
            else
                echo "   Update-Optionen:"
                echo "   1. Git: cd $(dirname "$SCRIPT_DIR")/cachyos-multi-updater && git pull"
                echo "   2. Download: https://github.com/$GITHUB_REPO/releases/latest"
                echo "   3. ZIP: https://github.com/$GITHUB_REPO/archive/refs/tags/v$LATEST_VERSION.zip"
                echo ""
                echo "   Tipp: Setze ENABLE_AUTO_UPDATE=true in config.conf für automatische Updates"
            fi
        else
            log_info "Lokale Version ist neuer als GitHub-Version (Entwicklung?)"
            echo "ℹ️  Lokale Version: $SCRIPT_VERSION (GitHub: $LATEST_VERSION)"
        fi
    else
        log_info "Script ist auf dem neuesten Stand (Version $SCRIPT_VERSION)"
        echo "✅ Script ist aktuell (Version $SCRIPT_VERSION)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

check_script_update

log_info "Update-Script erfolgreich beendet"

