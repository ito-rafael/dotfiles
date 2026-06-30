#!/usr/bin/env python3
"""
Automates toggling the "Advanced Mode" setting inside the Surfingkeys extension.
Ensures idempotency by checking the toggle state before acting.
Must be run when Brave is closed to prevent profile corruption.
"""

import os
import re
import sys
import time
import json
import subprocess
import urllib.request

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

EXTENSION_ID = "gfbliohnnapiefjpjlpjnehglfpaknnc"

# dynamically find the right Brave binary path based on what exists on the system
POSSIBLE_BINARIES = [
    "/usr/bin/brave-origin",        # Debian / Arch Linux
    #"/usr/bin/brave-origin-beta",  # Arch Linux (Beta)
    #"/usr/bin/brave",              # fallback Stable
    #"/usr/bin/brave-browser",      # fallback Standard
    #"/usr/bin/brave-beta",         # fallback Beta
]

BRAVE_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not BRAVE_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Brave executable in any known locations.")

username = os.getenv("USER")

# dynamically find the correct Brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"/home/{username}/.config/BraveSoftware/Brave-Origin",        # Debian & Arch Linux
    #f"/home/{username}/.config/BraveSoftware/Brave-Browser-Beta"  # fallback Beta
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    raise FileNotFoundError("Critical: Could not locate the Brave profile directory.")

# define the state marker file
MARKER_FILE = os.path.join(profile_base, ".surfingkeys_advanced_mode_configured")

def get_chromium_version_for_brave(binary_path):
    """fetches the exact Chromium milestone required for the current Brave build."""
    try:
        result = subprocess.run([binary_path, "--version"], capture_output=True, text=True, check=True)
        match = re.search(r'(\d+)\.\d+\.\d+\.\d+', result.stdout)
        if not match:
            raise ValueError(f"Could not parse major version from: {result.stdout}")

        major_version = match.group(1)
        api_url = "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone.json"

        req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))

        return data["milestones"][major_version]["version"]

    except Exception as e:
        raise RuntimeError(f"Critical failure: Could not auto-detect or map Brave version. ({e})") from e


#----------------------------------------
# state marker pre-flight check
#----------------------------------------
if os.path.exists(MARKER_FILE):
    # if the receipt exists, we already did the hard work, skip everything
    print("Skipped: Already ON (Verified by state marker).")
    sys.exit(0)


#----------------------------------------
# active session safety check
#----------------------------------------
try:
    # get the full command line (-a) of all processes containing "brave" (-f)
    result = subprocess.check_output(["pgrep", "-a", "-f", "[o]pt/brave.com/brave-origin-beta/brave"], text=True)
    running_standard_sessions = False
    for line in result.splitlines():
        # ignore child processes (renderers, GPU, utility, etc.)
        if " --type=" in line:
            continue

        # ignore Distrobox Web Apps (--app=...)
        if " --app=" in line:
            continue

        # kill Ansible burn-in zombie process, if any
        if "--ansible-burn-in" in line:
            try:
                pid = line.split()[0]
                subprocess.run(["kill", "-9", pid], check=False)
                print(f"Terminated lingering background burn-in process (PID {pid}).")
            except Exception:
                pass
            continue

        # real desktop brave process found
        running_standard_sessions = True
        break

    if running_standard_sessions:
        print("Error: Standard Brave is currently running. Aborting to protect active session.")
        sys.exit(1)
    else:
        print("No active standard Brave sessions found. Proceeding with headless configuration...")
except subprocess.CalledProcessError:
    # pgrep returns non-zero if no processes are found, safe to proceed
    print("No active Brave sessions found. Proceeding with headless configuration...")


#----------------------------------------
# lock cleanup
#----------------------------------------
for lock in ["SingletonLock", "SingletonCookie", "SingletonSocket"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
        except OSError:
            pass


#----------------------------------------
# browser configuration
#----------------------------------------
options = Options()
options.binary_location = BRAVE_BINARY_PATH

options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option('useAutomationExtension', False)

options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
#options.add_argument("--headless=new")
options.add_argument("--ozone-platform=x11")
options.add_argument("--window-size=1920,1080")
options.add_argument("--window-position=0,0")

options.add_argument(f"--user-data-dir={profile_base}")
options.add_argument("--profile-directory=Default")


#----------------------------------------
# initialize driver
#----------------------------------------
driver_path = ChromeDriverManager(driver_version=get_chromium_version_for_brave(BRAVE_BINARY_PATH)).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)


#----------------------------------------
# automation execution
#----------------------------------------
try:
    # navigate directly to the extension's internal options page
    options_url = f"chrome-extension://{EXTENSION_ID}/pages/options.html"
    toggle_checkbox = None

    # polling loop
    for i in range(30):
        driver.get(options_url)

        # give the extension database 1 second to apply your saved settings to the HTML
        time.sleep(1)

        try:
            toggle_checkbox = driver.find_element(By.ID, "advancedToggler")
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    if not toggle_checkbox:
        print("Error: Surfingkeys never installed or loaded.")
        sys.exit(1)

    # idempotent action: use pure Javascript to read the true DOM property
    is_checked = driver.execute_script("return arguments[0].checked;", toggle_checkbox)

    if not is_checked:
        driver.execute_script("arguments[0].click();", toggle_checkbox)

        # write the receipt to disk so we never have to run Selenium for this again
        with open(MARKER_FILE, 'w') as f:
            f.write(f"Advanced Mode configured via Ansible on {time.ctime()}\n")

        print("Success: Toggled ON.")
    else:
        # if it was already on (maybe you clicked it manually), write the receipt anyway
        with open(MARKER_FILE, 'w') as f:
            f.write(f"Advanced Mode verified via Ansible on {time.ctime()}\n")

        print("Skipped: Already ON.")

    # force a disk flush to save extension settings locally
    time.sleep(1)
    driver.get("chrome://version")
    time.sleep(2)

finally:
    driver.quit()
