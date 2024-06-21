#!/usr/bin/env sh

SCREENSHOT_XWD='/tmp/lock-screen.xwd'
SCREENSHOT_PNG='/tmp/lock-screen.png'

# take screenshot
#scrot --overwrite $SCREENSHOT_PNG
xwd -root -silent -out $SCREENSHOT_XWD

magick              \
    $SCREENSHOT_XWD \
    $SCREENSHOT_PNG
