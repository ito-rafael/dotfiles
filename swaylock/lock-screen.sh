#!/usr/bin/env sh

TODO_FILE='/tmp/todo-list.tmp'

#-----------------------------
# before screen locking
#-----------------------------

# pause notifications
dunstctl set-paused true

# pause medias
playerctl --all-players pause

# dim LEDs of keyboard
$XDG_CONFIG_HOME/scripts/keeb-leds.sh dim

# check if there are any reminders
REMINDERS=$(cat $TODO_FILE | wc -l)

# var to hold swaylock arguments and a list for cleanup
SWAYLOCK_ARGS=""
SCREENSHOTS=""

# loop through all active outputs (monitors)
for OUTPUT in $(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .name'); do
    SCREENSHOT="/tmp/swaylock-${OUTPUT}.png"
    SCREENSHOTS="$SCREENSHOTS $SCREENSHOT"

    if [[ "$REMINDERS" == "0" ]]; then
        # if no reminders, take a simple screenshot of this output
        grim -o "$OUTPUT" "$SCREENSHOT"
    else
        # if any reminders, take screenshot (grim's stdout) and apply a red background (ImageMagick's stdin)
        grim -o "$OUTPUT" - | magick - \
            -format png    \
            -fill red      \
            -colorize 80%  \
            "$SCREENSHOT"
    fi

    # append the specific image for this output to the swaylock arguments
    SWAYLOCK_ARGS="$SWAYLOCK_ARGS -i $OUTPUT:$SCREENSHOT"
done

# save current screen brightness and dim it
brightnessctl --quiet --save
brightnessctl --quiet set 10%

#-----------------------------
# screen locking
#-----------------------------

# lock remote screen, if any
ssh ipf "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg exec $XDG_CONFIG_HOME/swaylock/lock-screen.sh" &

# lock screen
swaylock $SWAYLOCK_ARGS --config "$XDG_CONFIG_HOME/swaylock/config"

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

# delete screenshot
rm $SCREENSHOTS
