#!/bin/bash
# Smarter Update: CachyOS + AUR + Cursor + AdGuardHome
# Verbesserte Version mit Logging und Error Handling

set -euo pipefail

# ========== Version ==========
readonly SCRIPT_VERSION="2.7.3"
readonly GITHUB_REPO="SunnyCueq/cachyos-multi-updater"

# ========== Exit-Codes ==========
# EXIT_SUCCESS=0 wird implizit verwendet (exit 0)
# EXIT_LOCK_EXISTS=1 wird implizit verwendet (exit 1)
# EXIT_CONFIG_ERROR=2 wird implizit verwendet (exit 2)
readonly EXIT_DOWNLOAD_ERROR=3
readonly EXIT_UPDATE_ERROR=4

# ========== Konfiguration ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_DIR
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"
readonly LOG_FILE
MAX_LOG_FILES=10
readonly CONFIG_FILE="$SCRIPT_DIR/config.conf"

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

# Snapshot/Backup-Verzeichnis
readonly SNAPSHOT_DIR="$SCRIPT_DIR/.snapshots"
mkdir -p "$SNAPSHOT_DIR"

# Statistiken-Verzeichnis
readonly STATS_DIR="$SCRIPT_DIR/.stats"
readonly STATS_FILE="$STATS_DIR/stats.json"
mkdir -p "$STATS_DIR"

# Log-Verzeichnis erstellen
mkdir -p "$LOG_DIR"

# ========== Config-Validierung ==========
validate_config_value() {
    local key="$1"
    local value="$2"

    case "$key" in
        DRY_RUN|ENABLE_NOTIFICATIONS|ENABLE_COLORS|ENABLE_AUTO_UPDATE)
            if [[ ! "$value" =~ ^(true|false)$ ]]; then
                echo "WARNUNG: Ungültiger Wert für $key: '$value' (erwartet: true/false)" >&2
                return 1
            fi
            ;;
        MAX_LOG_FILES|DOWNLOAD_RETRIES)
            if [[ ! "$value" =~ ^[0-9]+$ ]]; then
                echo "WARNUNG: Ungültiger Wert für $key: '$value' (erwartet: Zahl)" >&2
                return 1
            fi
            ;;
    esac
    return 0
}

# ========== Konfigurationsdatei laden ==========
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        local line_num=0
        # Source config file (sicher laden)
        while IFS='=' read -r key value || [ -n "$key" ]; do
            ((line_num++))
            # Ignoriere Kommentare und leere Zeilen
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue

            # Entferne führende/trailing Whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            # Validiere Wert
            if ! validate_config_value "$key" "$value"; then
                echo "  in Zeile $line_num von $CONFIG_FILE" >&2
                continue
            fi

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
        done < "$CONFIG_FILE" || true
    fi
}

load_config

# ========== Module laden ==========
if [ ! -f "$SCRIPT_DIR/lib/statistics.sh" ]; then
    echo "Fehler: statistics.sh nicht gefunden in $SCRIPT_DIR/lib/" >&2
    exit 1
fi
source "$SCRIPT_DIR/lib/statistics.sh"
source "$SCRIPT_DIR/lib/progress.sh"
source "$SCRIPT_DIR/lib/interactive.sh"

# ========== Kommandozeilen-Argumente ==========
INTERACTIVE_MODE=false

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
            --interactive|-i)
                INTERACTIVE_MODE=true
                shift
                ;;
            --stats)
                show_stats
                exit 0
                ;;
            --help|-h)
                echo "CachyOS Multi-Updater"
                echo "Version: $SCRIPT_VERSION"
                echo ""
                echo "Verwendung: $0 [OPTIONEN]"
                echo ""
                echo "Optionen:"
                echo "  --only-system        Nur System-Updates (CachyOS)"
                echo "  --only-aur           Nur AUR-Updates"
                echo "  --only-cursor        Nur Cursor-Update"
                echo "  --only-adguard       Nur AdGuard Home-Update"
                echo "  --dry-run            Zeigt was gemacht würde, ohne Änderungen"
                echo "  --interactive, -i    Interaktiver Modus (wähle Updates aus)"
                echo "  --stats              Zeige Update-Statistiken"
                echo "  --version, -v        Zeigt die Versionsnummer"
                echo "  --help, -h           Zeigt diese Hilfe"
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

