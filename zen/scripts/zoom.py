#!/usr/bin/env python3
"""
Automates setting a custom zoom value in about:preferences#accessibility for Zen Browser.
Idempotent task that leverages the native preferences page.
Must be run when Zen is closed to prevent profile corruption.
"""

import os
import sys
import time
import glob
import subprocess
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.firefox import GeckoDriverManager

# Dynamically find the Zen Browser binary path
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

MARKER_FILE = os.path.join(profile_base, ".accessibility_zoom_configured")

#----------------------------------------
# State marker pre-flight check
#----------------------------------------
if os.path.exists(MARKER_FILE):
    print("Skipped: Accessibility zoom already set (Verified by state marker).")
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
# Browser configuration
#----------------------------------------
options = Options()
options.binary_location = ZEN_BINARY_PATH
options.add_argument("-profile")
options.add_argument(profile_base)

# Optional: Run headlessly
# options.add_argument("-headless")

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
    print("Navigating to native accessibility preferences...")
    driver.get("about:preferences#accessibility")

    wait = WebDriverWait(driver, 10)
    actions = ActionChains(driver)

    print("Using native search to reveal the setting...")
    # Use the search bar to ensure the element is visible in the viewport
    search_box = wait.until(EC.presence_of_element_located((By.ID, "searchInput")))
    actions.click(search_box).pause(0.5).send_keys("Default zoom").perform()

    # Give the UI a moment to filter the page
    time.sleep(1.5)

    print("Locating the outer wrapper...")
    # Target the outer web component wrapper, which lives in the normal light DOM
    target_dropdown = wait.until(EC.presence_of_element_located((By.ID, "defaultZoom")))

    print("Injecting 120% value natively...")
    # Click the wrapper and send the keys directly to it
    actions = ActionChains(driver)
    actions.click(target_dropdown).pause(0.5).send_keys("120").pause(0.5).send_keys(Keys.RETURN).perform()

    # Give Firefox's internal engine a moment to flush the change to the SQLite database
    time.sleep(1)

    with open(MARKER_FILE, 'w') as f:
        f.write(f"Accessibility zoom set to 120% via Ansible on {time.ctime()}\n")

    print("Success: Accessibility zoom set to 120%.")

    # Force disk flush
    driver.get("about:support")
    time.sleep(2)

finally:
    driver.quit()
