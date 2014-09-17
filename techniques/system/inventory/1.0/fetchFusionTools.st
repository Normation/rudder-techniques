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

############################################################
# Fetch PERL and Curl
############################################################

bundle agent fetchFusionTools
{

&if(NOVA)&
  files:

    windows::

        # This won't work anymore now we've removed Perl from tools
        # See http://www.rudder-project.org/redmine/issues/2177
      "${g.rudder_sbin}/perl"
        copy_from    => remote_unsecured("${server_info.cfserved}", "${g.rudder_dependencies_origin}/perl"),
        depth_search => recurse("inf"),
        action => if_elapsed("2880"),
        classes => cf2_if_else("fusion_tools_copied", "cannot_copy_fusion_tools"),
        comment => "Copying PERL userland";
&endif&

  packages:

    debian::
      "curl"
        package_policy  => "add",
        package_method  => apt,
        classes => rudder_common_classes("fetchFusionTools_install_curl"),
        comment => "Installing curl using apt";
    redhat::
      "curl"
        package_policy  => "add",
        package_method  => rudder_yum,
        classes => rudder_common_classes("fetchFusionTools_install_curl"),
        comment => "Installing curl using yum";

  reports:
    fusion_tools_copied::
      "@@Inventory@@log_info@@&TRACKINGKEY&@@tools@@None@@${g.execRun}##${g.uuid}@#Copied fusion related utilities";

    cannot_copy_fusion_tools::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@tools@@None@@${g.execRun}##${g.uuid}@#Can't copy fusion utilities. Fusion might not work";

    fetchFusionTools_install_curl_error::
      "@@Inventory@@result_error@@inventory-all@@inventory-all@@00@@tools@@None@@${g.execRun}##${g.uuid}@#Installing 'curl' failed. Inventory registration will fail if curl is unavailable";

}

body perms myperms
{
        mode => "0700";
}
