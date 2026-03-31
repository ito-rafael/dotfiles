#!/usr/bin/env bash

# kill the lan-mouse daemon if it is running
pkill -u lightdm lan-mouse || true

# kill the background wait-loop from the greeter script (lightdm-lanmouse.sh) if it's still running
pkill -u lightdm -f "lightdm-lanmouse.sh" || true
pkill -u lightdm -f "sleep" || true

# force a successful exit code (0) so LightDM does't abort the login
exit 0
