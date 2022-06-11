# shebang not used since the script is called directly from /bin/bash

# restart udevmon in background, so interception-tools can grab the events of both devices
#   - keyboard: MX Keys
#   - mouse: MX Master 3
systemctl restart udevmon &
