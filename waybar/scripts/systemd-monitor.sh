#!/usr/bin/env bash

# arguments:
#   - SCOPE: --user, --system
#   - SERVICE: service-name
#   - ICON: --icon=""

# set the default scope
SCOPE="--system"
SERVICE=""
ICON=""

# loop through all arguments
for arg in "$@"; do
    case $arg in
        --user) SCOPE="--user" ;;
        --system) SCOPE="--system" ;;
        --icon=*) ICON="${arg#*=}" ;;
        *) SERVICE=$arg ;;
    esac
done

# make sure a service name was actually found
if [ -z "$SERVICE" ]; then
    echo "Error: No service name provided."
    exit 1
fi

LAST_STATE=""

# function to check and print the current JSON state
print_status() {
    if systemctl $SCOPE is-active --quiet "$SERVICE"; then
        CURRENT_STATE="running"
    else
        CURRENT_STATE="stopped"
    fi

    # only output to Waybar if the state actually changed
    if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
        if [ "$CURRENT_STATE" = "running" ]; then
            echo "{\"text\": \"$ICON\", \"class\": \"running\", \"tooltip\": \"$SERVICE is RUNNING\"}"
        else
            echo "{\"text\": \"$ICON\", \"class\": \"stopped\", \"tooltip\": \"$SERVICE is STOPPED\"}"
        fi
        LAST_STATE=$CURRENT_STATE
    fi
}

# print the initial state
print_status

# get D-Bus scope
DBUS_BUS="--system"
[ "$SCOPE" = "--user" ] && DBUS_BUS="--session"

# extract the base name (eg: "my-awesome-service.service" -> "my-awesome-service") 
BASENAME="${SERVICE%.*}"

# listen to D-Bus events from systemd and trigger on the selected service
dbus-monitor $DBUS_BUS "sender='org.freedesktop.systemd1'" | grep --line-buffered -i "$BASENAME" | while read -r line; do
    print_status
done
