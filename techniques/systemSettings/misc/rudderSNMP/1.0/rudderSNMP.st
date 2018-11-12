#####################################################################################
# Copyright 2018 Normation SAS
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

# @name rudderSNMP
# @description Rudder SNMP Configuration
# @version 1.0

bundle agent rudderSNMP
{
  vars:
    
    debian|ubuntu::
      "package_name" string => "snmpd";

    !(debian|ubuntu)::
      "package_name" string => "net-snmp";
  
    any:: 
      "canon_pkg_name" string => canonify("${package_name}");
      "conf_slist" slist => { "pass 1.3.6.1.4.1.35061.2.3.1 /etc/snmp/scripts/rudder_health.sh", "rocommunity public" };

  methods:
    
      "method_call" usebundle => package_present("${package_name}", "", "", "");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "package_present_${canon_pkg_name}", "&TRACKINGKEY&", "Presence of the SNMP server package", "None", "Presence of the ${package_name} package");
  
      "method_call" usebundle => file_enforce_content("/etc/snmp/snmpd.conf", ${conf_slist}, "false");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "file_ensure_lines_present__etc_snmp_snmpd_conf", "&TRACKINGKEY&", "SNMP configuration file contains required OID and community", "None", "Checking the configuration file for SNMP");
    
      "method_call" usebundle => directory_create("/etc/snmp/scripts");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "directory_create__etc_snmp_scripts", "&TRACKINGKEY&", "Presence of a scripts directory whithin /etc/snmp/", "None", "Directory /etc/snmp/scripts");
     
     "method_call" usebundle => file_copy_from_local_source("${this.promise_dirname}/rudder_health.sh", "/etc/snmp/scripts/rudder_health.sh");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "file_copy_from_local_source__etc_snmp_scripts_rudder_health_sh", "&TRACKINGKEY&","Presence of the rudder agent health evaluation script whithin /etc/snmp/scripts/", "None", "Copy rudder_health.sh");

      "method_call" usebundle => permissions("/etc/snmp/scripts/rudder_health.sh", "755", "root", "root");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "permissions__etc_snmp_scripts_rudder_health_sh", "&TRACKINGKEY&", "Execution permission for the rudder agent health evaluation script", "None", "Check permissions on rudder_health.sh");
    
      "method_call" usebundle => service_ensure_running("snmpd");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "service_ensure_running_snmpd", "&TRACKINGKEY&", "Ensure SNMP service is running", "None", "Checking snmpd service running");

      "method_call" usebundle => service_ensure_started_at_boot("snmpd");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "service_ensure_started_at_boot_snmpd", "&TRACKINGKEY&", "Ensure SNMP service is enabled at boot time", "None", "Checking snmpd service enabled at boot time");
     
    file_ensure_lines_present__etc_snmp_snmpd_conf_repaired::
      "method_call" usebundle => service_restart("snmpd");
      "reporting" usebundle => rudder_common_reports_generic("rudderSNMP", "service_restart_snmpd", "&TRACKINGKEY&", "SNMP service restart", "None", "Restarted SNMP service");

    !file_ensure_lines_present__etc_snmp_snmpd_conf_repaired::
      "reporting" usebundle => rudder_common_report("rudderSNMP", "result_na", "&TRACKINGKEY&", "SNMP service restart", "None", "No need to restart SNMP service");
}
