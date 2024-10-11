#!/usr/bin/env bash
set -euo pipefail

dbus-monitor path='/org/freedesktop/Notifications',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged' --profile |
    while read -r _; do
        PAUSED="$(dunstctl is-paused)"
        if [ "$PAUSED" == 'false' ]; then
            echo '{"text": "", "alt": "enabled", "class": "enabled"}'
        else
            echo '{"text": "", "alt": "disabled", "class": "disabled"}'
        fi
    done
