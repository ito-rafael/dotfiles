PID_FILE='/tmp/vpn_lbic_pid.tmp'
echo $$ > $PID_FILE; exec sudo openvpn /etc/openvpn/client/vpn-lbic.conf
