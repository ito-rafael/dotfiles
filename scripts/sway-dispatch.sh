#!/usr/bin/env bash

shopt -s extglob # enable special variable syntax

TERMINAL_LIST=(
    "kitty"
    "dropdown_terminal"
    "dropdown_python"
)

IFS='|' # set separator to pipe temporarily
TERMINALS="@(${TERMINAL_LIST[*]})"
unset IFS # reset separator

# Usage:
# ./smart_dispatch.sh focus left
# ./smart_dispatch.sh type symbol
# ./smart_dispatch.sh launch

COMMAND="$1"
PARAM="$2"

# get the app_id of the focused window
# some XWayland apps might have null app_id, so we fallback to window_properties.class if needed
FOCUSED_APP=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | if .app_id then .app_id else .window_properties.class end')

case "$COMMAND" in

"focus")
    DIRECTION="$PARAM"
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(evil-window-$DIRECTION 1)" >/dev/null 2>&1 ;;
    *) swaymsg focus "$DIRECTION" ;;
    esac
    ;;

"kill")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(evil-window-delete)" >/dev/null 2>&1 ;;
    *) "$HOME/.config/scripts/hide-or-kill.sh" ;;
    esac
    ;;

"cut")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(execute-extended-command)" >/dev/null 2>&1 ;;
    $TERMINALS) ydotool key 29:1 42:1 45:1 45:0 42:0 29:0 ;; # C-S-x
    *) ydotool key 29:1 45:1 45:0 29:0 ;;                    # C-x
    esac
    ;;

"copy")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(evil-yank)" >/dev/null 2>&1 ;;
    $TERMINALS) ydotool key 29:1 42:1 46:1 46:0 42:0 29:0 ;; # C-S-c
    *) ydotool key 29:1 46:1 46:0 29:0 ;;                    # C-c
    esac
    ;;

"paste")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(evil-paste-before)" >/dev/null 2>&1 ;;
    $TERMINALS) ydotool key 29:1 42:1 47:1 47:0 42:0 29:0 ;; # C-S-v
    *) ydotool key 29:1 47:1 47:0 29:0 ;;                    # C-v
    esac
    ;;

"fullscreen")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -s efs --eval "(zoom-window-zoom)" >/dev/null 2>&1 ;;
    *) swaymsg fullscreen toggle ;;
    esac
    ;;

"new_terminal")
    case "$FOCUSED_APP" in
    [Ee]macs*) emacsclient -n -s efs --eval "(progn (split-window-autotiling) (other-window 1) (counsel-find-file))" >/dev/null 2>&1 ;;
    *) kitty ;;
    esac
    ;;

esac
