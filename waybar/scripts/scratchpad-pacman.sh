#!/usr/bin/env bash

# prepare message for dialog
TEXT="  Arch Linux pacman\n  Enter password:"
ORIGINAL_IMAGE_1="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/icon/archlinux.png"
ORIGINAL_IMAGE_2="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/icon/pacman.png"

# check if images exist before trying to stitch them
if [[ ! -f "$ORIGINAL_IMAGE_1" ]] || [[ ! -f "$ORIGINAL_IMAGE_2" ]]; then
    echo "Error: One or both source images are missing."
    exit 1
fi

# create a temporary file for the combined image
TEMP_IMAGE=$(mktemp --suffix=.png)

# set a trap to delete the temporary file when the script exits (or fails)
trap 'rm -f "$TEMP_IMAGE"' EXIT

# combine and resize both images side-by-side using ImageMagick
#   "-background none": ensures the gap between them is transparent
#   "+smush 15": adds a 15-pixel gap between them horizontally
magick \
  \( "$ORIGINAL_IMAGE_1" -resize x64 \) \
  \( "$ORIGINAL_IMAGE_2" -resize x64 \) \
  -background none +smush 15 \
  "$TEMP_IMAGE"

# get password with dialog
PASSWORD="$(yad \
  --center \
  --entry \
  --hide-text \
  --text="$TEXT" \
  --title="Authentication required" \
  --licon=/usr/share/icons/Papirus-Dark/32x32/status/dialog-password.svg \
  --image="$TEMP_IMAGE" \
)"

# get the exit code of the yad command
YAD_STATUS=$?

# check if user canceled the prompt (exit code != 0)
if [[ $YAD_STATUS -ne 0 ]]; then
    echo "Authentication canceled by user."
    exit 0
fi

# check password (use printf instead of echo to prevent passwords starting with "-" from breaking)
if printf "%s\n" "$PASSWORD" | su - "$USER" -c true; then
    # password is correct, ignoring...
    true
else
    # password is wrong, exiting...
    yad \
        --center \
        --button=yad-ok \
        --buttons-layout=center \
        --text="Password incorrect." \
        --image=/usr/share/icons/Papirus-Dark/32x32/status/dialog-error.svg
    exit 1
fi

# launch scratchpad (pass the password securely via env var)
# how this block works:
#   - after "sudo pacman -Syu" finishes, it triggers a notification.
#   - if the terminal window is closed, the notification is automatically killed.
#   - if the notification is clicked and the window is hidden, it shows the window.
#   - if the notification is clicked and the window is visible, it just dismisses itself.
#   - an interactive shell is left open so the user can continue typing.
env SUDO_PASS="$PASSWORD" PACMAN_ICON="$ORIGINAL_IMAGE_2" kitty \
    --class="dropdown_pacman" \
    -o font_size=12 \
    -o include="$XDG_CONFIG_HOME/kitty/themes/pacman.conf" \
    bash -c '
        # run the update command
        printf "%s\n" "$SUDO_PASS" | sudo -S -v && \
        sudo pacman -Syu

        # run the notification logic in a background subshell
        (
            cleanup() {
                if [ -n "$NOTIF_ID" ]; then
                    gdbus call --session \
                        --dest org.freedesktop.Notifications \
                        --object-path /org/freedesktop/Notifications \
                        --method org.freedesktop.Notifications.CloseNotification \
                        "$NOTIF_ID" >/dev/null 2>&1
                fi
            }

            # trap termination so cleanup runs when Kitty closes
            trap cleanup EXIT SIGHUP SIGINT SIGTERM

            exec 3< <(notify-send -p -a dropdown_pacman \
                "Arch Linux" \
                "Pacman update finished!" \
                --icon="$PACMAN_ICON" \
                --action="default=Focus Window" \
                --expire-time=0)

            read -u 3 NOTIF_ID
            read -u 3 ACTION

            # check if the notification was clicked, and if the scratchpad is currently visible or hidden
            if [ "$ACTION" = "default" ]; then
                # Check if the dropdown_pacman window is currently visible
                if ! swaymsg -t get_tree | jq -e ".. | objects | select(.app_id == \"dropdown_pacman\" and .visible == true)" >/dev/null 2>&1; then
                    swaymsg exec ~/.config/scripts/show-or-launch.sh dropdown_pacman 0.75 0.75
                fi
            fi
        ) &

        # hand control over to a fully interactive shell so you can keep typing.
        exec bash
    ' &

# wait for dropdown_pacman appears in Sway's window tree
MAX_WAIT=50
COUNTER=0
while ! swaymsg -t get_tree | grep -q '"app_id": "dropdown_pacman"'; do
    sleep 0.1
    ((COUNTER++))
    if [[ $COUNTER -ge $MAX_WAIT ]]; then
        echo "Error: Kitty window never appeared."
        exit 1
    fi
done

# exit cleanly
exit 0
