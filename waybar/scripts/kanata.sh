#!/usr/bin/env bash
#
# This script is meant to be used with Waybar to control and monitor kanata global/user services.
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help       show this help text
    action [--user]  action to be performed, can be one of the options:
      \"start\"        start kanata service with systemd
      \"stop\"         stop kanata service with systemd
      \"restart\"      restart kanata service with systemd
      \"toggle\"       toggle (start/stop) kanata service with systemd
      \"monitor\"      prints kanata service status everytime the file /tmp/kanata-status.tmp is updated (meant to be used with Waybar)

    Obs: if the flag \"--user\" is used, then systemd controls the user service. Otherwise, the global service is used as the target.
"

#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to create, show, detach or destroy temporary scratchpad\n\n"
	echo "$usage"
	exit 0
fi

#=================================================
# parse parameters
#=================================================
ACTION=$1
SCOPE=$2

case "${SCOPE}" in
    "--user")
        CMD="systemctl --user"
        ;;
    "")
        CMD="sudo systemctl"
        ;;
    *)
        echo "Error: parameter \"$SCOPE\" not supported"
        exit 1
        ;;
esac

#=================================================
# read kanata service status
FILE="/tmp/kanata-status.tmp"
TIMEOUT=0.75

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
        "activating")
            echo '{"text": "", "alt": "activating", "class": "activating"}'
            ;;
        "deactivating")
            echo '{"text": "", "alt": "deactivating", "class": "deactivating"}'
            ;;
        *)
            echo '{"text": "", "alt": "unknown", "class": "unknown"}'
            ;;
    esac
}

# function to query kanata service status and dump it into a file
check_status () {
    STATUS=$(systemctl $SCOPE is-active kanata)
    while [[ "$STATUS" == "activating" ]] || [[ "$STATUS" == "deactivating" ]]; do
        sleep 1
        update_output $STATUS
        STATUS=$(systemctl $SCOPE is-active kanata)
    done
    # update bar & file
    update_output $STATUS
    echo $STATUS > $FILE
}

# parse requested action
case "${ACTION}" in
    "status")
        check_status
        ;;
    "start")
        $CMD start kanata
        sleep $TIMEOUT
        check_status
        ;;
    "stop")
        $CMD stop kanata
        sleep $TIMEOUT
        check_status
        ;;
    "restart")
        $CMD restart kanata
        sleep $TIMEOUT
        check_status
        ;;
    "toggle")
        if systemctl $SCOPE is-active --quiet kanata; then
            # kanata active, stopping it...
            $CMD stop kanata
        else
            # kanata inactive, starting it...
            $CMD start kanata
        fi
        sleep $TIMEOUT
        check_status
        ;;
    "monitor")
        check_status
        # infinite loop that updates text everytime the mouse warping file changes
        inotifywait --quiet --monitor --event close_write $FILE | while read; do
            STATUS=$(systemctl $SCOPE is-active kanata)
            update_output $STATUS
            sleep 0.1
        done
        ;;
    *)
        ;;
esac
