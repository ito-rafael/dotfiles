#!/usr/bin/env bash
#
# This script is meant to be used with i3wm to show/hide scratchpads.
# When displaying the scratchpad, it resizes the window according to the parameters received and center the window.
#
# Parameters:
#   1. APPLICATION: $prop ("class" for i3wm, "app_id" for Sway) of the window. Example: "dropdown_terminal".
#   2. SCALE_W: scale multiplier for the scratchpad width. Example: 0.75 (default: 0.66).
#   3. SCALE_H: scale multiplier for the scratchpad height. Example: 0.90 (default: 0.66).
#

#=======================================
# get parameters
#=======================================
TARGET_OUTPUT=""
APPLICATION=""
SCALE_W="0.66"
SCALE_H="0.66"

# define monitors order
PRIMARY_MONITOR="HDMI-A-1"
SECONDARY_MONITOR="DP-1"
TERTIARY_MONITOR="DVI-I-1"

# parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --primary) TARGET_OUTPUT="$PRIMARY_MONITOR"; shift ;;
        --secondary) TARGET_OUTPUT="$SECONDARY_MONITOR"; shift ;;
        --tertiary) TARGET_OUTPUT="$TERTIARY_MONITOR"; shift ;;
        --output) TARGET_OUTPUT="$2"; shift 2 ;;
        -*) echo "Unknown parameter: $1"; exit 1 ;;
        *)
            # assign positional arguments if they don't match flags
            if [ -z "$APPLICATION" ]; then
                APPLICATION="$1"
            elif [ "$SCALE_W" == "0.66" ] && [ -z "${SCALE_W_SET}" ]; then
                SCALE_W="$1"
                SCALE_W_SET=1
            elif [ "$SCALE_H" == "0.66" ] && [ -z "${SCALE_H_SET}" ]; then
                SCALE_H="$1"
                SCALE_H_SET=1
            fi
            shift
            ;;
    esac
done

# make $APPLICATION ($1) parameter mandatory
if [ -z "$APPLICATION" ]; then
    echo "Error: APPLICATION parameter is required."
    exit 1
fi

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
# identify session (i3wm/Sway) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        if [ -n "$TARGET_OUTPUT" ]; then
            # if $TARGET_OUTPUT was defined in the parameters, use this output
            FOCUSED_OUTPUT="$TARGET_OUTPUT"
        else
            # if not defined, use the current focused output
            FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')
        fi
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ID_PROP="window"
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        OUTPUT_SCALE=1.0  # to be implemented
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ID_PROP="pid"
        # get height & width of target or current output
        if [ -n "$TARGET_OUTPUT" ]; then
            # if $TARGET_OUTPUT was defined in the parameters, use this output
            RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.name=="'$TARGET_OUTPUT'").rect')
            OUTPUT_SCALE=$(swaymsg -t get_outputs | jq '.[] | select(.name=="'$TARGET_OUTPUT'").scale')
        else
            # if not defined, use the current focused output
            RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).rect')
            OUTPUT_SCALE=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).scale')
        fi
        RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        ;;
    "tty")
        exit 1
        ;;
    *)
        exit 1
        ;;
esac

# calc height & width (as int) according to the scale parameter
WIN_WIDTH=$(echo "scale=1; $SCALE_W * $RES_WIDTH / $OUTPUT_SCALE" | bc | cut -d'.' -f1)
WIN_HEIGHT=$(echo "scale=1; $SCALE_H * $RES_HEIGHT / $OUTPUT_SCALE" | bc | cut -d'.' -f1)
# fallback: if calculation fails for any reason, set a hard default
WIN_WIDTH=${WIN_WIDTH:-1728}
WIN_HEIGHT=${WIN_HEIGHT:-972}

# check if target output is valid/connected
if [ -n "$TARGET_OUTPUT" ]; then
    if ! $WM_CMD -t get_outputs | jq -e '.[] | select(.name=="'$TARGET_OUTPUT'")' > /dev/null; then
        echo "Warning: Output '$TARGET_OUTPUT' not found or inactive. Falling back to focused output."
        TARGET_OUTPUT=""
    fi
fi

#=======================================
# get focused window
#=======================================
if [ $APPLICATION = "music.youtube.com" ] || [ $APPLICATION = "web.whatsapp.com" ]; then
    # special cases for i3wm (use "instance" instead of "class")
    #   - YouTube Music
    #   - WhatsApp Web
    FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$INSTANCE'')
else
    FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$PROP'')
fi

