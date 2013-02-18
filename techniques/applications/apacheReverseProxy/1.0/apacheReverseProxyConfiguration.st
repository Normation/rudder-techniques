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

bundle agent check_apache_reverse_proxy_configuration {

  vars:

    "debian_modules" string => "proxy proxy_http";

#    &APACHE_REVERSE_PROXY_URL_SRC,APACHE_REVERSE_PROXY_URL_DST,APACHE_REVERSE_PROXY_TIMEOUT:{src, dst, timeout|"proxies[&i&]" string => "ProxyPass &src& &dst& connectiontimeout=5 timeout=&timeout&$(const.n)ProxyPassReverse &src& &dst&";
#}&

    "proxies" string => "&APACHE_REVERSE_PROXY_URL_SRC,APACHE_REVERSE_PROXY_URL_DST,APACHE_REVERSE_PROXY_TIMEOUT:{src, dst, timeout|ProxyPass &src& &dst& connectiontimeout=5 timeout=&timeout&$(const.n)ProxyPassReverse &src& &dst&
}&";
    (debian|SuSE)::

      "reverse_proxy_configuration_file" string => "/etc/apache2/conf.d/rudder-reverse-proxy.conf";

    redhat::

      "reverse_proxy_configuration_file" string => "/etc/httpd/conf.d/rudder-reverse-proxy.conf";

	classes:

		debian::

			# Security : if not there, Apache too, so don't bother anymore
			"apache_bin_present" expression => fileexists("/usr/sbin/apache2");

		redhat::

			"apache_bin_present" expression => fileexists("/usr/sbin/httpd");

		SuSE::

			"apache_bin_worker" expression => fileexists("/usr/sbin/httpd2-worker");
			"apache_bin_prefork" expression => fileexists("/usr/sbin/httpd2-prefork");
			"apache_bin_present" expression => "apache_bin_prefork|apache_bin_worker";

		any::

			# Adjust SELinux ?
			"apache_selinux_adjust" expression => strcmp("&APACHE_REVERSE_PROXY_ADJUST_SELINUX&","true");

	processes:
	
		debian::
	
			"/usr/sbin/apache2"
				restart_class => "apache_down",
				comment => "Ensuring apache is up";

		redhat::
	
			"/usr/sbin/httpd"
				restart_class => "apache_down",
				comment => "Ensuring apache is up";

		SuSE.apache_bin_prefork::

			"/usr/sbin/httpd2-prefork"
				restart_class => "apache_down",
				comment => "Ensuring apache is up";

		SuSE.!apache_bin_prefork::

			"/usr/sbin/httpd2-worker"
				restart_class => "apache_down",
				comment => "Ensuring apache is up";

	commands:

		debian::

			"/usr/sbin/a2enmod"
				args => "$(debian_modules)",
				classes => cf2_if_else("apache_modules_enabled", "apache_modules_not_enabled"),
				comment => "Enable Apache modules on Debian";

		apache_selinux_adjust::

			"/usr/sbin/setsebool"
				args => "httpd_can_network_relay on",
				classes => cf2_if_else("apache_selinux_adjusted", "apache_selinux_not_adjusted"),
				comment => "Enable SELinux Apache entry to let Apache proxy entries";

		(SuSE|debian).(apache_down|reverse_proxy_file_edited)::
			"/etc/init.d/apache2"
				args => "restart",
				classes => cf2_if_else("apache_restarted", "cant_restart_apache"),
				comment => "restarting apache";

		redhat.(apache_down|reverse_proxy_file_edited)::
			"/etc/init.d/httpd"
				args => "restart",
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

		apache_modules_enabled|(redhat|SuSE)::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy modules@@None@@$(g.execRun)##$(g.uuid)@#The Apache proxy related modules Apache have been successfully enabled";

		apache_modules_not_enabled.!apache_modules_enabled::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy modules@@None@@$(g.execRun)##$(g.uuid)@#The Apache proxy related modules Apache were NOT enabled.";

		apache_selinux_adjust.apache_selinux_adjusted::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy SELinux configuration@@None@@$(g.execRun)##$(g.uuid)@#The Apache SELinux proxy related configuration has been edited";

		apache_selinux_adjust.apache_selinux_not_adjusted::
			"@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Apache reverse proxy SELinux configuration@@None@@$(g.execRun)##$(g.uuid)@#The Apache SELinux proxy related configuration has NOT been edited !";

    reverse_proxy_file_ok::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The Apache reverse proxy configuration is correct";

    reverse_proxy_file_edited::
			"@@apacheReverseProxy@@result_repaired@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The Apache reverse proxy configuration has been edited";

    reverse_proxy_file_not_edited::
			"@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Reverse Proxy Settings@@None@@$(g.execRun)##$(g.uuid)@#The Apache reverse proxy configuration could NOT be edited !";

		apache_restarted::
			"@@apacheReverseProxy@@log_info@@&TRACKINGKEY&@@apacheServer@@None@@$(g.execRun)##$(g.uuid)@#Apache HTTPD restarted";

		cant_restart_apache::
			"@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@apacheServer@@None@@$(g.execRun)##$(g.uuid)@#Could not restart Apache HTTPD";

		!apache_bin_present::
			"@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Apache2 installation@@None@@$(g.execRun)##$(g.uuid)@#Apache binary is not present. Something is wrong (installation failure ?)";

}

bundle edit_line insert_proxy_entries(entries)
{
insert_lines:

  "<IfModule mod_proxy.c>
$(entries)</IfModule>";

#  "</IfModule>"
#    location => after("<IfModule\s+mod_proxy.c>");

#  "$($(entries)[$(index)])"
#    location => after("<IfModule\s+mod_proxy.c>"),
#    comment  => "Append lines if they don't exist";

}
