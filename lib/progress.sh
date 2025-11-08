#!/bin/bash
# Progress Indicator Module für CachyOS Multi-Updater

# ========== Fortschritts-Indikator ==========
show_progress() {
    local step="$1"
    local total="$2"
    local name="$3"
    local status="${4:-⏳}"  # ⏳ wartend, 🔄 läuft, ✅ fertig, ❌ fehler, ⏭️ übersprungen

    local percentage=$((step * 100 / total))

    case "$status" in
        "⏳") # Wartend
            echo -e "[$step/$total] ${COLOR_WARNING}$status${COLOR_RESET} $name ${COLOR_BOLD}($percentage%)${COLOR_RESET}"
            ;;
        "🔄") # Läuft
            echo -e "[$step/$total] ${COLOR_INFO}$status${COLOR_RESET} $name ${COLOR_BOLD}($percentage%)${COLOR_RESET}"
            ;;
        "✅") # Fertig
            echo -e "[$step/$total] ${COLOR_SUCCESS}$status${COLOR_RESET} $name ${COLOR_BOLD}($percentage%)${COLOR_RESET}"
            ;;
        "❌") # Fehler
            echo -e "[$step/$total] ${COLOR_ERROR}$status${COLOR_RESET} $name ${COLOR_BOLD}($percentage%)${COLOR_RESET}"
            ;;
        "⏭️") # Übersprungen
            echo -e "[$step/$total] ${COLOR_WARNING}$status${COLOR_RESET} $name (übersprungen)"
            ;;
        *)
            echo "[$step/$total] $status $name"
            ;;
    esac
}

calculate_total_steps() {
    local steps=0

    [ "$UPDATE_SYSTEM" = "true" ] && steps=$((steps + 1))
    [ "$UPDATE_AUR" = "true" ] && steps=$((steps + 1))
    [ "$UPDATE_CURSOR" = "true" ] && steps=$((steps + 1))
    [ "$UPDATE_ADGUARD" = "true" ] && steps=$((steps + 1))

    echo "$steps"
}
