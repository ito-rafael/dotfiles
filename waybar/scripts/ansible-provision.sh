#!/usr/bin/env bash

# define the interval
DELAY=3600  # 3600 seconds = 1 hour

while true; do
    # output the loading state
    echo '{"text": " ", "alt": "loading", "class": "loading"}'

    # run Ansible in check mode (--check) and force JSON output
    # obs: we redirect stderr to /dev/null so warnings don't corrupt the JSON string
    OUTPUT=$(sudo -u ansible /home/ansible/git/dotfiles/waybar/scripts/ansible-check.sh 2>/dev/null)

    # extract the sum of all 'changed' stats across all hosts
    CHANGED=$(echo "$OUTPUT" | jq -r '[.stats[].changed] | add')

    # catch errors (e.g., if Ansible failed to run entirely)
    if [ -z "$CHANGED" ] || [ "$CHANGED" == "null" ]; then
        # return a Waybar JSON error state
        echo '{"text": "⚠ err", "tooltip": "Ansible check failed to execute", "class": "error"}'
    elif [ "$CHANGED" -gt 0 ]; then
        # out of sync! send "warning" as the alt state
        echo '{"text": "'"$CHANGED"'", "alt": "out-of-sync", "tooltip": "'"$CHANGED"' tasks pending sync", "class": "out-of-sync"}'
    else
        # perfect sync! send "synced" as the alt state
        echo '{"text": "0", "alt": "synced", "tooltip": "System is fully synced", "class": "synced"}'
    fi

    sleep $DELAY
done
