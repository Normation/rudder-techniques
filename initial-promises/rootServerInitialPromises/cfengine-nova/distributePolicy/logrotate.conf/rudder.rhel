# Pre-2.8 rotation for Apache
# Before the unification of the apache log directories (http://www.rudder-project.org/redmine/issues/4010)
# we used this directory to store apache logs.
/var/log/rudder/httpd/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root root
        delaycompress
        sharedscripts
        postrotate
          /etc/init.d/httpd reload > /dev/null
        endscript
}

/var/log/rudder/apache2/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root root
        delaycompress
        sharedscripts
        postrotate
          /etc/init.d/httpd reload > /dev/null
        endscript
}

/var/log/rudder/ldap/slapd.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root root
        delaycompress
        postrotate
          /etc/init.d/rsyslog reload > /dev/null
        endscript
}

/var/log/rudder/reports/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create 640 root root
        delaycompress
        sharedscripts
        postrotate
          /etc/init.d/rsyslog reload > /dev/null
        endscript
}

