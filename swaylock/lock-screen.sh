#!/usr/bin/env sh

#-----------------------------
# before screen locking
#-----------------------------

# pause notifications
dunstctl set-paused true

# dim LEDs of keyboard
$XDG_CONFIG_HOME/scripts/keyboard-leds.sh dim

#-----------------------------
# screen locking
#-----------------------------
# lock screen
swaylock --config $XDG_CONFIG_HOME/swaylock/config

#-----------------------------
# after screen locking
#-----------------------------

# turn on keyboard LEDs
$XDG_CONFIG_HOME/scripts/keyboard-leds.sh on

# unpause notifications
dunstctl set-paused false
