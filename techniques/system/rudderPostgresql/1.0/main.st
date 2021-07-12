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
bundle common rudder_postgresql {
  vars:
    # sles 12, sp1 and sp2 don't have by default a systemd postgresql
    !(sles_12_0|sles_12_1|sles_12_2)::
      "service_name"    string => execresult("${paths.systemctl} --no-ask-password list-unit-files --type service | ${paths.awk} -F'.' '{print $1}' | ${paths.grep} -E \"^postgresql-?[0-9]*$\" | tail -n 1", "useshell");
    sles_12_0|sles_12_1|sles_12_2::
      "service_name"    string => execresult("chkconfig 2>/dev/null | ${paths.awk} '{ print $1 }' | ${paths.grep} 'postgresql' | tail -n 1", "useshell");

    any::
      "no"                 int => getfields("RUDDER_PSQL_PASSWORD:.*","/opt/rudder/etc/rudder-passwords.conf",":","password_getter");
      "postgres_passwd" string => "${password_getter[2]}";

      "db_name"         string => "&RUDDER_REPORTS_DB_NAME&";
      "db_user"         string => "&RUDDER_REPORTS_DB_USER&";
      "user_name"       string => "postgres";
    # Define the where to send the reports messages
    # default is localhost if the rudder_db is unknown
    # or if the role rudder-server-root is installed
      "host"            string => "localhost";
    role_rudder_db_server_defined.!role_rudder_server_root::
      "host"            string => "${rudder_servers_by_role.roles[rudder-db]}";
}

bundle agent system_rudder_postgresql_configuration {
  vars:
    any::
      "trackingkey"     string => "&TRACKINGKEY&";
      "postgres_passwd" string => "${rudder_postgresql.postgres_passwd}";
      "technique_name"  string => "Rudder Postgresql";

  methods:

      # Check that apache is running and enabled
      "any" usebundle => _method_reporting_context("Postgresql service", "Started");
      "any" usebundle => service_started("${rudder_postgresql.service_name}");

      "any" usebundle => _method_reporting_context("Postgresql service", "Enabled");
      "any" usebundle => service_enabled("${rudder_postgresql.service_name}");

      # Check pgpass and db credentials
      "any" usebundle => system_rudder_postgresql("${trackingkey}", "${technique_name}", "${postgres_passwd}");

}
