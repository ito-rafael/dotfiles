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
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
#from webdriver_manager.firefox import GeckoDriverManager

# The official Firefox Extension ID for Surfingkeys
EXTENSION_ID = "{a8332c60-5b6d-41ee-bfc8-e9bb331d34ad}"
DOTFILES_URL = "https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/brave/extension/surfingkeys.js"

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

MARKER_FILE = os.path.join(profile_base, ".surfingkeys_load_settings_configured")

#----------------------------------------
# State marker pre-flight check
#----------------------------------------
if os.path.exists(MARKER_FILE):
    print("Skipped: URL is already set (Verified by state marker).")
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
    print("Error: Could not find the internal UUID for Surfingkeys in prefs.js. Is it installed?")
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
# using "webdriver_manager.firefox"
#print("Initializing GeckoDriver...")
#driver_path = GeckoDriverManager().install()
#service = Service(driver_path)
#driver = webdriver.Firefox(service=service, options=options)

# using binary from package manager
print("Initializing system GeckoDriver...")
service = Service("/usr/bin/geckodriver")
driver = webdriver.Firefox(service=service, options=options)

#----------------------------------------
# Automation execution
#----------------------------------------
try:
    options_url = f"moz-extension://{internal_uuid}/pages/options.html"

    print("Waiting for the Surfingkeys extension to load...")
    path_input = None
    for i in range(30):
        driver.get(options_url)
        time.sleep(3)

        try:
            path_input = driver.find_element(By.ID, "localPath")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    if not path_input:
        print("Error: Surfingkeys never installed or loaded.")
        sys.exit(1)

    wait = WebDriverWait(driver, 10)

    # ensure Advanced Mode is active first (required for the URL input to be visible)
    print("Ensuring Advanced Mode is active...")
    advanced_toggle = wait.until(EC.presence_of_element_located((By.ID, "advancedToggler")))
    is_advanced = driver.execute_script("return arguments[0].checked;", advanced_toggle)

    if not is_advanced:
        driver.execute_script("arguments[0].click();", advanced_toggle)
        time.sleep(1)

    # idempotent check for URL
    current_val = path_input.get_attribute("value")

    if current_val == DOTFILES_URL:
        with open(MARKER_FILE, 'w') as f:
            f.write(f"Settings URL verified via Ansible on {time.ctime()}\n")
        print("Skipped: URL is already set to the dotfiles repository.")

    else:
        print("Injecting dotfiles URL...")
        driver.execute_script("""
            let input = arguments[0];
            let newUrl = arguments[1];

            input.value = newUrl;
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            input.dispatchEvent(new KeyboardEvent('keydown', {
                key: 'Enter',
                code: 'Enter',
                keyCode: 13,
                which: 13,
                bubbles: true
            }));
        """, path_input, DOTFILES_URL)

        print("Saving configuration...")
        time.sleep(1)
        save_button = wait.until(EC.presence_of_element_located((By.ID, "save_button")))
        driver.execute_script("arguments[0].click();", save_button)

        with open(MARKER_FILE, 'w') as f:
            f.write(f"Settings URL configured via Ansible on {time.ctime()}\n")

        print("Success: Configuration URL saved and applied.")

    # force disk flush (using Firefox internal page)
    time.sleep(1)
    driver.get("about:support")
    time.sleep(2)

finally:
    driver.quit()
