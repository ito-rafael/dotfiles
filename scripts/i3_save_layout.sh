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
	printf "script to navigate to i3 workspaces and open specifics windows if woskpace is empty\n\n"
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
    # save workspace layout to file
    i3-save-tree --workspace $WORKSPACE > $HOME/.config/i3/ws$WORKSPACE.json
    #=================================================
    ## edit 
    ## editing the json file
    #    # vim ~/.config/i3/wsN.json
    #    --------------------------
    #    # remove the first line:
    #        // vim:ts=4:sw=4:et
    #    # remove the "//" under 'swallows' section:
    #       // "class": "^Thunar$",
    #       // "instance": "^thunar$",
    #       // "title": "^rafael\\ \\-\\ File\\ Manager$",
    #    # delete 'window_role' item:
    #       // "window_role": "^Thunar\\-1587310553\\-3422989574$"
    #    # delete last trailing comma from 'swallow' section:
    #       // "title": "^rafael\\ \\-\\ File\\ Manager$",
    #    --------------------------
    #    # script not workig: 
    #    tail -n +2 ~/.config/i3/wsN.json | fgrep -v '// split' | sed 's|//||g' > ~/.config/i3/wsN.json
    #
    ##=================================================
    ## restoring the layout
    #i3-msg "workspace WS_NAME; append_layout $HOME/.config/i3/wsN.json"
    ##=================================================
fi
