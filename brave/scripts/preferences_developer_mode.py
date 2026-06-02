#!/usr/bin/env python3

import os
import sys
import glob
import json

# path for the Preferences file
paths = glob.glob(os.path.expanduser('~/.config/BraveSoftware/*/Default/Preferences'))

# exit if the file does not exist
if not paths:
    print("ERROR: Preferences file not found! Brave did not generate the profile in time.")
    sys.exit(1)

# track changes for idempotence
made_changes = False

# if it does, enable developer mode
for p in paths:
    with open(p, 'r') as f:
        d = json.load(f)

    # check the current state
    extensions = d.get('extensions', {})
    ui = extensions.get('ui', {})
    is_dev_mode = ui.get('developer_mode', False)

    # idempotency check
    if is_dev_mode is True:
        continue

    # enable Developer Mode
    d.setdefault('extensions', {}).setdefault('ui', {})['developer_mode'] = True

    with open(p, 'w') as f:
        json.dump(d, f)

    made_changes = True

# output if changes were made
if made_changes:
    print('Success: Developer mode enabled!')
else:
    print('Skipped: Developer mode already enabled.')
