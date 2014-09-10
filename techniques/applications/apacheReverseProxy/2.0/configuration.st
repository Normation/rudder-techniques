#####################################################################################
# Copyright 2011-2013 Normation SAS
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

bundle agent rudder_reverse_proxy_apache_configuration(service_name, internal_name, params) {

  vars:

      "rudder_reverse_proxy_apache_proxies"               string => "${${params}[proxies]}";

    debian::

      "rudder_reverse_proxy_apache_debian_modules"      slist  => { "proxy", "proxy_http" };

    SuSE::

      "rudder_reverse_proxy_apache_binary_name"         string => "/usr/sbin/httpd2-(prefork|worker)";

    redhat::

      "reverse_proxy_configuration_file"                string => "/etc/httpd/conf.d/rudder-reverse-proxy.conf";
      "rudder_reverse_proxy_apache_binary_name"         string => "/usr/sbin/httpd";
      "rudder_reverse_proxy_apache_restart_command"     string => "/etc/init.d/httpd";

    !redhat::

      "reverse_proxy_configuration_file"                string => "/etc/apache2/conf.d/rudder-reverse-proxy.conf";
      "rudder_reverse_proxy_apache_restart_command"     string => "/etc/init.d/apache2";

    !SuSE.!redhat::

      "rudder_reverse_proxy_apache_binary_name"         string => "/usr/sbin/apache2";

  classes:

    # Adjust SELinux ?
    "rudder_reverse_proxy_apache_selinux_adjust"        expression => strcmp("${${params}[selinux]}","true");

    # What is the current SELinux http proxying policy ?
    "rudder_reverse_proxy_apache_selinux_proxy_policy"  expression => returnszero("/usr/sbin/getsebool httpd_can_network_relay | grep -q on", "useshell");

    "rudder_reverse_proxy_apache_mod_${rudder_reverse_proxy_apache_debian_modules}_loaded" expression => fileexists("/etc/apache2/mods-enabled/${rudder_reverse_proxy_apache_debian_modules}.load");

  files:

      "${reverse_proxy_configuration_file}"
        create        => "true",
        edit_defaults => empty_backup,
        edit_line     => insert_proxy_entries("${rudder_reverse_proxy_apache_proxies}"),
        classes       => rudder_common_classes("rudder_reverse_proxy_apache_configuration"),
        comment       => "Edit the Apache reverse proxy file";

  # Class visibility forces us to use these bundles here.
  methods:

    # Modules edition
    "any"
      usebundle  => rudder_common_report("${internal_name}", "result_success", "${${params}[tracking_key]}", "Module parameters", "None", "No ${service_name} modules edition needed"),
      ifvarclass => "!debian|(rudder_reverse_proxy_apache_mod_proxy_loaded.rudder_reverse_proxy_apache_mod_proxy_http_loaded)";

    # SELinux edition
    "any"
      usebundle  => rudder_common_report("${internal_name}", "result_success", "${${params}[tracking_key]}", "SELinux parameters", "None", "No ${service_name} SELinux modification needed"),
      ifvarclass => "!rudder_reverse_proxy_apache_selinux_adjust|rudder_reverse_proxy_apache_selinux_proxy_policy";

    # Apache restart/reload
    "any"
      usebundle  => rudder_common_report("${internal_name}", "log_info", "${${params}[tracking_key]}", "Daemon status", "None", "${service_name} has been restarted or reloaded"),
      ifvarclass => "rudder_reverse_proxy_apache_restart_repaired|rudder_reverse_proxy_apache_reload_repaired";
    "any"
      usebundle  => rudder_common_report("${internal_name}", "result_error", "${${params}[tracking_key]}", "Daemon status", "None", "Unable to restart or reload ${service_name}"),
      ifvarclass => "rudder_reverse_proxy_apache_restart_error|rudder_reverse_proxy_apache_reload_error";
  processes:
	
      "${rudder_reverse_proxy_apache_binary_name}"
        restart_class => "rudder_reverse_proxy_apache_process_down",
        comment       => "Ensuring apache is up";

  commands:

    debian::
      "/usr/sbin/a2enmod ${rudder_reverse_proxy_apache_debian_modules}"
        classes    => rudder_common_classes("rudder_reverse_proxy_apache_modules"),
        ifvarclass => "!rudder_reverse_proxy_apache_mod_${rudder_reverse_proxy_apache_debian_modules}_loaded",
        comment    => "Enable Apache modules on Debian";

    rudder_reverse_proxy_apache_selinux_adjust.!rudder_reverse_proxy_apache_selinux_proxy_policy::
      "/usr/sbin/setsebool httpd_can_network_relay on"
        classes => rudder_common_classes("rudder_reverse_proxy_apache_selinux"),
        comment => "Enable SELinux Apache entry to let Apache proxy entries";

    rudder_reverse_proxy_apache_configuration_repaired::
      "${rudder_reverse_proxy_apache_restart_command} reload"
        classes => rudder_common_classes("rudder_reverse_proxy_apache_reload"),
        comment => "reloading apache";

    (rudder_reverse_proxy_apache_process_down|rudder_reverse_proxy_apache_modules_repaired)::
      "${rudder_reverse_proxy_apache_restart_command} restart"
        classes => rudder_common_classes("rudder_reverse_proxy_apache_restart"),
        comment => "restarting apache";

}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_reverse_proxy_apache_configuration_reporting(service_name, internal_name, params)
{
  methods:
    # Modules edition
    "any" usebundle => rudder_common_reports_generic("${internal_name}", "rudder_reverse_proxy_apache_modules", "${${params}[tracking_key]}", "Module parameters", "None", "The ${service_name} modules");

    # SELinux edition
    "any" usebundle => rudder_common_reports_generic("${internal_name}", "rudder_reverse_proxy_apache_selinux", "${${params}[tracking_key]}", "SELinux parameters", "None", "The ${service_name} SELinux configuration");

    # Apache configuration
    "any" usebundle => rudder_common_reports_generic("${internal_name}", "rudder_reverse_proxy_apache_configuration", "${${params}[tracking_key]}", "Reverse proxy parameters", "None", "The ${service_name} reverse proxy configuration");
}
