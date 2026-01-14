#!/usr/bin/env bash

# display LightDM only in central monitor
/etc/lightdm/lightdm-outputs.sh &

# launch lan-mouse (software KVM) as lightdm user
/etc/lightdm/lightdm-lan-mouse.sh &
