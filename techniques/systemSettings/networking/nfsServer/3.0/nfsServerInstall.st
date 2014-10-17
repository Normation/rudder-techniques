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

###############################################################
# Installs the NFS server


bundle agent check_nfs_server_installation
{

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  packages:

    linux.!redhat::
      "nfs-kernel-server"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("nfs_server_here", "nfs_server_installed", "cant_install_nfs_server"),
        comment => "Installing NFS server using generic interface";

    redhat::
      "nfs-utils"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("nfs_server_here", "nfs_server_installed", "cant_install_nfs_server"),
        comment => "Installing NFS server using generic interface";

  methods:
    pass3.nfs_server_here::
      "any" usebundle => rudder_common_report("nfsServer", "result_success", "&TRACKINGKEY&", "NFS server package install", "None", "NFS server package already installed");

    pass3.nfs_server_installed::
      "any" usebundle => rudder_common_report("nfsServer", "result_repaired", "&TRACKINGKEY&", "NFS server package install", "None", "NFS server package installed");

    pass3.cant_install_nfs_server::
      "any" usebundle => rudder_common_report("nfsServer", "result_error", "&TRACKINGKEY&", "NFS server package install", "None", "Can't install NFS server package");

    pass3.(!linux)::
      "any" usebundle => rudder_common_report("nfsServer", "result_success", "&TRACKINGKEY&", "NFS server package install", "None", "Support to check if NFS server is installed not available on this platform");

}
