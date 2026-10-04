#!/usr/bin/env python3
"""
Silently opts into Google Widevine in Brave by modifying the Local State JSON.
This triggers Brave to download the Widevine CDM in the background on next launch.
Must be run when Brave is closed to prevent state corruption.
"""

import os
import sys
import json
import fcntl
import subprocess

# safely get the home directory (works in Ansible non-login shells)
home_dir = os.path.expanduser("~")

# dynamically find the correct Brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"{home_dir}/.config/BraveSoftware/Brave-Browser",
    f"{home_dir}/.config/BraveSoftware/Brave-Origin-Beta",
    f"{home_dir}/.config/BraveSoftware/Brave-Origin",
    f"{home_dir}/.config/BraveSoftware/Brave-Browser-Beta",
    f"{home_dir}/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    print("Critical: Could not locate the Brave profile directory.")
    sys.exit(1)

# Widevine opt-in is a browser-wide setting stored in "Local State", not in "Default/Preferences"
local_state_path = os.path.join(profile_base, "Local State")

if not os.path.exists(local_state_path):
    print(f"Critical: Local State file not found at {local_state_path}")
    sys.exit(1)

# ----------------------------------------
# Active Session Safety Check
# ----------------------------------------
try:
    result = subprocess.check_output(["pgrep", "-a", "-i", "brave"], text=True)
    running_standard_sessions = False
    for line in result.splitlines():
        # ignore child processes and web apps
        if " --type=" in line or " --app=" in line:
            continue

        # Explicitly verify the binary name
        if "brave" in line or "brave-bin" in line or "brave-origin" in line:
            running_standard_sessions = True
            break

    if running_standard_sessions:
        print("Error: Brave is currently running. Aborting to prevent Local State corruption.")
        sys.exit(1)
except subprocess.CalledProcessError:
    pass # pgrep returned non-zero, meaning no matching processes were found, safe to proceedno matching processes were found, safe to proceed

# ----------------------------------------
# Modify Local State JSON
# ----------------------------------------
try:
    # use fcntl to ensure exclusive access to the file
    with open(local_state_path, 'r+', encoding='utf-8') as f:
        fcntl.flock(f, fcntl.LOCK_EX)

        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print("Error: Local State file is corrupted or not valid JSON.")
            sys.exit(1)

        # gracefully navigate or create the nested brave dictionaries
        brave_prefs = data.setdefault('brave', {})
        current_widevine_state = brave_prefs.get('widevine_opted_in')

        # ----------------------------------------
        # save to disk if necessary
        # ----------------------------------------
        if current_widevine_state is not True:
            print("Injecting: Google Widevine -> Opted In (True)...")
            brave_prefs['widevine_opted_in'] = True

            f.seek(0)
            json.dump(data, f, separators=(',', ':'))
            f.truncate()
            print("\nSuccess: Local State updated. Widevine will download on next browser launch.")
        else:
            print("\nSkipped: Google Widevine is already opted in. No disk writes needed.")

        fcntl.flock(f, fcntl.LOCK_UN)

except PermissionError:
    print(f"Error: Permission denied trying to read/write {local_state_path}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1)
