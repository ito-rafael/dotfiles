#!/bin/sh
# use Solaar to check in which host Logitech MX peripherals are connected to
HOST=$(solaar config "MX Master 3" change-host | grep change-host | awk -F':' '{print $2}')
if [ $HOST = 'catuaba' ]
then
    solaar config 'MX Master 3' change-host 2;
    solaar config 'MX Keys' change-host 2;
elif [ $HOST = 'Y2P-ArchLinux' ]
then
    solaar config 'MX Master 3' change-host 1;
    solaar config 'MX Keys' change-host 1;
fi