# Interaktiver Modus aktivieren
if [ "$INTERACTIVE_MODE" = "true" ]; then
    interactive_mode
fi

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

# ========== Snapshot/Rollback-Funktionen ==========
create_snapshot() {
    local component="$1"
    local source_dir="$2"
    local snapshot_name
    snapshot_name="$component-$(date +%Y%m%d-%H%M%S)"
    local snapshot_path="$SNAPSHOT_DIR/$snapshot_name"

    if [ ! -d "$source_dir" ]; then
        log_warning "Snapshot für $component übersprungen: Verzeichnis nicht gefunden"
        return 1
    fi

    log_info "Erstelle Snapshot für $component..."
    if cp -a "$source_dir" "$snapshot_path" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Snapshot erstellt: $snapshot_name"
        echo "$snapshot_path"  # Rückgabe des Snapshot-Pfads
        return 0
    else
        log_error "Snapshot-Erstellung fehlgeschlagen für $component"
        return 1
    fi
}

rollback_snapshot() {
    local component="$1"
    local snapshot_path="$2"
    local target_dir="$3"

    if [ ! -d "$snapshot_path" ]; then
        log_error "Snapshot nicht gefunden: $snapshot_path"
        return 1
    fi

    log_warning "Führe Rollback durch für $component..."
    echo "⚠️  Führe Rollback durch: $component"

    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir" 2>&1 | tee -a "$LOG_FILE" || true
    fi

    if cp -a "$snapshot_path" "$target_dir" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Rollback erfolgreich: $component"
        echo "✅ Rollback erfolgreich"
        return 0
    else
        log_error "Rollback fehlgeschlagen: $component"
        echo "❌ Rollback fehlgeschlagen!"
        return 1
    fi
}

cleanup_old_snapshots() {
    local max_snapshots=5
    if [ -d "$SNAPSHOT_DIR" ]; then
        local snapshot_count
        snapshot_count=$(find "$SNAPSHOT_DIR" -maxdepth 1 -type d | wc -l)
        if [ "$snapshot_count" -gt "$max_snapshots" ]; then
            log_info "Bereinige alte Snapshots (behalte $max_snapshots neueste)..."
            find "$SNAPSHOT_DIR" -maxdepth 1 -type d -printf '%T@ %p\n' | sort -n | head -n -$max_snapshots | cut -d' ' -f2- | xargs rm -rf 2>/dev/null || true
        fi
    fi
}

# ========== Update-Zeitplanung prüfen ==========
check_update_frequency() {
    local last_update_file
    last_update_file=$(find "$LOG_DIR" -name "update-*.log" -type f 2>/dev/null | sort -r | head -1)

    if [ -z "$last_update_file" ]; then
        log_info "Kein vorheriges Update gefunden - erstes Update"
        return 0
    fi

    local last_update_time
    last_update_time=$(stat -c %Y "$last_update_file" 2>/dev/null || echo 0)
    local current_time
    current_time=$(date +%s)
    local days_ago=$(( (current_time - last_update_time) / 86400 ))

    if [ $days_ago -gt 14 ]; then
        log_warning "Letztes Update vor $days_ago Tagen! Regelmäßige Updates (wöchentlich) empfohlen."
        echo ""
        echo "⚠️  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   WARNUNG: Letztes Update vor $days_ago Tagen!"
        echo "   Regelmäßige Updates sind wichtig für Sicherheit und Stabilität."
        echo "   Empfehlung: Updates wöchentlich durchführen"
        echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    elif [ $days_ago -gt 7 ]; then
        log_info "Letztes Update vor $days_ago Tagen"
        echo "ℹ️  Letztes Update vor $days_ago Tagen"
    fi
}

