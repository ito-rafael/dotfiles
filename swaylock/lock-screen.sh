#!/usr/bin/env sh

TODO_FILE='/tmp/todo-list.tmp'
SCREENSHOT=$XDG_CONFIG_HOME/swaylock/screenshot.png

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
if [[ $REMINDERS == "0" ]]; then
    # if no reminders, take a simple screenshot
    grim - | magick - $SCREENSHOT
else
    # if any reminders, take screenshot (grim's stdout) and apply a red background (ImageMagick's stdin)
    grim - | magick -  \
        -format png    \
        -fill red      \
        -colorize 80%  \
        $SCREENSHOT
fi

# save current screen brightness and dim it
brightnessctl --quiet --save
brightnessctl --quiet set 10%

#-----------------------------
# screen locking
#-----------------------------

# lock remote screen, if any
ssh ipf "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg exec $XDG_CONFIG_HOME/swaylock/lock-screen.sh" &

# lock screen
swaylock --config $XDG_CONFIG_HOME/swaylock/config

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
rm $SCREENSHOT
