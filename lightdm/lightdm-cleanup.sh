#!/usr/bin/env bash

# kill the lan-mouse daemon if it is running
pkill -u lightdm lan-mouse

# kill the background wait-loop from the greeter script (lightdm-lanmouse.sh) if it's still running
pkill -u lightdm -f "lightdm-lanmouse.sh"
pkill -u lightdm -f "sleep"

# force a successful exit code (0) so LightDM does't abort the login
exit 0
