#!/usr/bin/env bash

# TODO tasks file
TODO_FILE='/tmp/todo-list.tmp'
# TODO message
TASK_MSG="MX Master 3 mouse with low battery"

# define batery levels
LEVEL_1="100%"  # Full
LEVEL_2="50%"   # Good/Normal
LEVEL_3="20%"   # Low
LEVEL_4="10%"   # Critical

# ensure TODO file exists
touch "$TODO_FILE"
# remove duplicate lines, if they exist
awk '!seen[$0]++' "$TODO_FILE" > "${TODO_FILE}.tmp" && mv "${TODO_FILE}.tmp" "$TODO_FILE"

# helper function to update warning @ TODO_FILE
add_or_update_warning() {
    # check if the warning already exists in the file
    if grep -q "$TASK_MSG" "$TODO_FILE"; then
        # it exists: use sed to overwrite just that specific line to update the percentage
        sed -i "s/.*$TASK_MSG.*/$TASK_MSG;$BATTERY_LEVEL/" "$TODO_FILE"
    else
        # it doesn't exist: safely append (>>) the new line to the bottom
        echo "$TASK_MSG;$BATTERY_LEVEL" >> "$TODO_FILE"
    fi
}

# helper function to remove warning @ TODO_FILE
remove_warning() {
    # find any line containing the task message and delete it
    sed -i "/$TASK_MSG/d" "$TODO_FILE"
}

# get current battery level
BATTERY_LEVEL=$(solaar show 'MX Master 3' 2>/dev/null | tail -n1 | awk '/Battery/ {print $2}' | tr -d ',')

case "$BATTERY_LEVEL" in
    $LEVEL_1)
        remove_warning
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "full", "class": "full"}'
        ;;
    $LEVEL_2)
        remove_warning
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "good", "class": "good"}'
        ;;
    $LEVEL_3)
        add_or_update_warning
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "low", "class": "low"}'
        ;;
    $LEVEL_4)
        add_or_update_warning
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "critical", "class": "critical"}'
        ;;
    *) exit 1 ;;
esac
