#!/bin/bash

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

if [[ -f /usr/local/letsencrypt/letsencrypt-auto ]]; then
        /usr/sbin/service apache2 stop
        /usr/local/letsencrypt/letsencrypt-auto renew
        /usr/sbin/service apache2 start
fi
