#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
# If all your bars have ipc enabled, you can also use 
# polybar-msg cmd quit

# small delay
sleep 1

# Launch Polybar, using default config location ~/.config/polybar/config.ini
#polybar i3 2>&1 | tee -a /tmp/polybar.log & disown
for m in $(polybar --list-monitors | cut -d":" -f1); do
    #MONITOR=$m polybar --reload i3 &
    MONITOR=$m FC_DEBUG=1 polybar --reload i3 &
done

echo "Polybar launched..."
