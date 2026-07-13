#!/usr/bin/env python3
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
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager

"""
Automates toggling the "Allow in Private" permission for the Dark Reader extension.
Uses Selenium with a real user profile to pierce the Shadow DOM and physically click the toggle.
"""

EXTENSION_ID = "eimadpbcbfnmbkopoojfekhnkhdbieeh"  # Dark Reader

# bypass the Linux bash wrappers and target the compiled binaries directly
POSSIBLE_BINARIES = [
    "/opt/brave.com/brave-origin/brave",  # Debian
    "/opt/brave-origin-bin/brave",        # Arch Linux
    "/opt/brave.com/brave/brave",         # Standard Stable
    "/usr/bin/brave-origin-beta",         # Bash wrapper fallbacks
    "/usr/bin/brave-origin",
    "/usr/bin/brave",
    "/usr/bin/brave-browser"
]

BRAVE_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not BRAVE_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Brave executable in any known locations.")

home_dir = os.path.expanduser("~")

# dynamically find the correct Brave profile directory based on what exists
POSSIBLE_PROFILES = [
    f"{home_dir}/.config/BraveSoftware/Brave-Origin-Beta",  # Arch Linux
    f"{home_dir}/.config/BraveSoftware/Brave-Origin",       # Debian
    f"{home_dir}/.config/BraveSoftware/Brave-Browser",      # Fallback Stable
    f"{home_dir}/.config/BraveSoftware/Brave-Browser-Beta"  # Fallback Beta
]

profile_base = next((path for path in POSSIBLE_PROFILES if os.path.exists(path)), None)

if not profile_base:
    raise FileNotFoundError("Critical: Could not locate the Brave profile directory.")

def get_chromium_version_for_brave(binary_path):
    """
    Extracts Brave's major version, then queries the official Chrome for Testing API to map it to the exact underlying Chromium version required by ChromeDriver
    """
    try:
        result = subprocess.run([binary_path, "--version"], capture_output=True, text=True, check=True)
        match = re.search(r'(\d+)\.\d+\.\d+\.\d+', result.stdout)
        if not match:
            raise ValueError(f"Could not parse major version from: {result.stdout}")

        major_version = match.group(1)
        print(f"Detected Brave Milestone: {major_version}")

        api_url = "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone.json"
        req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))

        exact_chromium_version = data["milestones"][major_version]["version"]
        print(f"Mapped to Chromium Version: {exact_chromium_version}")
        return exact_chromium_version

    except Exception as e:
        raise RuntimeError(f"Critical failure: Could not auto-detect or map Brave version. ({e})") from e

BRAVE_VERSION = get_chromium_version_for_brave(BRAVE_BINARY_PATH)

options = Options()
options.binary_location = BRAVE_BINARY_PATH

options.add_experimental_option("excludeSwitches", [
    "enable-automation",
    "disable-background-networking"
])
options.add_experimental_option('useAutomationExtension', False)

options.add_experimental_option("prefs", {
    "profile.exit_type": "Normal",
    "profile.exited_cleanly": True
})

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
                print(f"Terminated lingering background burn-in process (PID {pid}).")
            except Exception:
                pass
            continue

        running_standard_sessions = True
        break

    if running_standard_sessions:
        print("Error: Standard Brave is currently running. Aborting to protect active session.")
        sys.exit(1)
    else:
        print("No active standard Brave sessions found. Proceeding with headless configuration...")

except subprocess.CalledProcessError:
    print("No active Brave sessions found. Proceeding with headless configuration...")

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
target_url = f"brave://extensions/?id={EXTENSION_ID}"

try:
    # Pierce the Shadow DOM looking specifically for the Allow in Private toggle
    js_get_incognito_toggle = """
    const manager = document.querySelector('extensions-manager');
    if (!manager || !manager.shadowRoot) return null;

    const detailView = manager.shadowRoot.querySelector('extensions-detail-view');
    if (!detailView || !detailView.shadowRoot) return null;

    let row = detailView.shadowRoot.querySelector('#allow-incognito');
    if (!row) return null;

    // Return the wrapper so Python can read its 'checked' attribute
    return row.querySelector('cr-toggle') || (row.shadowRoot && row.shadowRoot.querySelector('cr-toggle'));
    """

    actions = ActionChains(driver)

    toggle_element = None
    print(f"Waiting for the Brave Extensions page to load for {EXTENSION_ID}...")

    for i in range(15):
        driver.get(target_url)
        time.sleep(1)
        toggle_element = driver.execute_script(js_get_incognito_toggle)
        if toggle_element:
            print("Extension DOM hydrated successfully!")
            break
        print(f"Waiting for DOM to hydrate... (Attempt {i+1}/15)")

    if not toggle_element:
        print("Error: 'Allow in Private' toggle element not found.")
        sys.exit(1)

    # Evaluate physical DOM state
    is_checked = driver.execute_script("return arguments[0].checked === true || arguments[0].getAttribute('aria-pressed') === 'true';", toggle_element)

    if not is_checked:
        driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", toggle_element)
        time.sleep(0.5)
        actions.move_to_element(toggle_element).click().perform()
        print("Success: 'Allow in Private' toggled ON.")
    else:
        print("Skipped: 'Allow in Private' is already ON.")

    # force an asynchronous disk flush by navigating away before terminating the process
    time.sleep(2)
    driver.get("brave://settings")
    time.sleep(3)

finally:
    driver.quit()
