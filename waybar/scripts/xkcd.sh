#!/usr/bin/env bash

FILE="/tmp/xkcd.tmp"

# handle the click action
if [[ "$1" == "open" ]]; then
    if [[ -f "$FILE" ]]; then
        NUMBER=$(cat "$FILE")
        # remove the file immediately to switch to the inactive state
        rm -f "$FILE"
        xdg-open "https://www.explainxkcd.com/$NUMBER"
    else
        # fallback if clicked while inactive
        xdg-open "https://www.explainxkcd.com/"
    fi
    exit 0
fi

# print state for Waybar
print_state() {
    if [[ -f "$FILE" ]]; then
        NUMBER=$(cat "$FILE")
        echo '{"text": ".", "class": "active", "tooltip": "Explain xkcd: '"$NUMBER"'"}'
    else
        echo '{"text": ".", "class": "inactive", "tooltip": "Explain xkcd (No pending comic)"}'
    fi
}

# initial Waybar render
print_state

# monitor /tmp for changes to dynamically update the state
inotifywait -q -m -e close_write,create,moved_to,delete /tmp | while read -r dir action file; do
    if [[ "$file" == "xkcd.tmp" ]]; then
        print_state
    fi
done
