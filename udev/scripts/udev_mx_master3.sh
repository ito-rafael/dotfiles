# shebang not used since the script is called directly from /bin/bash

# export PATH env var for executable binary commands
export PATH=/bin:/usr/bin

#-----------------------------
# the next commands try to identify the username, uid and display
# of the user connected to an X server to send a command through it
#-----------------------------
# detect the name of the display in use (eg: ":0")
display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"
#detect the user using such display (eg: user)
user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)
# detect the id of the user (eg: 1000)
uid=$(id -u $user)

#-----------------------------
# function to send command as an user connected to the X server
#-----------------------------
function send-cmd() {
    # input [str]: command to be sent
    #-----------------------------
    # send command passed as argument of this function
    sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus $@
}

#-----------------------------
# send notification
send-cmd "notify-send MX Master3"
#-----------------------------
