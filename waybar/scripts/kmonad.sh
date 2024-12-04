#!/usr/bin/env bash
#
# This script is meant to be used with Waybar to control and monitor KMonad global/user services.
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help       show this help text
    action [--user]  action to be performed, can be one of the options:
      \"start\"        start KMonad service with systemd
      \"stop\"         stop KMonad service with systemd
      \"restart\"      restart KMonad service with systemd
      \"toggle\"       toggle (start/stop) KMonad service with systemd
      \"monitor\"      prints KMonad service status everytime the file /tmp/kmonad-status.tmp is updated (meant to be used with Waybar)

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
# read KMonad service status
FILE="/tmp/kmonad-status.tmp"
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
        *)
            echo '{"text": "", "alt": "unknown", "class": "unknown"}'
            ;;
    esac
}

# function to query KMonad service status and dump it into a file
check_status () {
    STATUS=$(systemctl --user is-active kmonad)
    update_output $STATUS
    echo $STATUS > $FILE
}

# parse requested action
case "${ACTION}" in
    "status")
        check_status
        ;;
    "start")
        $CMD start kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "stop")
        $CMD stop kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "restart")
        $CMD restart kmonad
        sleep $TIMEOUT
        check_status
        ;;
    "toggle")
        if systemctl --user is-active --quiet kmonad; then
            # kmonad active, stopping it...
            $CMD stop kmonad
        else
            # kmonad inactive, starting it...
            $CMD start kmonad
        fi
        sleep $TIMEOUT
        check_status
        ;;
    "monitor")
        check_status
        # infinite loop that updates text everytime the mouse warping file changes
        inotifywait --quiet --monitor --event close_write $FILE | while read; do
            STATUS=$(systemctl --user is-active kmonad)
            update_output $STATUS
            sleep 0.1
        done
        ;;
    *)
        ;;
esac
