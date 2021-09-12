#!/bin/bash

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == setup the config file first, so we know where things go

if [[ ! -f /etc/server-build.sh ]]; then
        bash config.sh
fi
. /etc/server-build.sh

if [[ ! -d $app_path ]]; then
        mkdir $app_path
fi

if [[ ! -d $log_path ]]; then
        mkdir $log_path
        chown 0:0 $log_path
        chmod 600 $log_path
fi

if [[ ! -d $backup_path ]]; then
        mkdir $backup_path
        chown 0:0 $backup_path
        chmod 600 $backup_path
fi

for name in $(echo maintain_wp.sh setup_web.sh letsencrypt.sh config.sh harden_web.sh cronwrapper.sh maintain_os.sh maintain_av.sh setup_db.sh maintain_backup.sh maintain_letsencrypt.sh)
do
        echo $name
        cp $name $app_path
        chmod 750 $app_path/$name
done

apt-get update -y
bash install_crontab.sh

echo "export PATH=\$PATH:$app_path" >> /etc/profile
echo "export PATH=\$PATH:$app_path" >> /etc/bashrc
export PATH=$PATH:$app_path
