#!/bin/sh
rc=0
if [ -f /etc/nsswitch.conf ] ; then
    NSSWPERM="`stat -c '%a' /etc/nsswitch.conf`"
    if [ "$NSSWPERM" == "600" ] ; then
        if [ "$1" != "check" ] ; then
            chmod 644 /etc/nsswitch.conf
            rc=$?
        fi
    else
        [ "$1" == "check" ] && rc=1
    fi
else
    rc=1
fi

exit $rc
