#!/usr/bin/env sh

SCREENSHOT_XWD='/tmp/lock-screen.xwd'
SCREENSHOT_PNG='/tmp/lock-screen.png'
SCREENSHOT_DONE='/tmp/lock-screen.done'

# delete old screenshots
rm -f $SCREENSHOT_XWD
rm -f $SCREENSHOT_PNG
rm -f $SCREENSHOT_DONE
