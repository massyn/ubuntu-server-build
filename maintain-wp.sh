#!/bin/bash

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

# == do we need to install it?
if [[ ! -f /usr/local/bin/wp ]]; then
        curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
        chmod +x /usr/local/bin/wp
fi

for dir in $wwwroot/*
do
    dir=${dir%*/}

    wpconfig=$wwwroot/${dir##*/}/www/
    echo Checking for Wordpress in ${dir##*/}
    if [[ -f $wpconfig/wp-config.php ]]; then
            echo " == ** FOUND IT **"
            wp --path=$wpconfig core update --allow-root
            wp --path=$wpconfig plugin update --all --allow-root
            wp --path=$wpconfig theme update --all --allow-root
    fi
done
