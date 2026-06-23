#!/usr/bin/env bash

# file to communicate between the background update checker and the main loop
status_file="/tmp/zsa_firmware_status"
echo "" > "$status_file"

# track the last printed layer so we only push updates to Waybar when the layer actually changes
# this prevents Waybar from redrawing the UI 10 times a second unnecessarily
last_layer="-1"
last_update_status=""
last_update_check=0
UPDATE_INTERVAL=3600  # 1 hour in seconds

# function to check firmware in the background without blocking the loop
check_firmware() {
    # we set "timeout 3" because zapp hangs waiting for the bootloader
    # 3 seconds is plenty of time to fetch the server response
    zapp_out=$(timeout 3 zapp update 2>&1)
    if [[ "$zapp_out" == *"Update available:"* ]]; then
        echo "update" > "$status_file"
    else
        echo "" > "$status_file"
    fi
}

while true; do
    # check for firmware updates every UPDATE_INTERVAL
    current_time=$(date +%s)
    if (( current_time - last_update_check >= UPDATE_INTERVAL )); then
        check_firmware &  # run in background so the 100ms loop doesn't freeze
        last_update_check=$current_time
    fi

    # read the latest firmware status from the tmp file
    update_status=$(cat "$status_file" 2>/dev/null)

    # if the update status changes, invalidate the last_layer to force a Waybar redraw
    if [ "$update_status" != "$last_update_status" ]; then
        last_layer="-1"
        last_update_status="$update_status"
    fi

    # fetch connectivity/layer status
    status=$(kontroll status 2>/dev/null)

    # safety check: empty status or "No keyboard connected" message
    if [ -z "$status" ] || echo "$status" | grep -q "No keyboard connected"; then
        if [ "$last_layer" != "disconnected" ]; then
            echo ""  # output empty string to hide the entire module (icon + text)
            last_layer="disconnected"
        fi
    else
        # pure-bash parsing (avoids spawning grep/awk)
        layer=""
        while IFS= read -r line; do
            # look for the line containing "layer"
            if [[ "$line" == *"layer"* ]] || [[ "$line" == *"Layer"* ]]; then
                # get the last word of the line
                raw_layer="${line##* }"
                # strip any stray text/color codes, keeping strictly numbers
                layer="${raw_layer//[^0-9]/}"
                break
            fi
        done <<< "$status"

        # if a layer was found and it changed (or if update status forced a redraw)
        if [ -n "$layer" ] && [ "$layer" != "$last_layer" ]; then
            case "$layer" in
                0)  name="col"  ;;
                1)  name="num"  ;;
                2)  name="sym"  ;;
                3)  name="obs"  ;;
                4)  name="obn"  ;;
                5)  name="wm"   ;;
                6)  name="nav"  ;;
                7)  name="med"  ;;
                8)  name="lum"  ;;
                9)  name="rat"  ;;
                10) name="misc" ;;
                11) name="out1" ;;
                12) name="out2" ;;
                13) name="out3" ;;
                14) name="yt"   ;;
                15) name="fn1"  ;;
                16) name="fn2"  ;;
                *)  name="Layer $layer" ;;
            esac

            # construct the CSS class, appending "update-available" if an update is pending.
            if [ "$update_status" == "update" ]; then
                css_classes="\"layer-$layer\", \"update-available\""
            else
                css_classes="\"layer-$layer\""
            fi

            # print JSON object. Waybar instantly updates upon receiving this new line.
            printf '{"text": "%s", "class": [%s]}\n' "$name" "$css_classes"

            # update the layer tracker
            last_layer="$layer"
        fi
    fi

    # sleep for 100 ms
    sleep 0.1
done
