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
            echo '{"text": ".", "alt": "connected", "class": "connected"}'
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
