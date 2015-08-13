#####################################################################################
# Copyright 2015- Normation SAS
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

#######################################################
#
# restart_services
#
# This bundle restarts all the services in need at the end
# of the agent execution
#
#######################################################

bundle agent restart_services
{
  
  methods:
  
    # (sys)log service

    (!SuSE.!aix.!solaris).syslogd_repaired::

      "restart_syslog" usebundle => service_restart("syslog");

    !SuSE.syslog_ng_repaired::

      "restart_syslog_ng" usebundle => service_restart("syslog-ng");

    !SuSE.(rsyslog_installed|rsyslog_pgsql_installed|rudder_rsyslog_conf_copied|rudder_rsyslog_pgsql|rudder_rsyslog_historical_conf_purged_repaired|rsyslog_repaired|rsyslog_limit_repaired)::

      "restart_rsyslog" usebundle => service_restart("rsyslog");

    SuSE.(rsyslog_installed|rsyslog_pgsql_installed|rudder_rsyslog_conf_copied|rudder_rsyslog_pgsql|rudder_rsyslog_historical_conf_purged_repaired|syslog_ng_repaired|rsyslog_repaired|syslogd_repaired|rsyslog_limit_repaired)::

      "restart_rsyslog" usebundle => service_restart("syslog");
      
    # Final report about (sys)log setting enforcement / restart

    service_restart_rsyslog_repaired|service_restart_syslog_ng_repaired|service_restart_syslog_repaired::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "Logging system has been restarted");

    service_restart_rsyslog_not_ok|service_restart_syslog_ng_not_ok|service_restart_syslog_not_ok::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Could not restart the logging system");

}
