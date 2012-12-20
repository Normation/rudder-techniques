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
        classes         => rudder_common_setclass("rudder_openssh_server_package"),
        comment         => "Installing OpenSSH using the generic package manager method";

  reports:

    rudder_openssh_server_package_kept.!rudder_openssh_server_package_repaired.!rudder_openssh_server_package_error::
      "@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH installation@@None@@${g.execRun}##${g.uuid}@#The SSH package was already installed";
    rudder_openssh_server_package_repaired.!rudder_openssh_server_package_error::
        "@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH installation@@None@@${g.execRun}##${g.uuid}@#The SSH package was installed";
    rudder_openssh_server_package_error::
        "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH installation@@None@@${g.execRun}##${g.uuid}@#Can't install the SSH package";

}
