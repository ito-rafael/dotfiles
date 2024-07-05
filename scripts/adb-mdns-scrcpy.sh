#!/usr/bin/env bash
#
# This script is meant to be used with i3wm/Sway to mirror a device (eg: phone, smartwatch) screen on the desktop.
#
# Prerequisites:
#   - device already paired with the desktop: "adb pair IP:PORT".
#   - "debug wireless" activated on the device (Developer options).
#   - scrcpy: tool to mirror device screen (https://github.com/Genymobile/scrcpy).
#   - Avahi: tool to discover the IP & port of the device (wireless ADB) via mDNS.
#
# How it works:
#   1. Identify the session (i3wm/Sway) to run the respective commands.
#   2. Check if =scrcpy= scratchpad exists. If it does, show it and exit.
#   3. If not, try to find the ADB IP & port of the device.
#   4. If it finds, start =scrcpy= and display it. If not, exit.
#
# Source
#   https://stackoverflow.com/questions/65991502/adb-over-wi-fi-android-11-on-windows-how-to-keep-a-fixed-port-or-connect-aut
#

# get output resolution
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        #RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        # get height & width of current output
        RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        #RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

# calc height (int) of the window (90% of full height)
# examples:
#   - for Full HD (1920x1080): height = 972
#   - for 4K (3840x2160): height = 1944
WIN_HEIGHT=$(echo "0.9 * $RES_HEIGHT / 1" | bc)

# calc width (int) of the window based on the resolution of the device
# examples:
#   - for 1440x3200:
#     - width = 1440/3200 * $WIN_HEIGHT
#       - Full HD: width = 437
#       - 4K: width = 875
WIN_WIDTH=$(echo "0.455 * $WIN_HEIGHT / 1" | bc)

# get focused window
FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$PROP'')

# check if ADB scratchpad is already running
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy")')

# check if current focused window is a scratchpad
if [ $FOCUSED != "scrcpy" ]; then
    # then check if the {class,app_id} is one of the listed bellow
    is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
        .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
        .'$PROP_PREFIX''$PROP' == "dropdown_python" or
        .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy" or
        .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
        .'$PROP_PREFIX'class == "Brave-browser" and .'$PROP_PREFIX'title == "YouTube Music" and .'$PROP_PREFIX'instance == "music.youtube.com"
        ')

    # if focused window is a scratchpad (according to the above list), hide it
    if [ $is_scratchpad = "true" ]; then
        $WM_CMD scratchpad show
    fi
fi

# display scratchpad if it's active, or try to launch if it isn't
if [[ $SCRATCHPAD ]]; then
    echo "Scratchpad found! Displaying it..."
    $WM_CMD '['$PROP'="scrcpy" title="dropdown_scrcpy"] scratchpad show; ['$PROP'="scrcpy" title="dropdown_scrcpy"] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'="scrcpy" title="dropdown_scrcpy"] move position center'
    exit 0
else
    # try to discover IP & port of device ADB via mDNS
    echo "Scratchpad not found! Searching for ADB IP & port on device..."
    MDNS_OUTPUT=$(avahi-browse --all --ignore-local --resolve --terminate --parsable | grep adb-RQ8N400FVCP-bNfaUl | grep v=ADB_SECURE_SERVICE_VERSION | tail -1)
    IP=$(echo $MDNS_OUTPUT | cut -d ";" -f8)
    PORT=$(echo $MDNS_OUTPUT | cut -d ";" -f9)

    # check if ADB is running
    if [ -z "${MDNS_OUTPUT}" ]; then
        echo "Device not found! Exiting."
        exit 1
    else
        echo "Device found: trying to connect to $IP:$PORT."
        ADB_RESPONSE=$(adb connect $IP:$PORT)
        
        #-------------------------------------------------
        # if ADB connection succeed, launch scrcpy as scratchpad
        #-------------------------------------------------
        if [ "$ADB_RESPONSE" == "connected to $IP:$PORT" ]; then
            scrcpy \
                -s $IP:$PORT \
                --prefer-text \
                --window-title="dropdown_scrcpy" \
                >& /dev/null &

            # wait for scrcpy window to be launched
            SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy")')
            if [ -z $SCRATCHPAD ]; then
                echo "Waiting scratchpad to be launched."
                while [[ $SCRATCHPAD ]]; do
                    sleep 0.2
                    echo "..."
                    SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy")')
                done
            fi

            # display scratchpad
            sleep 2
            $WM_CMD '['$PROP'="scrcpy" title="dropdown_scrcpy"] scratchpad show; ['$PROP'="scrcpy" title="dropdown_scrcpy"] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'="scrcpy" title="dropdown_scrcpy"] move position center'
            exit 0

        #-------------------------------------------------
        # if ADB connection failed, send notification
        #-------------------------------------------------
        elif [ "$ADB_RESPONSE" == "failed to connect to $IP:$PORT" ]; then
            # send alert notification
            notify-send \
                --expire-time=0 \
                --urgency=NORMAL \
                --icon='/usr/share/icons/Papirus/symbolic/status/dialog-warning-symbolic.svg' \
                "Failed to connect to $IP:$PORT!" \
                "Make sure the device is paired."

            # play alert sound
            paplay /usr/share/sounds/freedesktop/stereo/bell.oga

            exit 1

        #-------------------------------------------------
        # if ADB connection timed out, send notification
        #-------------------------------------------------
        #elif [ "$ADB_RESPONSE" == "Failed to resolve service \'adb-RQ8N400FVCP-bNfaUl\' of type \'_adb-tls-connect._tcp\' in domain \'local\': Timeout reached" ]; then
        elif [ "$ADB_RESPONSE" == "Failed to resolve service 'adb-RQ8N400FVCP-bNfaUl' of type '_adb-tls-connect._tcp' in domain 'local': Timeout reached" ]; then
            
            # send alert notification
            notify-send \
                --expire-time=0 \
                --urgency=NORMAL \
                --icon='/usr/share/icons/Papirus/symbolic/status/dialog-warning-symbolic.svg' \
                "Failed to resolve service!" \
                "Timeout reached."

            # play alert sound
            paplay /usr/share/sounds/freedesktop/stereo/bell.oga

            exit 1

        #-------------------------------------------------
        # different error from ADB
        #-------------------------------------------------
        else
            # TBD
            echo $ADB_RESPONSE
            echo $ADB_RESPONSE >> output_of_adb
            # TBD
        fi

    fi
fi
