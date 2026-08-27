#!/usr/bin/env bash

PRIMARY=$1
SECONDARY=$2
TERTIARY=$3

CMD=""

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
    swaymsg "$CMD"
fi
