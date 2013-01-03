#####################################################################################
# Copyright 2012 Normation SAS
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

###############################################################
# Installs SSH, and checks wether it is started on boot or not.
###############################################################

bundle agent rudder_openssh_server_installation
{
  packages:
    # Install OpenSSH if needed, using generic installation.
    (debian|redhat)::
      "openssh-server"
        package_policy  => "add",
        package_method  => generic,
        classes         => rudder_common_classes("rudder_openssh_server_package"),
        comment         => "Installing OpenSSH on RedHat or Debian using the generic package manager method";
    SuSE::
      "openssh"
        package_policy  => "add",
        package_method  => generic,
        classes         => rudder_common_classes("rudder_openssh_server_package"),
        comment         => "Installing OpenSSH on SuSE using the generic package manager method";
}

bundle agent rudder_openssh_server_installation_reporting
{
  methods:
    "any" usebundle => rudder_common_reports_generic("OpenSSH server", "rudder_openssh_server_package", "&TRACKINGKEY&", "SSH installation", "None", "The OpenSSH package installation");
}
