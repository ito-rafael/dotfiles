#!/usr/bin/env bash

# parse argument
APP_CHOICE="$1"

# select the PWA to launch
case "$APP_CHOICE" in
    ytmusic)
        APP_URL="https://music.youtube.com"
        ;;
    calendar)
        APP_URL="https://calendar.google.com"
        ;;
    chatgpt)
        APP_URL="https://chatgpt.com"
        ;;
    translate)
        APP_URL="https://translate.google.com"
        ;;
    whatsapp)
        APP_URL="https://web.whatsapp.com"
        ;;
    *)
        echo "Error: Unknown app. Use {ytmusic|calendar|chatgpt|translate|whatsapp}"
        exit 1
        ;;
esac

# save the logs
exec > "/tmp/pwa-launcher-${APP_CHOICE}.log" 2>&1

echo "Starting launch sequence for: $APP_CHOICE"
echo "Target URL: $APP_URL"

# wait distrobox to be available before launching the PWA
for i in {1..30}; do
    echo "Checking if Distrobox is ready (Attempt $i/30)..."

    if distrobox-enter -n brave-origin -- true; then
        echo "SUCCESS: Container is ready!"
        break
    fi

    sleep 1
done

echo "Launching $APP_CHOICE..."

# launch PWA
exec distrobox-enter -n brave-origin -- brave-origin --skip-origin-startup-dialog --app="$APP_URL"
