#!/usr/bin/env bash
PROTON_FILE="/tmp/proton-vpn-status.tmp"

is_connected() {
    protonvpn status | grep -q "Connected"
}

update_status() {
    if is_connected; then
        echo "connected" >"$PROTON_FILE"
    else
        echo "disconnected" >"$PROTON_FILE"
    fi
}

connecting() {
    echo "connecting" >"$PROTON_FILE"
    protonvpn connect
    update_status
}

disconnecting() {
    echo "disconnecting" >"$PROTON_FILE"
    protonvpn disconnect
    update_status
}

case "$1" in
status)
    protonvpn status
    ;;
monitor)
    print_state() {
        PROTON_STATUS=$(cat "$PROTON_FILE" 2>/dev/null)
        case "$PROTON_STATUS" in
        connected)
            # fetch status cleaning ANSI colors and carriage returns
            STATUS=$(protonvpn status 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g' | tr -d '\r')
            # extract server name
            SERVER=$(echo "$STATUS" | grep -i "Server:" | awk '{print $2}')
            # extract the server load
            LOAD=$(echo "$STATUS" | grep -i "Load:" | awk '{print $2}')
            # extract the country code and explicitly convert it to UPPERCASE to match dictionary
            CC=$(echo "$SERVER" | cut -d'-' -f1 | tr -dc 'a-zA-Z' | tr '[:lower:]' '[:upper:]')

            # dictionary mapping country codes to flags and names
            declare -A COUNTRIES=(
                ["US"]="🇺🇸"
                ["NL"]="🇳🇱"
                ["JP"]="🇯🇵"
                ["CH"]="🇨🇭"
                ["RO"]="🇷🇴"
                ["IS"]="🇮🇸"
                ["SE"]="🇸🇪"
                ["DE"]="🇩🇪"
                ["FR"]="🇫🇷"
                ["UK"]="🇬🇧"
                ["BR"]="🇧🇷"
                ["CA"]="🇨🇦"
                ["AU"]="🇦🇺"
            )

            # grab the emoji from the dictionary
            FLAG_EMOJI="${COUNTRIES[$CC]}"

            # check if CC exists AND if the dictionary successfully found a flag
            if [ -n "$CC" ] && [ -n "$FLAG_EMOJI" ]; then
                # use printf to safely inject variables into the JSON structure
                printf '{"text": "%s", "alt": "connected", "class": "connected", "tooltip": "Server: %s\\nLoad: %s"}\n' "$FLAG_EMOJI" "${SERVER:-Unknown}" "${LOAD:-Unknown}"
            else
                # fallback if no flag is found
                echo '{"text": "🛡️", "alt": "connected", "class": "connected"}'
            fi
            ;;
        disconnected)
            echo '{"text": ".", "alt": "disconnected", "class": "disconnected"}'
            ;;
        connecting)
            echo '{"text": ".", "alt": "connecting", "class": "connecting"}'
            ;;
        disconnecting)
            echo '{"text": ".", "alt": "disconnecting", "class": "disconnecting"}'
            ;;
        *)
            echo '{"text": ".", "alt": "unknown", "class": "unknown"}'
            ;;
        esac
    }

    print_state

    inotifywait --quiet --monitor --event close_write "$PROTON_FILE" | while read; do
        print_state
    done
    ;;
connect)
    if ! is_connected; then
        connecting
    fi
    ;;
disconnect)
    if is_connected; then
        disconnecting
    fi
    ;;
toggle)
    if is_connected; then
        disconnecting
    else
        connecting
    fi
    ;;
*)
    echo "usage: $0 {status|connect|disconnect|toggle}"
    exit 1
    ;;
esac
