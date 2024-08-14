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
# pause medias
playerctl --all-players pause
# dim LEDs of keyboard
$XDG_CONFIG_HOME/scripts/keyboard-leds.sh dim

# lock screen
i3lock \
    --image=$SCREENSHOT_PNG         \
    --color=00000099                \
    --screen=1                      \
                                    \
    --indicator                     \
    --radius=120                    \
    --ring-width=10                 \
    --line-color=000000             \
                                    \
    --clock                         \
    --time-color=1793d1bb           \
    --time-str="%H:%M:%S"           \
    --time-size=38                  \
                                    \
    --date-color=1793d1bb           \
    --date-str="%d %b"              \
    --date-size=20                  \
                                    \
    --inside-color=111111aa         \
    --ring-color=1793d155           \
    --keyhl-color=1793d1            \
    --bshl-color=fa000077           \
                                    \
    --verif-text="Verifying"        \
    --verif-size=38                 \
    --insidever-color=0077ff88      \
    --ringver-color=3300ffff        \
                                    \
    --wrong-text="Wrong"            \
    --wrong-size=38                 \
    --insidewrong-color=883300cc    \
    --ringwrong-color=fa0000aa      \
                                    \
    --noinput-text="Cleared"        \
                                    \
    --nofork

# The "--nofork" flag of the i3lock command garantees that the
# next commands will run only after the system is unlocked.

# turn on keyboard LEDs
$XDG_CONFIG_HOME/scripts/keyboard-leds.sh on

# unpause notifications
dunstctl set-paused false

# delete screenshots
rm -f $SCREENSHOT_XWD
rm -f $SCREENSHOT_PNG
rm -f $SCREENSHOT_DONE
