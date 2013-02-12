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
# Installs the NFS client


bundle agent check_nfs_client_installation
{

  packages:

    debian::
      "nfs-common"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("nfs_client_here", "nfs_client_installed", "cant_install_nfs_client"),
        comment => "Installing NFS client using generic interface";

    redhat::
      "nfs-utils"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("nfs_client_here", "nfs_client_installed", "cant_install_nfs_client"),
        comment => "Installing NFS client using generic interface";

    SuSE::
      "nfs-client"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("nfs_client_here", "nfs_client_installed", "cant_install_nfs_client"),
        comment => "Installing NFS client using generic interface";

  reports:
    nfs_client_here::
      "@@nfsClient@@result_success@@&TRACKINGKEY&@@NFS Client package install@@None@@${g.execRun}##${g.uuid}@#NFS client already installed";

    nfs_client_installed::
      "@@nfsClient@@result_repaired@@&TRACKINGKEY&@@NFS Client package install@@None@@${g.execRun}##${g.uuid}@#NFS client installed";

    cant_install_nfs_client::
      "@@nfsClient@@result_error@@&TRACKINGKEY&@@NFS Client package install@@None@@${g.execRun}##${g.uuid}@#Can't install the NFS client package";
}
