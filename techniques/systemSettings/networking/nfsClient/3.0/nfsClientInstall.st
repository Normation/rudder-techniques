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
  vars:
    linux.!redhat.!SuSE::
      "rudder_nfs_client_package" string => "nfs-common";
    redhat::
      "rudder_nfs_client_package" string => "nfs-utils";
    SuSE::
      "rudder_nfs_client_package" string => "nfs-client";

  methods:
      "any" usebundle => package_present("${rudder_nfs_client_package}");
    linux::
      "any" usebundle => rudder_common_reports_generic("nfsClient", "package_present_${rudder_nfs_client_package}", "&TRACKINGKEY&", "NFS Client package install", "None", "The ${rudder_nfs_client_package} package installation");
    !linux::
      "any" usebundle => rudder_common_report("nfsClient", "result_na", "&TRACKINGKEY&", "NFS Client package install", "None", "Support to check if NFS client is installed not available on this platform");
}
