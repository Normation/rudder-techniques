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

###############################################################
# Installs SSH, and checks wether it is started on boot or not.
###############################################################

bundle agent rudder_openssh_server_installation(service_name)
{
  vars:
    (debian|redhat)::
      "rudder_openssh_server_package_name"
        string => "openssh-server";
    SuSE::
      "rudder_openssh_server_package_name"
        string => "openssh";

  packages:
    # Install OpenSSH if needed, using generic installation.
    (debian|redhat|SuSE)::
      "${rudder_openssh_server_package_name}"
        package_policy  => "add",
        package_method  => generic,
        classes         => rudder_common_classes("rudder_openssh_server_package"),
        comment         => "Installing OpenSSH using the generic package manager method";
}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_openssh_server_installation_reporting(service_name)
{
  methods:
      "any" usebundle => rudder_common_reports_generic("${service_name}", "rudder_openssh_server_package", "&TRACKINGKEY&", "SSH installation", "None", "The ${service_name} package installation");
}
