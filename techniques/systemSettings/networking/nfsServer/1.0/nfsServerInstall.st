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

  packages:

    (debian|SuSE)::
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

  reports:
    nfs_server_here::
      "@@nfsServer@@result_success@@&TRACKINGKEY&@@NFS server package install@@None@@${g.execRun}##${g.uuid}@#NFS server package already installed";

    nfs_server_installed::
      "@@nfsServer@@result_repaired@@&TRACKINGKEY&@@NFS server package install@@None@@${g.execRun}##${g.uuid}@#NFS server package installed";

    cant_install_nfs_server::
      "@@nfsServer@@result_error@@&TRACKINGKEY&@@NFS server package install@@None@@${g.execRun}##${g.uuid}@#Can't install NFS server package";
}
