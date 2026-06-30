#!/usr/bin/env python3
"""
Configures global brave appearance settings by directly modifying the profile preferences file.
Adjusts the default font size and the global page zoom level.
Must be run when brave is closed to prevent profile corruption.
"""

import os
import sys
import json
import fcntl
import subprocess

#----------------------------------------
# configuration targets
#----------------------------------------
# chromium standard font sizes: 9 (very small), 12 (small), 16 (medium), 20 (large), 24 (very large)
TARGET_FONT_SIZE = 20

# chromium zoom level is stored as a calculated float: ln(target_percentage) / ln(1.2)
# 0.0 = 100%, 0.522 = 110%, 1.2239010857415449 = 125%, 2.2239 = 150%
TARGET_ZOOM_LEVEL = 1.2239010857415449

username = os.getenv("USER")

# dynamically find the correct brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"/home/{username}/.config/BraveSoftware/Brave-Origin",        # Debian & Arch Linux
    #f"/home/{username}/.config/BraveSoftware/Brave-Browser-Beta"  # fallback Beta
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    print("Critical: Could not locate the Brave profile directory.")
    sys.exit(1)

prefs_path = os.path.join(profile_base, "Default", "Preferences")

if not os.path.exists(prefs_path):
    print(f"Critical: Preferences file not found at {prefs_path}")
    sys.exit(1)


#----------------------------------------
# active session safety check
#----------------------------------------
try:
    # get the full command line (-a) of all processes containing "brave" (-f)
    result = subprocess.check_output(["pgrep", "-a", "-f", "[o]pt/brave.com/brave-origin-beta/brave"], text=True)
    running_standard_sessions = False
    for line in result.splitlines():
        # ignore child processes and web apps
        if " --type=" in line or " --app=" in line:
            continue
        running_standard_sessions = True
        break

    if running_standard_sessions:
        print("Error: Standard Brave is currently running. Aborting to prevent profile corruption.")
        sys.exit(1)
except subprocess.CalledProcessError:
    pass # pgrep returned non-zero, meaning no matching processes were found, safe to proceed


#----------------------------------------
# modify preferences json
#----------------------------------------
try:
    # use fcntl to ensure exclusive access to the file
    with open(prefs_path, 'r+', encoding='utf-8') as f:
        fcntl.flock(f, fcntl.LOCK_EX)

        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print("Error: Preferences file is corrupted or not valid JSON.")
            sys.exit(1)

        changes_made = False

        # 1. configure font size
        # gracefully navigate or create the nested dictionaries using python's setdefault
        webkit_prefs = data.setdefault('webkit', {}).setdefault('webprefs', {})
        current_font = webkit_prefs.get('default_font_size')

        if current_font != TARGET_FONT_SIZE:
            print(f"Injecting: Font Size -> 'Large' ({TARGET_FONT_SIZE}px)...")
            webkit_prefs['default_font_size'] = TARGET_FONT_SIZE
            changes_made = True
        else:
            print(f"Skipped: Font Size is already set to 'Large' ({TARGET_FONT_SIZE}px).")

        # 2. configure page zoom
        # the default zoom partition key is literally 'x'
        partition_prefs = data.setdefault('partition', {}).setdefault('default_zoom_level', {})
        current_zoom = partition_prefs.get('x')

        if current_zoom != TARGET_ZOOM_LEVEL:
            print(f"Injecting: Page Zoom -> '125%' ({TARGET_ZOOM_LEVEL})...")
            partition_prefs['x'] = TARGET_ZOOM_LEVEL
            changes_made = True
        else:
            print(f"Skipped: Page Zoom is already set to '125%'.")

        #----------------------------------------
        # save to disk if necessary
        #----------------------------------------
        if changes_made:
            f.seek(0)
            json.dump(data, f, separators=(',', ':'))
            f.truncate()
            print("\nSuccess: Preferences file updated with new appearance settings.")
        else:
            print("\nSuccess: Appearance settings were already configured correctly. No disk writes needed.")

        fcntl.flock(f, fcntl.LOCK_UN)

except PermissionError:
    print(f"Error: Permission denied trying to read/write {prefs_path}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1)
