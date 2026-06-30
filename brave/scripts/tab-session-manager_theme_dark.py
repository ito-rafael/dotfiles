#!/usr/bin/env python3
"""
Automates changing the theme to 'Dark' for the Tab Session Manager extension.
Ensures idempotency by checking the dropdown state before acting.
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

EXTENSION_ID = "iaiomicjabeggjcfkbimgmglanimpnae"

# dynamically find the right Brave binary path based on what exists on the system
POSSIBLE_BINARIES = [
    "/usr/bin/brave-origin",        # Debian / Arch Linux
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
MARKER_FILE = os.path.join(profile_base, ".tsm_dark_theme_configured")

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
    # if the receipt exists, skip the active session check and selenium execution
    print("Skipped: Theme is already set to Dark (Verified by state marker).")
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
print("Initializing ChromeDriver...")
driver_path = ChromeDriverManager(driver_version=get_chromium_version_for_brave(BRAVE_BINARY_PATH)).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)


#----------------------------------------
# automation execution
#----------------------------------------
try:
    # navigate directly to the settings hash of the extension's internal options page
    options_url = f"chrome-extension://{EXTENSION_ID}/options/index.html#settings"
    theme_dropdown = None

    # polling loop with hydration wait
    print("Waiting for the Tab Session Manager extension to load...")
    for i in range(30):
        driver.get(options_url)

        # give the vue framework time to build the DOM
        time.sleep(2)

        try:
            theme_dropdown = driver.find_element(By.XPATH, '//*[@id="theme"]')
            print("Extension loaded successfully!")
            break
        except:
            print(f"Still unpacking... (Attempt {i+1}/30)")

    if not theme_dropdown:
        print("Error: Tab Session Manager never installed or loaded.")
        sys.exit(1)

    # check current theme state
    current_theme = driver.execute_script("return arguments[0].value;", theme_dropdown)

    # the value attribute is usually lowercase 'dark' inside the <select> element
    if current_theme.lower() == "dark":
        # write the receipt so we skip selenium next time
        with open(MARKER_FILE, 'w') as f:
            f.write(f"Theme verified as Dark via Ansible on {time.ctime()}\n")
        print("Skipped: Theme is already set to Dark.")

    else:
        print(f"Current theme is '{current_theme}'. Injecting Dark theme...")

        # bypass ui blocks with direct javascript dom injection
        # we trigger both input and change events to ensure vue.js catches the update
        driver.execute_script("""
            let select = arguments[0];
            select.value = 'dark';
            select.dispatchEvent(new Event('input', { bubbles: true }));
            select.dispatchEvent(new Event('change', { bubbles: true }));
        """, theme_dropdown)

        # write the receipt so we skip selenium next time
        with open(MARKER_FILE, 'w') as f:
            f.write(f"Theme configured to Dark via Ansible on {time.ctime()}\n")

        print("Success: Theme updated to Dark.")

    # force disk flush by navigating away before terminating the process
    time.sleep(1)
    driver.get("chrome://version")
    time.sleep(2)

finally:
    driver.quit()
