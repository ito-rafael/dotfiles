#!/usr/bin/env bash

# function to check state and output json
print_state() {
    if systemctl --user is-active --quiet pdfjs.service; then
        echo '{"text": ".", "class": "active"}'
    else
        echo '{"text": ".", "class": "inactive"}'
    fi
}

# get initial state
print_state

# block and listen to systemd journal events
journalctl --user -u pdfjs.service SYSLOG_IDENTIFIER=systemd -f -n 0 | while read -r line; do
    print_state
done
