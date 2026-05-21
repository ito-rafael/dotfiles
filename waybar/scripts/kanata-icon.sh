#!/usr/bin/env bash

# function to check state and output json
update_state() {
    if systemctl --user is-active --quiet kanata; then
        # service active
        echo '{"text": " ", "class": "active", "tooltip": "kanata is running"}'
    else
        # service inactive
        echo '{"text": " ", "class": "inactive", "tooltip": "kanata is stopped"}'
    fi
}

# get initial state
update_state

# block and listen for systemd state changes via D-Bus
# listen specifically for changes to the kanata.service on the user bus
dbus-monitor --session "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.freedesktop.systemd1.Unit',path='/org/freedesktop/systemd1/unit/kanata_2eservice'" |
while read -r line; do
    # when D-Bus spits out a change for Kanata, update Waybar
    # (check for the 'ActiveState' string to ensure it's a real start/stop event)
    if echo "$line" | grep -q "ActiveState"; then
        update_state
    fi
done
