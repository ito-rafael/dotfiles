#!/usr/bin/env bash

# define the cities coordinates
CITY_LONDON="'51.50853,-0.12574'"
CITY_CAMPINAS="'-22.90556,-47.06083'"
APP_ID="io.github.amit9838.mousam"

# get the current city
CURRENT_CITY=$(gsettings get $APP_ID selected-city)

# toggle city
if [ "$CURRENT_CITY" = "$CITY_LONDON" ]; then
    gsettings set $APP_ID selected-city "$CITY_CAMPINAS"
else
    gsettings set $APP_ID selected-city "$CITY_LONDON"
fi
