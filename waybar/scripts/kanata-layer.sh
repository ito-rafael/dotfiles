#!/usr/bin/env bash

# check if the systemd user service is active
if ! systemctl --user is-active --quiet kanata; then
    exit 0  # outputting nothing and exiting hides the module in Waybar
fi

# ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo '{"text": "jq missing"}'
    exit 1
fi

# attempt to connect to kanata's TCP server
# if the port isn't open yet, exit to avoid a "stuck" module
if ! exec 3<>/dev/tcp/127.0.0.1/54338 2>/dev/null; then
    exit 0
fi

# output a default fallback state upon Waybar startup
# (kanata only broadcasts on layer *changes*, so this prevents an empty module on boot)
echo '{"text": "default", "class": "default"}'

# filter, map, and format the JSON stream
jq --unbuffered -c '
  # define the dictionary mapping ("kanata_name": "Waybar_name")
  {
    "colemak":         "col",
    "number":          "num",
    "symbol":          "sym",
    "obs":             "obs",
    "obs-num":         "obn",
    "window-manager":  "win",
    "navigation":      "nav",
    "media":           "med",
    "luminosity":      "lum",
    "mouse":           "rat",
    "misc":            "mis",
    "out1":            "out1",
    "out2":            "out2",
    "out3":            "out3",
    "youtube-speed":   "yts",
    "function-keys-1": "fn1",
    "function-keys-2": "fn2",
  } as $names |

  select(.LayerChange != null) |
  {
    # look up the short name in the dictionary, fallback to the original name if not found
    text: ($names[.LayerChange.new] // .LayerChange.new),

    # keep the tooltip showing the full original name
    tooltip: ("Active Layer: " + .LayerChange.new),

    # keep the class as the original name so your CSS styling still works
    class: .LayerChange.new
  }
' <&3
