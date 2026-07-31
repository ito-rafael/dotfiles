#!/usr/bin/env python3
"""
Automates configuring the tbkeys extension inside Betterbird.
Uses a dynamic Trojan Horse wrapper to bypass Geckodriver's security checks.
Bypasses Fission (e10s) isolation natively via Mozilla IPC messageManager.
"""

import os
import sys
import time
import base64
import subprocess

from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options

# ========================================
# configuration
# ========================================
CONFIG_FILE_PATH = "/home/ansible/git/dotfiles/betterbird/tbkeys.json"

POSSIBLE_BINARIES = [
    "/usr/bin/betterbird",
    "/opt/betterbird/betterbird"
]
BB_BINARY_PATH = next((path for path in POSSIBLE_BINARIES if os.path.exists(path)), None)

if not BB_BINARY_PATH:
    raise FileNotFoundError("Critical: Could not find the Betterbird executable.")
# ========================================

#----------------------------------------
# find the active profile & Guardrails
#----------------------------------------
profile_base = os.path.expanduser("~/.thunderbird/default")

if not os.path.exists(os.path.join(profile_base, "prefs.js")):
    raise FileNotFoundError(f"Critical: Could not find prefs.js in {profile_base}")

print(f"Targeting active profile: {profile_base}")

MARKER_FILE = os.path.join(profile_base, ".tbkeys_configured")
if os.path.exists(MARKER_FILE):
    print("Skipped: tbkeys already configured.")
    sys.exit(0)

try:
    result = subprocess.check_output(["pgrep", "-a", "-i", "betterbird"], text=True)
    if "betterbird" in result.lower():
        print("Error: Betterbird is currently running. Aborting.")
        sys.exit(1)
except subprocess.CalledProcessError:
    pass

for lock in ["lock", "parent.lock", ".parentlock"]:
    lock_path = os.path.join(profile_base, lock)
    if os.path.islink(lock_path) or os.path.exists(lock_path):
        try: os.remove(lock_path)
        except OSError: pass

#----------------------------------------
# the trojan horse wrapper
#----------------------------------------
wrapper_path = os.path.join(profile_base, "bb_wrapper.sh")
wrapper_script = f"""#!/bin/bash
for arg in "$@"; do
    if [ "$arg" = "-v" ] || [ "$arg" = "-V" ] || [ "$arg" = "--version" ]; then
        echo "Mozilla Firefox 115.0"
        exit 0
    fi
done
exec "{BB_BINARY_PATH}" -remote-allow-system-access "$@"
"""
with open(wrapper_path, "w") as f:
    f.write(wrapper_script)
os.chmod(wrapper_path, 0o755)

#----------------------------------------
# browser configuration & driver init
#----------------------------------------
options = Options()
options.binary_location = wrapper_path
options.add_argument("-profile")
options.add_argument(profile_base)

print("Initializing system GeckoDriver for Betterbird...")
service = Service("/usr/bin/geckodriver")
driver = webdriver.Firefox(service=service, options=options)
driver.command_executor._commands["SET_CONTEXT"] = ("POST", "/session/$sessionId/moz/context")

