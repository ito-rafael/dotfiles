#!/usr/bin/env bash
distrobox rm -f brave-origin-beta
podman build -t brave-origin-beta -f Dockerfile ../../brave/
distrobox create --name brave-origin-beta --image brave-origin-beta
#distrobox enter brave-origin-beta -- sh -c 'brave-origin-beta --skip-origin-startup-dialog --headless=new --no-first-run > /dev/null 2>&1 & sleep 15 && pkill -15 -f brave-origin-beta'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/allow_user_scripts.py
distrobox enter brave-origin-beta -- python3 /usr/local/bin/surfingkeys_advanced_mode.py
distrobox enter brave-origin-beta -- python3 /usr/local/bin/surfingkeys_load_settings.py
