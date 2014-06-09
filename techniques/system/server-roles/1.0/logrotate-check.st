#####################################################################################
# Copyright 2011 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

bundle agent root_logrotate_check
{
  vars:

      "syslog_user"
        string => "root",
        policy => "overridable";

      "syslog_group"
        string => "root",
        policy => "overridable";

      "syslog_file_mode"
        string => "640",
        policy => "overridable";

      "service_restart_utility"
        string => "/sbin/service",
        policy => "overridable";

      "apache_service_name"
        string => "apache2",
        policy => "overridable";

      "syslog_service_name"
        string => "rsyslog",
        policy => "overridable";

    debian|ubuntu::

      "service_restart_utility" string => "/usr/sbin/service";

    ubuntu::
      "syslog_user"             string => "syslog";

    debian::
      "syslog_group"            string => "adm";

    redhat::
      "apache_service_name"     string => "httpd";

    SuSE::
      "syslog_service_name"     string => "syslog";

  files:

      "/etc/logrotate.d/rudder"
        create        => "true",
        edit_defaults => empty_backup,
        edit_template => "${sys.workdir}/inputs/server-roles/logrotate.conf/rudder",
        classes       => kept_if_else("rudder_logrotate_conf_ok", "rudder_logrotate_conf_copied", "cannot_copy_rudder_logrotate_conf"),
        comment       => "Copying the Rudder logrotate configuration";

  reports:

    rudder_logrotate_conf_ok.!rudder_logrotate_conf_copied.!cannot_copy_rudder_logrotate_conf::
      "@@server-roles@@result_success@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration is correct";

    rudder_logrotate_conf_copied.!cannot_copy_rudder_logrotate_conf::
      "@@server-roles@@result_repaired@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration has been updated";

    cannot_copy_rudder_logrotate_conf::
      "@@server-roles@@result_error@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration could not be updated";

}
