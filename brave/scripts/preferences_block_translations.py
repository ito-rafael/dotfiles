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

# block translations
for p in paths:
    with open(p, 'r') as f:
        d = json.load(f)

    # get current blocked languages list, or create an empty one
    blocked_langs = d.get('translate_blocked_languages', [])

    # include the base languages plus regional variations
    langs_to_block = ['en', 'en-US', 'en-GB', 'pt', 'pt-BR', 'pt-PT']

    for lang in langs_to_block:
        if lang not in blocked_langs:
            blocked_langs.append(lang)

    # save the updated list back into the JSON dictionary
    d['translate_blocked_languages'] = blocked_langs

    with open(p, 'w') as f:
        json.dump(d, f)

print('Success: Translation blocks for EN and PT applied!')
