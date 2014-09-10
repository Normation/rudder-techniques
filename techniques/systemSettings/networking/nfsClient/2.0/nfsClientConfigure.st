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

bundle agent check_nfs_client_configuration
{

  vars:

    &NFS_CLIENT_REMOTE_PATH:{remote_path |"nfs_client_remote_path[&i&]" string => "&remote_path&";
}&
    &NFS_CLIENT_REMOTE_SERVER:{remote_server |"nfs_client_remote_server[&i&]" string => "&remote_server&";
}&
    &NFS_CLIENT_LOCAL_PATH:{local_path |"nfs_client_local_path[&i&]" string => "&local_path&";
}&
    &NFS_CLIENT_REMOTE_TYPE:{remote_type |"nfs_client_remote_type[&i&]" string => "&remote_type&";
}&
    &NFS_CLIENT_ADDFSTAB:{addfstab |"nfs_client_addfstab[&i&]" string => "&addfstab&";
}&
    &NFS_CLIENT_UMOUNT:{umount |"nfs_client_umount[&i&]" string => "&umount&";
}&
    &TRACKINGKEY:{uuid |"nfs_client_uuid[&i&]" string => "&uuid&";
}&
      "nfs_client_index" slist => getindices("nfs_client_remote_path");

  classes:

      "begin_evaluation" expression => isvariable("nfs_client_index");

    begin_evaluation::

      "index_${nfs_client_index}_add" expression => strcmp("${nfs_client_umount[${nfs_client_index}]}", "no");
      "index_${nfs_client_index}_remove" expression => strcmp("${nfs_client_umount[${nfs_client_index}]}", "yes");

  storage:

    linux::

      "${nfs_client_local_path[${nfs_client_index}]}"
        mount => rudder_nfs("${nfs_client_remote_server[${nfs_client_index}]}","${nfs_client_remote_path[${nfs_client_index}]}", "${nfs_client_remote_type[${nfs_client_index}]}", "${nfs_client_addfstab[${nfs_client_index}]}"),
        classes => kept_if_else("${nfs_client_index}_operation_kept", "${nfs_client_index}_operation_ok", "${nfs_client_index}_operation_failed"),
        ifvarclass => "index_${nfs_client_index}_add";

      "${nfs_client_local_path[${nfs_client_index}]}"
        mount => unmount,
        classes => kept_if_else("${nfs_client_index}_operation_kept", "${nfs_client_index}_operation_ok", "${nfs_client_index}_operation_failed"),
        ifvarclass => "index_${nfs_client_index}_remove";

  reports:

    linux::

      "@@nfsClient@@result_repaired@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was successfully mounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}"
        ifvarclass => "${nfs_client_index}_operation_ok.index_${nfs_client_index}_add";

      "@@nfsClient@@result_repaired@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was successfully unmounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}"
        ifvarclass => "${nfs_client_index}_operation_ok.index_${nfs_client_index}_remove";

      "@@nfsClient@@result_success@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was already mounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}"
        ifvarclass => "${nfs_client_index}_operation_kept.index_${nfs_client_index}_add";

      "@@nfsClient@@result_success@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was not mounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}"
        ifvarclass => "${nfs_client_index}_operation_kept.index_${nfs_client_index}_remove";

      "@@nfsClient@@result_error@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was NOT mounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}. This could be an error in the mount definition or an nfs failure"
        ifvarclass => "${nfs_client_index}_operation_failed.!${nfs_client_index}_operation_ok.index_${nfs_client_index}_add";

      "@@nfsClient@@result_error@@${nfs_client_uuid[${nfs_client_index}]}@@NFS mountpoint@@${nfs_client_local_path[${nfs_client_index}]}@@${g.execRun}##${g.uuid}@#The path ${nfs_client_local_path[${nfs_client_index}]} was NOT unmounted on ${nfs_client_remote_server[${nfs_client_index}]}:${nfs_client_remote_path[${nfs_client_index}]}. This could be an error in the mount definition or an nfs failure"
        ifvarclass => "${nfs_client_index}_operation_failed.!${nfs_client_index}_operation_ok.index_${nfs_client_index}_remove";

}
