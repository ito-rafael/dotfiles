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

#-----------------------------
# screen locking
#-----------------------------
# lock screen
swaylock --config $XDG_CONFIG_HOME/swaylock/config

#-----------------------------
# after screen unlocking
#-----------------------------


# turn on keyboard LEDs
$XDG_CONFIG_HOME/scripts/keeb-leds.sh on

# unpause notifications
dunstctl set-paused false

# delete screenshot
rm $SCREENSHOT
