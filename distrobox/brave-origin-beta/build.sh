#!/usr/bin/env bash
stty sane
reset

rm -rf ~/.config/BraveSoftware/Brave-Distrobox
mkdir -p ~/.config/BraveSoftware/Brave-Distrobox

distrobox rm -f brave-origin-beta

podman build -t brave-origin-beta -f Dockerfile ../../brave/
#podman build --no-cache -t brave-origin-beta -f Dockerfile ../../brave/

distrobox create --name brave-origin-beta --image brave-origin-beta --volume ~/.config/BraveSoftware/Brave-Distrobox:/home/rafael/.config/BraveSoftware

echo -e '********************\nPre-warming Distrobox Container...\n********************'
distrobox enter brave-origin-beta -- echo "Container is ready!"

echo -e '********************\nGenerating Brave Profile...\n********************'
#distrobox enter brave-origin-beta -- sh -c 'xvfb-run -a brave-origin-beta --skip-origin-startup-dialog --no-first-run --disable-gpu --disable-dev-shm-usage https://example.com > /dev/null 2>&1 & sleep 15 && pkill -15 brave'
distrobox enter brave-origin-beta -- sh -c 'xvfb-run -a brave-origin-beta --skip-origin-startup-dialog --no-first-run --disable-gpu --disable-dev-shm-usage --ozone-platform=x11 https://example.com > /dev/null 2>&1 & sleep 15 && pkill -15 brave'
echo -e '\n********************\nWaiting for Brave to finish saving its profile...\n********************'
sleep 3
stty sane

echo -e '\n********************\nDark Theme\n********************'
distrobox enter brave-origin-beta -- sh -c 'jq ".browser.theme.color_scheme2 = 2" ~/.config/BraveSoftware/Brave-Origin-Beta/Default/Preferences > tmp.json && mv tmp.json ~/.config/BraveSoftware/Brave-Origin-Beta/Default/Preferences'

echo -e '\n********************\nPreferences: Enabling Developer Mode\n********************'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/preferences_developer_mode.py

echo -e '\n********************\nPreferences: Block EN and PT Translations\n********************'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/preferences_block_translations.py

echo -e '\n********************\nSurfingkeys: Allow User Scripts\n********************'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/surfingkeys_allow_user_scripts.py

echo -e '\n********************\nSurfingkeys: Advanced Mode\n********************'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/surfingkeys_advanced_mode.py

echo -e '\n********************\nSurfingkeys: Load Settings\n********************'
distrobox enter brave-origin-beta -- python3 /usr/local/bin/surfingkeys_load_settings.py

rm -rf ~/.local/share/applications/brave-origin-beta*
distrobox enter brave-origin-beta -- distrobox-export --app brave-origin-beta --extra-flags "--no-default-browser-check"
