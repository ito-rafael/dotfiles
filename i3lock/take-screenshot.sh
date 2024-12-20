#!/usr/bin/env sh

SCREENSHOT_XWD='/tmp/lock-screen.xwd'
SCREENSHOT_PNG='/tmp/lock-screen.png'
SCREENSHOT_DONE='/tmp/lock-screen.done'
TODO_FILE='/tmp/todo-list.tmp'
BLACK="#000000"
RED="#771111"

# delete old screenshots
rm -f $SCREENSHOT_XWD
rm -f $SCREENSHOT_PNG
rm -f $SCREENSHOT_DONE

# take screenshot
#scrot --overwrite $SCREENSHOT
xwd -root -silent -out $SCREENSHOT_XWD

# check if there are any reminders
REMINDERS=$(cat $TODO_FILE | wc -l)
if [[ $REMINDERS == "0" ]]; then
    # if no reminders, set background to black
    COLOR=$BLACK
else
    # if any reminders, set background to red
    COLOR=$RED
fi

# pixelate, blur & darken
magick              \
    $SCREENSHOT_XWD \
    -format png     \
    -scale 25%      \
    -blur 2x2       \
    -fill $COLOR    \
    -colorize 80%   \
    -scale 400%     \
    $SCREENSHOT_PNG

# check if last command executed without any errors
EXITCODE=$?

# use file as flag to signal image processing has finished
if [ $EXITCODE -eq 0 ]; then
    touch $SCREENSHOT_DONE
fi