# ========== Fehler-Report Generator ==========
generate_error_report() {
    local error_type="${1:-Unbekannt}"
    local error_file
    error_file="$LOG_DIR/error-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "FEHLER-REPORT: CachyOS Multi-Updater"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Fehlertyp:      $error_type"
        echo "Datum:          $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Script Version: $SCRIPT_VERSION"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "SYSTEM INFORMATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "OS:        $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unbekannt")"
        echo "Kernel:    $(uname -r)"
        echo "User:      $(whoami)"
        echo "Hostname:  $(hostname)"
        echo "Disk:      $(df -h / 2>/dev/null | awk 'NR==2 {print $4 " free / " $2 " total"}' || echo "N/A")"
        echo "Memory:    $(free -h 2>/dev/null | awk 'NR==2 {print $7 " available / " $2 " total"}' || echo "N/A")"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "LETZTE 50 LOG-ZEILEN"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        tail -50 "$LOG_FILE" 2>/dev/null || echo "Log-Datei nicht verfügbar"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "KONFIGURATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [ -f "$CONFIG_FILE" ]; then
            cat "$CONFIG_FILE"
        else
            echo "Keine Config-Datei vorhanden (Standard-Einstellungen)"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "ENDE FEHLER-REPORT"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } > "$error_file"

    log_error "Fehler-Report erstellt: $error_file"
    echo ""
    echo "❌ Ein Fehler ist aufgetreten!"
    echo "   Fehler-Report erstellt: $error_file"
    echo "   Bitte prüfe den Report für Details."
    echo ""
}

