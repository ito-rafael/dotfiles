#!/usr/bin/env bash

ARCHLINUX_ICON="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/icon/archlinux.png"

# launch scratchpad
kitty \
    --class="dropdown_aur" \
    -d "~" \
    -o font_size=12 \
    -o include="$XDG_CONFIG_HOME/kitty/themes/pacman.conf" \
    zsh -ic '
        paru -Syu

        # run the notification logic in a background subshell
        (
            cleanup() {
                if [ -n "$NOTIF_ID" ]; then
                    gdbus call --session \
                        --dest org.freedesktop.Notifications \
                        --object-path /org/freedesktop/Notifications \
                        --method org.freedesktop.Notifications.CloseNotification \
                        "$NOTIF_ID" >/dev/null 2>&1
                fi
            }

            # trap termination so cleanup runs when Kitty closes
            trap cleanup EXIT HUP INT TERM

            # capture notify-send using file descriptor 3
            exec 3< <(notify-send -p -a dropdown_aur \
                "AUR Update" \
                "Paru update finished!" \
                --icon="$ARCHLINUX_ICON" \
                --action="default=Focus Window" \
                --expire-time=0)

            read -u 3 NOTIF_ID
            read -u 3 ACTION

            # check if the notification was clicked, and if the scratchpad is currently visible or hidden
            if [ "$ACTION" = "default" ]; then
                if ! swaymsg -t get_tree | jq -e ".. | objects | select(.app_id == \"dropdown_aur\" and .visible == true)" >/dev/null 2>&1; then
                    swaymsg exec ~/.config/scripts/show-or-launch.sh dropdown_aur 0.75 0.75
                fi
            fi
        ) &

        # hand control over to a fully interactive zsh shell
        exec zsh
    ' &

# wait for dropdown_aur appears in Sway window tree
MAX_WAIT=50
COUNTER=0
while ! swaymsg -t get_tree | grep -q '"app_id": "dropdown_aur"'; do
    sleep 0.1
    ((COUNTER++))
    if [[ $COUNTER -ge $MAX_WAIT ]]; then
        echo "Error: Kitty window never appeared."
        exit 1
    fi
done

# exit cleanly
exit 0