#=======================================
# check if scratchpad requested is different than the focused one
#=======================================
if [ $FOCUSED != $APPLICATION ]; then
    # then check if the {class,app_id} is one of the listed bellow
    is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
        .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
        .'$PROP_PREFIX''$PROP' == "dropdown_python" or
        .'$PROP_PREFIX''$PROP' == "dropdown_pacman" or
        .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp" or
        .'$PROP_PREFIX''$PROP' == "brave-calendar.google.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "brave-chatgpt.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "brave-translate.google.com__-Default" or
        .'$PROP_PREFIX''$PROP' == "wasistlos" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "calendar.google.com" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "chatgpt.com" or
        .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "translate.google.com" or
        .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy_phone" or
        .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy_watch" or
        .'$ID_PROP' == '$TEMP_PID_1' or 
        .'$ID_PROP' == '$TEMP_PID_2' or 
        .'$ID_PROP' == '$TEMP_PID_3'
        ')
        # deprecated
        #.'$PROP_PREFIX''$PROP' == "brave-web.whatsapp.com__-Default" or
        #.'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com" or

    # if focused window is a scratchpad (according to the above list), hide it
    if [ "$is_scratchpad" == "true" ]; then
        $WM_CMD scratchpad show
    fi
fi

#=======================================
# check if scratchpad exists
#=======================================
# special cases for i3wm (use "instance" instead of "class")
#   - YouTube Music
#   - WhatsApp Web
if [ $APPLICATION = "music.youtube.com" ] || [ $APPLICATION = "web.whatsapp.com" ]; then
    PROP="instance"
fi
# search for scratchpad
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "'$APPLICATION'")')

#=======================================
# if it does not exist, launch it
#=======================================
if [[ ! $SCRATCHPAD ]]; then
    case "${APPLICATION}" in
        "brave-music.youtube.com__-Default")
            brave-beta --app=https://music.youtube.com &
            sleep 2
            ;;
        #"brave-web.whatsapp.com__-Default")
        #    brave-beta --app=https://web.whatsapp.com &
        #    sleep 2
        #    ;;
        "brave-calendar.google.com__-Default")
            brave-beta --app=https://calendar.google.com &
            sleep 2
            ;;
        "brave-chatgpt.com__-Default")
            brave-beta --app=https://chatgpt.com &
            sleep 2
            ;;
        "brave-translate.google.com__-Default")
            brave-beta --app=https://translate.google.com &
            sleep 2
            ;;
        "calendar.google.com")
            brave-beta --app=https://calendar.google.com &
            sleep 2
            ;;
        "chatgpt.com")
            brave-beta --app=https://chatgpt.com &
            sleep 2
            ;;
        "dropdown_terminal")
            kitty --detach --class="dropdown_terminal" -o font_size=14 -o include=$XDG_CONFIG_HOME/kitty/themes/terminal.conf -o background_opacity=0.85
            sleep 0.05
            ;;
        "dropdown_python")
            kitty --detach --class="dropdown_python" -o font_size=20 -o include=$XDG_CONFIG_HOME/kitty/themes/python.conf python -q
            sleep 0.05
            ;;
        "dropdown_pacman")
            kitty --detach --class="dropdown_pacman" -o font_size=14 -o include=$XDG_CONFIG_HOME/kitty/themes/pacman.conf -o background_opacity=0.85
            sleep 0.05
            ;;
        "keymapp")
            keymapp &
            sleep 1
            ;;
        "Keymapp")
            keymapp &
            sleep 1
            ;;
        "music.youtube.com")
            brave-beta --app=https://music.youtube.com &
            sleep 2
            ;;
        "translate.google.com")
            brave-beta --app=https://translate.google.com &
            sleep 2
            ;;
        #"web.whatsapp.com")
        #    brave-beta --app=https://web.whatsapp.com &
        #    sleep 2
        #    ;;
        "wasistlos")
            wasistlos &
            sleep 2
            ;;
        *)
            exit 1
            ;;
    esac
fi

#=======================================
# proceed to resize, center & display requested scratchpad
#=======================================
# prepare the move command if a target output was specified
if [ -n "$TARGET_OUTPUT" ]; then
    MOVE_CMD="[${PROP}=${APPLICATION}] move window to output ${TARGET_OUTPUT};"
else
    MOVE_CMD=""
fi

# move window to specified output + show scratchpad
$WM_CMD "[${PROP}=${APPLICATION}] scratchpad show; ${MOVE_CMD} [${PROP}=${APPLICATION}] resize set ${WIN_WIDTH} ${WIN_HEIGHT}; [${PROP}=${APPLICATION}] move position center"

#=======================================
# set transparency for "YouTube Music" scratchpad on i3wm/Sway
#=======================================
if [ "$APPLICATION" = "brave-music.youtube.com__-Default" ] ; then
    # Sway
    sleep 0.01
    $WM_CMD '['$PROP'='$APPLICATION'] opacity set 0.9'
    exit 0
elif [ "$APPLICATION" = "music.youtube.com" ]; then
    # i3wm
    WINDOW_ID=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com") | .window')
    picom-trans -w $WINDOW_ID -o 90
    exit 0
fi

#=======================================
# set transparency for "WhatsApp Web" scratchpad on i3wm/Sway
#=======================================
if [ "$APPLICATION" = "brave-web.whatsapp.com__-Default" ] ; then
    # Sway
    sleep 0.01
    $WM_CMD '['$PROP'='$APPLICATION'] opacity set 0.95'
    exit 0
elif [ "$APPLICATION" = "web.whatsapp.com" ]; then
    # i3wm
    WINDOW_ID=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com") | .window')
    picom-trans -w $WINDOW_ID -o 95
    exit 0
fi
