#!/bin/bash

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

site=$1

wwwuser=www-data
wwwgroup=webmasters
#wwwroot=/wwwroot	## getting it from the config file

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == check if the group exists
if [[ -z $(getent group $wwwgroup) ]]; then
        echo "Group $wwwgroup does not exist... Creating"
        groupadd $wwwgroup
       	if [[ ! -z $SUDO_USER ]]; then 
		echo "Adding $SUDO_USER to the group $wwwgroup"
        	usermod -a -G $wwwgroup $SUDO_USER
        	echo "Setting $SUDO_USER GID to the group $wwwgroup"
        	usermod -g webmasters $SUDO_USER
	fi
else
        echo "Group $wwwgroup exists"
fi

# == delete the 000-default.conf file (it messes up what we're trying to do)
if [[ -f /etc/apache2/sites-enabled/000-default.conf ]]; then
	echo "Removing /etc/apache2/sites-enabled/000-default.conf"
	rm /etc/apache2/sites-enabled/000-default.conf
fi

# == create the new default config file
if [[ -f /etc/apache2/sites-enabled/server-build.conf ]]; then
	rm /etc/apache2/sites-enabled/server-build.conf
fi
echo "ServerTokens Prod" >> /etc/apache2/sites-enabled/server-build.conf
echo "ServerSignature Off" >> /etc/apache2/sites-enabled/server-build.conf

# == check if apache is installed... It not, install it
dpkg -l apache2 > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo Installing Apache...
	apt-get update
	apt-get install apache2 -y

	apt-get install libapache2-mod-auth-plain -y
	apt-get install libapache2-mod-fcgid -y
	apt-get install libapache2-mod-perl2 -y
	apt-get install libapache2-mod-php -y

	apt-get install $(apt-cache search php | grep -E "php[0-9].+-mysql" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-cgi" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-common" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-mbstring" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-gd" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-zip" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-curl" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-mcrypt" | awk {'print $1'} | head -1) -y
	apt-get install $(apt-cache search php | grep -E "php[0-9].+-imagick" | awk {'print $1'} | head -1) -y

	a2enmod ssl
        a2enmod rewrite
        a2enmod cgi
        a2enmod cache
        a2enmod headers

	# == install perl modules for perl applications
	apt-get install libcgi-pm-perl -y
fi

if [[ ! -d "$wwwroot" ]]; then
	echo "- Creating directory $wwwroot"
	mkdir "$wwwroot"
	chown -R $wwwuser:$wwwgroup $wwwroot
	chmod -R 750 $wwwroot
fi

if [[ ! -z $site ]]; then
	echo "Configuring $site"

	# == create the directories
	if [[ ! -d "$wwwroot/$site" ]]; then
		echo "- Creating directory $wwwroot/$site"
		mkdir $wwwroot/$site/
		mkdir $wwwroot/$site/logs/
		mkdir $wwwroot/$site/www/

		chown -R $wwwuser:$wwwgroup "$wwwroot/$site"
        	chmod -R 750 "$wwwroot/$site"
	fi

	# == create the config for this site
	config=/etc/apache2/sites-enabled/$site.conf

	echo "<VirtualHost *:80>" > $config
	echo "ServerName $site" >> $config
        echo "ServerAdmin webmaster@localhost" >> $config
        echo "DocumentRoot $wwwroot/$site/www" >> $config
        echo "ErrorLog $wwwroot/$site/logs/error.log" >> $config
        echo "CustomLog $wwwroot/$site/logs/access.log combined" >> $config

	if [[ -f "/etc/letsencrypt/live/$site/fullchain.pem" ]]; then
		echo "RewriteEngine On" >> $config
		echo "RewriteCond \%{HTTPS} !=on" >> $config
		echo "RewriteRule ^/?(.*) https://$site/\$1 [R,L]" >> $config
	else
		echo "<FilesMatch \"\.(?i:gif|jpe?g|png|ico|css|js|swf)\$\">" >> $config
  		echo "<IfModule mod_headers.c>" >> $config
    		echo "Header set Cache-Control \"max-age=86400, public, must-revalidate\"" >> $config
  		echo "</IfModule>" >> $config
		echo "</FilesMatch>" >> $config
	fi
	echo "</VirtualHost>" >> $config

	if [[ -f "/etc/letsencrypt/live/$site/fullchain.pem" ]]; then
		echo " - Configuring SSL..."

		echo "<VirtualHost *:443>" >> $config
                echo "ServerName $site" >> $config
                echo "ServerAdmin webmaster@localhost" >> $config
		echo "DocumentRoot $wwwroot/$site/www" >> $config
        	echo "ErrorLog $wwwroot/$site/logs/error.log" >> $config
        	echo "CustomLog $wwwroot/$site/logs/access.log combined" >> $config
                echo "SSLEngine on" >> $config
                echo "SSLCertificateFile /etc/letsencrypt/live/$site/cert.pem" >> $config
                echo "SSLCertificateKeyFile /etc/letsencrypt/live/$site/privkey.pem" >> $config
                echo "SSLCertificateChainFile /etc/letsencrypt/live/$site/fullchain.pem" >> $config
                echo "SSLProtocol all -SSLv2 -SSLv3" >> $config
                echo "SSLHonorCipherOrder on" >> $config
                echo "SSLCipherSuite \"EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4\"" >> $config

                echo "<FilesMatch \"\.(cgi|shtml|phtml|php|pl)\$\">" >> $config
                echo "SSLOptions +StdEnvVars" >> $config
                echo "</FilesMatch>" >> $config
		echo "<FilesMatch \"\.(?i:gif|jpe?g|png|ico|css|js|swf)\$\">" >> $config
                echo "<IfModule mod_headers.c>" >> $config
                echo "Header set Cache-Control \"max-age=86400, public, must-revalidate\"" >> $config
                echo "</IfModule>" >> $config
                echo "</FilesMatch>" >> $config

        	echo "</VirtualHost>" >> $config
	fi

	echo "<Directory $wwwroot/$site/>" >> $config
        echo "Options +ExecCGI -Indexes -MultiViews +SymLinksIfOwnerMatch" >> $config
        echo "AddHandler cgi-script .pl .cgi" >> $config
        echo "AllowOverride All" >> $config
        echo "Require all granted" >> $config
	echo "</Directory>" >> $config

	# == restart the web server
	echo "Restarting apache..."
	service apache2 restart	
	if [[ $? -eq 0 ]]; then
		echo " - success"
	else
		echo " ** FAILED **"
		systemctl status apache2.service
	fi
fi
