#!/usr/bin/env bash
#
# This script constantly prints the focused output whenever a windows focus is changed.
#

#=================================================

while read -r line 
do
    WINDOW_ID_HEX=$(echo $line | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
    #OUTPUT=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.window == '$WINDOW_ID') | .output'
    WINDOW_ID_INT=$((WINDOW_ID_HEX))
    OUTPUT=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.window == '$WINDOW_ID_INT') | .output')
done < <(xprop -spy -root _NET_ACTIVE_WINDOW)
