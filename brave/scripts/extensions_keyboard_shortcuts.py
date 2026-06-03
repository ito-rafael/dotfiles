#!/usr/bin/env python3
"""
configures brave extension shortcuts by directly modifying the profile preferences file.
targets the root extensions.commands dictionary and maps the shortcut string directly.
must be run when brave is closed.
"""

import os
import sys
import json
import fcntl

TARGET_EXTENSION_NAME = "Dark Reader"
TARGET_COMMAND_NAME = "Toggle extension"
TARGET_SHORTCUT_STRING = "Alt+D"

username = os.getenv("USER")

# dynamically find the correct Brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"/home/{username}/.config/BraveSoftware/Brave-Origin-Beta",  # Debian & Arch Linux
    #f"/home/{username}/.config/BraveSoftware/Brave-Browser",      # fallback Standard
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
import subprocess
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
    pass # pgrep returned non-zero, meaning no matching processes were found. Safe!


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

        extensions = data.get('extensions', {}).get('settings', {})
        target_ext_id = None

        # 1. find the specific extension id by looking for its manifest name
        for ext_id, ext_data in extensions.items():
            manifest = ext_data.get('manifest', {})
            if manifest.get('name') == TARGET_EXTENSION_NAME:
                target_ext_id = ext_id
                break

        if not target_ext_id:
            print(f"Error: Could not find '{TARGET_EXTENSION_NAME}' installed in this profile.")
            sys.exit(1)

        # 2. find the internal command mapping (e.g., "Toggle extension" -> "toggle")
        manifest = extensions[target_ext_id].get('manifest', {})
        manifest_commands = manifest.get('commands', {})
        actual_command_key = None

        for cmd_key, cmd_data in manifest_commands.items():
            if cmd_data.get('description') == TARGET_COMMAND_NAME:
                actual_command_key = cmd_key
                break

        if not actual_command_key:
             print(f"Error: Could not find a command with description '{TARGET_COMMAND_NAME}' in the manifest.")
             sys.exit(1)

        print(f"Found {TARGET_EXTENSION_NAME} (ID: {target_ext_id})")
        print(f"Mapped command '{TARGET_COMMAND_NAME}' to internal key: '{actual_command_key}'")

        # 3. ensure the root commands dictionary exists
        if 'commands' not in data.get('extensions', {}):
            if 'extensions' not in data:
                data['extensions'] = {}
            data['extensions']['commands'] = {}

        commands_dict = data['extensions']['commands']

        # 4. generate the os-specific target key (e.g., "linux:Alt+D")
        os_prefix = ""
        if sys.platform.startswith("linux"):
            os_prefix = "linux:"
        elif sys.platform == "darwin":
            os_prefix = "mac:"
        elif sys.platform == "win32":
            os_prefix = "win:"

        target_shortcut_key = f"{os_prefix}{TARGET_SHORTCUT_STRING}"

        # 5. idempotent check: is it already set perfectly?
        if target_shortcut_key in commands_dict:
            existing_binding = commands_dict[target_shortcut_key]
            if existing_binding.get('extension') == target_ext_id and existing_binding.get('command_name') == actual_command_key:
                print(f"Skipped: Shortcut for '{TARGET_COMMAND_NAME}' is already set to '{TARGET_SHORTCUT_STRING}'.")
                fcntl.flock(f, fcntl.LOCK_UN)
                sys.exit(0)

        print(f"Injecting shortcut '{target_shortcut_key}'...")

        # 6. clear any old shortcuts mapped to this specific extension command so we don't create duplicates
        keys_to_delete = []
        for shortcut_key, shortcut_data in commands_dict.items():
            if shortcut_data.get('extension') == target_ext_id and shortcut_data.get('command_name') == actual_command_key:
                keys_to_delete.append(shortcut_key)

        for k in keys_to_delete:
            del commands_dict[k]

        # 7. warn if another extension was currently using our desired shortcut (chromium will overwrite it)
        if target_shortcut_key in commands_dict:
            print(f"Warning: Shortcut '{target_shortcut_key}' was used by another extension. Overwriting to enforce state...")

        # 8. apply the new shortcut
        commands_dict[target_shortcut_key] = {
            "command_name": actual_command_key,
            "extension": target_ext_id,
            "global": False
        }

        # 9. write back to disk
        f.seek(0)
        json.dump(data, f, separators=(',', ':'))
        f.truncate()

        print("Success: Preferences file updated.")

        fcntl.flock(f, fcntl.LOCK_UN)

except PermissionError:
    print(f"Error: Permission denied trying to read/write {prefs_path}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1)
