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

######################################################
# Adjust file permissions                            #
# #######################                            #
#                                                    #
# This PT adjusts file or directory permissions      #
# according to user set parameters.                  #
######################################################

bundle agent files_permissions
{
  vars:

      "dim_array" int =>  readstringarrayidx("file","${sys.workdir}/inputs/filesPermissions/permlist","#[^\n]*",":",15,4000);

      "filePerms" slist => getindices("file");

  methods:

      "any" usebundle => check_permissions("$(file[${filePerms}][0])",
      "$(file[${filePerms}][1])",
      "$(file[${filePerms}][2])",
      "$(file[${filePerms}][3])",
      "$(file[${filePerms}][4])",
      "$(file[${filePerms}][5])",
      "$(file[${filePerms}][6])",
      "$(file[${filePerms}][7])",
      "$(file[${filePerms}][8])");

}

bundle agent check_permissions(directiveId, fileName, user, group, mode, edit_user, edit_group, edit_mode, recursion)
{


  vars:

      "identifier" string => canonify("${directiveId}${fileName}");

  classes:

      "file_exists"   expression => fileexists(${fileName});

      "user_absent"   not => userexists("${user}");

      "group_absent"  not => groupexists("${group}");

      "edit_owner"    not => strcmp("${edit_user}","false");

      "edit_group"    not => strcmp("${edit_group}","false");

      "edit_mode"     not => strcmp("${edit_mode}","false");

      "edit_recurse"  not => strcmp("${recursion}","false");

      "is_symlink"    expression => islink("${fileName}");

  files:

    file_exists.edit_owner.!user_absent.!edit_recurse.!is_symlink::

      "${fileName}"
        perms => owner("${user}"),
        comment => "Setting the file owner",
        classes => kept_if_else("${identifier}_owner_ok", "${identifier}_owner_repaired", "${identifier}_owner_not_repaired");

    file_exists.edit_group.!group_absent.!edit_recurse.!is_symlink::

      "${fileName}"
        perms => group("${group}"),
        comment => "Setting the file group",
        classes => kept_if_else("${identifier}_group_ok", "${identifier}_group_repaired", "${identifier}_group_not_repaired");

    file_exists.edit_mode.!edit_recurse.!is_symlink::

      "${fileName}"
        perms => m("${mode}"),
        comment => "Setting the file mode",
        classes => kept_if_else("${identifier}_mode_ok", "${identifier}_mode_repaired", "${identifier}_mode_not_repaired");

    file_exists.edit_owner.!user_absent.edit_recurse.!is_symlink::

      "${fileName}"
        perms => owner("${user}"),
        depth_search => recurse_with_current("inf"),
        comment => "Setting the file owner",
        classes => kept_if_else("${identifier}_owner_ok", "${identifier}_owner_repaired", "${identifier}_owner_not_repaired");

    file_exists.edit_group.!group_absent.edit_recurse.!is_symlink::

      "${fileName}"
        perms => group("${group}"),
        depth_search => recurse_with_current("inf"),
        comment => "Setting the file group",
        classes => kept_if_else("${identifier}_group_ok", "${identifier}_group_repaired", "${identifier}_group_not_repaired");

    file_exists.edit_mode.edit_recurse.!is_symlink::

      "${fileName}"
        perms => m("${mode}"),
        depth_search => recurse_with_current("inf"),
        comment => "Setting the file mode",
        classes => kept_if_else("${identifier}_mode_ok", "${identifier}_mode_repaired", "${identifier}_mode_not_repaired");

  reports:

    is_symlink::
      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Will not adjust permissions on ${fileName}, because it is a symlink";

    !file_exists::
      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#File or directory not found: ${fileName}";

    user_absent::
      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#The requested user (${user}) was not found on this machine: ${fileName}'s owner can't be set";

    group_absent::
      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#The requested group (${group}) was not found on this machine: ${fileName}'s group can't be set";

    edit_recurse::
      "@@FilesPermissions@@log_info@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Permissions will be applied recursively for ${fileName}";

    file_exists::

  # User

      "@@FilesPermissions@@log_info@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner ${user} already matches current owner for: ${fileName}"
        ifvarclass => "${identifier}_owner_ok.!${identifier}_owner_repaired";

      "@@FilesPermissions@@log_repaired@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner reset to ${user} for: ${fileName}"
        ifvarclass => "${identifier}_owner_repaired";

      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner ${user} could not be set for: ${fileName}"
        ifvarclass => "${identifier}_owner_not_repaired";

  # Group

      "@@FilesPermissions@@log_info@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Group ${group} already matches current group for: ${fileName}"
        ifvarclass => "${identifier}_group_ok.!${identifier}_group_repaired";

      "@@FilesPermissions@@log_repaired@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Group reset to ${group} for: ${fileName}"
        ifvarclass => "${identifier}_group_repaired";

      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Group ${group} could not be set for: ${fileName}"
        ifvarclass => "${identifier}_group_not_repaired";

  # Mode

      "@@FilesPermissions@@log_info@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Mode ${mode} already matches current mode for: ${fileName}"
        ifvarclass => "${identifier}_mode_ok.!${identifier}_mode_repaired";

      "@@FilesPermissions@@log_repaired@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Mode reset to ${mode} for: ${fileName}"
        ifvarclass => "${identifier}_mode_repaired";

      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Mode ${mode} could not be set for: ${fileName}"
        ifvarclass => "${identifier}_mode_not_repaired";

  # Final report

      "@@FilesPermissions@@result_success@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner, group and permissions already correct for ${fileName}"
      # Success if nothing in error AND nothing repaired
        ifvarclass => "(!${identifier}_owner_not_repaired.!${identifier}_group_not_repaired.!${identifier}_mode_not_repaired).(!${identifier}_owner_repaired.!${identifier}_group_repaired.!${identifier}_mode_repaired)";

      "@@FilesPermissions@@result_repaired@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner, group, or permissions were fixed for: ${fileName}"
      # Repaired if nothing in error AND something repaired
        ifvarclass => "!${identifier}_owner_not_repaired.!${identifier}_group_not_repaired.!${identifier}_mode_not_repaired.(${identifier}_owner_repaired|${identifier}_group_repaired|${identifier}_mode_repaired)";

      "@@FilesPermissions@@result_error@@${directiveId}@@File permissions@@${fileName}@@${g.execRun}##${g.uuid}@#Owner, group or permissions could not be set for: ${fileName}"
      # Error if something in error
        ifvarclass => "${identifier}_owner_not_repaired|${identifier}_group_not_repaired|${identifier}_mode_not_repaired";

}
