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

####################
# Installs Apache  #
####################

bundle agent check_apache_installation
{

  packages:

    debian|SuSE_11::

      "apache2"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
        comment => "Installing apache using generic interface";

    SuSE_10::

      "apache2"
        package_policy  => "add",
        package_method  => rudder_rug,
        classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
        comment => "Installing apache using the rug interface";
    redhat::

      "httpd"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("apache_here", "apache_installed", "cant_install_apache"),
        comment => "Installing apache using generic interface";

  reports:
    apache_here.!apache_installed.!cant_install_apache::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Apache2 installation@@None@@${g.execRun}##${g.uuid}@#Apache already installed";

    apache_installed.!cant_install_apache::
      "@@apacheServerConfiguration@@result_repaired@@&TRACKINGKEY&@@Apache2 installation@@None@@${g.execRun}##${g.uuid}@#Apache installed";

    cant_install_apache::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Apache2 installation@@None@@${g.execRun}##${g.uuid}@#Can't install Apache";
}
