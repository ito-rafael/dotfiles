#!/usr/bin/env bash

# information:
#   - native Wayland windows have a ".shell" property of "xdg_shell"
#   - X11 windows have a ".shell" property of "xwayland"

# function to check the focused window's shell type and output JSON
update_state() {
    # query Sway's tree once per event to minimize overhead
    local tree
    tree=$(swaymsg -t get_tree)

    # extract the shell property of the currently focused node
    local focused_shell
    focused_shell=$(echo "$tree" | jq -r '.. | objects | select(.focused? == true) | .shell' 2>/dev/null)

    # count all nodes in the tree that have the shell property set to "xwayland"
    local count
    count=$(echo "$tree" | jq '[.. | objects | select(.shell? == "xwayland")] | length' 2>/dev/null)

    # output JSON based on the count and focus state
    if [[ -z "$count" || "$count" -eq 0 ]]; then
        # no Xwayland windows running
        echo '{"text": "", "class": "empty", "tooltip": ""}' || exit 0
    elif [[ "$focused_shell" == "xwayland" ]]; then
        # Xwayland windows exist and one is currently focused
        echo "{\"text\": \"$count\", \"class\": \"focused\", \"tooltip\": \"Focused window is Xwayland.\\nTotal Xwayland windows: $count\"}" || exit 0
    else
        # Xwayland windows exist, but a native Wayland window is currently focused
        echo "{\"text\": \"$count\", \"class\": \"background\", \"tooltip\": \"Native Wayland window focused.\\nTotal Xwayland windows: $count\"}" || exit 0
    fi
}

# print initial state
update_state

# block and listen for Sway events
# subscribe to "window" (focus changes, opens, closes) and "workspace" (switching workspaces)
swaymsg -t subscribe -m '["window", "workspace"]' | while read -r event; do
    update_state
done
