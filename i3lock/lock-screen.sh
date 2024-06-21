#!/usr/bin/env sh

SCREENSHOT_XWD='/tmp/lock-screen.xwd'
SCREENSHOT_PNG='/tmp/lock-screen.png'

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
