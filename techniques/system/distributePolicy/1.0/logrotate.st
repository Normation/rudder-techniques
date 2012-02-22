/var/log/rudder/apache2/*.log {
        daily
        missingok
        rotate 30
        compress
        delaycompress
		notifempty
		create 640 root adm
        sharedscripts
        postrotate
			if [ -f "`. /etc/apache2/envvars ; echo ${APACHE_PID_FILE:-/var/run/apache2.pid}`" ]; then
				if [ -x /usr/sbin/invoke-rc.d ]; then
					invoke-rc.d apache2 reload > /dev/null
				else
					/etc/init.d/apache2 reload > /dev/null
				fi
			fi
		endscript
}

/var/log/rudder/ldap/slapd.log {
        daily
        missingok
        rotate 30
        compress
        delaycompress
        notifempty
		create 640 root adm
}

/var/log/rudder/reports/*.log {
        daily
        missingok
        rotate 30
        compress
        delaycompress
        notifempty
		create 640 root adm
}
