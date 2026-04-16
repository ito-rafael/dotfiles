#!/usr/bin/env bash

# ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo '{"text": "jq missing"}'
    exit 1
fi

# output a default fallback state upon Waybar startup
# (kanata only broadcasts on layer *changes*, so this prevents an empty module on boot)
echo '{"text": "default", "class": "default"}'

# connect to Kanata's TCP server and keep the stream open
exec 3<>/dev/tcp/127.0.0.1/54338

# filter, map, and format the JSON stream
jq --unbuffered -c '
  # define the dictionary mapping ("kanata_name": "Waybar_name")
  {
    "colemak":         "col",
    "number":          "num",
    "symbol":          "sym",
    "obs":             "obs",
    "obs-num":         "obn",
    "window-manager":  "wm",
    "navigation":      "nav",
    "out1":            "out1",
    "out2":            "out2",
    "out3":            "out2",
    "media":           "med",
    "luminosity":      "lum",
    "mouse":           "rat",
    "misc":            "misc",
    "youtube-speed":   "yt",
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
