#!/usr/bin/env sh

TODO_FILE='/tmp/todo-list.tmp'

# set main output for displaying the time
PRIMARY_OUTPUT="HDMI-A-1"

# We will generate the config file here on the fly
HYPRLOCK_CONF="/tmp/hyprlock-dynamic.conf"

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

# add the clock and password input on the primary monitor
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
    size = 250, 50
    outline_thickness = 3
    dots_size = 0.33
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = false
    placeholder_text = <i>Password...</i>
    position = 0, -50
    halign = center
    valign = center
}
" >> "$HYPRLOCK_CONF"

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
