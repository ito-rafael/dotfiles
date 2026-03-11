#!/usr/bin/env python

import sys
import argparse
from i3ipc import Connection

def check_direction(direction: str) -> bool:
    # check if Sway/i3 IPC is available
    try:
        i3 = Connection()
    except Exception as e:
        print(f"Error connecting to Sway IPC: {e}", file=sys.stderr)
        return False

    tree = i3.get_tree()
    focused = tree.find_focused()

    # check if a window is actually focused
    if not focused:
        return False

    # we start at the focused window and climb up the family tree
    current = focused

    while current.parent:
        parent = current.parent
        # we only care if the parent manages vertical splits
        # (and isn't a tabbed/stacked container, unless you want to count those)
        if parent.layout == 'splitv':
            # prevent ValueError if "current" is missing from nodes
            if current in parent.nodes:
                index = parent.nodes.index(current)
                #------------------
                # check UP: if window is not the first child, there is another window above
                if direction == "up" and index > 0:
                    return True
                #------------------
                # check DOWN: if window is NOT the last child, there is another window below
                elif direction == "down" and index < len(parent.nodes) - 1:
                    return True
                #------------------
        # if we didn't find a neighbor here, we climb to the grandparent
        current = parent
    # if we reached the root (workspace) without finding a neighbor
    return False


def main():
    # use argparse to strictly validate input: "up" or "down"
    parser = argparse.ArgumentParser(description="Check if a window exists above or below the focused window in Sway.")
    parser.add_argument("direction", choices=["up", "down"], help="Direction to check (strictly 'up' or 'down').")
    args = parser.parse_args()

    if check_direction(args.direction):
        sys.exit(0)  # there's a window
    else:
        sys.exit(1)  # there's no window

if __name__ == "__main__":
    main()
