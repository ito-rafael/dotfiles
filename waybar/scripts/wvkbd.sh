#!/usr/bin/env bash

STATE_FILE="/tmp/wvkbd_state.tmp"
HEIGHT_FILE="/tmp/wvkbd_height.tmp"

# define variables
DEFAULT_HEIGHT=300
MIN_HEIGHT=200
MAX_HEIGHT=600
STEP=50

# ensure height file exists
if [[ ! -f "$HEIGHT_FILE" ]]; then
    echo "$DEFAULT_HEIGHT" >"$HEIGHT_FILE"
fi

current_height=$(cat "$HEIGHT_FILE")

#---------------------------------------------------------
# Actions
#---------------------------------------------------------
if [[ "$1" == "inc" || "$1" == "dec" || "$1" == "reset" ]]; then
    # debouncer: lock the file descriptor.
    exec 200>"/tmp/wvkbd_resize.lock"
    if ! flock -n 200; then
        exit 0
    fi

    # read height inside the lock to prevent stale variables
    original_height=$(cat "$HEIGHT_FILE")
    current_height=$original_height

    if [[ "$1" == "inc" ]]; then
        current_height=$((current_height + STEP))
        [[ $current_height -gt $MAX_HEIGHT ]] && current_height=$MAX_HEIGHT
    elif [[ "$1" == "dec" ]]; then
        current_height=$((current_height - STEP))
        [[ $current_height -lt $MIN_HEIGHT ]] && current_height=$MIN_HEIGHT
    elif [[ "$1" == "reset" ]]; then
        current_height=$DEFAULT_HEIGHT
    fi

    # exit early if the height didn't actually change
    if [[ "$current_height" -eq "$original_height" ]]; then
        exit 0
    fi

    # relaunch logic
    if pgrep -x "wvkbd-deskintl" >/dev/null; then
        hidden_flag=""

        if [[ -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "inactive" ]]; then
            hidden_flag="--hidden"
        fi

        pkill -x wvkbd-deskintl

        # strict wait: ensure the old process is completely gone before spawning the new one
        for _ in {1..10}; do
            pgrep -x "wvkbd-deskintl" >/dev/null || break
            sleep 0.05
        done

        swaymsg exec "wvkbd-deskintl -H $current_height -L $current_height $hidden_flag"

        # state sync: wait for the new process to register, then 'touch' the state file to force Waybar to refresh its UI out of the fail-safe.
        for _ in {1..10}; do
            pgrep -x "wvkbd-deskintl" >/dev/null && break
            sleep 0.05
        done
    fi

    # safe state sync: only write to the file now.
    echo "$current_height" >"$HEIGHT_FILE"

    # hold the lock for a split second to absorb any lingering free-spin scroll events
    sleep 0.15
    exit 0
fi

if [[ "$1" == "toggle" ]]; then
    if ! pgrep -x "wvkbd-deskintl" >/dev/null; then
        # not running: start it with current height and set state to active
        swaymsg exec "wvkbd-deskintl -H $current_height -L $current_height"
        echo "active" >"$STATE_FILE"
    else
        # running: explicitly show or hide based on current state
        if [[ -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "active" ]]; then
            pkill -SIGUSR1 -x wvkbd-deskintl # hide
            echo "inactive" >"$STATE_FILE"
        else
            pkill -SIGUSR2 -x wvkbd-deskintl # show
            echo "active" >"$STATE_FILE"
        fi
    fi
    exit 0
fi

#---------------------------------------------------------
# Monitor
#---------------------------------------------------------
# initial sync
if pgrep -x "wvkbd-deskintl" >/dev/null; then
    [[ ! -f "$STATE_FILE" ]] && echo "active" >"$STATE_FILE"
else
    [[ ! -f "$STATE_FILE" ]] && echo "inactive" >"$STATE_FILE"
fi

update_state() {
    local h=$(cat "$HEIGHT_FILE")
    # fail-safe: check if the process was killed externally
    if ! pgrep -x "wvkbd-deskintl" >/dev/null; then
        echo "{\"text\": \" \", \"class\": \"inactive\", \"tooltip\": \"wvkbd: Off (${h}px)\"}"
    elif [[ "$(<"$STATE_FILE")" == "active" ]]; then
        echo "{\"text\": \" \", \"class\": \"active\", \"tooltip\": \"wvkbd: Visible (${h}px)\"}"
    else
        echo "{\"text\": \" \", \"class\": \"inactive\", \"tooltip\": \"wvkbd: Hidden (${h}px)\"}"
    fi
}

# get initial state
update_state

# block and listen for filesystem changes in /tmp using inotify
inotifywait -q -m -e create,modify,moved_to --format '%f' /tmp | while read -r filename; do
    if [[ "$filename" == "wvkbd_state.tmp" || "$filename" == "wvkbd_height.tmp" ]]; then
        update_state
    fi
done

# ---------------------------------------------------------
# ACTIONS (inc, dec, reset, toggle)
# ---------------------------------------------------------
if [[ "$1" == "inc" || "$1" == "dec" || "$1" == "reset" ]]; then
    # 1. Debounce: Lock the file descriptor.
    exec 200>"/tmp/wvkbd_resize.lock"
    if ! flock -n 200; then
        exit 0
    fi

    # Read height INSIDE the lock to prevent stale variables
    original_height=$(cat "$HEIGHT_FILE")
    current_height=$original_height

    if [[ "$1" == "inc" ]]; then
        current_height=$((current_height + STEP))
        [[ $current_height -gt $MAX_HEIGHT ]] && current_height=$MAX_HEIGHT
    elif [[ "$1" == "dec" ]]; then
        current_height=$((current_height - STEP))
        [[ $current_height -lt $MIN_HEIGHT ]] && current_height=$MIN_HEIGHT
    elif [[ "$1" == "reset" ]]; then
        current_height=$DEFAULT_HEIGHT
    fi

    # 2. Optimization: Exit early if the height didn't actually change
    if [[ "$current_height" -eq "$original_height" ]]; then
        exit 0
    fi

    echo "$current_height" >"$HEIGHT_FILE"

    # Relaunch logic
    if pgrep -x "wvkbd-deskintl" >/dev/null; then
        hidden_flag=""

        if [[ -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "inactive" ]]; then
            hidden_flag="--hidden"
        fi

        pkill -x wvkbd-deskintl

        # 3. Strict Wait: Ensure the old process is completely gone before spawning the new one
        for _ in {1..10}; do
            pgrep -x "wvkbd-deskintl" >/dev/null || break
            sleep 0.05
        done

        swaymsg exec "wvkbd-deskintl -H $current_height -L $current_height $hidden_flag"

        # 4. State Sync: Wait a split second for the new process to register,
        # then 'touch' the state file to force Waybar to refresh its UI out of the fail-safe.
        sleep 0.1
        touch "$STATE_FILE"
    fi

    # Hold the lock for a split second to absorb any lingering free-spin scroll events
    sleep 0.15
    exit 0
fi
