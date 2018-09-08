#!/bin/sh

function UpdateParameter {
	file=$1
	key=$2
	value=$3

	echo $file - $key $value

	cat $file | grep -v "^$key" > $file.new
	echo $key $value >> $file.new
	mv $file.new $file
}


UpdateParameter /etc/apache2/conf-enabled/security.conf ServerTokens Prod
UpdateParameter /etc/apache2/conf-enabled/security.conf ServerSignature Off
UpdateParameter /etc/apache2/conf-enabled/security.conf "Header always append X-Frame-Options" SAMEORIGIN

UpdateParameter /etc/apache2/conf-enabled/security.conf "Header set X-Content-Type-Options" nosniff
UpdateParameter /etc/apache2/conf-enabled/security.conf "Header set X-XSS-Protection" "\"1; mode=block\""
UpdateParameter /etc/apache2/conf-enabled/security.conf "Header set Strict-Transport-Security" "\"max-age=31536000; includeSubDomains; preload\""
UpdateParameter /etc/apache2/conf-enabled/security.conf "Header set Content-Security-Policy" "\"default-src https: 'unsafe-inline'\""
#UpdateParameter /etc/apache2/conf-enabled/security.conf "Header set add_header Referrer-Policy" "same-origin"

# find the php.ini file
for phpini in $(find / -name php.ini); do
	UpdateParameter $phpini expose_php "= Off"
	UpdateParameter $phpini cgi.force_redirect "= On"
	UpdateParameter $phpini allow_url_fopen "= Off"
	UpdateParameter $phpini allow_url_include "= Off"
	UpdateParameter $phpini sql.safe_mode "= On"
	UpdateParameter $phpini display_errors "= Off"
	UpdateParameter $phpini session.name "= SECURESERVERSESSIONCOOKIE"
	UpdateParameter $phpini session.cookie_lifetime "= 86400"
	UpdateParameter $phpini session.cookie_httponly "= 1"
	UpdateParameter $phpini session.sid_length "= 48"
	UpdateParameter $phpini session.cookie_secure "= On"
done

echo "Restarting apache..."
systemctl restart apache2.service
if [[ $? -eq 0 ]]; then
	echo " - success"
else
	echo " ** FAILED **"
	systemctl status apache2.service
fi
