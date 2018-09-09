#!/bin/bash

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        You need to run config.sh first
fi
. /etc/server-build.sh

db=$1

# == we must run as root

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == check if mysql is installed

dpkg -l mysql-server > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
        echo "Installing mysql..."
	apt-get install mysql-server -y
        systemctl start mysql
        systemctl enable mysql
        mysql_secure_installation
fi

if [[ ! -z $db ]]; then
        echo "Create a new database - $db"
        echo "create database $db;" | mysql
        if [[ $? -ne 0 ]]; then
                exit 1
        fi

        # == generate a random password
        passdb=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1)

        user=$db        # set the user the same as the db name

        echo "grant usage on *.* to $user@localhost identified by '$passdb'" | mysql
        echo "grant all privileges on $db.* to $user@localhost" | mysql

        echo "Database name : $db"
        echo "Username      : $user"
        echo "Password      : $passdb"

fi
