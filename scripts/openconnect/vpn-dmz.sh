#!/bin/bash

# input info
USERNAME=<USER>
HOST=<VPN-DOMAIN>
PASSWD=$(gpg --decrypt ~/.config/scripts/openconnect/<ENCRYPTED-FILE>.gpg 2>/dev/null)
TOKEN=$(stoken tokencode)

# create tun device
sudo ip tuntap add vpn0 mode tun user rafael

# connect to VPN
openconnect $HOST \
    --interface=vpn0 \
    --script='sudo -E /etc/vpnc/vpnc-script' \
    --form-entry=main:username=$USERNAME \
    --form-entry=main:password=$PASSWD \
    --form-entry=main:secondary_password=$TOKEN
