#!/usr/bin/env python3
"""
configures multiple brave extension shortcuts by directly modifying the profile preferences file.
iterates through a configuration list and applies all changes in a single disk write.
must be run when brave is closed.
"""

import os
import sys
import json
import fcntl
import subprocess

#----------------------------------------
# define all your target shortcuts here
#----------------------------------------
SHORTCUTS_CONFIG = [
    {
        "extension": "Dark Reader",
        "command": "Toggle extension",
        "shortcut": "Alt+D"
    },
    {
        "extension": "Pelando",
        "command": "Activate the extension",
        "shortcut": "Shift+Alt+P"
    },
    {
        "extension": "Tab Session Manager",
        "command": "Save session (all windows)",
        "shortcut": "Alt+O"
    },
    {
        "extension": "Zotero Connector",
        "command": "Activate the extension",
        "shortcut": "Alt+Z"
    }
]

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
# determine os prefix for shortcuts
#----------------------------------------
os_prefix = ""
if sys.platform.startswith("linux"):
    os_prefix = "linux:"
elif sys.platform == "darwin":
    os_prefix = "mac:"
elif sys.platform == "win32":
    os_prefix = "win:"


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

        # ensure the root commands dictionary exists
        if 'commands' not in data.get('extensions', {}):
            if 'extensions' not in data:
                data['extensions'] = {}
            data['extensions']['commands'] = {}

        commands_dict = data['extensions']['commands']
        changes_made = False

        # iterate through the configuration list
        for config in SHORTCUTS_CONFIG:
            target_ext_name = config["extension"]
            target_cmd_name = config["command"]
            target_shortcut_string = config["shortcut"]

            target_ext_id = None

            # 1. find the specific extension id by looking for its manifest name
            for ext_id, ext_data in extensions.items():
                manifest = ext_data.get('manifest', {})
                if manifest.get('name') == target_ext_name:
                    target_ext_id = ext_id
                    break

            if not target_ext_id:
                print(f"Error: Could not find '{target_ext_name}' installed in this profile. Aborting.")
                sys.exit(1)

            # 2. find the internal command mapping (e.g., "Toggle extension" -> "toggle")
            manifest = extensions[target_ext_id].get('manifest', {})
            manifest_commands = manifest.get('commands', {})
            actual_command_key = None

            for cmd_key, cmd_data in manifest_commands.items():
                if cmd_data.get('description') == target_cmd_name:
                    actual_command_key = cmd_key
                    break

            if not actual_command_key:
                 print(f"Error: Could not find a command '{target_cmd_name}' for '{target_ext_name}'. Aborting.")
                 sys.exit(1)

            target_shortcut_key = f"{os_prefix}{target_shortcut_string}"

            # 3. idempotent check: is it already set perfectly?
            if target_shortcut_key in commands_dict:
                existing_binding = commands_dict[target_shortcut_key]
                if existing_binding.get('extension') == target_ext_id and existing_binding.get('command_name') == actual_command_key:
                    print(f"Skipped: '{target_ext_name}' -> '{target_cmd_name}' is already '{target_shortcut_string}'.")
                    continue

            print(f"Injecting: '{target_ext_name}' -> '{target_shortcut_key}'...")

            # 4. clear any old shortcuts mapped to this specific extension command
            keys_to_delete = []
            for shortcut_key, shortcut_data in commands_dict.items():
                if shortcut_data.get('extension') == target_ext_id and shortcut_data.get('command_name') == actual_command_key:
                    keys_to_delete.append(shortcut_key)

            for k in keys_to_delete:
                del commands_dict[k]

            # 5. warn if another extension was currently using our desired shortcut
            if target_shortcut_key in commands_dict:
                print(f"  Warning: '{target_shortcut_key}' was used by another extension. Overwriting...")

            # 6. apply the new shortcut
            commands_dict[target_shortcut_key] = {
                "command_name": actual_command_key,
                "extension": target_ext_id,
                "global": False
            }

            changes_made = True

        #----------------------------------------
        # save to disk if necessary
        #----------------------------------------
        if changes_made:
            f.seek(0)
            json.dump(data, f, separators=(',', ':'))
            f.truncate()
            print("\nSuccess: Preferences file updated with new shortcuts.")
        else:
            print("\nSuccess: All shortcuts were already configured correctly. No disk writes needed.")

        fcntl.flock(f, fcntl.LOCK_UN)

except PermissionError:
    print(f"Error: Permission denied trying to read/write {prefs_path}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1)
