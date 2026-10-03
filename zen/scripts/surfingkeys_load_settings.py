#!/usr/bin/env python3
"""
Sets the Surfingkeys 'Load settings from' path to a GitHub raw URL for Zen Browser.
Idempotent task that skips execution if the URL is already set.
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
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# The official Firefox Extension ID for Surfingkeys
EXTENSION_ID = "{a8332c60-5b6d-41ee-bfc8-e9bb331d34ad}"
EXTENSION_PAGE_PATH = "/pages/options.html"
DOTFILES_URL = "https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/brave/extension/surfingkeys.js"

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

MARKER_FILE = os.path.join(profile_base, ".surfingkeys_load_settings_configured")

if os.path.exists(MARKER_FILE):
    print("Skipped: URL is already set (Verified by state marker).")
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
    print("Error: Could not find the internal UUID for Surfingkeys. Is it installed?")
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

try:
    print("Waiting for the Surfingkeys extension to load...")
    path_input = None
    for i in range(30):
        try:
            path_input = driver.find_element(By.ID, "localPath")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")
            driver.refresh()
            time.sleep(2)

    if not path_input:
        print("Error: Surfingkeys never installed or loaded.")
        sys.exit(1)

    wait = WebDriverWait(driver, 10)

    print("Ensuring Advanced Mode is active...")
    advanced_toggle = wait.until(EC.presence_of_element_located((By.ID, "advancedToggler")))

    # is_selected() is a native boolean check and does NOT use JS!
    if not advanced_toggle.is_selected():
        advanced_toggle.click()
        time.sleep(1)

    print("Injecting dotfiles URL...")
    # Native Selenium input clears the box and sends the text + Enter key
    path_input.clear()
    path_input.send_keys(DOTFILES_URL, Keys.RETURN)

    print("Saving configuration...")
    time.sleep(1)

    # Locate the save button
    save_button = wait.until(EC.presence_of_element_located((By.ID, "save_button")))

    # Send the RETURN key directly to the button element to trigger it natively,
    # bypassing any overlapping divs that would intercept a standard mouse .click()
    save_button.send_keys(Keys.RETURN)

    with open(MARKER_FILE, 'w') as f:
        f.write(f"Settings URL configured via Ansible on {time.ctime()}\n")

    print("Success: Configuration URL saved and applied.")
    time.sleep(1)

finally:
    driver.quit()
