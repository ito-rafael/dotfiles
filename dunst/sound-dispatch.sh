#!/usr/bin/env bash

APPNAME="$1"

case "$APPNAME" in
    "wasistlos")
        paplay ~/.config/dunst/whatsapp.mp3 ;;
    *)
        paplay /usr/share/sounds/freedesktop/stereo/bell.oga ;;
esac
