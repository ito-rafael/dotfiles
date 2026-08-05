#!/usr/bin/env bash

# check the current color scheme
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)

if [ "$CURRENT" == "'prefer-dark'" ]; then
    # switch to light mode
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
else
    # switch to dark mode
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

# call OSD script to display message
~/.config/scripts/osd.sh theme
