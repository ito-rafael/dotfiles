#!/usr/bin/env python
import os
import re
import sys
import time
import json
import subprocess
import urllib.request
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

"""
Automates toggling the "Allow User Scripts" permission for the Surfingkeys extension.
Uses Selenium with a real user profile, ensuring state is securely saved to disk.

Before running this script, be sure there is no Brave process running.
"""

EXTENSION_ID = "gfbliohnnapiefjpjlpjnehglfpaknnc"
BRAVE_BINARY_PATH = "/usr/bin/brave"

username = os.getenv("USER")
profile_base = f"/home/{username}/.config/BraveSoftware/Brave-Browser"

def get_chromium_version_for_brave(binary_path):
    """
    Extracts Brave's major version, then queries the official Chrome for Testing API to map it to the exact underlying Chromium version required by ChromeDriver
    """
    try:
        # ask Brave version
        result = subprocess.run([binary_path, "--version"], capture_output=True, text=True, check=True)
        
        # extract just the very first number (the Major Milestone)
        match = re.search(r'(\d+)\.\d+\.\d+\.\d+', result.stdout)
        if not match:
            raise ValueError(f"Could not parse major version from: {result.stdout}")
            
        major_version = match.group(1)
        print(f"Detected Brave Milestone: {major_version}")
        
        # ask Google for the exact Chromium version for this milestone
        api_url = "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone.json"
        
        # use a simple User-Agent to prevent getting blocked by the API
        req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        # extract the exact Chromium version string
        exact_chromium_version = data["milestones"][major_version]["version"]
        print(f"Mapped to Chromium Version: {exact_chromium_version}")
        
        return exact_chromium_version
        
    except Exception as e:
        # raise a fatal error and chain the original exception for debugging
        raise RuntimeError(f"Critical failure: Could not auto-detect or map Brave version. ({e})") from e

BRAVE_VERSION = get_chromium_version_for_brave(BRAVE_BINARY_PATH)

def is_user_scripts_enabled(profile_path, ext_id):
    """Safely checks the profile JSON without touching the browser process."""
    prefs_paths = [
        os.path.join(profile_path, "Secure Preferences"),
        os.path.join(profile_path, "Preferences")
    ]
    for path in prefs_paths:
        if os.path.exists(path):
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                ext_settings = data.get("extensions", {}).get("settings", {}).get(ext_id, {})
                active_api = ext_settings.get("active_permissions", {}).get("api", [])
                if "userScripts" in active_api:
                    return True
            except Exception:
                pass
    return False

options = Options()
options.binary_location = BRAVE_BINARY_PATH

# cloaking flags (prevents Brave from isolating preference changes in an automation sandbox)
options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option('useAutomationExtension', False)

# stability flags (required for launching UI head-on in Wayland/Sway environments)
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")

# headless mode (runs the full browser pipeline without a UI)
options.add_argument("--headless=new")

# virtual geometry (even though it's headless, it needs a virtual canvas to "draw" the DOM, so our Javascript can find the toggle button coordinates)
options.add_argument("--window-size=1920,1080")
options.add_argument("--window-position=0,0")

username = os.getenv("USER")
profile_base = f"/home/{username}/.config/BraveSoftware/Brave-Browser"
options.add_argument(f"--user-data-dir={profile_base}")
options.add_argument("--profile-directory=Default")

if is_user_scripts_enabled(profile_base, EXTENSION_ID):
    print("Skipped: Already ON.")
    sys.exit(0)  # exit cleanly

try:
    # pgrep returns exit code 0 if it finds the process
    subprocess.check_output(["pgrep", "-f", "brave"])
    print("Error: Brave is currently running. Aborting to protect active session.")
    sys.exit(1)  # exit with error

except subprocess.CalledProcessError:
    # pgrep returns non-zero if no processes are found --> safe to proceed!
    print("No active Brave sessions found. Proceeding with headless configuration...")

# clear stale locks left behind by abrupt process termination (pkill)
for lock in ["SingletonLock", "SingletonCookie", "SingletonSocket"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
        except OSError:
            pass

driver_path = ChromeDriverManager(driver_version=BRAVE_VERSION).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)
try:
    driver.get(f"brave://extensions/?id={EXTENSION_ID}")
    time.sleep(2)

    # retrieve the nested toggle WebElement through Chromium's Web Components (Shadow DOM)
    js_get_element = """
    const manager = document.querySelector('extensions-manager');
    if (!manager) return null;
    
    const detailView = manager.shadowRoot.querySelector('extensions-detail-view');
    if (!detailView) return null;
    
    const toggleContainer = detailView.shadowRoot.querySelector('#allow-user-scripts');
    if (!toggleContainer) return null;
    
    return toggleContainer.querySelector('cr-toggle') || toggleContainer;
    """
    
    toggle_element = driver.execute_script(js_get_element)

    if toggle_element is None:
        print("Error: Toggle element could not be found.")
    else:
        is_checked = toggle_element.get_attribute("checked")
        
        if is_checked is None or is_checked == "false":
            # Perform a trusted hardware-level click so the browser allows the security change
            toggle_element.click()
            print("Success: Toggled ON.")
        else:
            print("Skipped: Already ON.")

    # force an asynchronous disk flush by navigating away before terminating the process
    time.sleep(2)
    driver.get("brave://settings")
    time.sleep(3)

finally:
    driver.quit()
