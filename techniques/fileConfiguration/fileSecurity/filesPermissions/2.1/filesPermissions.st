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

      "dim_array" int =>  readstringarrayidx("file","${sys.workdir}/inputs/filesPermissions/permlist","#[^\n]*",":",1024,102400);

      "filePerms" slist => getindices("file");

  methods:

      "any" usebundle => check_permissions("${file[${filePerms}][0]}",
      "${file[${filePerms}][1]}",
      "${file[${filePerms}][2]}");

}

bundle agent check_permissions(directiveId, fileName, action_parameters)
{


  vars:

      "identifier" string => canonify("${directiveId}${fileName}");

      # Splitting the action parameters
      # we need to do the split in two pass, as we cannot reliably use array with more than 10 column in CFEngine 3.6
      # See https://dev.cfengine.com/issues/6674
      "dim_array" int => parsestringarrayidx("permission_parameters", "${action_parameters}", "\s*#[^\n]*", ";;", 10, 4096);

      # directly get the content of the value for ease of use in the technique
      "user"       string => "${permission_parameters[0][0]}";
      "group"      string => "${permission_parameters[0][1]}";
      "mode"       string => "${permission_parameters[0][2]}";
      "edit_user"  string => "${permission_parameters[0][3]}";
      "edit_group" string => "${permission_parameters[0][4]}";
      "edit_mode"  string => "${permission_parameters[0][5]}";
      "suid"       string => "${permission_parameters[0][6]}";
      "sgid"       string => "${permission_parameters[0][7]}";
      "recursion"  string => "${permission_parameters[0][8]}";
      "ignoreFile" string => "${permission_parameters[0][9]}";

    # See the explication below, before the "classes_defined" class definition
    classes_defined.enable_suid.!enable_sgid::

      "extended_modes"
        string     => "4";

    classes_defined.!enable_suid.enable_sgid::

      "extended_modes"
        string     => "2";

    classes_defined.enable_suid.enable_sgid::

      "extended_modes"
        string     => "6";

    classes_defined.!enable_suid.!enable_sgid::

      "extended_modes"
        string     => "0";

  classes:

      "file_exists"   expression => fileexists("${fileName}");

      "ignore_absent"   not => strcmp("${ignoreFile}","false");

      "user_absent"   not => userexists("${user}");

      "group_absent"  not => groupexists("${group}");

      "edit_owner"    not => strcmp("${edit_user}","false");

      "edit_group"    not => strcmp("${edit_group}","false");

      "edit_mode"     not => strcmp("${edit_mode}","false");

      "edit_recurse"  not => strcmp("${recursion}","false");

      "enable_suid"  not => strcmp("${suid}","false");

      "enable_sgid"  not => strcmp("${sgid}","false");

      "is_symlink"    expression => islink("${fileName}");

  # Again, normal ordering must be altered for this to work.
  # This class will block variable definition as long as the other
  # classes are not defined properly
      "classes_defined" expression => "any";

  # When ${suid_definition} exists, it means that we can now set SUID
  # and SGID bits.
      "can_edit_suid_sgid" expression => isvariable("extended_modes");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

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

    can_edit_suid_sgid.file_exists.edit_mode.!edit_recurse.!is_symlink::

      "${fileName}"
        perms => m("${extended_modes}${mode}"),
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

  methods:

    pass3.is_symlink::
      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "Will not adjust permissions on ${fileName}, because it is a symlink");

    pass3.!file_exists.ignore_absent::
      "any" usebundle => rudder_common_report("FilesPermissions", "result_success", "${directiveId}", "File permissions", "${fileName}", "${fileName} does not exist but is ignored");

    pass3.!file_exists.!ignore_absent::
      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "File or directory not found: ${fileName}");

    pass3.user_absent::
      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "The requested user (${user}) was not found on this machine: ${fileName}'s owner can't be set");

    pass3.group_absent::
      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "The requested group (${group}) was not found on this machine: ${fileName}'s group can't be set");

    pass3.edit_recurse::
      "any" usebundle => rudder_common_report("FilesPermissions", "log_info", "${directiveId}", "File permissions", "${fileName}", "Permissions will be applied recursively for ${fileName}");

    pass3.(file_exists.can_edit_suid_sgid)::

      # User

      "any" usebundle => rudder_common_report("FilesPermissions", "log_info", "${directiveId}", "File permissions", "${fileName}", "Owner ${user} already matches current owner for: ${fileName}"),
        ifvarclass => "${identifier}_owner_ok.!${identifier}_owner_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "log_repaired", "${directiveId}", "File permissions", "${fileName}", "Owner reset to ${user} for: ${fileName}"),
        ifvarclass => "${identifier}_owner_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "Owner ${user} could not be set for: ${fileName}"),
        ifvarclass => "${identifier}_owner_not_repaired";

      # Group

      "any" usebundle => rudder_common_report("FilesPermissions", "log_info", "${directiveId}", "File permissions", "${fileName}", "Group ${group} already matches current group for: ${fileName}"),
        ifvarclass => "${identifier}_group_ok.!${identifier}_group_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "log_repaired", "${directiveId}", "File permissions", "${fileName}", "Group reset to ${group} for: ${fileName}"),
        ifvarclass => "${identifier}_group_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "Group ${group} could not be set for: ${fileName}"),
        ifvarclass => "${identifier}_group_not_repaired";

      # Mode

      "any" usebundle => rudder_common_report("FilesPermissions", "log_info", "${directiveId}", "File permissions", "${fileName}", "Mode ${extended_modes}${mode} already matches current mode for: ${fileName}"),
        ifvarclass => "${identifier}_mode_ok.!${identifier}_mode_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "log_repaired", "${directiveId}", "File permissions", "${fileName}", "Mode reset to ${extended_modes}${mode} for: ${fileName}"),
        ifvarclass => "${identifier}_mode_repaired";

      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "Mode ${extended_modes}${mode} could not be set for: ${fileName}"),
        ifvarclass => "${identifier}_mode_not_repaired";

  # Final report

      "any" usebundle => rudder_common_report("FilesPermissions", "result_success", "${directiveId}", "File permissions", "${fileName}", "Owner, group and permissions already correct for ${fileName}"),
        # Success if nothing in error AND nothing repaired
        ifvarclass => "(!${identifier}_owner_not_repaired.!${identifier}_group_not_repaired.!${identifier}_mode_not_repaired).(!${identifier}_owner_repaired.!${identifier}_group_repaired.!${identifier}_mode_repaired)";

      "any" usebundle => rudder_common_report("FilesPermissions", "result_repaired", "${directiveId}", "File permissions", "${fileName}", "Owner, group or permissions were fixed for: ${fileName}"),
        # Repaired if nothing in error AND something repaired
        ifvarclass => "!${identifier}_owner_not_repaired.!${identifier}_group_not_repaired.!${identifier}_mode_not_repaired.(${identifier}_owner_repaired|${identifier}_group_repaired|${identifier}_mode_repaired)";

      "any" usebundle => rudder_common_report("FilesPermissions", "result_error", "${directiveId}", "File permissions", "${fileName}", "Owner, group or permissions could not be set for: ${fileName}"),
        # Error if something in error
        ifvarclass => "${identifier}_owner_not_repaired|${identifier}_group_not_repaired|${identifier}_mode_not_repaired";

}
