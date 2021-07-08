####################################################################################
# Copyright 2021 Normation SAS
####################################################################################
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
bundle common rudder_slapd {
  vars:
      "service_name" string => "rudder-slapd";
      "user_name"    string => "rudder-slapd";
      "group_name"   string => "rudder-slapd";

      "config_file"  string => "${g.rudder_base}/etc/openldap/slapd.conf";
}

bundle agent system_rudder_slapd_configuration {
  vars:

      "slapd_password" string => "&RUDDER_LDAP_PASSWORD&";

      "technique_name"   string => "Rudder slapd";
      "trackingkey"      string => "&TRACKINGKEY&";

      "args"              slist => { "${rudder_slapd.config_file}", "640", "root", "${rudder_slapd.group_name}" };
      "report_param"     string => join("_", args);
      "permission_class" string => canonify("permissions_${report_param}");

  classes:
      "rudder_server_system_restart_slapd" expression => "rudder_slapd_ldap_password_repaired|${permission_class}_repaired",
                                                scope => "namespace";
      "rudder_server_system_restart_jetty" expression => "rudder_slapd_ldap_password_repaired|${permission_class}_repaired",
                                                scope => "namespace";

  files:
      "${rudder_slapd.config_file}"
        edit_line => set_rudder_slapd_password("${slapd_password}"),
        classes   => classes_generic("rudder_slapd_ldap_password"),
        comment   => "Verifying the Rudder LDAP file password and user";

  methods:
    # Log rotation
      "any" usebundle => system_slapd_logrotate;
    # Service configuration
      "any" usebundle => _method_reporting_context("Rudder slapd configuration", "Check Rudder ldap permissions");
      "any" usebundle => permissions("${rudder_slapd.config_file}", "640", "root", "${rudder_slapd.group_name}");
      "any" usebundle => _method_reporting_context("Rudder slapd service", "Started");
      "any" usebundle => service_started("${rudder_slapd.service_name}");
      "any" usebundle => _method_reporting_context("Rudder slapd service", "Enabled");
      "any" usebundle => service_enabled("${rudder_slapd.service_name}");

      "any" usebundle => rudder_common_reports_generic("${technique_name}", "rudder_slapd_ldap_password", "${trackingkey}", "Rudder slapd configuration", "Check Rudder ldap password", "OpenLDAP configuration file (rootdn password)");
}


bundle edit_line set_rudder_slapd_password(password) {
  delete_lines:
      "rootpw.*";

  insert_lines:
      "rootpw		${password}" location => after("^rootdn.*");
}
