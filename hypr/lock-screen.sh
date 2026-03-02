#!/usr/bin/env sh

TODO_FILE='/tmp/todo-list.tmp'

# set main output for displaying the time
PRIMARY_OUTPUT="HDMI-A-1"
SECONDARY_OUTPUT="DP-1"
TERTIARY_OUTPUT="DVI-I-1"

# config generated on the fly
HYPRLOCK_CONF="/tmp/hyprlock-dynamic.conf"
XKCD_IMG="/tmp/hyprlock-xkcd.png"

#-----------------------------
# before screen locking
#-----------------------------

# pause notifications & media
dunstctl set-paused true
playerctl --all-players pause

# dim LEDs of keyboard
$XDG_CONFIG_HOME/scripts/keeb-leds.sh dim

REMINDERS=$(cat "$TODO_FILE" | wc -l)
SCREENSHOTS=""

# fetch random xkcd
# check if xkcd.com is reachable
if curl --output /dev/null --silent --head --fail "https://xkcd.com"; then
    # get the latest comic number
    LATEST=$(curl -s "https://xkcd.com/info.0.json" | jq -r '.num')
    # pick a random number between 1 and LATEST using shuf
    RAND_NUM=$(shuf -i 1-"$LATEST" -n 1)
    # skip the 404 comic
    while [ "$RAND_NUM" -eq 404 ]; do
        RAND_NUM=$(shuf -i 1-"$LATEST" -n 1)
    done
    # get the direct image URL for the random comic
    IMG_URL=$(curl -s "https://xkcd.com/$RAND_NUM/info.0.json" | jq -r '.img')
    # download the image to our temporary file
    curl -s "$IMG_URL" -o "$XKCD_IMG"
else
    # if offline, remove the temp file so hyprlock doesn't try to load garbage
    rm -f "$XKCD_IMG"
fi

# start building the Hyprlock configuration
> "$HYPRLOCK_CONF" # clear the file

if [[ "$REMINDERS" == "0" ]]; then
    # no reminders: use Hyprlock's native, instant blur across all monitors.
    # leaving 'monitor =' empty applies this background to all screens.
    echo "
    background {
        monitor =
        path = screenshot
        blur_passes = 3
        blur_size = 8
    }" >> "$HYPRLOCK_CONF"

else
    # if any reminders, take screenshot (grim's stdout) and apply a red background (ImageMagick's stdin)
    for OUTPUT in $(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .name'); do
        SCREENSHOT="/tmp/hyprlock-${OUTPUT}.png"
        SCREENSHOTS="$SCREENSHOTS $SCREENSHOT"

        grim -o "$OUTPUT" - | magick - \
            -format png    \
            -fill red      \
            -colorize 80%  \
            "$SCREENSHOT"

        # write a specific background block for this exact monitor
        echo "
        background {
            monitor = $OUTPUT
            path = $SCREENSHOT
        }" >> "$HYPRLOCK_CONF"
    done
fi

# primary output: clock and password input ring
echo "
label {
    monitor = $PRIMARY_OUTPUT
    text = \$TIME
    font_size = 90
    font_family = sans-serif
    color = rgba(255, 255, 255, 1.0)
    position = 0, 150
    halign = center
    valign = center
}

input-field {
    monitor = $PRIMARY_OUTPUT
    size = 100, 100
    outline_thickness = 4
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = true
    placeholder_text =
    hide_input = true
    position = 0, -50
    halign = center
    valign = center
}
" >> "$HYPRLOCK_CONF"

# secondary output: xkcd image
if [[ -f "$XKCD_IMG" ]]; then
    echo "
    image {
        monitor = $SECONDARY_OUTPUT
        path = $XKCD_IMG
        size = 250
        rounding = 0
        border_size = 4
        border_color = rgb(15, 15, 15)
        position = 0, 0
        halign = center
        valign = center
    }
    " >> "$HYPRLOCK_CONF"
fi

# tertiary: reminder/to-do list
if [[ "$REMINDERS" != "0" ]]; then
    echo "
    image {
        monitor = $TERTIARY_OUTPUT
        path = /home/rafael/.config/hypr/todo-list.png
        size = 250
        rounding = 0
        border_size = 3
        border_color = rgb(200, 200, 200)
        position = 0, 0
        halign = center
        valign = center
    }
    " >> "$HYPRLOCK_CONF"
fi

# save current screen brightness and dim it
brightnessctl --quiet --save
brightnessctl --quiet set 10%

#-----------------------------
# screen locking
#-----------------------------

# lock remote screen, if any
ssh ipf "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg exec $XDG_CONFIG_HOME/swaylock/lock-screen.sh" &

# lock the screen with hyprlock using the dynamically generated config
hyprlock --config "$HYPRLOCK_CONF"

#-----------------------------
# after screen unlocking
#-----------------------------

# unlock remote screen, if any
ssh ipf "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); pkill -USR1 swaylock" &

# restore previous screen brightness
brightnessctl --quiet --restore

# turn on keyboard LEDs
$XDG_CONFIG_HOME/scripts/keeb-leds.sh on

# unpause notifications
dunstctl set-paused false

# cleanup screenshots if they were generated
if [ -n "$SCREENSHOTS" ]; then
    rm -f $SCREENSHOTS
fi
