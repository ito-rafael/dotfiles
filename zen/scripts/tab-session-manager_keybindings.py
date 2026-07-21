#!/usr/bin/env python3
"""
Automates custom keybindings for a specific extension in Zen Browser.
Must be run when Zen is closed to prevent profile corruption.
"""

import os
import re
import sys
import time
import glob
import json
import subprocess

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
#from webdriver_manager.firefox import GeckoDriverManager

# ========================================
# CONFIGURATION
# ========================================
EXTENSION_ID = "Tab-Session-Manager@sienori"
EXTENSION_PAGE_PATH = "/options/index.html#shortcuts"
SETTINGS_CONFIG = [
    {
        "description": "Open toolbar popup",
        "xpath": "//*[@id='_execute_action']",
        "target_value": "Alt+B"
    },
    {
        "description": "Save session (only current window)",
        "xpath": "//*[@id='saveCurrentWindow']",
        "target_value": "Alt+O"
    }
]
# ========================================

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

MARKER_FILE = os.path.join(profile_base, f".tab-session-manager_keybindings_configured")

if os.path.exists(MARKER_FILE):
    print("Skipped: Extension settings already configured (Verified by state marker).")
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
except subprocess.CalledProcessError:
    pass

#----------------------------------------
# Lock cleanup
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
    print(f"Error: Could not find the internal UUID for {EXTENSION_ID} in prefs.js. Is it installed?")
    sys.exit(1)

#----------------------------------------
# Browser configuration & Driver Init
#----------------------------------------
options = Options()
options.binary_location = ZEN_BINARY_PATH
options.add_argument("-profile")
options.add_argument(profile_base)

# using "webdriver_manager.firefox"
#print("Initializing GeckoDriver...")
#driver_path = GeckoDriverManager().install()
#service = Service(driver_path)
#driver = webdriver.Firefox(service=service, options=options)

# using binary from package manager
print("Initializing system GeckoDriver...")
service = Service("/usr/bin/geckodriver")
driver = webdriver.Firefox(service=service, options=options)

# Force a 1080p viewport so elements don't get squished off-screen
driver.set_window_size(1920, 1080)

#----------------------------------------
# Automation execution
#----------------------------------------
try:
    options_url = f"moz-extension://{internal_uuid}{EXTENSION_PAGE_PATH}"
    print(f"Navigating to {options_url}...")

    # Wait loop for extension DOM hydration
    for i in range(30):
        driver.get(options_url)
        time.sleep(2)

        try:
            # Replaced "body" with the actual ID you are looking for to guarantee JS has rendered
            driver.find_element(By.ID, "saveCurrentWindow")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    wait = WebDriverWait(driver, 10)
    actions = ActionChains(driver)

    # Loop through the configuration manifest
    for setting in SETTINGS_CONFIG:
        try:
            print(f"Configuring {setting['description']}...")
            element = wait.until(EC.presence_of_element_located((By.XPATH, setting["xpath"])))

            # Force the browser to scroll the element into the exact center of the screen
            driver.execute_script("arguments[0].scrollIntoView({block: 'center', inline: 'center'});", element)
            time.sleep(0.5)

            # Click the field to focus it
            actions.click(element).pause(0.5).perform()

            # Note: For many shortcut fields, hitting Backspace clears it natively
            actions.send_keys(Keys.BACKSPACE).pause(0.5).perform()

            # Dynamic Keystroke Parser: split "Alt+X" into ["Alt", "X"]
            keys_list = setting["target_value"].split("+")
            modifier_string = keys_list[0]
            letter = keys_list[1].lower() # Selenium requires lowercase letters for send_keys

            # Map the string to the correct Selenium Key object
            if modifier_string == "Alt":
                mod_key = Keys.ALT
            elif modifier_string == "Ctrl":
                mod_key = Keys.CONTROL
            elif modifier_string == "Shift":
                mod_key = Keys.SHIFT
            else:
                mod_key = Keys.ALT # Fallback

            # Physically hold the modifier, press the letter, then release
            actions.key_down(mod_key).send_keys(letter).key_up(mod_key).perform()
            # -------------------------------------

            time.sleep(0.5)

        except Exception as e:
            print(f"Error interacting with {setting['description']}: {e}")

    # Write marker file
    with open(MARKER_FILE, 'w') as f:
        f.write(f"Configured via Ansible on {time.ctime()}\n")

    print("Success: Configuration applied.")

    # Force disk flush
    time.sleep(1)
    driver.get("about:support")
    time.sleep(2)

finally:
    driver.quit()
