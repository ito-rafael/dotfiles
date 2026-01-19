#!/usr/bin/env bash

# description:
#   script to share clipboard via lan-mouse (software KVM) with the sender host.
# how it works:
#   it monitors the output of the journal for the lan-mouse unit, and once it 
#   detects that the cursor moved back to the sender, it runs push-clipboard.sh
#   script that sends the clipboard via SSH forced commands (previously 
#   configured in ~/.ssh/authorized-keys).

# define unit to monitor
UNIT="lan-mouse"
# define message to monitor on output of journalctl
TRIGGER_TEXT="releasing capture: no active client at this position"
# set cooldown (in seconds) to avoid double trigger
COOLDOWN=1
LAST_TRIGGER=0

# monitor the journal for the specific user unit
journalctl --user -u $UNIT -f -n 0 | while read -r line; do
    if [[ "$line" == *"$TRIGGER_TEXT"* ]]; then
        CURRENT_TIME=$(date +%s)

        # check if enough time (cooldown) has passed since the last trigger
        if (( CURRENT_TIME - LAST_TRIGGER >= COOLDOWN )); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Mouse returned to PC. Sending clipboard..."
            $HOME/.config/scripts/push-clipboard.sh catuaba > /dev/null
            # append "Done!" or "Failed!" to the previous line according to the script status
            if [ $? -eq 0 ]; then
                echo " Done!"
            else
                echo " Failed!"
            fi
            LAST_TRIGGER=$CURRENT_TIME
        fi
    fi
done
