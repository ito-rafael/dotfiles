#!/usr/bin/env bash

# run informant silently
UNREAD_COUNT=$(informant list --unread 2>/dev/null | wc -l)

# check if the exit code is greater than 0
if [ "$UNREAD_COUNT" -gt 0 ]; then
    # output JSON for Waybar to parse
    echo '{"text": "'"$UNREAD_COUNT"'", "tooltip": "'"$UNREAD_COUNT"' unread Arch News items!", "class": "news"}'
else
    # output empty text (hide module)
    echo '{"text": "", "tooltip": "No unread news.", "class": "empty"}'
fi
