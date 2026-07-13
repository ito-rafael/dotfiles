#!/usr/bin/env python3
"""
Automates disabling (turning OFF) a list of Brave/Chrome extensions.
Uses Selenium ActionChains to bypass the untrusted event shield.
"""

import os
import sys
import time
import subprocess
import re
import urllib.request
import json

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager

# ---------------------------------------------------------
# define the extensions to be disabled here
# ---------------------------------------------------------
EXTENSIONS_TO_DISABLE = [
    "eodaonbgmhniagpgfepdflgjhmmkbnfi",  # Aliexpress SuperStar
    "nidpcgnchpokfhpdpdmobjkjefnofojo",  # Ativador de Cupons Mercado Livre Brasil
    "kbfnbcaeplbcioakkpcpgfkobkghlhen",  # Grammarly
    "neebplgakaahbhdphmkckjjcegoiijjo",  # Keepa
    "jdcfmebflppkljibgpdlboifpcaalolg",  # Méliuz
    "bmnlcjabgnpnenekpadlanbbkooimhnj",  # Honey
    "ghnomdcacenbmilgjigehppbamfndblo",  # The Camelizer
]

# Safely get the home directory (works perfectly inside Ansible non-login shells)
home_dir = os.path.expanduser("~")

POSSIBLE_BINARIES = [
    "/opt/brave-origin-bin/brave",
    "/opt/brave.com/brave-origin/brave",
    "/opt/brave.com/brave/brave",
    "/usr/bin/brave-origin-beta",
    "/usr/bin/brave-origin",
    "/usr/bin/brave",
    "/usr/bin/brave-browser"
]

BRAVE_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not BRAVE_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Brave executable in any known locations.")

POSSIBLE_PROFILES = [
    f"{home_dir}/.config/BraveSoftware/Brave-Origin-Beta",
    f"{home_dir}/.config/BraveSoftware/Brave-Origin",
    f"{home_dir}/.config/BraveSoftware/Brave-Browser",
    f"{home_dir}/.config/BraveSoftware/Brave-Browser-Beta"
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    raise FileNotFoundError("Critical: Could not locate the Brave profile directory.")

def get_chromium_version_for_brave(binary_path):
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

# ---------------------------------------------------------
# safety check: make sure Brave is not running
# ---------------------------------------------------------
try:
    result = subprocess.check_output(["pgrep", "-a", "-f", "[o]pt/brave.com/.*brave"], text=True)
    running_standard_sessions = False

    for line in result.splitlines():
        if " --type=" in line or " --app=" in line:
            continue
        if "--ansible-burn-in" in line:
            try:
                pid = line.split()[0]
                subprocess.run(["kill", "-9", pid], check=False)
            except Exception:
                pass
            continue
        running_standard_sessions = True
        break

    if running_standard_sessions:
        print("Error: Standard Brave is currently running. Aborting to protect active session.")
        sys.exit(1)
except subprocess.CalledProcessError:
    pass

# Clear stale locks
for lock in ["SingletonLock", "SingletonCookie", "SingletonSocket"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
        except OSError:
            pass

# ---------------------------------------------------------
# configure & launch selenium
# ---------------------------------------------------------
options = Options()
options.binary_location = BRAVE_BINARY_PATH
options.add_experimental_option("excludeSwitches", ["enable-automation", "disable-background-networking"])
options.add_experimental_option('useAutomationExtension', False)
options.add_experimental_option("prefs", {"profile.exit_type": "Normal", "profile.exited_cleanly": True})
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
options.add_argument("--ozone-platform=x11")
options.add_argument("--disable-software-rasterizer")
options.add_argument("--remote-allow-origins=*")
options.add_argument("--window-size=1920,1080")
options.add_argument("--window-position=0,0")
options.add_argument(f"--user-data-dir={profile_base}")
options.add_argument("--profile-directory=Default")

BRAVE_VERSION = get_chromium_version_for_brave(BRAVE_BINARY_PATH)
driver_path = ChromeDriverManager(driver_version=BRAVE_VERSION).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)
actions = ActionChains(driver)

# Javascript to pierce the Shadow DOM and grab the main Enable/Disable toggle
js_get_enable_toggle = """
const manager = document.querySelector('extensions-manager');
if (!manager || !manager.shadowRoot) return null;

const detailView = manager.shadowRoot.querySelector('extensions-detail-view');
if (!detailView || !detailView.shadowRoot) return null;

return detailView.shadowRoot.querySelector('#enableToggle');
"""

# ---------------------------------------------------------
# execution loop
# ---------------------------------------------------------
try:
    for ext_id in EXTENSIONS_TO_DISABLE:
        print(f"\nProcessing Extension: {ext_id}")
        target_url = f"brave://extensions/?id={ext_id}"
        toggle_element = None

        # Polling Loop
        for i in range(15):
            driver.get(target_url)
            time.sleep(1)
            toggle_element = driver.execute_script(js_get_enable_toggle)

            if toggle_element:
                break
            print(f"  Waiting for DOM to hydrate... (Attempt {i+1}/15)")

        # Fallback if extension doesn't exist
        if not toggle_element:
            print(f"  Error: Could not find toggle. Is extension {ext_id} installed?")
            continue  # Gracefully skip to the next extension in the list

        # Evaluate current hardware state
        is_checked = driver.execute_script("return arguments[0].checked === true || arguments[0].getAttribute('aria-pressed') === 'true';", toggle_element)

        # Execute Click
        if is_checked:
            driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", toggle_element)
            time.sleep(0.5)
            actions.move_to_element(toggle_element).click().perform()
            print(f"  Success: Extension {ext_id} toggled OFF.")
        else:
            print(f"  Skipped: Extension {ext_id} is already OFF.")

    # Force an asynchronous disk flush
    time.sleep(2)
    driver.get("brave://settings")
    time.sleep(3)

finally:
    driver.quit()
