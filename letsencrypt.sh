#!/bin/bash

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

site=$1

# == install lets encrypt if it's not yet installed
dpkg -l certbot > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo Installing certbot...
	apt-get install certbot -y
fi

if [[ $site != '' ]]; then
        echo "Site - $site"

        service apache2 stop

        /usr/bin/certbot certonly --standalone -d $site --email $admin_email --renew-by-default

        service apache2 start
else
        echo "No site specified..."
fi

