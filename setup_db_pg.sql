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

# == check if postgresql is installed

dpkg -l postgresql > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
        echo "Installing postgresql..."
        apt-get install postgresql php-pgsql -y

        # == find the pg_hba file
        pghba=$(find /etc/postgresql -name pg_hba.conf |head -1)
        cat $pghba | grep -qe "^\s*local\s*all\s*all\s*md5"
        if [[ $? -ne 0 ]]; then
                echo Updating config file $pghba
                echo local all all md5 >> $pghba
        fi
        systemctl stop postgresql
        systemctl start postgresql
        systemctl enable postgresql
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

        sudo -u postgres createuser $db
        sudo -u postgres createdb $db
        sudo -u postgres psql -c "alter user $db with encrypted password '$passdb';"

        echo "Database name : $db"
        echo "Username      : $user"
        echo "Password      : $passdb"

fi
