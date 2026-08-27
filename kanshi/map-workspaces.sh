#!/usr/bin/env bash

PRIMARY=$1
SECONDARY=$2
TERTIARY=$3

CMD=""

#---------------------------------------------------------
# define where newly opened workspaces should be spawned
#---------------------------------------------------------

# primary: workspaces 0~9
if [ -n "$PRIMARY" ]; then
    for i in {1..9}; do CMD+="workspace \"${i}:${i}\" output $PRIMARY; "; done
    CMD+="workspace \"10:0\" output $PRIMARY; "
fi

# secondary: workspaces 10~19
if [ -n "$SECONDARY" ]; then
    for i in {1..9}; do CMD+="workspace \"1${i}:1${i}\" output $SECONDARY; "; done
    CMD+="workspace \"20:10\" output $SECONDARY; "
fi

# tertiary: workspaces 20~29
if [ -n "$TERTIARY" ]; then
    for i in {1..9}; do CMD+="workspace \"2${i}:2${i}\" output $TERTIARY; "; done
    CMD+="workspace \"30:20\" output $TERTIARY; "
fi

# apply rules instantly
if [ -n "$CMD" ]; then
    swaymsg -q "$CMD"
fi

#---------------------------------------------------------
# move already opened workspaces to the right output
#---------------------------------------------------------

# get a list of all currently active workspaces
active_workspaces=$(swaymsg -t get_workspaces | jq -r '.[].name')

# loop through every open workspace and check where it belongs
while IFS= read -r ws; do
    # extract the number before the colon (eg: "18:18" -> "18")
    # if there is no colon, it just takes the number
    ws_num=$(echo "$ws" | awk -F':' '{print $1}')

    target_output=""

    # ws 0~9: primary
    if (( ws_num >= 1 && ws_num <= 10 )); then
        target_output="$PRIMARY"
    elif (( ws_num >= 11 && ws_num <= 20 )); then
        # ws 10~19: sencondary
        # (if $SECONDARY is not defined, fallback to primary)
        target_output="${SECONDARY:-$PRIMARY}"
    elif (( ws_num >= 21 && ws_num <= 30 )); then
        # ws 20~29: sencondary
        # (if $TERTIARY is not defined, fallback to secondary, then to primary)
        target_output="${TERTIARY:-${SECONDARY:-$PRIMARY}}"
    fi

    # if a valid target output is found, move the workspace there
    if [ -n "$target_output" ]; then
        # the syntax requires focusing the workspace first, then moving it
        swaymsg -q "workspace \"$ws\"; move workspace to output $target_output"
    fi

done <<< "$active_workspaces"

#---------------------------------------------------------
# focus workspace 1 to avoid being left on an empty screen
#---------------------------------------------------------
swaymsg -q "workspace 1:1"
