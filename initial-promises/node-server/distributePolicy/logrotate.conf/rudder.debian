/var/log/rudder/apache2/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root adm
        delaycompress
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
        notifempty
        create 640 root adm
        delaycompress
        postrotate
        if [ -x /usr/sbin/invoke-rc.d ]; then
          invoke-rc.d rsyslog rotate > /dev/null
        else
          /etc/init.d/rsyslog rotate > /dev/null
        fi
        endscript
}

/var/log/rudder/reports/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root adm
        delaycompress
        sharedscripts
        postrotate
        if [ -x /usr/sbin/invoke-rc.d ]; then
          invoke-rc.d rsyslog rotate > /dev/null
        else
          /etc/init.d/rsyslog rotate > /dev/null
        fi
        endscript
}

