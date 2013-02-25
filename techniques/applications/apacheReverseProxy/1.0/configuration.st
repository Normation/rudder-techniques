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

bundle agent rudder_reverse_proxy_apache_configuration(service_name) {

  vars:

    "proxies"                                          string => "&APACHE_REVERSE_PROXY_URL_SRC,APACHE_REVERSE_PROXY_URL_DST,APACHE_REVERSE_PROXY_TIMEOUT:{src, dst, timeout|ProxyPass &src& &dst& connectiontimeout=5 timeout=&timeout&$(const.n)ProxyPassReverse &src& &dst&
}&";
    debian::

      "rudder_reverse_proxy_apache_debian_modules"     string => "proxy proxy_http";
      "rudder_reverse_proxy_apache_binary_name"        string => "/usr/sbin/apache2";

    SuSE::

      "rudder_reverse_proxy_apache_binary_name"        string => "/usr/sbin/httpd2-(prefork|worker)";

    redhat::

      "reverse_proxy_configuration_file"               string => "/etc/httpd/conf.d/rudder-reverse-proxy.conf";
      "rudder_reverse_proxy_apache_binary_name"        string => "/usr/sbin/httpd";
      "rudder_reverse_proxy_apache_restart_command"    string => "/etc/init.d/httpd restart";

    !redhat::

      "reverse_proxy_configuration_file"               string => "/etc/apache2/conf.d/rudder-reverse-proxy.conf";
      "rudder_reverse_proxy_apache_restart_command"    string => "/etc/init.d/apache2 restart";

  classes:

    # Adjust SELinux ?
    "rudder_reverse_proxy_apache_selinux_adjust"       expression => strcmp("&APACHE_REVERSE_PROXY_ADJUST_SELINUX&","true");

    # Are the SELinux utilities installed ?
    "rudder_reverse_proxy_apache_selinux_presence"     expression => fileexists("/usr/sbin/getsebool");

    # What is the current SELinux http proxying policy ?
    "rudder_reverse_proxy_apache_selinux_proxy_policy" expression => returnszero("/usr/sbin/getsebool httpd_can_network_relay | grep -q on", "useshell");

  processes:
	
      "${rudder_reverse_proxy_apache_binary_name}"
        restart_class => "rudder_reverse_proxy_apache_process_down",
        comment       => "Ensuring apache is up";

  commands:

    debian::
      "/usr/sbin/a2enmod"
        args    => "$(rudder_reverse_proxy_apache_debian_modules)",
        classes => rudder_common_classes("rudder_reverse_proxy_apache_modules"),
        comment => "Enable Apache modules on Debian";

    rudder_reverse_proxy_apache_selinux_adjust.!rudder_reverse_proxy_apache_selinux_proxy_policy::
      "/usr/sbin/setsebool"
        args    => "httpd_can_network_relay on",
        classes => rudder_common_classes("rudder_reverse_proxy_apache_selinux"),
        comment => "Enable SELinux Apache entry to let Apache proxy entries";

    (rudder_reverse_proxy_apache_process_down|reverse_proxy_file_edited)::
      "/etc/init.d/${rudder_reverse_proxy_apache_binary_name}"
        args    => "restart",
        classes => cf2_if_else("rudder_reverse_proxy_apache_restarted", "rudder_reverse_proxy_apache_restart_error"),
        comment => "restarting apache";

  files:

      "$(reverse_proxy_configuration_file)"
        create        => "true",
        edit_defaults => empty,
        edit_line     => insert_proxy_entries("$(proxies)"),
        classes       => rudder_common_classes("rudder_reverse_proxy_apache_configuration"),
        comment       => "Edit the Apache reverse proxy file";

}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_reverse_proxy_apache_configuration_reporting(service_name)
{
  methods:
    # Modules edition
    "any"
      usebundle  => rudder_common_report("${service_name}", "result_success", "&TRACKINGKEY&", "Apache reverse proxy modules", "None", "No ${service_name} modules edition needed on this OS"),
      ifvarclass => "!debian";
    "any" usebundle => rudder_common_reports_generic("${service_name}", "rudder_reverse_proxy_apache_modules", "&TRACKINGKEY&", "Apache reverse proxy modules", "None", "The ${service_name} modules");

    # SELinux edition
    "any"
      usebundle  => rudder_common_report("${service_name}", "result_success", "&TRACKINGKEY&", "Apache reverse proxy SELinux configuration", "None", "No ${service_name} SELinux modification needed"),
      ifvarclass => "!rudder_reverse_proxy_apache_selinux_adjust|rudder_reverse_proxy_apache_selinux_proxy_policy";
    "any" usebundle => rudder_common_reports_generic("${service_name}", "rudder_reverse_proxy_apache_selinux", "&TRACKINGKEY&", "Apache reverse proxy SELinux configuration", "None", "The ${service_name} SELinux configuration");

    # Apache configuration
    "any" usebundle => rudder_common_reports_generic("${service_name}", "rudder_reverse_proxy_apache_configuration", "&TRACKINGKEY&", "Apache reverse proxy settings", "None", "The ${service_name} reverse proxy configuration");

    # Apache restart
    "any"
      usebundle  => rudder_common_report("${service_name}", "log_info", "&TRACKINGKEY&", "Apache reverse proxy modules", "None", "${service_name} has been restarted"),
      ifvarclass => "rudder_reverse_proxy_apache_restarted";
    "any"
      usebundle  => rudder_common_report("${service_name}", "result_error", "&TRACKINGKEY&", "Apache reverse proxy modules", "None", "Unable to restart ${service_name}"),
      ifvarclass => "rudder_reverse_proxy_apache_restart_error";
}
