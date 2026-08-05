#!/usr/bin/env bash

# check the current color scheme
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)

if [ "$CURRENT" == "'prefer-dark'" ]; then
    # switch to light mode
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    #notify-send -t 2000 "Theme toggled" "Light Mode enabled"
else
    # switch to dark mode
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    #notify-send -t 2000 "Theme toggled" "Dark Mode enabled"
fi
