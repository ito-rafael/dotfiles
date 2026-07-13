#!/usr/bin/env python3
"""
Custom Rofi Launcher for Zen Browser.
Dynamically extracts the Tab Session Manager UUID and launches it as the first page.
"""

import os
import re
import sys
import json
import subprocess

EXTENSION_ID = "Tab-Session-Manager@sienori"
EXTENSION_PAGE = "/popup/index.html#inTab"
ZEN_BIN = "/opt/zen-browser-bin/zen-bin"

# 1. Find the active Zen profile
zen_dir = os.path.expanduser("~/.config/zen")
profiles = []
if os.path.exists(zen_dir):
    for d in os.listdir(zen_dir):
        p_path = os.path.join(zen_dir, d)
        if os.path.isdir(p_path) and os.path.exists(os.path.join(p_path, "prefs.js")):
            profiles.append(p_path)

if not profiles:
    print("No Zen profile found.")
    subprocess.Popen([ZEN_BIN])
    sys.exit(1)

profiles.sort(key=lambda p: os.path.getmtime(os.path.join(p, "prefs.js")), reverse=True)
active_profile = profiles[0]

# 2. Extract the dynamic extension UUID
uuid = None
with open(os.path.join(active_profile, "prefs.js"), "r", encoding="utf-8") as f:
    for line in f:
        if "extensions.webextensions.uuids" in line:
            match = re.search(r'user_pref\("extensions\.webextensions\.uuids",\s*"(.*)"\);', line)
            if match:
                try:
                    uuid_map = json.loads(match.group(1).replace('\\"', '"'))
                    uuid = uuid_map.get(EXTENSION_ID)
                except json.JSONDecodeError:
                    pass
            break

# 3. Launch Zen
if uuid:
    target_url = f"moz-extension://{uuid}{EXTENSION_PAGE}"
    # Launch Zen explicitly targeting your profile and the dynamic URL
    subprocess.Popen([ZEN_BIN, "--profile", active_profile, target_url])
else:
    # Fallback: Launch normally if the extension isn't installed
    subprocess.Popen([ZEN_BIN, "--profile", active_profile])
