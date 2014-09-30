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

# Configure rsyslog on the orchestrator

# This will provide promises to add the backports repos to Debian Lenny:
#       - in sources.list
#       - default apt_preferences to upgrade packages installed from backports
#       - a package_method to install packages from backports via cfengine

bundle agent setup_debian_backports
{
  vars:
      "apt_source_line"       slist => { "deb http://backports.debian.org/debian-backports lenny-backports" };
      "apt_components"        slist => { "main" };

  files:

    debian_5::

      "/etc/apt/sources.list"
        comment => "Include extra apt repos",
        edit_line => append_if_no_lines("${apt_source_line} ${apt_components}"),
        edit_defaults => noempty_backup,
        classes => if_repaired("apt_sources_updated");

      "/etc/apt/preferences"
        comment => "Set automatic upgrades for packages installed from backports (recommended setting from backports.debian.org)",
        create => "true",
        edit_line => append_if_no_lines("Package: *${const.n}Pin: release a=lenny-backports${const.n}Pin-Priority: 200"),
        edit_defaults => noempty_backup,
        classes => if_repaired("apt_preferences_repaired");

  commands:
    apt_sources_updated::
      "/usr/bin/aptitude"
        args => "update";

  reports:
    apt_sources_updated::
      "apt's sources.list was edited, and an aptitude update will now run";

    apt_preferences_repaired::
      "apt's /etc/apt/preferences file was changed";

}


bundle agent install_rsyslogd {
  files:
    policy_server::
      "/etc/rsyslog.d/rudder.conf"
        create    => "true",
        edit_defaults => empty_backup,
        edit_line => expand_template("${sys.workdir}/inputs/distributePolicy/rsyslog.conf/rudder.conf"),
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

    policy_server.debian_5.!SuSE::
      "rsyslog"
        package_policy  => "add",
        package_method  => debian_backports,
        classes => cf2_if_else("rsyslog_installed", "cant_install_rsyslog"),
        comment => "Installing rsyslog using apt backports";

      "rsyslog-pgsql"
        package_policy  => "add",
        package_method  => debian_backports,
        classes => cf2_if_else("rsyslog_pgsql_installed", "cant_install_rsyslog_pgsql"),
        comment => "Installing rsyslog_pgsql using apt backports";

    policy_server.!debian_5.!SuSE.!redhat::
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

    policy_server.!debian_5.!SuSE.redhat::
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

# Package method to install packages from debian-backports
body package_method debian_backports
{

    debian::
        package_changes => "bulk";
        package_list_command => "/usr/bin/dpkg -l";
        package_list_name_regex    => "ii\s+([^\s]+).*";
        package_list_version_regex => "ii\s+[^\s]+\s+([^\s]+).*";
        package_installed_regex => ".*"; # all reported are installed
        package_name_convention => "${name}";
        package_list_update_ifelapsed => "240";    # 4 hours

    debian.have_aptitude::
        package_add_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o Aptitude::Delete-Unused=false -t lenny-backports --assume-yes install";
        package_list_update_command => "/usr/bin/aptitude update";
        package_delete_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o Aptitude::Delete-Unused=false --assume-yes -q remove";
        package_update_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o Aptitude::Delete-Unused=false --assume-yes install";
        package_verify_command => "/usr/bin/aptitude show";
        package_noverify_regex => "(State: not installed|E: Unable to locate package .*)";

    debian.!have_aptitude::
        package_add_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false --yes -t lenny-backports install";
        package_list_update_command => "/usr/bin/apt-get update";
        package_delete_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false --yes -q remove";
        package_update_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false --yes install";
        package_verify_command => "/usr/bin/dpkg -s";
        package_noverify_returncode => "1";

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

