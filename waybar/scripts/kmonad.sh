#!/usr/bin/env bash

# read KMonad service status
FILE="/tmp/kmonad-status.tmp"
TIMEOUT=0.75

# parse parameter
CMD=$1

# function to update text in status bar (Waybar)
update_output () {
    STATUS=$1
    case "${STATUS}" in
        "active")
            echo '{"text": "", "alt": "active", "class": "active"}'
            ;;
        "inactive")
            echo '{"text": "", "alt": "inactive", "class": "inactive"}'
            ;;
        "failed")
            echo '{"text": "", "alt": "failed", "class": "failed"}'
            ;;
        *)
            echo '{"text": "", "alt": "unknown", "class": "unknown"}'
            ;;
    esac
}

# function to query KMonad service status and dump it into a file
check_status () {
    STATUS=$(systemctl is-active kmonad)
    update_output $STATUS
    echo $STATUS > $FILE
}

# parse requested action
case "${CMD}" in
    "status")
        check_status
        ;;
    "start")
        systemctl start kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "stop")
        systemctl stop kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "restart")
        systemctl restart kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "toggle")
        if systemctl is-active --quiet kmonad; then
            # kmonad active, stopping it...
            systemctl stop kmonad
        else
            # kmonad inactive, starting it...
            systemctl start kmonad
        fi
        sleep $TIMEOUT
        check_status
        ;;
    "monitor")
        check_status
        # infinite loop that updates text everytime the mouse warping file changes
        inotifywait --quiet --monitor --event close_write $FILE | while read; do
            STATUS=$(systemctl is-active kmonad)
            update_output $STATUS
            sleep 0.1
        done
        ;;
    *)
        ;;
esac
