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

    any::
      "syslog_user"
        string => "root",
        policy => "overridable";

      "syslog_group"
        string => "root",
        policy => "overridable";

      "syslog_file_mode"
        string => "640",
        policy => "overridable";

      "syslog_daemon"
        string => "rsyslog",
        policy => "overridable";

      "httpd_daemon"
        string => "apache2",
        policy => "overridable";

    ubuntu::
      "syslog_user"   string => "syslog";

    redhat::
      "httpd_daemon"  string => "httpd";

    SuSE::
      "syslog_daemon" string => "syslog";

  files:

    any::
      "/etc/logrotate.d/rudder"
        delete  => tidy,
        classes => classes_generic("rudder_logrotate_legacy_removed"),
        comment => "Remove legacy logrotate files";

    linux::
      "/etc/logrotate.d/rudder-server-root"
        create        => "true",
        edit_defaults => empty,
        edit_line     => expand_template("${sys.workdir}/inputs/distributePolicy/logrotate.d/rudder-server-root"),
        classes       => kept_if_else("rudder_logrotate_conf_ok", "rudder_logrotate_conf_copied", "cannot_copy_rudder_logrotate_conf"),
        comment       => "Copying the logrotate configuration for Linux systems";

  reports:

    cfengine::

      "@@DistributePolicy@@log_info@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#A legacy logrotate configuration has been found and removed"
        ifvarclass => "rudder_logrotate_legacy_removed_repaired";

      "@@DistributePolicy@@log_warn@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#A legacy logrotate configuration has been found, but failed to be removed"
        ifvarclass => "rudder_logrotate_legacy_removed_not_ok";

      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration is correct"
        ifvarclass => "rudder_logrotate_conf_ok.!rudder_logrotate_conf_copied.!cannot_copy_rudder_logrotate_conf";

      "@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration has been updated"
        ifvarclass => "rudder_logrotate_conf_copied.!cannot_copy_rudder_logrotate_conf";

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#The logrotate configuration could not be updated"
        ifvarclass => "cannot_copy_rudder_logrotate_conf";

    !linux::

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check logrotate configuration@@None@@${g.execRun}##${g.uuid}@#No logrotate configuration available for this system";

}