# ========== System-Info sammeln ==========
collect_system_info() {
    cat >> "$LOG_FILE" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SYSTEM INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OS:             $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unbekannt")
Kernel:         $(uname -r)
Script Version: $SCRIPT_VERSION
Datum:          $(date '+%Y-%m-%d %H:%M:%S')
Benutzer:       $(whoami)
Hostname:       $(hostname)
Disk Space:     $(df -h / 2>/dev/null | awk 'NR==2 {print $4 " frei von " $2}' || echo "N/A")
Memory:         $(free -h 2>/dev/null | awk 'NR==2 {print $7 " verfügbar von " $2}' || echo "N/A")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ========== Logging-Funktionen ==========
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
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
        # Terminal offen halten bei Fehlern
        if [ -t 0 ] && [ -t 1 ]; then
            echo ""
            read -p "Drücke Enter zum Beenden..." || true
        fi
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

# ========== Alte Logs aufräumen ==========
cleanup_old_logs() {
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "update-*.log" -type f | sort -r | tail -n +$((MAX_LOG_FILES + 1)) | xargs rm -f 2>/dev/null || true
    fi
}

cleanup_old_logs
cleanup_old_snapshots

# System-Info sammeln
collect_system_info

log_info "CachyOS Multi-Updater Version $SCRIPT_VERSION"
log_info "Update gestartet..."
log_info "Log-Datei: $LOG_FILE"
[ "$DRY_RUN" = "true" ] && log_info "DRY-RUN Modus aktiviert"
[ "$ENABLE_COLORS" = "true" ] && log_info "Farbige Ausgabe aktiviert"

# Prüfe Update-Häufigkeit
check_update_frequency

# Geschätzte Dauer anzeigen
estimate_duration

echo -e "${COLOR_BOLD}🛡️  Update gestartet... (Passwort für sudo eingeben)${COLOR_RESET}"
echo ""

# Passwort-Abfrage VOR den Updates (damit Desktop-Icon funktioniert)
if [ "$DRY_RUN" != "true" ]; then
    sudo -v || {
        log_error "Sudo-Authentifizierung fehlgeschlagen"
        echo "❌ Sudo-Authentifizierung fehlgeschlagen!"
        exit $EXIT_UPDATE_ERROR
    }
fi

# Berechne Gesamtschritte für Fortschritts-Anzeige
TOTAL_STEPS=$(calculate_total_steps)
CURRENT_STEP=0

# ========== CachyOS updaten ==========
if [ "$UPDATE_SYSTEM" = "true" ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress $CURRENT_STEP $TOTAL_STEPS "System-Updates (pacman)" "🔄"

    log_info "Starte CachyOS-Update..."
    echo "📦 CachyOS-Repos updaten..."

    if [ "$DRY_RUN" = "true" ]; then
        packages_available=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
        log_info "[DRY-RUN] Verfügbare Updates: $packages_available Pakete"
        log_info "[DRY-RUN] Würde ausführen: sudo pacman -Syu --noconfirm"
        echo "🔍 [DRY-RUN] System-Update würde durchgeführt ($packages_available Pakete)"
    else
        # Zähle Pakete VOR dem Update
        SYSTEM_PACKAGES=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
        log_info "Zu aktualisierende Pakete: $SYSTEM_PACKAGES"

        if sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"; then
            SYSTEM_UPDATED=true
            log_success "CachyOS-Update erfolgreich ($SYSTEM_PACKAGES Pakete aktualisiert)"
            show_progress $CURRENT_STEP $TOTAL_STEPS "System-Updates (pacman)" "✅"
        else
            log_error "Pacman-Update fehlgeschlagen!"
            show_progress $CURRENT_STEP $TOTAL_STEPS "System-Updates (pacman)" "❌"
            exit $EXIT_UPDATE_ERROR
        fi
    fi
else
    log_info "System-Update übersprungen (deaktiviert)"
fi

echo ""

# ========== AUR updaten ==========
if [ "$UPDATE_AUR" = "true" ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress $CURRENT_STEP $TOTAL_STEPS "AUR-Updates (yay/paru)" "🔄"

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
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress $CURRENT_STEP $TOTAL_STEPS "Cursor Editor Update" "🔄"

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
            
            # Aktuelle Version ermitteln (versuche verschiedene Methoden)
            CURRENT_VERSION=""
            # Methode 1: package.json (zuverlässigste Methode)
            if [ -f "$CURSOR_INSTALL_DIR/resources/app/package.json" ]; then
                CURRENT_VERSION=$(grep -oP '"version":\s*"\K[0-9.]+' "$CURSOR_INSTALL_DIR/resources/app/package.json" 2>/dev/null | head -1 || echo "")
            fi
            # Methode 2: cursor --version
            if [ -z "$CURRENT_VERSION" ]; then
                CURRENT_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
            fi
            # Methode 3: Direkter Aufruf der Binary
            if [ -z "$CURRENT_VERSION" ] && [ -f "$CURSOR_INSTALL_DIR/cursor" ]; then
                CURRENT_VERSION=$("$CURSOR_INSTALL_DIR/cursor" --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
            fi
            if [ -z "$CURRENT_VERSION" ]; then
                CURRENT_VERSION="unbekannt"
            fi
            log_info "Aktuelle Cursor-Version: $CURRENT_VERSION"
            echo "📌 Aktuelle Version: $CURRENT_VERSION"
            
            # Prüfe neueste verfügbare Version (ohne Download)
            SKIP_DOWNLOAD=false
            if [ "$CURRENT_VERSION" != "unbekannt" ]; then
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
                        SKIP_DOWNLOAD=true
                    else
                        echo "⚠️  Versionsprüfung fehlgeschlagen, fahre mit Update fort..."
                        log_warning "Versionsprüfung fehlgeschlagen"
                    fi
                else
                    log_warning "Konnte neueste Version nicht abrufen, fahre mit Update fort..."
                fi
            else
                log_warning "Cursor-Version konnte nicht ermittelt werden, fahre mit Update fort..."
            fi
            
            # Überspringe Download wenn bereits aktuell
            if [ "$SKIP_DOWNLOAD" = "true" ]; then
                log_info "Cursor-Update übersprungen (bereits aktuell)"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
            else
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
                        
                        # Cursor-Prozesse prüfen (nicht automatisch schließen)
                        # Verwende -x für exact match, verhindert false positives
                        cursor_pids=$(pgrep -x "cursor" 2>/dev/null || pgrep -x "Cursor" 2>/dev/null || true)
                        if [ -n "$cursor_pids" ]; then
                            log_warning "Cursor läuft noch (PID: $cursor_pids) - bitte manuell schließen für sauberes Update"
                            echo "⚠️  Cursor läuft noch (PID: $cursor_pids)"
                            echo "   Bitte manuell schließen für sauberes Update"
                            echo "   (Cursor wird nicht automatisch geschlossen)"
                        else
                            log_info "Keine laufenden Cursor-Prozesse gefunden"
                            echo "ℹ️  Cursor läuft nicht"
                        fi
                        
                        # Extrahiere .deb
                        extract_dir=$(mktemp -d -t cursor-extract.XXXXXXXXXX)
                        trap 'rm -rf "$extract_dir" "$DEB_FILE"' EXIT
                        
                        log_info "Extrahiere Cursor .deb..."
                        echo "📦 Extrahiere .deb-Archiv..."
                        cd "$extract_dir"

                        if ! ar x "$DEB_FILE" 2>&1 | tee -a "$LOG_FILE"; then
                            log_error "Fehler beim Extrahieren des .deb-Archivs"
                            echo "❌ Fehler beim Extrahieren!"
                            rm -rf "$extract_dir" "$DEB_FILE"
                            exit $EXIT_DOWNLOAD_ERROR
                        elif ! tar -xf data.tar.* 2>&1 | tee -a "$LOG_FILE"; then
                            log_error "Fehler beim Extrahieren der Daten"
                            echo "❌ Fehler beim Extrahieren der Daten!"
                            rm -rf "$extract_dir" "$DEB_FILE"
                            exit $EXIT_DOWNLOAD_ERROR
                        else
                            # Finde Cursor-Binary und Ressourcen
                            install_success=false

                            if [[ -d "opt/Cursor" ]]; then
                                log_info "Installiere Cursor-Update (opt/Cursor)..."
                                echo "📦 Installiere Update..."
                                if sudo cp -rf opt/Cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                    sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                    log_success "Cursor-Update installiert"
                                    install_success=true
                                elif sudo cp -rf opt/Cursor/* "$(dirname "$CURSOR_INSTALL_DIR")/" 2>&1 | tee -a "$LOG_FILE"; then
                                    sudo chmod +x "$(dirname "$CURSOR_INSTALL_DIR")/cursor" 2>/dev/null || true
                                    log_success "Cursor-Update installiert (alternativer Pfad)"
                                    install_success=true
                                elif sudo cp -rf opt/Cursor /opt/ 2>&1 | tee -a "$LOG_FILE"; then
                                    sudo chmod +x /opt/Cursor/cursor 2>/dev/null || true
                                    log_success "Cursor-Update installiert (nach /opt)"
                                    install_success=true
                                fi
                            elif [[ -d "usr/share/cursor" ]]; then
                                log_info "Installiere Cursor-Update (usr/share/cursor)..."
                                echo "📦 Installiere Update (usr-Variante)..."
                                if sudo cp -rf usr/share/cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                    sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                    log_success "Cursor-Update installiert"
                                    install_success=true
                                fi
                            fi

                            # Cleanup IMMER durchführen (trap entfernen vor cleanup)
                            trap - EXIT
                            log_info "Bereinige temporäre Dateien..."
                            rm -rf "$extract_dir" "$DEB_FILE"
                            log_info "Temporäre Dateien gelöscht"

                            if [ "$install_success" = "true" ]; then
                                # Neue Version prüfen
                                sleep 1
                                NEW_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "installiert")
                                CURSOR_UPDATED=true
                                log_success "Cursor updated: $CURRENT_VERSION → $NEW_VERSION"
                                echo "✅ Cursor aktualisiert: $CURRENT_VERSION → $NEW_VERSION"
                                echo "ℹ️  Cursor kann jetzt manuell gestartet werden (falls geschlossen)"
                            else
                                log_error "Cursor-Dateien nicht gefunden im .deb oder Installation fehlgeschlagen!"
                                echo "❌ Installation fehlgeschlagen!"
                            fi
                        fi
                        # WICHTIG: cd zurück zum Script-Verzeichnis
                        cd "$SCRIPT_DIR" || true
                    else
                        log_error "Download zu klein oder fehlgeschlagen!"
                        echo "❌ Download zu klein oder fehlgeschlagen!"
                        rm -f "$DEB_FILE"
                    fi
                fi
            fi
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
fi

# ========== AdGuardHome updaten ==========
if [ "$UPDATE_ADGUARD" = "true" ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress $CURRENT_STEP $TOTAL_STEPS "AdGuard Home Update" "🔄"

    log_info "Starte AdGuardHome-Update..."
    echo "🛡️ AdGuardHome updaten..."
    agh_dir="$HOME/AdGuardHome"
    temp_dir=$(mktemp -d -t adguard-update.XXXXXXXXXX)
    trap 'rm -rf "$temp_dir"' EXIT
    
    if [ "$DRY_RUN" = "true" ]; then
        if [[ -f "$agh_dir/AdGuardHome" ]]; then
            current_version=$(cd "$agh_dir" && ./AdGuardHome --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
            log_info "[DRY-RUN] Aktuelle AdGuard-Version: v$current_version"
            log_info "[DRY-RUN] Würde AdGuard Home aktualisieren"
            echo "🔍 [DRY-RUN] AdGuard Home-Update würde durchgeführt"
        else
            log_warning "[DRY-RUN] AdGuard Home nicht gefunden in $agh_dir"
        fi
    elif [[ -f "$agh_dir/AdGuardHome" ]]; then
        cd "$agh_dir"
        
        log_info "Stoppe AdGuardHome-Service..."
        systemctl --user stop AdGuardHome 2>&1 | tee -a "$LOG_FILE" || log_warning "AdGuardHome-Service konnte nicht gestoppt werden"

        current_version=$(./AdGuardHome --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
        log_info "Aktuelle AdGuard-Version: v$current_version"
        echo "Aktuelle AdGuard-Version: v$current_version"

        backup_dir="$agh_dir-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp AdGuardHome.yaml data/* "$backup_dir/" 2>/dev/null || log_warning "Backup konnte nicht erstellt werden"
        log_info "Backup erstellt in: $backup_dir"

        download_url="https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz"
        log_info "Lade AdGuardHome von: $download_url"

        if download_with_retry "$download_url" "$temp_dir/AdGuardHome.tar.gz"; then
            if [[ -f "$temp_dir/AdGuardHome.tar.gz" ]]; then
                if tar -C "$temp_dir" -xzf "$temp_dir/AdGuardHome.tar.gz" 2>&1 | tee -a "$LOG_FILE"; then
                    new_binary="$temp_dir/AdGuardHome/AdGuardHome"
                    if [[ -f "$new_binary" ]]; then
                        new_version=$("$new_binary" --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
                        # Semantischer Versionsvergleich statt String-Vergleich
                        if printf '%s\n%s\n' "$current_version" "$new_version" | sort -V | head -1 | grep -q "^$current_version$"; then
                            if [ "$new_version" != "$current_version" ]; then
                                if cp "$new_binary" "$agh_dir/" 2>&1 | tee -a "$LOG_FILE"; then
                                    ADGUARD_UPDATED=true
                                    log_success "AdGuardHome updated: v$current_version → v$new_version"
                                    echo "✅ AdGuardHome updated: v$current_version → v$new_version"
                                else
                                    log_error "Fehler beim Kopieren der neuen AdGuardHome-Binary"
                                fi
                            else
                                log_info "AdGuardHome ist bereits aktuell (v$new_version)"
                                echo "ℹ️ AdGuardHome ist aktuell (v$new_version)."
                            fi
                        else
                            log_info "AdGuardHome ist bereits aktuell (v$new_version)"
                            echo "ℹ️ AdGuardHome ist aktuell (v$new_version)."
                        fi
                    else
                        log_error "AdGuardHome-Binary nicht im Archiv gefunden"
                    fi
                else
                    log_error "Fehler beim Extrahieren von AdGuardHome"
                fi
            fi
            rm -rf "$temp_dir"
        else
            log_error "AdGuardHome-Download fehlgeschlagen!"
            rm -rf "$temp_dir"
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
        log_warning "AdGuardHome Binary nicht gefunden in: $agh_dir"
        echo "⚠️ AdGuardHome Binary nicht gefunden in: $agh_dir"
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
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        sudo pacman -Rns $orphans 2>&1 | tee -a "$LOG_FILE" || log_warning "Orphan-Pakete konnten nicht entfernt werden"
    else
        log_info "Keine Orphan-Pakete gefunden"
    fi
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

    # Statistiken speichern
    save_stats "$DURATION" "true"

    # Statistiken anzeigen (nur wenn interaktiv)
    if [ -t 0 ] && [ -t 1 ]; then
        show_stats
    fi

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
    
    # Versuche zuerst Releases, dann Tags
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null | grep -oP '"tag_name":\s*"v?\K[0-9.]+' | head -1 || echo "")
    
    # Falls kein Release, prüfe Tags direkt
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/git/refs/tags" 2>/dev/null | grep -oP '"ref":\s*"refs/tags/v?\K[0-9.]+' | sort -V | tail -1 || echo "")
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

# Terminal offen halten wenn interaktiv (auch bei Desktop-Icon)
# WICHTIG: Prüfe ob wirklich interaktiv (Desktop-Icons haben oft kein echtes Terminal)
if [ -t 0 ] && [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Drücke Enter zum Beenden..." </dev/tty || true
fi

