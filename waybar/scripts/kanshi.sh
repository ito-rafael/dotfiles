#!/usr/bin/env bash

# function to get current profile name
get_profile() {
    kanshictl status | awk '{print $3}'
}

# function to update Waybar
update_waybar() {
    current_profile=$(get_profile)

    case "$current_profile" in
        "ipf_extend_hdmi")
            echo '{"text": ".", "tooltip": "Click to Mirror Screen", "class": "extend"}' ;;
        "ipf_mirror_hdmi")
            echo '{"text": ".", "tooltip": "Click to Extend Screen", "class": "mirror"}' ;;
        "ipf_extend_dp")
            echo '{"text": ".", "tooltip": "Click to Mirror Screen", "class": "extend"}' ;;
        "ipf_mirror_dp")
            echo '{"text": ".", "tooltip": "Click to Extend Screen", "class": "mirror"}' ;;
        *)
            # for ipf_native or any other profiles (hides the module)
            echo '{"text": "", "tooltip": "", "class": "hidden"}' ;;
    esac
}

# parse parameter
case "$1" in
    #------------------------------------------
    # toggle screen
    #------------------------------------------
    "toggle")
        current_profile=$(get_profile)
        case "$current_profile" in
            # HDMI
            "ipf_extend_hdmi") kanshictl switch ipf_mirror_hdmi ;;
            "ipf_mirror_hdmi") kanshictl switch ipf_extend_hdmi ;;
            # DisplayPort
            "ipf_extend_dp")   kanshictl switch ipf_mirror_dp ;;
            "ipf_mirror_dp")   kanshictl switch ipf_extend_dp ;;
        esac
        exit 0
        ;;
    #------------------------------------------
    # monitor profile and print JSON
    #------------------------------------------

    "monitor")
        # get initial state
        update_waybar

        # block and listen Sway output events
        swaymsg -t subscribe -m '["output"]' | while read -r event; do
            # wait kanshi apply the new profile
            sleep 0.5
            update_waybar
        done
        ;;
    #------------------------------------------
    # fallback: handle invalid or missing arguments
    #------------------------------------------
    *)
        echo "usage: $0 {toggle|monitor}"
        exit 1
        ;;
    #------------------------------------------
esac
