#!/usr/bin/env bash

# track the last printed layer so we only push updates to Waybar when the layer actually changes
# this prevents Waybar from redrawing the UI 10 times a second unnecessarily
last_layer="-1"

while true; do
    # fetch connectivity/layer status
    status=$(kontroll status 2>/dev/null)

    # safety check: Keymapp closed or keyboard unplugged
    if [ -z "$status" ]; then
        if [ "$last_layer" != "disconnected" ]; then
            echo ""  # Output empty string to hide the module
            last_layer="disconnected"
        fi
    else
        # pure-bash parsing (avoids spawning grep/awk)
        layer=""
        while IFS= read -r line; do
            # Look for the line containing "layer"
            if [[ "$line" == *"layer"* ]] || [[ "$line" == *"Layer"* ]]; then
                # Get the last word of the line
                raw_layer="${line##* }"
                # Strip any stray text/color codes, keeping strictly numbers
                layer="${raw_layer//[^0-9]/}"
                break
            fi
        done <<< "$status"

        # if a layer was found and it changed, map it and print
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

            # print JSON object. Waybar instantly updates upon receiving this new line.
            printf '{"text": "%s", "class": "layer-%s"}\n' "$name" "$layer"

            # update the layer tracker
            last_layer="$layer"
        fi
    fi

    # sleep for 100ms
    sleep 0.1
done
