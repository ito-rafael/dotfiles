#!/bin/sh
#=================================================
# definitions
THEME_DARK='Adwaita-dark'
THEME_LIGHT='Adwaita'
#THEME_CURRENT=$(cat ~/.config/gtk-3.0/settings.ini | grep -oP '(?<=gtk-theme-name=).*')
#=================================================
# help menu and usage message



#=================================================
# change THEME_CURRENT env var:
#---------------------------------------
# if current theme is set to dark, then change it to light
if [ $THEME_CURRENT = $THEME_DARK ]
then
    THEME_CURRENT=$THEME_LIGHT;
# if current theme is set to dark, then change it to light
elif [ $THEME_CURRENT = $THEME_LIGHT ]
then
    THEME_CURRENT=$THEME_DARK;
fi
#---------------------------------------
# change GTK-3.0 theme:
sed -i 's/^gtk-theme-name=.*$/gtk-theme-name='"$THEME_CURRENT"/ $HOME/.config/gtk-3.0/settings.ini
#=================================================
# update i3blocks



# create applet to put icon in system tray
# when icon is clicked, change theme mode



# use "source $HOME/.config/scripts/darth_mode.sh"
#=================================================
