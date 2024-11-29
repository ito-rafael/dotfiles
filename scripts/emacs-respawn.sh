#!/usr/bin/env sh

# wait until there are 2 Emacs daemons running
COUNT=$(pgrep -f "emacs.* --daemon --with-profile efs" | wc -l)
while [ $COUNT != 2 ]; do
    sleep 0.1
    COUNT=$(pgrep -f "emacs.* --daemon --with-profile efs" | wc -l)
done

# now wait for the first Emacs daemon to be killed
while [ $COUNT != 1 ]; do
    sleep 0.1
    COUNT=$(pgrep -f "emacs.* --daemon --with-profile efs" | wc -l)
done

# lauch emacsclient with the new spawned daemon
emacsclient -c -s efs -a emacs &
