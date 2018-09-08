#!/bin/sh

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

site=$1

# == install git if its not yet installed
dpkg -l git > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
        echo Installing Apache...
        apt-get update
	apt-get install git -y
fi

# == install lets encrypt if it's not yet installed
if [[ ! -d /usr/local/letsencrypt ]]; then
        cd /usr/local/
        git clone https://github.com/letsencrypt/letsencrypt
fi

if [[ $site != '' ]]; then
        echo "Site - $site"

        service apache2 stop

        /usr/local/letsencrypt/letsencrypt-auto certonly --standalone -d $site --email $admin_email --renew-by-default

        service apache2 start
else
        echo "No site specified..."
fi

