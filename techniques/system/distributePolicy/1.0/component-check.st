#####################################################################################
# Copyright 2014 Normation SAS
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

bundle agent root_component_check
{

  vars:

    !redhat::

      "apache_dist_specific_name"                      string => "apache2";

    redhat::

      "apache_dist_specific_name"                      string => "httpd";

    any::

      "service[rudder_slapd][name]"                    string => "slapd";
      "service[rudder_slapd][binary]"                  string => "/opt/rudder/libexec/slapd";
      "service[rudder_slapd][initscript]"              string => "rudder-slapd";
      "service[rudder_slapd][check_on_relay_server]"   string => "false";

      "service[rudder_jetty][name]"                    string => "jetty";
      "service[rudder_jetty][binary]"                  string => ".*java.*/opt/rudder/jetty7/start.jar";
      "service[rudder_jetty][initscript]"              string => "rudder-jetty";
      "service[rudder_jetty][check_on_relay_server]"   string => "false";

      "service[rudder_reports][name]"                  string => "postgresql";
      "service[rudder_reports][binary]"                string => "postgres: writer process";
      "service[rudder_reports][initscript]"            string => "postgresql";
      "service[rudder_reports][check_on_relay_server]" string => "false";

      "service[apache][name]"                          string => "apache";
      "service[apache][binary]"                        string => "${apache_dist_specific_name}";
      "service[apache][initscript]"                    string => "${apache_dist_specific_name}";
      "service[apache][check_on_relay_server]"         string => "true";

    any::

      "index" slist => getindices("service");

  methods:

      # First, verify if the packages we want to check are installed
      "check_rudder_server_root_presence"        usebundle => package_check_installed("rudder-server-root");
      "check_rudder_inventory_ldap_presence"     usebundle => package_check_installed("rudder-inventory-ldap");
      "check_rudder_jetty_presence"              usebundle => package_check_installed("rudder-jetty");
      "check_rudder_webapp_presence"             usebundle => package_check_installed("rudder-webapp");
      "check_rudder_inventory_endpoint_presence" usebundle => package_check_installed("rudder-inventory-endpoint");
      "check_rudder_reports_presence"            usebundle => package_check_installed("rudder-reports");

      # Make sure every required logrotate entry is present
      "any" usebundle => root_logrotate_check;

    # This is to be done only if the package rudder-server-root is present
    package_check_installed_rudder_server_root_ok::
      "any" usebundle => root_integrity_check;

      # Password management is expected to be done manually in case of a splitted/relayed installation for now.
      "any" usebundle => root_password_check_ldap;
      "any" usebundle => root_password_check_psql;
      "any" usebundle => root_password_check_file;
      "any" usebundle => root_password_restart_jetty;

    # Do this if the package rudder-server-root is installed OR I am a relay server (serving files but NOT a root server)
    # This way, I avoid having trouble with splitted installations who match policy_server.root_server because of rudder-webapp
    # even without having rudder-server-root installed.
    package_check_installed_rudder_server_root_ok|(policy_server.!root_server)::
      "any" usebundle => root_networks_check;
      "any" usebundle => root_password_check_dav;
      "any" usebundle => generic_process_check_process("${service[apache][binary]}", "${service[apache][initscript]}", "${service[apache][name]}", "false", "${service[apache][check_on_relay_server]}");
      "any" usebundle => generic_process_check_bootstart("${service[apache][binary]}", "${service[apache][initscript]}", "${service[apache][name]}");

    package_check_installed_rudder_jetty_ok::
      "any" usebundle => generic_process_check_process("${service[rudder_jetty][binary]}", "${service[rudder_jetty][initscript]}", "${service[rudder_jetty][name]}", "false", "${service[rudder_jetty][check_on_relay_server]}");
      "any" usebundle => generic_process_check_bootstart("${service[rudder_jetty][binary]}", "${service[rudder_jetty][initscript]}", "${service[rudder_jetty][name]}");

    package_check_installed_rudder_webapp_ok::
      "any" usebundle => root_technique_reload;
      "any" usebundle => generic_alive_check("rudder");

    package_check_installed_rudder_inventory_endpoint_ok::
      "any" usebundle => generic_alive_check("endpoint");

    package_check_installed_rudder_inventory_ldap_ok::
      "any" usebundle => generic_process_check_process("${service[rudder_slapd][binary]}", "${service[rudder_slapd][initscript]}", "${service[rudder_slapd][name]}", "false", "${service[rudder_slapd][check_on_relay_server]}");
      "any" usebundle => generic_process_check_bootstart("${service[rudder_slapd][binary]}", "${service[rudder_slapd][initscript]}", "${service[rudder_slapd][name]}");

    package_check_installed_rudder_reports_ok::
      "any" usebundle => root_postgres_check;
      "any" usebundle => generic_process_check_process("${service[rudder_reports][binary]}", "${service[rudder_reports][initscript]}", "${service[rudder_reports][name]}", "false", "${service[rudder_reports][check_on_relay_server]}");
      "any" usebundle => generic_process_check_bootstart("${service[rudder_reports][binary]}", "${service[rudder_reports][initscript]}", "${service[rudder_reports][name]}");

}
