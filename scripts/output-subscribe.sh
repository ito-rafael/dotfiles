#!/usr/bin/env bash
#
# This script constantly prints the focused output whenever a windows focus is changed.
#

#=================================================
	
i3-msg -t subscribe -m '[ "window" ]' | while read line ; do 
    FOCUSED_OUTPUT=$(echo $line | jq -re '.container.output')
    echo $FOCUSED_OUTPUT
done
