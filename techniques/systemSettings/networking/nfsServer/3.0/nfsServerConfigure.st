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

# (C) Normation 2011

bundle agent check_nfs_server_configuration
{

  vars:

    &NFS_SERVER_PATH:{path |"nfs_server_path[&i&]" string => "&path&";
}&
    &NFS_SERVER_NETWORK:{network |"nfs_server_network[&i&]" string => "&network&";
}&
    &NFS_SERVER_SECURE,NFS_SERVER_READWRITE,NFS_SERVER_SYNC,NFS_SERVER_WDELAY,NFS_SERVER_HIDE,NFS_SERVER_SUBTREECHECK,NFS_SERVER_SECURELOCKS,NFS_SERVER_ACL:{secure, readwrite, sync, wdelay, hide, subtreecheck, securelocks, acl |"nfs_server_options[&i&]" string => "&secure&,&readwrite&,&sync&,&wdelay&,&hide&,&subtreecheck&,&securelocks&,&acl&";
}&
    &TRACKINGKEY:{uuid |"nfs_server_uuid[&i&]" string => "&uuid&";
}&
      "nfs_server_index" slist => getindices("nfs_server_path");


  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    !windows::

      "/etc/exports"

        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_nfs_server_values("${nfs_server_path[${nfs_server_index}]}", "${nfs_server_network[${nfs_server_index}]}", "${nfs_server_options[${nfs_server_index}]}"),
        classes => kept_if_else("nfs_server_${nfs_server_index}_kept", "nfs_server_${nfs_server_index}_done", "nfs_server_${nfs_server_index}_failed");

  methods:

    pass2.(debian|ubuntu)::

      "bootstart_nfs" usebundle => service_ensure_started_at_boot("nfs-kernel-server");

      "restart_nfs"   usebundle => service_restart("nfs-kernel-server"),
                     ifvarclass => "nfs_server_${nfs_server_index}_done";

    pass2.redhat::

      "bootstart_nfs" usebundle => service_ensure_started_at_boot("nfs");
      "bootstart_nfs" usebundle => service_ensure_started_at_boot("nfslock");

      "restart_nfs"   usebundle => service_restart("nfs"),
                     ifvarclass => "nfs_server_${nfs_server_index}_done";
      "restart_nfs"   usebundle => service_restart("nfslock"),
                     ifvarclass => "nfs_server_${nfs_server_index}_done";

    pass2.SuSE::

      "bootstart_nfs" usebundle => service_ensure_started_at_boot("nfsserver");

      "restart_nfs"   usebundle => service_restart("nfsserver"),
                     ifvarclass => "nfs_server_${nfs_server_index}_done";

    pass3.(!windows)::

      "any" usebundle => rudder_common_report("nfsServer", "result_repaired", "${nfs_server_uuid[${nfs_server_index}]}", "NFS server settings", "${nfs_server_path[${nfs_server_index}]}", "The export ${nfs_server_path[${nfs_server_index}]} was successfully added"),
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done");

      "any" usebundle => rudder_common_report("nfsServer", "result_success", "${nfs_server_uuid[${nfs_server_index}]}", "NFS server settings", "${nfs_server_path[${nfs_server_index}]}", "The export ${nfs_server_path[${nfs_server_index}]} is already present"),
        ifvarclass => canonify("nfs_server_${nfs_server_index}_kept");

      "any" usebundle => rudder_common_report("nfsServer", "result_error", "${nfs_server_uuid[${nfs_server_index}]}", "NFS server settings", "${nfs_server_path[${nfs_server_index}]}", "The export ${nfs_server_path[${nfs_server_index}]} could not be added"),
        ifvarclass => canonify("nfs_server_${nfs_server_index}_failed");

    pass3.(service_restart_nfs_kernel_server_ok|service_restart_nfs_ok|service_restart_nfslock_ok|service_restart_nfsserver_ok)::

      "any" usebundle => rudder_common_report("nfsServer", "log_repaired", "${nfs_server_uuid[${nfs_server_index}]}", "NFS server settings", "${nfs_server_path[${nfs_server_index}]}", "Restarted the NFS server because of the export ${nfs_server_path[${nfs_server_index}]}");

    pass3.(service_restart_nfs_kernel_server_not_ok|service_restart_nfs_not_ok|service_restart_nfslock_not_ok|service_restart_nfsserver_not_ok)::

      "any" usebundle => rudder_common_report("nfsServer", "result_error", "${nfs_server_uuid[${nfs_server_index}]}", "NFS server settings", "${nfs_server_path[${nfs_server_index}]}", "Could not restart the NFS server because of the export ${nfs_server_path[${nfs_server_index}]}");

}

bundle edit_line set_nfs_server_values(export, network, options)
{

  delete_lines:

      "${export}.*";

  insert_lines:

      "${export}	${network}(${options})";

}
