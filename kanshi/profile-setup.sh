#!/usr/bin/env bash
PROFILE=$1

# define reusable paths
WALLPAPER_DIR="$HOME/.config/wallpaper"
MAP_WS="$HOME/.config/scripts/map-workspaces.sh"
WAYBAR_DYN="$HOME/.config/waybar/dynamic-output.json"
DELAY=1

case "$PROFILE" in

"catuaba")
    # map workspaces
    "$MAP_WS" "HDMI-A-1" "DP-1" "DVI-I-1"
    # apply background image
    swaymsg -q "\
        output HDMI-A-1 bg $WALLPAPER_DIR/london.jpg fill; \
        output DP-1     bg $WALLPAPER_DIR/london.jpg fill; \
        output DVI-I-1  bg $WALLPAPER_DIR/nasa.jpg fill"
    ;;

"ipf_triple_monitor")
    # enable Waybar in external monitor
    echo '{}' >"$WAYBAR_DYN"
    # restart Waybar service
    systemctl --user restart waybar
    sleep "$DELAY"
    # map workspaces
    "$MAP_WS" "eDP-1" "HDMI-A-1" "DP-1"
    # apply background image
    swaymsg -q "\
        output eDP-1    bg $WALLPAPER_DIR/london.jpg fill; \
        output HDMI-A-1 bg $WALLPAPER_DIR/london.jpg fill; \
        output DP-1     bg $WALLPAPER_DIR/nasa.jpg fill"
    ;;

"ipf_extend_hdmi")
    # enable Waybar in external monitor
    echo '{}' >"$WAYBAR_DYN"
    # restart Waybar service
    systemctl --user restart waybar
    sleep "$DELAY"
    # map workspaces
    "$MAP_WS" "eDP-1" "HDMI-A-1"
    # apply background image
    swaymsg -q "\
        output eDP-1    bg $WALLPAPER_DIR/london.jpg fill; \
        output HDMI-A-1 bg $WALLPAPER_DIR/london.jpg fill"
    ;;

"ipf_extend_dp")
    # enable Waybar in external monitor
    echo '{}' >"$WAYBAR_DYN"
    # restart Waybar service
    systemctl --user restart waybar
    sleep "$DELAY"
    # map workspaces
    "$MAP_WS" "eDP-1" "DP-1"
    # apply background image
    swaymsg -q "\
        output eDP-1 bg $WALLPAPER_DIR/london.jpg fill; \
        output DP-1  bg $WALLPAPER_DIR/london.jpg fill"
    ;;

"ipf_mirror_hdmi" | "ipf_mirror_dp")
    # disable Waybar in external monitor
    echo '{"output": ["eDP-1"]}' >"$WAYBAR_DYN"
    # restart Waybar service
    systemctl --user restart waybar
    sleep "$DELAY"
    # map workspaces
    "$MAP_WS" "eDP-1"
    # apply background image
    swaymsg -q "output eDP-1 bg $WALLPAPER_DIR/london.jpg fill"
    ;;

"ipf_native")
    # clear Waybar dynamic config
    echo '{}' >"$WAYBAR_DYN"
    # restart Waybar service
    systemctl --user restart waybar
    # map workspaces
    "$MAP_WS" "eDP-1"
    # apply background image
    swaymsg -q "output eDP-1 bg $WALLPAPER_DIR/london.jpg fill"
    ;;

"vb_hub1")
    # map workspaces
    "$MAP_WS" "HDMI-A-1" "DP-1" "eDP-1"
    # apply background image
    swaymsg -q "\
        output HDMI-A-1 bg $WALLPAPER_DIR/london.jpg fill; \
        output DP-1     bg $WALLPAPER_DIR/london.jpg fill; \
        output DVI-I-1  bg $WALLPAPER_DIR/nasa.jpg fill"
    ;;

"vb_hub2")
    # map workspaces
    "$MAP_WS" "HDMI-A-1" "DP-1" "eDP-1"
    # apply background image
    swaymsg -q "\
        output HDMI-A-1 bg $WALLPAPER_DIR/london.jpg fill; \
        output DP-1     bg $WALLPAPER_DIR/london.jpg fill; \
        output DVI-I-1  bg $WALLPAPER_DIR/nasa.jpg fill"
    ;;

"msc_presentation")
    # map workspaces
    "$MAP_WS" "eDP-1" "HDMI-A-1" "DP-1"
    ;;

*)
    exit 0
    ;;
esac
