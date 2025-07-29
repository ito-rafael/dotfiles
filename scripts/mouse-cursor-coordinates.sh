#!/usr/bin/env bash

# source:
#   https://gist.github.com/lidgnulinux/33a28be6a1352cb84d7c6c8b63b5a5c2
#
# description:
#   get cursor coordinates
#
# Dependencies :
# - slurp (https://wayland.emersion.fr/slurp/)
# - awk
# - cut
# - sed
# - Wayland compositor with layer_shell support

# How to use :
# - Run this script on terminal!
# - Click wherever spot you want!

coordinate=$(slurp -b 00000000 -p | awk '{print $1}')
x_cord=$(echo $coordinate | cut -d ',' -f 1)
y_cord=$(echo $coordinate | sed -e 's/^.*,//g')

echo "$x_cord" "$y_cord"
