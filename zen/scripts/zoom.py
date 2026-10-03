#!/usr/bin/env python3
"""
Automates setting default page zoom in Zen Browser by directly modifying user.js.
Bypasses Selenium and Marionette navigation blocks entirely.
Must be run when Zen is closed to prevent profile corruption.
"""

import os
import sys
import re
import time
import subprocess

# Target zoom percentage (120%)
TARGET_ZOOM_PERCENT = 120

# Find active profile directory
zen_config_dir = os.path.expanduser("~/.config/zen")

valid_profiles = []
if os.path.exists(zen_config_dir):
    for folder in os.listdir(zen_config_dir):
        full_path = os.path.join(zen_config_dir, folder)
        prefs_file = os.path.join(full_path, "prefs.js")
        if os.path.isdir(full_path) and os.path.exists(prefs_file):
            valid_profiles.append(full_path)

if not valid_profiles:
    print("Critical: Could not locate any Zen profile containing a prefs.js file.")
    sys.exit(1)

valid_profiles.sort(key=lambda p: os.path.getmtime(os.path.join(p, "prefs.js")), reverse=True)
profile_base = valid_profiles[0]

print(f"Targeting active profile: {profile_base}")

MARKER_FILE = os.path.join(profile_base, ".accessibility_zoom_configured")

if os.path.exists(MARKER_FILE):
    print("Skipped: Accessibility zoom already set (Verified by state marker).")
    sys.exit(0)

# Safety check for running browser
try:
    result = subprocess.check_output(["pgrep", "-a", "-i", "zen"], text=True)
    running_standard_sessions = False
    for line in result.splitlines():
        if "tab" in line or "extension" in line or "utility" in line or "socket" in line:
            continue
        if "zen-bin" in line or "zen-browser" in line:
            running_standard_sessions = True
            break
    if running_standard_sessions:
        print("Error: Zen Browser is currently running. Aborting.")
        sys.exit(1)
except subprocess.CalledProcessError:
    pass

user_js_path = os.path.join(profile_base, "user.js")

# Pref entries to enforce 120% default zoom
zoom_pref_line = f'user_pref("zoom.defaultPercent", {TARGET_ZOOM_PERCENT});\n'

existing_lines = []
if os.path.exists(user_js_path):
    with open(user_js_path, "r", encoding="utf-8") as f:
        existing_lines = f.readlines()

# Filter out old zoom.defaultPercent entries
updated_lines = [line for line in existing_lines if "zoom.defaultPercent" not in line]
updated_lines.append(zoom_pref_line)

# Write updated preferences
with open(user_js_path, "w", encoding="utf-8") as f:
    f.writelines(updated_lines)

# Write state marker
with open(MARKER_FILE, "w", encoding="utf-8") as f:
    f.write(f"Zoom set to {TARGET_ZOOM_PERCENT}% via user.js on {time.ctime()}\n")

print(f"Success: Default zoom set to {TARGET_ZOOM_PERCENT}% in user.js.")
