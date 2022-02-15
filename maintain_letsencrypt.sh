#!/bin/bash

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

if [[ -f /usr/bin/letsencrypt ]]; then
        /usr/sbin/service apache2 stop
        /usr/bin/letsencrypt renew
        /usr/sbin/service apache2 start
fi
