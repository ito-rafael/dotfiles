#!/usr/bin/env sh

SCREENSHOT_PNG='/tmp/lock-screen.png'

# lock screen
i3lock \
    --image=$SCREENSHOT_PNG         \
    --nofork

# The "--nofork" flag of the i3lock command garantees that the
# next commands will run only after the system is unlocked.

# delete screenshots
rm -f $SCREENSHOT_PNG
