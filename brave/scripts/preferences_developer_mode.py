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

# if it does, enable developer mode
for p in paths:
    with open(p, 'r') as f:
        d = json.load(f)

    # enable Developer Mode
    d.setdefault('extensions', {}).setdefault('ui', {})['developer_mode'] = True

    with open(p, 'w') as f:
        json.dump(d, f)

print('Success: Developer mode enabled!')
