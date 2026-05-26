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

# --- CONFIGURATION ---
EXTENSION_ID = "gfbliohnnapiefjpjlpjnehglfpaknnc"
BRAVE_BINARY_PATH = "/usr/bin/brave-origin"

username = os.getenv("USER")
profile_base = f"/home/{username}/.config/BraveSoftware/Brave-Origin-Beta"


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
    pass # No active sessions found, safe to proceed!


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
options.add_argument("--headless=new")
options.add_argument("--window-size=1920,1080")
options.add_argument("--window-position=0,0")

options.add_argument(f"--user-data-dir={profile_base}")
options.add_argument("--profile-directory=Default")


# --- INITIALIZE DRIVER ---
driver_path = ChromeDriverManager(driver_version=get_chromium_version_for_brave(BRAVE_BINARY_PATH)).install()
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=options)


# --- AUTOMATION EXECUTION ---
try:
    # 1. Navigate directly to the extension's internal options page
    options_url = f"chrome-extension://{EXTENSION_ID}/pages/options.html"
    driver.get(options_url)
    
    # 2. Wait for the DOM to render and locate the toggle
    wait = WebDriverWait(driver, 10)
    
    # Using By.ID is the cleanest implementation of your XPath: //*[@id="advancedToggler"]
    toggle_checkbox = wait.until(EC.presence_of_element_located((By.ID, "advancedToggler")))
    
    # 3. Idempotent action: Check state before clicking
    if not toggle_checkbox.is_selected():
        toggle_checkbox.click()
        print("Success: Toggled ON.")
    else:
        print("Skipped: Already ON.")

    # 4. Force a disk flush to save extension settings locally
    time.sleep(1)
    driver.get("chrome://version")
    time.sleep(2)

finally:
    driver.quit()
