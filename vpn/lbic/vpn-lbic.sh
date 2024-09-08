PID_FILE=$1
echo $$ > $PID_FILE; exec sudo openvpn /etc/openvpn/client/vpn-lbic.conf
