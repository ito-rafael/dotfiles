#!/usr/bin/env python

'''
description:
    extends navigation to previous/next workspaces in i3wm when using more than one output allowing crossing output borders

i3wm config:
  - using "workspace prev" navigates in sorted list of workspaces (consider all workspaces of all outputs)
  - using "workspace prev_on_output" navigates inside an output, but does not allow crossing output borders)
  - using this script ("exec "$SCRIPT_PATH/navigate2ws_next.py --prev"), crossing output borders are allowed
'''

import argparse
import subprocess

# parsing args
parser = argparse.ArgumentParser(description='Move to previous/next workspace in i3wm with more than one screen')
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('--previous', action='store_true', help='move to the previous workspace')
group.add_argument('--next', action='store_true', help='move to the next workspace')
args = parser.parse_args()

# get list of workspaces
cmd = "wmctrl -d | awk '{print $(NF-1)}'"
#cmd = """wmctrl -d | awk '{print $(NF-1)" "$NF}'"""    # full ws name
stdout = subprocess.check_output(cmd, shell=True)
ws = stdout.decode().split('\n')
del ws[-1]

# get position of current 
cmd = "wmctrl -d | awk '{print $2}'"
stdout = subprocess.check_output(cmd, shell=True)
current = stdout.decode().split('\n').index('*')

# calculate workspace to navigate to
if args.previous:
    next_ws = ws[ (current - 1) % len(ws) ]
elif args.next:
    next_ws = ws[ (current + 1) % len(ws) ]
else:
    exit()

# handle edge cases
if ( next_ws == '10' ):
    next_ws = '0'

# navigate to next workspace
cmd = "$HOME/.config/scripts/navigate2ws.sh " + next_ws
subprocess.check_output(cmd, shell=True)
