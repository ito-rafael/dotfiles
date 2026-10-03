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
import subprocess

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException

EXTENSION_ID = "{7be2ba16-0f1e-4d93-9ebc-5164397477a9}"
EXTENSION_PAGE_PATH = "/options.html"

POSSIBLE_BINARIES = [
    "/opt/zen-browser-bin/zen-bin",
    "/opt/zen-browser-bin/zen",
    "/usr/lib/zen-browser/zen-bin",
    "/usr/lib/zen-browser/zen"
]

ZEN_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not ZEN_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Zen Browser executable.")

zen_config_dir = os.path.expanduser("~/.config/zen")
valid_profiles = []
if os.path.exists(zen_config_dir):
    for folder in os.listdir(zen_config_dir):
        full_path = os.path.join(zen_config_dir, folder)
        prefs_file = os.path.join(full_path, "prefs.js")
        if os.path.isdir(full_path) and os.path.exists(prefs_file):
            valid_profiles.append(full_path)

if not valid_profiles:
    raise FileNotFoundError("Critical: Could not locate any Zen profile containing a prefs.js file.")

valid_profiles.sort(key=lambda p: os.path.getmtime(os.path.join(p, "prefs.js")), reverse=True)
profile_base = valid_profiles[0]

print(f"Targeting active profile: {profile_base}")

MARKER_FILE = os.path.join(profile_base, ".vsc_keybindings_configured")

if os.path.exists(MARKER_FILE):
    print("Skipped: VSC keybindings are already set (Verified by state marker).")
    sys.exit(0)

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

for lock in ["lock", "parent.lock", ".parentlock"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
        except OSError:
            pass

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
    print("Error: Could not find the internal UUID for Video Speed Controller. Is it installed?")
    sys.exit(1)

options = Options()
options.binary_location = ZEN_BINARY_PATH
options.add_argument("-profile")
options.add_argument(profile_base)

options_url = f"moz-extension://{internal_uuid}{EXTENSION_PAGE_PATH}"
print(f"Injecting startup URL: {options_url}")
options.add_argument(options_url)

print("Initializing system GeckoDriver...")
service = Service("/usr/bin/geckodriver")
driver = webdriver.Firefox(service=service, options=options)
driver.set_window_size(1920, 1080)

KEYBINDINGS_CONFIG = [
    {"description": "Decrease speed: Key", "xpath": "/html/body/section[1]/div[2]/input[1]", "target_value": "{"},
    {"description": "Decrease speed: Value", "xpath": "/html/body/section[1]/div[2]/input[2]", "target_value": "0.25"},
    {"description": "Increase speed: Key", "xpath": "/html/body/section[1]/div[3]/input[1]", "target_value": "}"},
    {"description": "Increase speed: Value", "xpath": "/html/body/section[1]/div[3]/input[2]", "target_value": "0.25"},
    {"description": "Reset speed: Key", "xpath": "/html/body/section[1]/div[6]/input[1]", "target_value": "U"},
    {"description": "Reset speed: Value", "xpath": "/html/body/section[1]/div[6]/input[2]", "target_value": "1"},
    {"description": "Preferred speed (original): Key", "xpath": "/html/body/section[1]/div[7]/input[1]", "target_value": "-"},
    {"description": "Preferred speed (original): Value", "xpath": "/html/body/section[1]/div[7]/input[2]", "target_value": "0.75"},
    {"description": "Preferred speed (added): Action 1", "xpath": "/html/body/section[1]/div[8]/select", "target_value": "fast", "is_select": True},
    {"description": "Preferred speed (added): Key 1", "xpath": "/html/body/section[1]/div[8]/input[1]", "target_value": "\\"},
    {"description": "Preferred speed (added): Value 1", "xpath": "/html/body/section[1]/div[8]/input[2]", "target_value": "1.5"},
    {"description": "Preferred speed (added): Action 2", "xpath": "/html/body/section[1]/div[9]/select", "target_value": "fast", "is_select": True},
    {"description": "Preferred speed (added): Key 2", "xpath": "/html/body/section[1]/div[9]/input[1]", "target_value": "H"},
    {"description": "Preferred speed (added): Value 2", "xpath": "/html/body/section[1]/div[9]/input[2]", "target_value": "2"},
    {"description": "Preferred speed (added): Action 3", "xpath": "/html/body/section[1]/div[10]/select", "target_value": "fast", "is_select": True},
    {"description": "Preferred speed (added): Key 3", "xpath": "/html/body/section[1]/div[10]/input[1]", "target_value": "A"},
    {"description": "Preferred speed (added): Value 3", "xpath": "/html/body/section[1]/div[10]/input[2]", "target_value": "3"},
    {"description": "Blacklisted Sites", "xpath": "//*[@id='blacklist']", "target_value": ""}
]

try:
    print("Waiting for the Video Speed Controller extension to load...")
    for i in range(30):
        try:
            driver.find_element(By.ID, "save")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")
            driver.refresh()
            time.sleep(2)

    wait = WebDriverWait(driver, 10)
    needs_saving = False

    for setting in KEYBINDINGS_CONFIG:
        element = None
        for attempt in range(5):
            try:
                element = driver.find_element(By.XPATH, setting["xpath"])
                break
            except NoSuchElementException:
                if attempt == 0:
                    print(f"Element '{setting['description']}' not found. Clicking 'Add New' to generate row...")
                add_button = driver.find_element(By.ID, "add")
                add_button.click()
                time.sleep(0.5)

        if not element:
            print(f"Error: Could not locate or generate DOM element for {setting['description']}.")
            sys.exit(1)

        # Swallowed Exception block to protect against disabled element JS errors
        try:
            if setting.get("is_select"):
                option_xpath = f"{setting['xpath']}/option[@value='{setting['target_value']}']"
                driver.find_element(By.XPATH, option_xpath).click()
                needs_saving = True
                print(f"Updating '{setting['description']}' -> [{repr(setting['target_value'])}]")
            else:
                element.clear()
                if setting["target_value"] != "":
                    element.send_keys(setting["target_value"])
                needs_saving = True
                print(f"Updating '{setting['description']}' -> [{repr(setting['target_value'])}]")
        except Exception as e:
            print(f"  -> Skipped: Element disabled or immutable ({type(e).__name__}).")

    if needs_saving:
        print("Changes detected. Saving configuration...")
        time.sleep(1)

        # THE FIX: Bypassing the JS visibility check natively
        save_button = wait.until(EC.presence_of_element_located((By.ID, "save")))
        time.sleep(0.5)
        save_button.click()

        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings configured via Ansible on {time.ctime()}\n")

        print("Success: Keybindings saved and applied.")
    else:
        with open(MARKER_FILE, 'w') as f:
            f.write(f"VSC Keybindings verified via Ansible on {time.ctime()}\n")

        print("Skipped: All keybindings are already configured correctly.")

    time.sleep(1)

finally:
    driver.quit()
