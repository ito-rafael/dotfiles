#!/usr/bin/env python3
"""
Automates setting custom keybindings in the Video Speed Controller extension for Zen Browser.
Idempotent task that skips execution if the values are already set.
Must be run when Zen is closed to prevent profile corruption.
"""

import os
import re
import sys
import time
import json
import glob
import subprocess

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.firefox import GeckoDriverManager

# The official Firefox Extension ID for Video Speed Controller
EXTENSION_ID = "{7be2ba16-0f1e-4d93-9ebc-5164397477a9}"

# Dynamically find the Zen Browser core binary path
POSSIBLE_BINARIES = [
    "/opt/zen-browser-bin/zen-bin",
    "/opt/zen-browser-bin/zen",
    "/usr/lib/zen-browser/zen-bin",
    "/usr/lib/zen-browser/zen"
]

ZEN_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not ZEN_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Zen Browser executable.")

#----------------------------------------
# Find the active Zen profile directory
#----------------------------------------
zen_config_dir = os.path.expanduser("~/.config/zen")

valid_profiles = []
if os.path.exists(zen_config_dir):
    for folder in os.listdir(zen_config_dir):
        full_path = os.path.join(zen_config_dir, folder)
        prefs_file = os.path.join(full_path, "prefs.js")

        if os.path.isdir(full_path) and os.path.exists(prefs_file):
            valid_profiles.append(full_path)

if not valid_profiles:
    raise FileNotFoundError("Critical: Could not locate any Zen Browser profile containing a prefs.js file.")

valid_profiles.sort(key=lambda p: os.path.getmtime(os.path.join(p, "prefs.js")), reverse=True)
profile_base = valid_profiles[0]

print(f"Targeting active profile: {profile_base}")

MARKER_FILE = os.path.join(profile_base, ".vsc_keybindings_configured")

#----------------------------------------
# State marker pre-flight check
#----------------------------------------
if os.path.exists(MARKER_FILE):
    print("Skipped: VSC keybindings are already set (Verified by state marker).")
    sys.exit(0)

#----------------------------------------
# Active session safety check
#----------------------------------------
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
        print("Error: Zen Browser is currently running. Aborting to protect active session.")
        sys.exit(1)
    else:
        print("No active standard Zen sessions found. Proceeding with configuration...")
except subprocess.CalledProcessError:
    print("No active Zen sessions found. Proceeding with configuration...")

#----------------------------------------
# Lock cleanup (Firefox/Gecko style)
#----------------------------------------
for lock in ["lock", "parent.lock", ".parentlock"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
            print(f"Removed stale lock: {lock}")
        except OSError:
            pass

#----------------------------------------
# Extract dynamic moz-extension UUID
#----------------------------------------
internal_uuid = None
prefs_path = os.path.join(profile_base, "prefs.js")

with open(prefs_path, "r", encoding="utf-8") as f:
    for line in f:
        if "extensions.webextensions.uuids" in line:
            match = re.search(r'user_pref\("extensions\.webextensions\.uuids",\s*"(.*)"\);', line)
            if match:
                json_str = match.group(1).replace('\\"', '"')
                try:
                    uuid_map = json.loads(json_str)
                    internal_uuid = uuid_map.get(EXTENSION_ID)
                except json.JSONDecodeError:
                    pass
            break

if not internal_uuid:
    print("Error: Could not find the internal UUID for Video Speed Controller in prefs.js. Is it installed?")
    sys.exit(1)

#----------------------------------------
# Browser configuration
#----------------------------------------
options = Options()
options.binary_location = ZEN_BINARY_PATH
options.add_argument("-profile")
options.add_argument(profile_base)

#----------------------------------------
# Initialize driver
#----------------------------------------
print("Initializing GeckoDriver...")
driver_path = GeckoDriverManager().install()
service = Service(driver_path)
driver = webdriver.Firefox(service=service, options=options)

#----------------------------------------
# Automation execution
#----------------------------------------
try:
    # Use the specific options page file for this extension
    options_url = f"moz-extension://{internal_uuid}/options.html"

    print("Waiting for the Video Speed Controller extension to load...")
    key_input = None

    for i in range(30):
        driver.get(options_url)
        time.sleep(2) # Give the extension storage time to hydrate the DOM

        try:
            # We look for the exact inputs using your XPaths
            key_input = driver.find_element(By.XPATH, "/html/body/section[1]/div[2]/input[1]")
            val_input = driver.find_element(By.XPATH, "/html/body/section[1]/div[2]/input[2]")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    if not key_input:
        print("Error: Video Speed Controller options DOM did not render properly.")
        sys.exit(1)

    wait = WebDriverWait(driver, 10)

    # Target Values
    target_key = "a"    # Extensions usually prefer lowercase for keystrokes
    target_val = "0.25"

    # Read the current DOM properties
    current_key = key_input.get_attribute("value")
    current_val = val_input.get_attribute("value")

    # Idempotency Check: Are they already set correctly?
    if current_key == target_key and current_val == target_val:
        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings verified via Ansible on {time.ctime()}\n")
        print("Skipped: Keybindings are already configured correctly.")

    else:
        print("Injecting new keybindings...")

        # Clear existing values and inject new ones
        key_input.clear()
        key_input.send_keys(target_key)

        val_input.clear()
        val_input.send_keys(target_val)

        print("Saving configuration...")
        time.sleep(1)

        # Find the native VSC "Save" button and click it
        save_button = wait.until(EC.element_to_be_clickable((By.ID, "save")))
        driver.execute_script("arguments[0].click();", save_button)

        # Write the receipt so we skip Selenium next time
        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings configured via Ansible on {time.ctime()}\n")

        print("Success: Keybindings saved and applied.")

    # Force disk flush (using Firefox internal page)
    time.sleep(1)
    driver.get("about:support")
    time.sleep(2)

finally:
    driver.quit()
