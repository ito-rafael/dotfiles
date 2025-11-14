#!/usr/bin/env bash
#
# This script is used to paste the emoji selected in emote according to the context.
# Depending on the window, a different key combination is sent via ydotool:
#   - Emacs: F18 (evil-paste-after)
#   - Terminal (kitty): C-S-v
#   - other: C-v
#
#=======================================
# identify session (i3wm/Sway) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        ;;
    "tty")
        exit 1
        ;;
    *)
        exit 1
        ;;
esac

#=======================================
# send commands to Emote + paste emoji
#=======================================

# copy emoji (S-Enter)
ydotool key 42:1 28:1 28:0 42:0

# exit Emote (Esc)
ydotool key 1:1 1:0

# get focused window
FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$PROP'')

# paste emoji according to window context
case "${FOCUSED}" in
    emacs*|Emacs)
        # F18 (evil-paste-after)
        ydotool key 188:1 188:0
        ;;
    kitty|dropdown_terminal)
        # C-S-v
        ydotool key 29:1 42:1 47:1 47:0 42:0 29:0
        ;;
    *)
        # C-v
        ydotool key 29:1 47:1 47:0 29:0
        ;;
esac