#----------------------------------------
# automation execution
#----------------------------------------
try:
    print("Waiting 5 seconds for Betterbird UI to fully render...")
    time.sleep(5)

    # start in God Mode and stay there forever
    print("Switching Geckodriver into 'Chrome Context' (God Mode)...")
    driver.execute("SET_CONTEXT", {"context": "chrome"})
    driver.switch_to.window(driver.window_handles[0])

    # open add-ons manager natively
    print("Opening the native Add-ons Manager...")
    driver.execute_script("openAddonsMgr();")
    time.sleep(3)

    # click the gear icon natively
    print("Locating tbkeys and clicking the Gear/Preferences icon...")
    driver.execute_script("""
        let tabInfo = document.getElementById('tabmail').currentTabInfo;
        let doc = (tabInfo.browser || tabInfo.panel.querySelector('browser')).contentDocument;
        let card = doc.querySelector('addon-card[addon-id="tbkeys@addons.thunderbird.net"]');
        if (card) {
            let prefBtn = card.querySelector('[action="preferences"]');
            if (prefBtn) {
                prefBtn.click();
            } else {
                card.click();
                setTimeout(() => {
                    let pb = card.querySelector('[action="preferences"]');
                    if (pb) pb.click();
                }, 500);
            }
        }
    """)

    # give fission a moment to spin up the out-of-process extension tab
    print("Waiting for the Fission extension process to spawn...")
    time.sleep(4)

    # ---------------------------------------------------------
    # injecting the tbkeys configuration via Mozilla ipc
    # ---------------------------------------------------------
    print("Loading configuration from tbkeys.json...")
    with open(CONFIG_FILE_PATH, "r", encoding="utf-8") as f:
        tbkeys_config = f.read()

    # base64 encoding bridges the process gap safely
    payload_b64 = base64.b64encode(tbkeys_config.encode('utf-8')).decode('utf-8')

    print("Firing payload across the OS Process Boundary via IPC...")
    driver.set_script_timeout(15)

    # notice the double curly braces {{ }} - we must escape them for Python f-strings!
    result = driver.execute_async_script(f"""
        let callback = arguments[0];

        try {{
            // Find the Fission frame you discovered
            let tabInfo = document.getElementById('tabmail').currentTabInfo;
            let tabDoc = (tabInfo.browser || tabInfo.panel.querySelector('browser')).contentDocument;
            let opts = tabDoc.querySelector('addon-options');
            let browser = (opts && opts.shadowRoot) ? opts.shadowRoot.getElementById('addon-inline-options') : tabDoc.getElementById('addon-inline-options');

            if (!browser) {{
                callback("error: addon-inline-options frame not found in DOM");
                return;
            }}

            if (!browser.messageManager) {{
                callback("error: messageManager not available on browser element");
                return;
            }}

            // Add an IPC Listener to hear back from the isolated process
            let listener = function(msg) {{
                browser.messageManager.removeMessageListener("tbkeys:done", listener);
                callback(msg.data.status);
            }};
            browser.messageManager.addMessageListener("tbkeys:done", listener);

            // The Javascript payload to run INSIDE the Fission extension process
            let frameScript = `
                try {{
                    let attempt = 0;
                    let interval = content.setInterval(() => {{
                        let mk = content.document.getElementById('mainkeys');

                        // Wait until the extension UI is fully rendered
                        if (mk) {{
                            content.clearInterval(interval);

                            // Decode our base64 payload natively
                            let jsonText = decodeURIComponent(escape(content.atob("{payload_b64}")));

                            // Inject and trigger save!
                            mk.value = jsonText;
                            mk.dispatchEvent(new content.Event('input', {{ bubbles: true }}));
                            mk.dispatchEvent(new content.Event('change', {{ bubbles: true }}));

                            // -----> THE FIX: Target the button inside the form <-----
                            let saveBtn = content.document.querySelector('form#save button');
                            if (saveBtn) {{
                                saveBtn.click();
                            }} else {{
                                // Fallback: try to submit the form directly
                                let saveForm = content.document.getElementById('save');
                                if (saveForm) saveForm.submit();
                            }}

                            // Shoot a success message back across the Fission gap!
                            sendAsyncMessage("tbkeys:done", {{status: "success"}});

                        }} else if (attempt > 20) {{
                            content.clearInterval(interval);
                            sendAsyncMessage("tbkeys:done", {{status: "timeout_mainkeys_not_found"}});
                        }}
                        attempt++;
                    }}, 500);
                }} catch(e) {{
                    sendAsyncMessage("tbkeys:done", {{status: "error_" + e.toString()}});
                }}
            `;

            // Fire the script into the frame!
            let url = "data:application/javascript;charset=utf-8," + encodeURIComponent(frameScript);
            browser.messageManager.loadFrameScript(url, true);

        }} catch(err) {{
            callback("error: " + err.toString());
        }}
    """)

    if result == "success":
        print("SUCCESS: Configuration injected and saved seamlessly!")
    else:
        print(f"FAILED: IPC script returned -> {result}")
        sys.exit(1)

    # ---------------------------------------------------------

    # clean up: close the add-ons tab natively
    print("Cleaning up by closing the Add-ons tab...")
    driver.execute_script("document.getElementById('tabmail').closeTab(document.getElementById('tabmail').currentTabInfo);")

    with open(MARKER_FILE, 'w') as f:
        f.write(f"Configured via Ansible/Script on {time.ctime()}\n")

    print("Full configuration complete. Betterbird is ready.")
    time.sleep(2)

finally:
    driver.quit()
    if os.path.exists(wrapper_path):
        try: os.remove(wrapper_path)
        except OSError: pass
