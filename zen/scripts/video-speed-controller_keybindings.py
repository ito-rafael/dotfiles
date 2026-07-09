#!/usr/bin/env python3
"""
Automates setting custom keybindings in the Video Speed Controller extension for Zen Browser.
Idempotent task that dynamically creates new rows if they do not exist.
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
from selenium.common.exceptions import NoSuchElementException
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


#========================================
# CONFIGURATION MANIFEST
#========================================
KEYBINDINGS_CONFIG = [
    #----------------------------------------
    # Decrease speed
    {
        "description": "Decrease speed: Key",
        "xpath": "/html/body/section[1]/div[2]/input[1]",
        "target_value": "{"
    },
    {
        "description": "Decrease speed: Value",
        "xpath": "/html/body/section[1]/div[2]/input[2]",
        "target_value": "0.25"
    },
    #----------------------------------------
    # Increase speed
    {
        "description": "Increase speed: Key",
        "xpath": "/html/body/section[1]/div[3]/input[1]",
        "target_value": "}"
    },
    {
        "description": "Increase speed: Value",
        "xpath": "/html/body/section[1]/div[3]/input[2]",
        "target_value": "0.25"
    },
    #----------------------------------------
    # Reset speed
    {
        "description": "Reset speed: Key",
        "xpath": "/html/body/section[1]/div[6]/input[1]",
        "target_value": "U"
    },
    {
        "description": "Reset speed: Value",
        "xpath": "/html/body/section[1]/div[6]/input[2]",
        "target_value": "1"
    },
    #----------------------------------------
    # Preferred speed #0
    {
        "description": "Preferred speed (original): Key (Row 7)",
        "xpath": "/html/body/section[1]/div[7]/input[1]",
        "target_value": "-"
    },
    {
        "description": "Preferred speed (original): Value (Row 7)",
        "xpath": "/html/body/section[1]/div[7]/input[2]",
        "target_value": "0.75"
    },
    #----------------------------------------
    # Preferred Speed #1
    {
        "description": "Preferred speed (added): Action (Row 8)",
        "xpath": "/html/body/section[1]/div[8]/select",
        "target_value": "fast"
    },
    {
        "description": "Preferred speed (added): Key (Row 8)",
        "xpath": "/html/body/section[1]/div[8]/input[1]",
        "target_value": "\\"
    },
    {
        "description": "Preferred speed (added): Value (Row 8)",
        "xpath": "/html/body/section[1]/div[8]/input[2]",
        "target_value": "1.5"
    },
    #----------------------------------------
    # Preferred speed #2
    {
        "description": "Preferred speed (added): Action (Row 9)",
        "xpath": "/html/body/section[1]/div[9]/select",
        "target_value": "fast"
    },
    {
        "description": "Preferred speed (added): Key (Row 9)",
        "xpath": "/html/body/section[1]/div[9]/input[1]",
        "target_value": "H"
    },
    {
        "description": "Preferred speed (added): Value (Row 9)",
        "xpath": "/html/body/section[1]/div[9]/input[2]",
        "target_value": "2"
    },
    #----------------------------------------
    # Preferred speed #3
    {
        "description": "Preferred speed (added): Action (Row 10)",
        "xpath": "/html/body/section[1]/div[10]/select",
        "target_value": "fast"
    },
    {
        "description": "Preferred speed (added): Key (Row 10)",
        "xpath": "/html/body/section[1]/div[10]/input[1]",
        "target_value": "A"
    },
    {
        "description": "Preferred speed (added): Value (Row 10)",
        "xpath": "/html/body/section[1]/div[10]/input[2]",
        "target_value": "3"
    },
    #----------------------------------------
    # Clear blocked sites
    {
        "description": "Blacklisted Sites",
        "xpath": "//*[@id='blacklist']",
        "target_value": ""
    }
]

#----------------------------------------
# Automation execution
#----------------------------------------
try:
    options_url = f"moz-extension://{internal_uuid}/options.html"
    print("Waiting for the Video Speed Controller extension to load...")

    for i in range(30):
        driver.get(options_url)
        time.sleep(2)

        try:
            driver.find_element(By.ID, "save")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    wait = WebDriverWait(driver, 10)
    needs_saving = False

    # Loop through the configuration manifest
    for setting in KEYBINDINGS_CONFIG:
        element = None

        # Try to find the element, clicking "Add New" if it doesn't exist
        for attempt in range(5):
            try:
                element = driver.find_element(By.XPATH, setting["xpath"])
                break  # Element found, exit the retry loop
            except NoSuchElementException:
                if attempt == 0:
                    print(f"Element '{setting['description']}' not found. Clicking 'Add New' to generate row...")
                add_button = driver.find_element(By.ID, "add")
                driver.execute_script("arguments[0].click();", add_button)
                time.sleep(0.5) # Give the DOM half a second to render the new row

        if not element:
            print(f"Error: Could not locate or generate DOM element for {setting['description']}. Check your XPath.")
            sys.exit(1)

        # Check and update the value
        current_val = element.get_attribute("value")

        if current_val != setting["target_value"]:
            # Added repr() so the multiline blacklist output formats cleanly in your terminal
            print(f"Updating '{setting['description']}': [{repr(current_val)}] -> [{repr(setting['target_value'])}]")

            # Handle dropdowns (<select>) and normal text fields differently
            if element.tag_name == "select":
                driver.execute_script(
                    "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('change'));",
                    element,
                    setting["target_value"]
                )
            else:
                element.clear()
                # Prevent sending empty keys if the goal is just to leave it blank
                if setting["target_value"] != "":
                    element.send_keys(setting["target_value"])

            needs_saving = True

    # Idempotency check: Only click save and write marker if a change was actually made
    if needs_saving:
        print("Changes detected. Saving configuration...")
        time.sleep(1)

        save_button = wait.until(EC.element_to_be_clickable((By.ID, "save")))
        driver.execute_script("arguments[0].click();", save_button)

        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings configured via Ansible on {time.ctime()}\n")

        print("Success: Keybindings saved and applied.")
    else:
        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings verified via Ansible on {time.ctime()}\n")

        print("Skipped: All keybindings are already configured correctly.")

    # Force disk flush
    time.sleep(1)
    driver.get("about:support")
    time.sleep(2)

finally:
    driver.quit()
