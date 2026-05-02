#!/usr/bin/env bash

# parse argument
case "$1" in
    info)
        # fetch status cleaning ANSI colors and carriage returns
        STATUS=$(protonvpn status 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g' | tr -d '\r')

        # check if the output says we are connected
        if echo "$STATUS" | grep -qi "Status: *Connected"; then
            # extract server name and load
            SERVER=$(echo "$STATUS" | grep -i "Server:" | awk '{print $2}')
            LOAD=$(echo "$STATUS" | grep -i "Load:" | awk '{print $2}')

            # force the country code to only contain uppercase letters A-Z
            CC=$(echo "$SERVER" | cut -d'-' -f1 | tr -dc 'A-Z')

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

            # safely check the dictionary only if CC isn't empty to prevent crashes
            DISPLAY=""
            if [ -n "$CC" ]; then
                DISPLAY="${COUNTRIES[$CC]}"
            fi

            # get the display text, fallback to just the shield + code if not in the list
            if [ -z "$DISPLAY" ]; then
                DISPLAY="🛡️ ${CC:-VPN}" 
            fi

            # output connected JSON (with safe fallbacks for missing data)
            printf '{"text": "%s", "class": "connected", "tooltip": "Server: %s\\nLoad: %s"}\n' "$DISPLAY" "${SERVER:-Unknown}" "${LOAD:-Unknown}"
        else
            # output disconnected JSON
            printf '{"text": "", "class": "disconnected", "tooltip": "Disconnected"}\n'
        fi
        ;;

    toggle)
        # check if connected
        if protonvpn status | grep -qi "Status: *Connected"; then
            protonvpn disconnect
        else
            # -f connects to the fastest available server automatically
            protonvpn connect
        fi
        # send a signal to Waybar to refresh the module instantly after the connection finishes
        pkill -RTMIN+9 waybar
        ;;

    *)
        # fallback if no valid argument is provided
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac
