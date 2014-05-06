/var/log/rudder/apache2/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
        sharedscripts
        postrotate
          /sbin/service ${root_logrotate_check.httpd_daemon} reload > /dev/null
        endscript
}

/var/log/rudder/ldap/slapd.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
        postrotate
          /sbin/service ${root_logrotate_check.syslog_daemon} reload > /dev/null
        endscript
}

/var/log/rudder/reports/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
        sharedscripts
        postrotate
          /sbin/service ${root_logrotate_check.syslog_daemon} reload > /dev/null
        endscript
}

/var/log/rudder/core/*.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
}

/var/log/rudder/compliance/non-compliant-reports.log {
        daily
        missingok
        rotate 365
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
}
