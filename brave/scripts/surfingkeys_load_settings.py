#!/usr/bin/env python3
"""
Sets the Surfingkeys 'Load settings from' path to a GitHub raw URL.
Idempotent task that skips execution if the URL is already set.
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
from selenium.webdriver.common.keys import Keys

EXTENSION_ID = "gfbliohnnapiefjpjlpjnehglfpaknnc"

# dynamically find the right Brave binary path based on what exists on the system
POSSIBLE_BINARIES = [
    "/usr/bin/brave-origin",       # Debian
    "/usr/bin/brave-origin-beta",  # Arch Linux
    #"/usr/bin/brave",              # Fallback Stable
    #"/usr/bin/brave-browser",      # Fallback Standard
    #"/usr/bin/brave-beta",         # Fallback Beta
]

BRAVE_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not BRAVE_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Brave executable in any known locations.")

DOTFILES_URL = "https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/surfingkeys/surfingkeys.js"

username = os.getenv("USER")

# dynamically find the correct Brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"/home/{username}/.config/BraveSoftware/Brave-Origin-Beta",  # Debian & Arch Linux
    #f"/home/{username}/.config/BraveSoftware/Brave-Browser",      # Fallback Standard
    #f"/home/{username}/.config/BraveSoftware/Brave-Browser-Beta"  # Fallback Beta
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    raise FileNotFoundError("Critical: Could not locate the Brave profile directory.")

def get_chromium_version_for_brave(binary_path):
    """Fetches the exact Chromium milestone required for the current Brave build."""
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


# --- ACTIVE SESSION SAFETY CHECK ---
try:
    subprocess.check_output(["pgrep", "brave"])
    print("Error: Brave is currently running. Aborting to protect active session.")
    sys.exit(1)
except subprocess.CalledProcessError:
    pass 


# --- LOCK CLEANUP ---
for lock in ["SingletonLock", "SingletonCookie", "SingletonSocket"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try:
            os.remove(lock_path)
        except OSError:
            pass


# --- BROWSER CONFIGURATION ---
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


# --- INITIALIZE DRIVER ---
print("Initializing ChromeDriver...")
driver_path = ChromeDriverManager(driver_version=get_chromium_version_for_brave(BRAVE_BINARY_PATH)).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)


# --- AUTOMATION EXECUTION ---
try:
    # 1. NAVIGATE TO EXTENSION SETTINGS
    options_url = f"chrome-extension://{EXTENSION_ID}/pages/options.html"
    driver.get(options_url)
    wait = WebDriverWait(driver, 10)

    # 2. ENSURE ADVANCED MODE IS ON
    print("Ensuring Advanced Mode is active...")
    advanced_toggle = wait.until(EC.presence_of_element_located((By.ID, "advancedToggler")))
    if not advanced_toggle.is_selected():
        driver.execute_script("arguments[0].click();", advanced_toggle)
        time.sleep(1)

    # 3. LOCATE THE INPUT FIELD
    print("Locating 'Load settings from' input field...")
    path_input = wait.until(EC.presence_of_element_located((By.ID, "localPath")))
    
    # 4. IDEMPOTENT CHECK
    current_val = path_input.get_attribute("value")
    
    if current_val == DOTFILES_URL:
        print("Skipped: URL is already set to the dotfiles repository.")
    else:
        print("Injecting dotfiles URL...")
        
        # Bypass UI blocks with direct DOM injection
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
        
        # 5. EXPLICITLY CLICK SAVE
        print("Saving configuration...")
        save_button = wait.until(EC.element_to_be_clickable((By.ID, "save_button")))
        # Using JS click here as well, just in case a sticky header is covering the save button in headless mode
        driver.execute_script("arguments[0].click();", save_button)
        
        print("Success: Configuration URL saved and applied.")

    # 6. FORCE DISK FLUSH
    time.sleep(1)
    driver.get("chrome://version")
    time.sleep(2)

finally:
    driver.quit()
