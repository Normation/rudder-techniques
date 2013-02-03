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

#####################################################################################
# This Technique installs and configures OpenSSH. See metadata.xml for more details.
#####################################################################################

bundle agent rudder_openssh_server
{
  vars:
      "rudder_openssh_server_service_name"
        string => "OpenSSH server";

  methods:
    # Note:
    # The reporting is made on separate bundles to abstract the complexity
    # inherent to the normal ordering.
      "any" usebundle => rudder_openssh_server_installation("${rudder_openssh_server_service_name}");
      "any" usebundle => rudder_openssh_server_installation_reporting("${rudder_openssh_server_service_name}");
      "any" usebundle => rudder_openssh_server_configuration("${rudder_openssh_server_service_name}");
      "any" usebundle => rudder_openssh_server_configuration_reporting("${rudder_openssh_server_service_name}");
}
