#!/bin/bash

# input info
USERNAME=<USER>
HOST=<VPN-DOMAIN>
PASSWD=$(gpg --decrypt ~/.config/scripts/openconnect/<ENCRYPTED-FILE>.gpg 2>/dev/null)
TOKEN=$(stoken tokencode)
PID_FILE='/tmp/vpn_samsung_pid.tmp'

# create tun device
sudo ip tuntap add vpn-samsung mode tun user rafael

# connect to VPN
echo $$ > $PID_FILE; exec sudo openconnect $HOST \
    --interface=vpn-samsung \
    --script='sudo -E /etc/vpnc/vpnc-script' \
    --form-entry=main:username=$USERNAME \
    --form-entry=main:password=$PASSWD \
    --form-entry=main:secondary_password=$TOKEN

# delete device on exit
del_device(){
    sudo ip link del vpn-samsung
}
trap 'del_device' EXIT
