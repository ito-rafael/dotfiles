#!/usr/bin/env bash

# launch scratchpad
kitty \
    --class="dropdown_aur" \
    --hold \
    -o font_size=12 \
    -o include="$XDG_CONFIG_HOME/kitty/themes/pacman.conf" \
    zsh -ic 'paru -Syu' &

# wait for dropdown_pacman appears in Sway's window tree
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
