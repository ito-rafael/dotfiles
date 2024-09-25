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

#=======================================
# identify session (i3wm/Sway) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ID_PROP="window"
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        #RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        OUTPUT_SCALE=1.0  # to be implemented
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ID_PROP="pid"
        # get height & width of current output
        RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        #RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        OUTPUT_SCALE=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).scale')
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

#=======================================
# temporary scratchpads
#=======================================
# scratchpad tmp files
SCRATCHPAD_TEMP_1='/tmp/scratchpad_pid_1.tmp'
SCRATCHPAD_TEMP_2='/tmp/scratchpad_pid_2.tmp'
SCRATCHPAD_TEMP_3='/tmp/scratchpad_pid_3.tmp'
# set default PID to 0
TEMP_PID_1=0
TEMP_PID_2=0
TEMP_PID_3=0
#----------------------------------
# temporary scratchpad #1 (comma)
if [ -f $SCRATCHPAD_TEMP_1 ]; then
    TEMP_PID_1=$(cat $SCRATCHPAD_TEMP_1)
fi 
#----------------------------------
# temporary scratchpad #2 (period)
if [ -f $SCRATCHPAD_TEMP_2 ]; then
    TEMP_PID_2=$(cat $SCRATCHPAD_TEMP_2)
fi 
#----------------------------------
# temporary scratchpad #3 (slash)
if [ -f $SCRATCHPAD_TEMP_3 ]; then
    TEMP_PID_3=$(cat $SCRATCHPAD_TEMP_3)
fi

#=======================================
# calculate window size
#=======================================
# calc height (int) of the window (90% of full height)
# examples:
#   - for Full HD (1920x1080): height = 972
#   - for 4K (3840x2160): height = 1944
WIN_HEIGHT=$(echo "0.9 * $RES_HEIGHT / $OUTPUT_SCALE / 1" | bc)

# calc width (int) of the window based on the resolution of the device
# examples:
#   - for 1440x3200:
#     - width = 1440/3200 * $WIN_HEIGHT
#       - Full HD: width = 437
#       - 4K: width = 875
WIN_WIDTH=$(echo "0.455 * $WIN_HEIGHT / $OUTPUT_SCALE / 1" | bc)

#=======================================
# get focused window
#=======================================
FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$PROP'')

#=======================================
# check if ADB scratchpad is already running
#=======================================
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy")')

#=======================================
# check if current focused window is a scratchpad
#=======================================
if [ $FOCUSED != "scrcpy" ]; then
    # then check if the {class,app_id} is one of the listed bellow
    is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
        .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
        .'$PROP_PREFIX''$PROP' == "dropdown_python" or
        .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy" or
        .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "brave-web.whatsapp.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com" or
        .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp" or
        .'$ID_PROP' == '$TEMP_PID_1' or 
        .'$ID_PROP' == '$TEMP_PID_2' or 
        .'$ID_PROP' == '$TEMP_PID_3'
        ')

    # if focused window is a scratchpad (according to the above list), hide it
    if [ "$is_scratchpad" == "true" ]; then
        $WM_CMD scratchpad show
    fi
fi

#=======================================
# fn that tries to connect to device via ADB
#=======================================
adb_connect () {
    ADB_RESPONSE=$(adb connect $IP:$PORT_CON)
    # if ADB connection succeed, launch scrcpy as scratchpad
    if [ "$ADB_RESPONSE" == "connected to $IP:$PORT_CON" ]; then
        scrcpy \
            -s $IP:$PORT_CON \
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
    # if ADB connection failed, try to pair first
    #-------------------------------------------------
    elif [ "$ADB_RESPONSE" == "failed to connect to $IP:$PORT_CON" ]; then
        return 1

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
        exit 1
    fi
}
#=======================================
# fn that tries to pair with device with ADB
#=======================================
adb_pair () {
    # ask pair code
    IMAGE=/usr/share/icons/Papirus-Dark/32x32/panel/keepassxc-dark.svg
    PAIR_CODE="$(yad \
        --center \
        --entry \
        --text="Insert ADB pair code:" \
        --title="Pair code" \
        --licon=$IMAGE \
        --image=$XDG_CONFIG_HOME/icon/android.svg \
        )"

    # try to discover IP & port of device ADB via mDNS
    MDNS_OUTPUT=$(avahi-browse --all --ignore-local --resolve --terminate --parsable | grep adb-RQ8N400FVCP-bNfaUl | grep pairing | tail -1)
    PORT_PAIR=$(echo $MDNS_OUTPUT | cut -d ";" -f9)
    IP=$1

    # check if ADB pair is running
    if [ -z "${MDNS_OUTPUT}" ]; then
        echo "Device not found! Exiting."
        # send alert notification
        notify-send \
            --expire-time=0 \
            --urgency=NORMAL \
            --icon='/usr/share/icons/Papirus/symbolic/status/dialog-warning-symbolic.svg' \
            "Failed to pair with device $IP" \
            "Make sure ADB is in pairing mode."
        # play alert sound
        paplay /usr/share/sounds/freedesktop/stereo/bell.oga
        exit 1
    else
        echo "Device found: trying to pair with $IP:$PORT_PAIR. Please enter the pairing code:"
        adb pair $IP:$PORT_PAIR $PAIR_CODE
        return 0
    fi
}

#=======================================
# display scratchpad if it's active, or try to launch if it isn't
#=======================================
if [[ $SCRATCHPAD ]]; then
    echo "Scratchpad found! Displaying it..."
    $WM_CMD '['$PROP'="scrcpy" title="dropdown_scrcpy"] scratchpad show; ['$PROP'="scrcpy" title="dropdown_scrcpy"] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'="scrcpy" title="dropdown_scrcpy"] move position center'
    exit 0
else
    # try to discover IP & port of device ADB via mDNS
    echo "Scratchpad not found! Searching for ADB IP & port on device..."
    MDNS_OUTPUT=$(avahi-browse --all --ignore-local --resolve --terminate --parsable | grep adb-RQ8N400FVCP-bNfaUl | grep connect | grep v=ADB_SECURE_SERVICE_VERSION | tail -1)
    IP=$(echo $MDNS_OUTPUT | cut -d ";" -f8)
    PORT_CON=$(echo $MDNS_OUTPUT | cut -d ";" -f9)

    # check if ADB is running
    if [ -z "${MDNS_OUTPUT}" ]; then
        echo "Device not found! Exiting."
        # send alert notification
        notify-send \
            --expire-time=0 \
            --urgency=NORMAL \
            --icon='/usr/share/icons/Papirus/symbolic/status/dialog-warning-symbolic.svg' \
            "Device not found!" \
            "Make sure ADB is running."
        # play alert sound
        paplay /usr/share/sounds/freedesktop/stereo/bell.oga
        exit 1
    else
            fi
        fi
    fi
fi
