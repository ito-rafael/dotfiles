#!/usr/bin/env bash

# use a temporary file in RAM
TMP_FILE="/tmp/waybar-dynamic-bg.css"
CSS_FILE="$HOME/.config/waybar/dynamic-bg.css"
# define colors
#COLOR_UNFOCUSED="rgba(43, 48, 59, 0.5)"
COLOR_FOCUSED="rgba(128, 0, 0, 0.5)"
# track state to avoid unecessary writes
LAST_OUTPUT=""

update_color() {
    # get focused output
    FOCUSED_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

    # only update if output focus changed
    if [[ "$FOCUSED_OUTPUT" != "$LAST_OUTPUT" ]]; then

        # write to the temp RAM file
        cat <<EOF > "$TMP_FILE"
window#waybar.${FOCUSED_OUTPUT} {
    background-color: $COLOR_FOCUSED;
}
EOF

        # atomically overwrite the real file
        mv "$TMP_FILE" "$CSS_FILE"

        # update tracker
        LAST_OUTPUT="$FOCUSED_OUTPUT"
    fi
}

# run once on startup
update_color

# listen continuously
swaymsg -t subscribe -m '["workspace", "window"]' | while read -r event; do
    update_color
done
