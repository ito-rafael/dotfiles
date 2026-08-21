#!/usr/bin/env bash

# systemd service name
UNIT_NAME="autorotate.service"

# function to check state and output json
print_state() {
    if systemctl --user is-active --quiet "$UNIT_NAME"; then
        echo '{"text": ".", "class": "active"}'
    else
        echo '{"text": ".", "class": "inactive"}'
    fi
}

# get initial state
print_state

# block and listen to systemd journal events
journalctl --user -u "$UNIT_NAME" SYSLOG_IDENTIFIER=systemd -f -n 0 | while read -r _; do
    print_state
done
