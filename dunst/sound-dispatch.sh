#!/usr/bin/env bash

APPNAME="$1"

case "$APPNAME" in
    "wasistlos")
        paplay ~/.config/dunst/sound/whatsapp.mp3 ;;
    "dropdown_pacman")
        paplay ~/.config/dunst/sound/pacman-waka.mp3 ;;
    *)
        paplay /usr/share/sounds/freedesktop/stereo/bell.oga ;;
esac
