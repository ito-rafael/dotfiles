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

# filter the JSON stream for layer changes and format it for Waybar
jq --unbuffered -c '
  select(.LayerChange != null) |
  {
    text: .LayerChange.new,
    tooltip: ("Active Layer: " + .LayerChange.new),
    class: .LayerChange.new
  }
' <&3
