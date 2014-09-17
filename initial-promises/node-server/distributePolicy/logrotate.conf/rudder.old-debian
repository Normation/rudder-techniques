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
        postrotate
        if [ -x /usr/sbin/invoke-rc.d ]; then
          invoke-rc.d rsyslog reload > /dev/null
        else
          /etc/init.d/rsyslog reload > /dev/null
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
          invoke-rc.d rsyslog reload > /dev/null
        else
          /etc/init.d/rsyslog reload > /dev/null
        fi
        endscript
}

/var/log/rudder/core/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root adm
}

/var/log/rudder/compliance/non-compliant-reports.log {
        daily
        missingok
        rotate 365
        compress
        notifempty
        create 640 root adm
}
