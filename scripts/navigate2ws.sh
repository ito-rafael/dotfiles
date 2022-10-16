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
# regex for two digits number
elif ! [[ $1 =~ ^[0-9]{,2}$ ]]; then
	printf "Error: 'ws' parameter missing or not understood!\n\n"
	echo "$usage"
	exit
else
    WORKSPACE=$1
    #=================================================
    # list the name of the workspaces
    #=================================================
    # todo: read from i3/sway config file

    # primary screen
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
    # secondary screen
    WS11="11 "
    WS12="12 "
    WS13="13 "
    WS14="14 "
    WS15="15 "
    WS16="16 "
    WS17="17 "
    WS18="18 "
    WS19="19 J"
    WS10="20 E"
    # tertiary screen
    WS21="21"
    WS22="22"
    WS23="23"
    WS24="24"
    WS25="25"
    WS26="26"
    WS27="27"
    WS28="28"
    WS29="29"
    WS20="30"
    
    #=================================================
    # get the workspace to navigate to
    #=================================================
    case $WORKSPACE in
        # primary screen
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
        # secondary screen
        11 ) WS_NAME=$WS11 ;;
        12 ) WS_NAME=$WS12 ;;
        13 ) WS_NAME=$WS13 ;;
        14 ) WS_NAME=$WS14 ;;
        15 ) WS_NAME=$WS15 ;;
        16 ) WS_NAME=$WS16 ;;
        17 ) WS_NAME=$WS17 ;;
        18 ) WS_NAME=$WS18 ;;
        19 ) WS_NAME=$WS19 ;;
        10 ) WS_NAME=$WS10 ;;
        # tertiary screen
        21 ) WS_NAME=$WS21 ;;
        22 ) WS_NAME=$WS22 ;;
        23 ) WS_NAME=$WS23 ;;
        24 ) WS_NAME=$WS24 ;;
        25 ) WS_NAME=$WS25 ;;
        26 ) WS_NAME=$WS26 ;;
        27 ) WS_NAME=$WS27 ;;
        28 ) WS_NAME=$WS28 ;;
        29 ) WS_NAME=$WS29 ;;
        20 ) WS_NAME=$WS20 ;;
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
    if ${CMD_MSG} -t get_workspaces | grep -e "$WS_NAME";
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
            # primary screen
            1 ) kitty ;;
            2 ) firefox & ;;
            3 ) brave & ;;
            4 ) thunderbird & ;;
            5 ) libreoffice --calc "/home/rafael/Desktop/Coisas da casa.ods" & ;;
            6 ) lutris & ;;
            7 ) deluge & nicotine & ;;
            8 ) lollypop & ;;
            9 ) spotify & ;;
            0 ) pavucontrol & blueman-manager & ;;
            #-------------------------------------
            # secondary screen
            11) ;;
            12) ;;
            13) ;;
            14) ;;
            15) ;;
            16) ;;
            17) ;;
            18) ;;
            19) ;;
            10) ;;
        esac
    fi
fi
