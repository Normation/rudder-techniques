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

    "proxies"                            string => "&APACHE_REVERSE_PROXY_URL_SRC,APACHE_REVERSE_PROXY_URL_DST,APACHE_REVERSE_PROXY_TIMEOUT:{src, dst, timeout|ProxyPass &src& &dst& connectiontimeout=5 timeout=&timeout&$(const.n)ProxyPassReverse &src& &dst&
}&";
    (debian|SuSE)::

      "reverse_proxy_configuration_file" string => "/etc/apache2/conf.d/rudder-reverse-proxy.conf";
      "apache_binary_name"               string => "apache2";

    debian::

      "debian_modules"                   string => "proxy proxy_http";

    redhat::

      "reverse_proxy_configuration_file" string => "/etc/httpd/conf.d/rudder-reverse-proxy.conf";
      "apache_binary_name"               string => "httpd";

  classes:

    # Adjust SELinux ?
    "apache_selinux_adjust"              expression => strcmp("&APACHE_REVERSE_PROXY_ADJUST_SELINUX&","true");

    SuSE::

      # You can't have both of them, they are mutually exclusive.
      "apache_bin_worker"                expression => fileexists("/usr/sbin/httpd2-worker");
      "apache_bin_prefork"               expression => fileexists("/usr/sbin/httpd2-prefork");

  processes:
	
    (debian|redhat)::
	
      "/usr/sbin/${apache_binary_name}"
      restart_class => "apache_down",
      comment => "Ensuring apache is up on Redhat or Debian machines";

    # Using a variable on this case is counter intuitive, as is forces us to bypass the regular
    # normal ordering model (vars before classes), as it would require that variables are defined
    # conditionnally with classes.
    SuSE::

      "/usr/sbin/httpd2-prefork"
        restart_class => "apache_down",
        ifvarclass    => "apache_bin_prefork",
        comment       => "Ensuring apache is up on SuSE (prefork model)";

      "/usr/sbin/httpd2-worker"
        restart_class => "apache_down",
        ifvarclass    => "apache_bin_worker",
        comment       => "Ensuring apache is up on SuSE (worker model)";

  commands:

    debian::

      "/usr/sbin/a2enmod"
        args    => "$(debian_modules)",
        classes => cf2_if_else("apache_modules_enabled", "apache_modules_not_enabled"),
        comment => "Enable Apache modules on Debian";

    apache_selinux_adjust::

      "/usr/sbin/setsebool"
        args    => "httpd_can_network_relay on",
        classes => cf2_if_else("apache_selinux_adjusted", "apache_selinux_not_adjusted"),
        comment => "Enable SELinux Apache entry to let Apache proxy entries";

    (apache_down|reverse_proxy_file_edited)::
      "/etc/init.d/${apache_binary_name}"
        args    => "restart",
        classes => cf2_if_else("apache_restarted", "cant_restart_apache"),
        comment => "restarting apache";

  files:

    (debian|redhat|SuSE)::

      "$(reverse_proxy_configuration_file)"
        create        => "true",
        edit_defaults => empty,
        edit_line     => insert_proxy_entries("$(proxies)"),
        classes       => kept_if_else("reverse_proxy_file_ok", "reverse_proxy_file_edited", "reverse_proxy_file_edition_failed"),
        comment       => "Edit the Apache reverse proxy file";

reports:

  (redhat|SuSE)::
    "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy modules@@None@@$(g.execRun)##$(g.uuid)@#No ${service_name} modules edition needed on this OS";

  apache_modules_enabled::
    "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy modules@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} proxy related modules Apache have been successfully enabled";

  apache_modules_not_enabled.!apache_modules_enabled::
    "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy modules@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} proxy related modules Apache were NOT enabled.";

  apache_selinux_adjust.apache_selinux_adjusted::
    "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy SELinux configuration@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} SELinux proxy related configuration has been edited";

  apache_selinux_adjust.apache_selinux_not_adjusted::
    "@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Apache reverse proxy SELinux configuration@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} SELinux proxy related configuration has NOT been edited !";

  reverse_proxy_file_ok::
    "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} reverse proxy configuration is correct";

  reverse_proxy_file_edited::
    "@@apacheReverseProxy@@result_repaired@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} reverse proxy configuration has been edited";

  reverse_proxy_file_not_edited::
    "@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The ${service_name} reverse proxy configuration could NOT be edited !";

  apache_restarted::
    "@@apacheReverseProxy@@log_info@@&TRACKINGKEY&@@apacheServer@@None@@$(g.execRun)##$(g.uuid)@#${service_name} restarted";

  cant_restart_apache::
    "@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@apacheServer@@None@@$(g.execRun)##$(g.uuid)@#Could not restart ${service_name}";

}
