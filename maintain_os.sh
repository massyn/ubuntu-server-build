#!/bin/sh

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

apt-get update
apt-get upgrade -y
apt-get autoremove
reboot
