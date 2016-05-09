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

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  packages:

    linux.!SuSE_10.!redhat::

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

  methods:
    pass3.(apache_here.!apache_installed.!cant_install_apache)::
      "any" usebundle => rudder_common_report("apacheServerConfiguration", "result_success", "&TRACKINGKEY&", "Apache2 installation", "None", "Apache already installed");

    pass3.(apache_installed.!cant_install_apache)::
      "any" usebundle => rudder_common_report("apacheServerConfiguration", "result_repaired", "&TRACKINGKEY&", "Apache2 installation", "None", "Apache installed");

    pass3.cant_install_apache::
      "any" usebundle => rudder_common_report("apacheServerConfiguration", "result_error", "&TRACKINGKEY&", "Apache2 installation", "None", "Can't install Apache");

    pass3.(!linux)::
      "any" usebundle => rudder_common_report("apacheServerConfiguration", "result_error", "&TRACKINGKEY&", "Apache2 installation", "None", "Support to check if Apache is installed not available on this platform");

}
