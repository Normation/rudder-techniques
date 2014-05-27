# This file contains the necessary logrotate entries relative for every installed
# Rudder component.
#
# It will automatically be updated by Rudder itself if a new component to be managed
# is added to the machine.

[%CFEngine package_check_installed_rudder_webapp_ok:: %]
/var/log/rudder/compliance/non-compliant-reports.log {
        daily
        missingok
        rotate 365
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
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

[%CFEngine package_check_installed_rudder_server_root_ok|(policy_server.!root_server):: %]
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
          ${root_logrotate_check.service_restart_utility} ${root_logrotate_check.apache_service_name} reload > /dev/null
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
          ${root_logrotate_check.service_restart_utility} ${root_logrotate_check.syslog_service_name} reload > /dev/null
        endscript
}

[%CFEngine package_check_installed_rudder_inventory_ldap_ok:: %]
/var/log/rudder/ldap/slapd.log {
        daily
        missingok
        rotate 30
        compress
        notifempty
        create ${root_logrotate_check.syslog_file_mode} ${root_logrotate_check.syslog_user} ${root_logrotate_check.syslog_group}
        delaycompress
        postrotate
          ${root_logrotate_check.service_restart_utility} ${root_logrotate_check.syslog_service_name} reload > /dev/null
        endscript
}
