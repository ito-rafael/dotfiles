#!/usr/bin/env sh

SCREENSHOT_XWD='/tmp/lock-screen.xwd'
SCREENSHOT_PNG='/tmp/lock-screen.png'
SCREENSHOT_DONE='/tmp/lock-screen.done'

# wait screenshot (or timeout)
TIMEOUT=3
timeout $TIMEOUT bash -c -- 'while [ ! -f \$SCREENSHOT_DONE ]; do sleep 0.1; done'

# if $SCREENSHOT_DONE does not exist after timeout, send notification & exit
if [ ! -f $SCREENSHOT_DONE ]; then

    # delete raw screenshot
    rm -f $SCREENSHOT_XWD

    # send alert notification
    notify-send \
        --expire-time=0 \
        --urgency=CRITICAL \
        --icon='/usr/share/icons/Papirus/symbolic/status/dialog-error-symbolic.svg' \
        "i3locker failed!" \
        "File $SCREENSHOT_DONE not found."

    # play alert sound
    paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
    exit 1
fi

# pause notifications
dunstctl set-paused true

# lock screen
i3lock \
    --image=$SCREENSHOT_PNG         \
    --nofork

# The "--nofork" flag of the i3lock command garantees that the
# next commands will run only after the system is unlocked.

# unpause notifications
dunstctl set-paused false

# delete screenshots
rm -f $SCREENSHOT_XWD
rm -f $SCREENSHOT_PNG
rm -f $SCREENSHOT_DONE
