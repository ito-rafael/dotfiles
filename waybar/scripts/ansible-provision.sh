#!/usr/bin/env bash

# run Ansible in check mode (--check) and force JSON output
# obs: we redirect stderr to /dev/null so warnings don't corrupt the JSON string
OUTPUT=$(sudo -u ansible /home/ansible/git/dotfiles/waybar/script/ansible-check.sh 2>/dev/null)

# extract the sum of all 'changed' stats across all hosts
CHANGED=$(echo "$OUTPUT" | jq -r '[.stats[].changed] | add')

# catch errors (e.g., if Ansible failed to run entirely)
if [ -z "$CHANGED" ] || [ "$CHANGED" == "null" ]; then
    # return a Waybar JSON error state
    echo '{"text": "⚠ err", "tooltip": "Ansible check failed to execute", "class": "error"}'
    exit 1
fi

# format the output for Waybar based on the state
if [ "$CHANGED" -gt 0 ]; then
    # out of sync! Show the number of changed tasks.
    echo "{\"text\": \" $CHANGED\", \"tooltip\": \"$CHANGED tasks pending sync\", \"class\": \"warning\"}"
else
    # perfect sync!
    echo "{\"text\": \"\", \"tooltip\": \"System is fully synced\", \"class\": \"synced\"}"
fi
