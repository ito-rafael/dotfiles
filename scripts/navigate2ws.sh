#!/bin/bash

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") ws [-h]

where:
    -h, --help   show this help text
    -ws          workspace number to navigate to"
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to navigate to i3/sway workspaces and open specifics windows if woskpace is empty\n\n"
	echo "$usage"
	exit
#------------------------
# regex for one digit number
elif ! [[ $1 =~ ^[0-9]{,1}$ ]]; then
	printf "Error: 'ws' parameter missing or not understood!\n\n"
	echo "$usage"
	exit
else
    WORKSPACE=$1
    #=================================================
    # list the name of the workspaces
    #=================================================
    # todo: read from i3/sway config file
    WS1="1 "
    WS2="2 "
    WS3="3 "
    WS4="4 "
    WS5="5 "
    WS6="6 "
    WS7="7 "
    WS8="8 "
    WS9="9 "
    WS0="10 "
    
    #=================================================
    # get the workspace to navigate to
    #=================================================
    case $WORKSPACE in
        1 ) WS_NAME=$WS1 ;;
        2 ) WS_NAME=$WS2 ;;
        3 ) WS_NAME=$WS3 ;;
        4 ) WS_NAME=$WS4 ;;
        5 ) WS_NAME=$WS5 ;;
        6 ) WS_NAME=$WS6 ;;
        7 ) WS_NAME=$WS7 ;;
        8 ) WS_NAME=$WS8 ;;
        9 ) WS_NAME=$WS9 ;;
        0 ) WS_NAME=$WS0 ;;
    esac
    
    #=================================================
    # check if navigating to current workspace
    #=================================================
    # get the current focused workspace
    #CURRENT_WS=$(
    #    i3-msg -t get_workspaces |
    #    jq -r '.[] |
    #    select(.focused==true).name' \
    #)
    #if [ $WS_NAME -eq $CURRENT_WS ];
    #then
    
    #=================================================
    # get session type (i3/sway/tty)
    #=================================================
    case "${XDG_SESSION_TYPE}" in
        "x11")
            CMD_MSG="i3-msg"
            ;;
        "wayland")
            CMD_MSG="swaymsg"
            ;;
        "tty")
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
    #=================================================
    # navigate to workspace and open windows if empty
    #=================================================
    # check if the workspace is empty
    if ${CMD_MSG} -t get_workspaces | grep -e "\"name\":\"$WS_NAME";
    then
        # if not, navigate to the workspace
        ${CMD_MSG} -t command workspace $WS_NAME;
    else
        # if it is, navigate to the workspace and open the layout and windows associated to it
        ${CMD_MSG} -t command "workspace $WS_NAME";
        if [[ ${CMD_MSG} == "i3-msg" ]]; then
            ${CMD_MSG} -t append_layout "/home/rafael/.config/i3/ws$WORKSPACE.json"
        fi
        case $WORKSPACE in
        1 )
            #nohup xfce4-terminal --command="ranger /home/rafael" &
            #nohup google-keep &
            #nohup i3-sensible-terminal &
            #nohup i3-sensible-terminal --working-directory /home/rafael &
#            nohup le terminal --working-directory /home/rafael &
#            nohup firefox &
#            nohup termite &
            # !!! BUG HERE !!!
            # Terminal being swallowed, but with problems (compositor? X?)
#            i3-msg -t command workspace $WS_NAME
#            sleep 0.1
            #nohup i3-sensible-terminal &
#            nohup xfce4-terminal &
#            i3-msg move container to workspace $WS_NAME
#            i3-msg -t command workspace $WS_NAME
            nohup kitty &
            ;;
        2 )
            nohup firefox &
            ;;
        3 )
            #nohup chromium &
            nohup brave &
            ;;
        4 )
            nohup thunderbird &
            ;;
        5 )
            #nohup thunar &
            nohup libreoffice --calc "/home/rafael/Desktop/Coisas da casa.ods" &
            ;;
        6 )
            nohup lutris &
            ;;
        7 )
            nohup deluge & 
            nohup nicotine & 
            ;;
        8 )
            nohup lollypop &
            ;;
        9 )
            nohup spotify &
            ;;
        0 )
            nohup pavucontrol &
            nohup blueman-manager &
            ;;
        esac
    fi
fi
