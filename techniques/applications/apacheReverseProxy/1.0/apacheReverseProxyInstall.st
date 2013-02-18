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

####################
# Installs Apache  #
####################

bundle agent check_apache_reverse_proxy_installation {

  classes:

    "install_apache" expression => strcmp("&APACHE_REVERSE_PROXY_INSTALL&", "true");

	packages:

		debian|SuSE_11.install_apache::

			"apache2"
				package_policy  => "add",
				package_method  => generic,
				classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
				comment => "Installing apache using generic interface";

		SuSE_10.install_apache::

			"apache2"
				package_policy  => "add",
				package_method  => rudder_rug,
				classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
				comment => "Installing apache using the rug interface";

		redhat.install_apache::

			"httpd"
				package_policy  => "add",
				package_method  => generic,
				classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
				comment => "Installing apache using generic interface";

	reports:
		!install_apache::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#Apache reverse proxy installation is not required. Skipping...";

		apache_here.!apache_installed.!cant_install_apache::
			"@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#Apache already installed";

		apache_installed.!cant_install_apache::
			"@@apacheReverseProxy@@result_repaired@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#Apache installed";

		cant_install_apache::
			"@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#Can't install Apache";
}
