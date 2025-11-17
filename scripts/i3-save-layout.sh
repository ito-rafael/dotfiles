#!/bin/bash

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") ws [-h]

where:
    -h, --help   show this help text
    -ws          workspace number to save layout"
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to save i3 layout\n\n"
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
    FILENAME=$HOME/.config/i3/ws$WORKSPACE.json
    #=================================================
    # save workspace layout to file
    i3-save-tree --workspace $WORKSPACE > $FILENAME
    #=================================================
    # editing the json file: vim ~/.config/i3/wsN.json
    #--------------------------
    # remove the first line:
    # // vim:ts=4:sw=4:et
    sed -i '/^\/\/ vim:/d' $FILENAME
    #--------------------------
    # delete 'window_role' item:
    # // "window_role": "^browser$"
    sed -i '/"window_role": "/d' $FILENAME
    #--------------------------
    # remove the "//" under 'swallows' section:
    # // "class": "^Brave\\-browser$",
    # // "instance": "^brave\\-browser$",
    # // "machine": "^Y2P\\-ArchLinux$",
    # // "title": "^New\\ Tab\\ \\-\\ Brave$",
    sed -i 's/\/\/ \(".*\)/\1/' $FILENAME
    #--------------------------
    # delete last trailing comma from 'swallow' section:
    # "title": "^New\\ Tab\\ \\-\\ Brave$",
    sed -i 's/\("title": .*\),$/\1/' $FILENAME
    #=================================================
    # restoring the layout
    # i3-msg "workspace WS_NAME; append_layout $HOME/.config/i3/wsN.json"
    #=================================================
fi
