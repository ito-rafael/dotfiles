#!/usr/bin/env python

import sys
from i3ipc import Connection

def check_direction(direction):
    i3 = Connection()
    tree = i3.get_tree()
    focused = tree.find_focused()

    # we start at the focused window and climb up the family tree
    current = focused

    while current.parent:
        parent = current.parent
        # we only care if the parent manages vertical splits
        # (and isn't a tabbed/stacked container, unless you want to count those)
        if parent.layout == 'splitv':
            index = parent.nodes.index(current)
            #------------------
            # check UP
            if direction == "up":
                # If I am NOT the first child, there is a window above me
                if index > 0:
                    return True
            #------------------
            # check DOWN
            elif direction == "down":
                # If I am NOT the last child, there is a window below me
                if index < len(parent.nodes) - 1:
                    return True
            #------------------
        # if we didn't find a neighbor here, we climb to the grandparent
        current = parent
    # if we reached the root (workspace) without finding a neighbor
    return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py [up|down]")
        sys.exit(1)

    direction = sys.argv[1]
    if check_direction(direction):
        print(f"Yes, window {direction}")
        sys.exit(0)
    else:
        print(f"No window {direction}")
        sys.exit(1)
