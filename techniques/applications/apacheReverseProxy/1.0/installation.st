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

bundle agent rudder_reverse_proxy_apache_installation(service_name) {
  vars:

    redhat::

      "apache_package_name" string => "httpd";

    !redhat::

      "apache_package_name" string => "apache2";

  classes:

    "install_apache" expression => strcmp("&APACHE_REVERSE_PROXY_INSTALL&", "true");

  packages:

    # Too bad SuSE 10 uses a different bundle, things would be so simple if it was not the case...
    SuSE_10.install_apache::

      "${apache_package_name}"
        package_policy  => "add",
        package_method  => rudder_rug,
        classes         => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
        comment         => "Installing apache using the rug interface";

    !SuSE_10.install_apache::

      "${apache_package_name}"
        package_policy  => "add",
        package_method  => generic,
        classes         => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
        comment         => "Installing apache using generic interface";

  reports:

    !install_apache::
      "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#${service_name} installation is not required. Skipping...";

    apache_here.!apache_installed.!cant_install_apache::
      "@@apacheReverseProxy@@result_success@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#${service_name} already installed";

    apache_installed.!cant_install_apache::
      "@@apacheReverseProxy@@result_repaired@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#${service_name} installed";

    cant_install_apache::
      "@@apacheReverseProxy@@result_error@@&TRACKINGKEY&@@Apache reverse proxy installation@@None@@$(g.execRun)##$(g.uuid)@#Can't install ${service_name}";

}
