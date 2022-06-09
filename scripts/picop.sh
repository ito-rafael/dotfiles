#!/usr/bin/env bash
wmctrl -l | awk '{print $1}' | xargs -i picom-trans -w {} $1
