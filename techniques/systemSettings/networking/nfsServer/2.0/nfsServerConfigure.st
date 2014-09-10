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


  files:

    (debian|redhat|SuSE)::

      "/etc/rc2.d/S.*nfs.*"

        create => "true",
                                #depth_search => recurse("0"),
                                #file_select => ssh_startlink,
        action => WarnOnly,
        classes => cf2_if_else("nfs_server_bootstarted", "nfs_server_unbootstarted");

      "/etc/exports"

        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_nfs_server_values("${nfs_server_path[${nfs_server_index}]}", "${nfs_server_network[${nfs_server_index}]}", "${nfs_server_options[${nfs_server_index}]}"),
        classes => kept_if_else("nfs_server_${nfs_server_index}_kept", "nfs_server_${nfs_server_index}_done", "nfs_server_${nfs_server_index}_failed");

  commands:

    debian::

      "/etc/init.d/nfs-kernel-server"
        args => "restart",
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done"),
        classes => cf2_if_else("nfs_server_${nfs_server_index}_restarted", "nfs_server_${nfs_server_index}_not_restarted"),
        comment => "Restarting the NFS server";

      "/usr/sbin/update-rc.d"
        args => "nfs-kernel-server defaults",
        ifvarclass => canonify("nfs_server_unbootstarted"),
        comment => "adding nfs to the startup scripts";

    redhat::

      "/sbin/chkconfig"
        args => "--add nfs",
        ifvarclass => canonify("nfs_server_unbootstarted"),
        comment => "adding nfs to the startup scripts";

      "/sbin/chkconfig"
        args => "--add nfslock",
        ifvarclass => canonify("nfs_server_unbootstarted"),
        comment => "adding nfslock to the startup scripts";

      "/sbin/service"
        args => "nfs restart",
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done"),
        classes => cf2_if_else("nfs_server_${nfs_server_index}_restarted", "nfs_server_${nfs_server_index}_not_restarted"),
        comment => "Restarting the NFS server";

      "/sbin/service"
        args => "nfslock restart",
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done"),
        classes => cf2_if_else("nfs_server_${nfs_server_index}_restarted", "nfs_server_${nfs_server_index}_not_restarted"),
        comment => "Restarting the NFS lock server";

    SuSE::

      "/sbin/chkconfig"
        args => "--add nfsserver",
        ifvarclass => canonify("nfs_server_unbootstarted"),
        comment => "adding nfs to the startup scripts";

      "/sbin/service"
        args => "nfsserver restart",
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done"),
        classes => cf2_if_else("nfs_server_${nfs_server_index}_restarted", "nfs_server_${nfs_server_index}_not_restarted"),
        comment => "Restarting the NFS server";

  reports:

    (debian|redhat|SuSE)::

      "@@nfsServer@@result_repaired@@${nfs_server_uuid[${nfs_server_index}]}@@NFS server settings@@${nfs_server_path[${nfs_server_index}]}@@${g.execRun}##${g.uuid}@#The export ${nfs_server_path[${nfs_server_index}]} was successfully added"
        ifvarclass => canonify("nfs_server_${nfs_server_index}_done");

      "@@nfsServer@@result_success@@${nfs_server_uuid[${nfs_server_index}]}@@NFS server settings@@${nfs_server_path[${nfs_server_index}]}@@${g.execRun}##${g.uuid}@#The export ${nfs_server_path[${nfs_server_index}]} is already present"
        ifvarclass => canonify("nfs_server_${nfs_server_index}_kept");

      "@@nfsServer@@result_error@@${nfs_server_uuid[${nfs_server_index}]}@@NFS server settings@@${nfs_server_path[${nfs_server_index}]}@@${g.execRun}##${g.uuid}@#The export ${nfs_server_path[${nfs_server_index}]} could not be added"
        ifvarclass => canonify("nfs_server_${nfs_server_index}_failed");

      "@@nfsServer@@log_repaired@@${nfs_server_uuid[${nfs_server_index}]}@@NFS server settings@@${nfs_server_path[${nfs_server_index}]}@@${g.execRun}##${g.uuid}@#Restarted the NFS server because of the export ${nfs_server_path[${nfs_server_index}]}"
        ifvarclass => canonify("nfs_server_${nfs_server_index}_restarted");

      "@@nfsServer@@result_error@@${nfs_server_uuid[${nfs_server_index}]}@@NFS server settings@@${nfs_server_path[${nfs_server_index}]}@@${g.execRun}##${g.uuid}@#Could not restart the NFS server because of the export ${nfs_server_path[${nfs_server_index}]}"
        ifvarclass => canonify("nfs_server_${nfs_server_index}_not_restarted");

}

bundle edit_line set_nfs_server_values(export, network, options)
{

  delete_lines:

      "${export}.*";

  insert_lines:

      "${export}	${network}(${options})";

}
