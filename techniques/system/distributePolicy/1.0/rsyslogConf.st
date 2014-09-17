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

# Configure rsyslog on the root/relay servers

bundle agent install_rsyslogd {

  vars:

    root_server|role_rudder_relay_top::
      "rsyslog_source_file" string => "rudder-rsyslog-root.conf";

    # Define the where to send the syslog messages
    # default is localhost if the rudder_db is unknown
    # or if the role rudder-server-root is installed

    root_server.(!role_rudder_db_server_defined|role_rudder_server_root)::
      "rudder_postgres_server" string => "localhost";

    (root_server|role_rudder_relay_top).role_rudder_db_server_defined.!role_rudder_server_root::
      "rudder_postgres_server" string => "${rudder_servers_by_role.roles[rudder-db]}";

    policy_server.!(root_server|role_rudder_relay_top)::
      "rsyslog_source_file" string => "rudder-rsyslog-relay.conf";

  files:

    policy_server::

      "/etc/rsyslog.d/rudder.conf"
        create    => "true",
        edit_defaults => empty,
        edit_line => expand_template("${sys.workdir}/inputs/distributePolicy/rsyslog.conf/${rsyslog_source_file}"),
              classes => cf2_if_else("rudder_rsyslog_conf_copied", "cannot_copy_rudder_rsyslog_conf"),
              comment => "Copying rsyslog conf";  

      "/etc/rsyslog.conf"
        edit_line => append_if_no_lines("$IncludeConfig /etc/rsyslog.d/*.conf"),
        edit_defaults => noempty_backup,
        comment => "Add the rsyslog.conf.d include if not already present",
        classes => cf2_if_else("rsyslog_inc_ok" , "rsyslog_inc_failed");

    policy_server.debian::
      "/etc/rsyslog.d/pgsql.conf"
        edit_line => comment_all(),
        edit_defaults => noempty_backup,
        classes => cf2_if_else("rudder_rsyslog_pgsql", "cannot_update_rudder_rsyslog_pgsql"),
              comment => "Removing the logging of all in the database";  

  packages:

    policy_server.!SuSE.!redhat::
      "rsyslog"
        package_policy  => "add",
        package_method  => generic,
        classes => cf2_if_else("rsyslog_installed", "cant_install_rsyslog"),
        comment => "Installing rsyslog using apt backports";

      "rsyslog-pgsql"
        package_policy  => "add",
        package_method  => generic,
        classes => cf2_if_else("rsyslog_pgsql_installed", "cant_install_rsyslog_pgsql"),
        comment => "Installing rsyslog_pgsql using apt backports";

    policy_server.!SuSE.redhat::
      "rsyslog"
        package_policy  => "add",
        package_method  => rudder_yum,
        classes => cf2_if_else("rsyslog_installed", "cant_install_rsyslog"),
        comment => "Installing rsyslog using apt backports";

      "rsyslog-pgsql"
        package_policy  => "add",
        package_method  => rudder_yum,
        classes => cf2_if_else("rsyslog_pgsql_installed", "cant_install_rsyslog_pgsql"),
        comment => "Installing rsyslog_pgsql using apt backports";

  commands:

    policy_server.(rsyslog_installed|rsyslog_pgsql_installed|rudder_rsyslog_conf_copied|rudder_rsyslog_pgsql).!SuSE::
      "/etc/init.d/rsyslog"
        args => "restart",
                                classes => cf2_if_else("rsyslog_restarted", "cant_restart_rsyslog"),
                                comment => "restarting rsyslog";
    policy_server.(rsyslog_installed|rsyslog_pgsql_installed|rudder_rsyslog_conf_copied|rudder_rsyslog_pgsql).SuSE::
      "/etc/init.d/syslog"
        args => "restart",
                                classes => cf2_if_else("rsyslog_restarted", "cant_restart_rsyslog"),
                                comment => "restarting rsyslog";

  reports:
    cant_install_rsyslog|cant_install_rsyslog_pgsql::
      "Fatal : Can't install rsyslog or rsyslog_pgsql on the Rudder root server !";

    cannot_copy_rudder_rsyslog_conf::
      "Fatal : Can't copy the rsyslog configuration !";

    rsyslog_inc_failed::
      "Fatal : Can't enable the rsyslog include directory !";

    cant_restart_rsyslog::
      "Fatal : Can't restart rsyslog !";

    cannot_update_rudder_rsyslog_pgsql::
      "Fatal : Cannot update the pgsql configuration !";

    rsyslog_restarted::
      "Info : Restarted rsyslog";

}

bundle edit_line comment_all()
{
  replace_patterns:
  # comment all lines
      "^[^#](.*)"
        replace_with => comments;
}

body replace_with comments
{
        replace_value => "#${match.1}"; # backreference 0
        occurrences => "all";  # first, last all
}

