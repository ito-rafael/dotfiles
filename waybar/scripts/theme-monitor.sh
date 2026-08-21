#!/usr/bin/env bash

# function to check state and output json
print_state() {
    local current=$(gsettings get org.gnome.desktop.interface color-scheme)
    if [ "$current" == "'prefer-dark'" ]; then
        echo '{"text": ".", "class": "dark"}'
    else
        echo '{"text": ".", "class": "light"}'
    fi
}

# get initial state
print_state

# block and listen to systemd journal events
gsettings monitor org.gnome.desktop.interface color-scheme | while read -r _; do
    print_state
done
