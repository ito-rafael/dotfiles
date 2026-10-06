#!/usr/bin/env bash

if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
    WM="hyprland"
else
    WM="sway"
fi

for cmd in jq bc; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: '$cmd' is not installed."
        exit 1
    fi
done

if [ "$WM" = "hyprland" ]; then
    if ! command -v hyprctl &>/dev/null; then
        echo "Error: 'hyprctl' is not installed."
        exit 1
    fi
else
    if ! command -v swaymsg &>/dev/null; then
        echo "Error: 'swaymsg' is not installed."
        exit 1
    fi
fi

show_help() {
    echo "Usage:"
    echo "  $(basename "$0") get         # Get current scale"
    echo "  $(basename "$0") toggle      # Toggle between $SCALE_DEFAULT and $SCALE_ZOOM"
    echo "  $(basename "$0") <number>    # Set scale to specific number (e.g.: 1.2)"
    echo "  $(basename "$0") help        # Show this message"
}

SCALE_DEFAULT="1.0"
SCALE_ZOOM="1.25"

SCALE_MIN="0.5"
SCALE_MAX="4.0"

STEP="0.25"

COMMAND="$1"

get_current_scale() {
    if [ "$WM" = "hyprland" ]; then
        hyprctl monitors -j | jq -r '.[0].scale'
    else
        swaymsg -t get_outputs | jq -r '.[0].scale'
    fi
}

validate_range() {
    local target_scale=$1
    # validate only positive number (integer or float)
    if ! [[ "$target_scale" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: '$target_scale' is not a valid positive number."
        exit 1
    fi

    # validate range
    local is_valid=$(echo "$target_scale >= $SCALE_MIN && $target_scale <= $SCALE_MAX" | bc -l)

    if [ "$is_valid" -eq 0 ]; then
        echo "Error: Scale '$target_scale' is out of bounds."
        echo "Please provide a scale between $SCALE_MIN and $SCALE_MAX."
        exit 1
    fi
}

set_scale() {
    local target_scale=$1

    if [ "$WM" = "hyprland" ]; then
        # loop through all monitors and apply the scale
        hyprctl monitors -j | jq -c '.[]' | while read -r mon; do
            name=$(echo "$mon" | jq -r '.name')
            width=$(echo "$mon" | jq -r '.width')
            height=$(echo "$mon" | jq -r '.height')
            refresh=$(echo "$mon" | jq -r '.refreshRate')
            echo "Setting $name to scale $target_scale..."
            # Auto position prevents layout overlap issues when scaling changes logical sizes
            hyprctl keyword monitor "$name,${width}x${height}@${refresh},auto,$target_scale" >/dev/null
        done
    else
        # get output names
        OUTPUT_NAMES=$(swaymsg -t get_outputs | jq -r '.[].name')
        # loop through all outputs and apply the scale
        for output in $OUTPUT_NAMES; do
            echo "Setting $output to scale $target_scale..."
            swaymsg output "$output" scale "$target_scale"
        done
    fi
}

case "$COMMAND" in

"help" | "-h" | "--help" | "")
    show_help
    exit 0
    ;;

"get")
    CURRENT_SCALE=$(get_current_scale)
    echo "$CURRENT_SCALE"
    exit 0
    ;;

"toggle")
    # get current scale and decide the target one
    CURRENT_SCALE=$(get_current_scale)
    # toggle between default/zoomed predefined scales
    IS_DEFAULT=$(echo "$CURRENT_SCALE == $SCALE_DEFAULT" | bc -l)
    if [ "$IS_DEFAULT" -eq 1 ]; then
        set_scale "$SCALE_ZOOM"
    else
        set_scale "$SCALE_DEFAULT"
    fi
    exit 0
    ;;

"inc" | "increase")
    # get current scale and calculate the next target step
    CURRENT_SCALE=$(get_current_scale)
    # the "scale=0" inside the parenthesis simulates the integer division
    TARGET_SCALE=$(echo "scale=0; ( ( $CURRENT_SCALE / $STEP ) + 1 ) * $STEP" | bc)
    if (($(echo "$TARGET_SCALE > $SCALE_MAX" | bc -l))); then
        TARGET_SCALE=$SCALE_MAX
    fi
    set_scale "$TARGET_SCALE"
    echo $TARGET_SCALE
    exit 0
    ;;

"dec" | "decrease")
    # get current scale and calculate the next target step
    CURRENT_SCALE=$(get_current_scale)
    # subtract a tiny epsilon and calculate step
    TARGET_SCALE=$(echo "scale=0; ( ( $CURRENT_SCALE - 0.001 ) / $STEP ) * $STEP" | bc)
    if (($(echo "$TARGET_SCALE < $SCALE_MIN" | bc -l))); then
        TARGET_SCALE=$SCALE_MIN
    fi
    set_scale "$TARGET_SCALE"
    echo $TARGET_SCALE
    exit 0
    ;;

*)
    validate_range "$COMMAND"
    set_scale "$COMMAND"
    exit 0
    ;;

esac
