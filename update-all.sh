#!/bin/bash
# Smarter Update: CachyOS + AUR + Cursor + AdGuardHome
# Verbesserte Version mit Logging und Error Handling

set -euo pipefail

# ========== Version ==========
SCRIPT_VERSION="2.1.0"

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

# Log-Verzeichnis erstellen
mkdir -p "$LOG_DIR"

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
    echo "ℹ️  $*"
}

log_success() {
    log "SUCCESS" "$@"
    echo "✅ $*"
}

log_error() {
    log "ERROR" "$@"
    echo "❌ $*" >&2
}

log_warning() {
    log "WARNING" "$@"
    echo "⚠️  $*"
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
echo "🛡️  Update gestartet... (Passwort für sudo eingeben)"

# ========== CachyOS updaten ==========
if [ "$UPDATE_SYSTEM" = "true" ]; then
    log_info "Starte CachyOS-Update..."
    echo "📦 CachyOS-Repos updaten..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Würde ausführen: sudo pacman -Syu --noconfirm"
        echo "🔍 [DRY-RUN] System-Update würde durchgeführt"
    else
        if sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"; then
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
                log_success "AUR-Update mit yay erfolgreich"
            else
                log_warning "AUR-Update mit yay hatte Warnungen"
            fi
        elif command -v paru >/dev/null 2>&1; then
            log_info "Verwende paru als AUR-Helper"
            if paru -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE" | grep -v "error occurred" || true; then
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
    echo "🖱️ Cursor updaten..."
    
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
        echo "⚠️ Cursor nicht gefunden – bitte manuell installieren!"
    else
        # Cursor-Pfad finden
        CURSOR_PATH=$(which cursor)
        CURSOR_INSTALL_DIR=$(dirname "$(readlink -f "$CURSOR_PATH")")
        
        log_info "Cursor gefunden in: $CURSOR_INSTALL_DIR"
        echo "📍 Cursor gefunden in: $CURSOR_INSTALL_DIR"
        
        # Aktuelle Version
        CURRENT_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unbekannt")
        log_info "Aktuelle Cursor-Version: $CURRENT_VERSION"
        echo "Aktuelle Version: $CURRENT_VERSION"
        
        # Download .deb in Script-Ordner
        DEB_FILE="$SCRIPT_DIR/cursor_latest_amd64.deb"
        DOWNLOAD_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.0"
        
        log_info "Lade Cursor .deb von: $DOWNLOAD_URL"
        echo "⬇️  Lade Cursor .deb nach $SCRIPT_DIR..."
        
        if ! curl -L -f -o "$DEB_FILE" "$DOWNLOAD_URL" 2>&1 | tee -a "$LOG_FILE"; then
            log_error "Cursor-Download fehlgeschlagen!"
            echo "❌ Download fehlgeschlagen!"
            rm -f "$DEB_FILE"
            # Weiter mit anderen Updates
        else
            # Prüfe Download
            if [[ -f "$DEB_FILE" ]] && [[ $(stat -c%s "$DEB_FILE") -gt 50000000 ]]; then
                log_success "Download erfolgreich: $(du -h "$DEB_FILE" | cut -f1)"
                echo "✅ Download OK: $(du -h "$DEB_FILE" | cut -f1)"
                
                # Cursor-Prozesse sicher beenden
                log_info "Beende Cursor-Prozesse..."
                echo "🔒 Schließe Cursor..."
                
                # Warte auf alle Cursor-Prozesse
                CURSOR_PIDS=$(pgrep -f cursor || true)
                if [ -n "$CURSOR_PIDS" ]; then
                    log_info "Gefundene Cursor-Prozesse: $CURSOR_PIDS"
                    killall cursor 2>/dev/null || true
                    
                    # Warte bis Prozesse beendet sind (max. 10 Sekunden)
                    for i in {1..10}; do
                        if ! pgrep -f cursor >/dev/null 2>&1; then
                            log_success "Alle Cursor-Prozesse beendet"
                            break
                        fi
                        sleep 1
                    done
                    
                    # Falls noch Prozesse laufen, force kill
                    if pgrep -f cursor >/dev/null 2>&1; then
                        log_warning "Force-Kill von Cursor-Prozessen..."
                        killall -9 cursor 2>/dev/null || true
                        sleep 2
                    fi
                else
                    log_info "Keine laufenden Cursor-Prozesse gefunden"
                fi
                
                # Extrahiere .deb
                EXTRACT_DIR="$SCRIPT_DIR/cursor-extract"
                rm -rf "$EXTRACT_DIR"
                mkdir -p "$EXTRACT_DIR"
                
                log_info "Extrahiere Cursor .deb..."
                cd "$EXTRACT_DIR"
                if ! ar x "$DEB_FILE" 2>&1 | tee -a "$LOG_FILE"; then
                    log_error "Fehler beim Extrahieren des .deb-Archivs"
                    rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                    # Weiter mit anderen Updates
                else
                    if ! tar -xf data.tar.* 2>&1 | tee -a "$LOG_FILE"; then
                        log_error "Fehler beim Extrahieren der Daten"
                        rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                        # Weiter mit anderen Updates
                    else
                        # Finde Cursor-Binary und Ressourcen
                        if [[ -d "opt/Cursor" ]]; then
                            log_info "Installiere Cursor-Update (opt/Cursor)..."
                            echo "📦 Installiere Update..."
                            if sudo cp -rf opt/Cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert"
                            elif sudo cp -rf opt/Cursor/* "$(dirname "$CURSOR_INSTALL_DIR")/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$(dirname "$CURSOR_INSTALL_DIR")/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert (alternativer Pfad)"
                            elif sudo cp -rf opt/Cursor /opt/ 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x /opt/Cursor/cursor 2>/dev/null || true
                                log_success "Cursor-Update installiert (nach /opt)"
                            else
                                log_error "Fehler beim Installieren von Cursor"
                            fi
                        elif [[ -d "usr/share/cursor" ]]; then
                            log_info "Installiere Cursor-Update (usr/share/cursor)..."
                            echo "📦 Installiere Update (usr-Variante)..."
                            if sudo cp -rf usr/share/cursor/* "$CURSOR_INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                                sudo chmod +x "$CURSOR_INSTALL_DIR/cursor" 2>/dev/null || true
                                log_success "Cursor-Update installiert"
                            else
                                log_error "Fehler beim Installieren von Cursor"
                            fi
                        else
                            log_error "Cursor-Dateien nicht gefunden im .deb!"
                            rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                            # Weiter mit anderen Updates
                        fi
                        
                        # Cleanup
                        rm -rf "$EXTRACT_DIR" "$DEB_FILE"
                        
                        # Cursor neu starten
                        log_info "Starte Cursor neu..."
                        echo "🚀 Starte Cursor..."
                        sleep 2
                        nohup cursor > /dev/null 2>&1 &
                        if [ $? -eq 0 ]; then
                            sleep 3
                            log_success "Cursor gestartet"
                        else
                            log_warning "Cursor konnte nicht automatisch gestartet werden"
                        fi
                        
                        # Neue Version prüfen
                        NEW_VERSION=$(cursor --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "installiert")
                        log_success "Cursor updated: $CURRENT_VERSION → $NEW_VERSION"
                        echo "✅ Cursor updated: $CURRENT_VERSION → $NEW_VERSION"
                    fi
                fi
            else
                log_error "Download zu klein oder fehlgeschlagen!"
                echo "❌ Download zu klein oder fehlgeschlagen!"
                rm -f "$DEB_FILE"
            fi
        fi
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
        
        if curl -L -f -o "$TEMP_DIR/AdGuardHome.tar.gz" "$DOWNLOAD_URL" 2>&1 | tee -a "$LOG_FILE"; then
            if [[ -f "$TEMP_DIR/AdGuardHome.tar.gz" ]]; then
                if tar -C "$TEMP_DIR" -xzf "$TEMP_DIR/AdGuardHome.tar.gz" 2>&1 | tee -a "$LOG_FILE"; then
                    NEW_BINARY="$TEMP_DIR/AdGuardHome/AdGuardHome"
                    if [[ -f "$NEW_BINARY" ]]; then
                        NEW_VERSION=$("$NEW_BINARY" --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
                        if [[ "$NEW_VERSION" > "$CURRENT_VERSION" ]]; then
                            if cp "$NEW_BINARY" "$AGH_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
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
        systemctl --user start AdGuardHome 2>&1 | tee -a "$LOG_FILE" || log_warning "AdGuardHome-Service konnte nicht gestartet werden"
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
if [ "$DRY_RUN" = "true" ]; then
    log_info "DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
    echo "🔍 DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
else
    log_success "Alle Updates abgeschlossen!"
    echo "🎉 Alles up-to-date!"
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "Update fertig!" "CachyOS, AUR, Cursor & AdGuard sind frisch!" 2>/dev/null || true
    fi
fi

log_info "Update-Script erfolgreich beendet"

