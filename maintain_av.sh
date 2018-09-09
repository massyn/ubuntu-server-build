#!/bin/bash

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == check if clamav is installed
dpkg -l clamav > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
        echo "Installing clamav..."
        apt-get install clamav -y
fi

# == update the AV database
/usr/bin/freshclam

# == run the AV scan
/usr/bin/clamscan -o -r -i /
