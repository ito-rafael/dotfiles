#!/usr/bin/env bash

# set paths for the =lightdm= user
export USER_HOME="/var/lib/lightdm"
export XDG_CONFIG_HOME="$USER_HOME/.config"
export XDG_RUNTIME_DIR="/run/user/$(id -u lightdm)"
export DISPLAY=":0"
# get the Xauthority cookie (authentication file)
export XAUTHORITY=$(ps ax | grep -oP '(?<=-auth )\S+' | head -n 1)

# create directories and set permissions
mkdir -p "$XDG_CONFIG_HOME/lan-mouse"
mkdir -p "$XDG_RUNTIME_DIR"
chown -R lightdm:lightdm "$USER_HOME" "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"

# wait for X server to initialize
sleep 5
# allow the =lightdm= user to connect to the display
xhost +SI:localuser:lightdm

# launch lan-mouse as the =lightdm= user with a clean environment
sudo -u lightdm -H bash -c "
  export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR;
  export XDG_CONFIG_HOME=$XDG_CONFIG_HOME;
  export DISPLAY=$DISPLAY;
  export XAUTHORITY=$XAUTHORITY;
  /usr/bin/lan-mouse daemon
" &
