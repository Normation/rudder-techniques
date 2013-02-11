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

bundle agent files_permissions {
vars:

"dim_array" int =>  readstringarrayidx("file","${sys.workdir}/inputs/filesPermissions/permlist","#[^\n]*",":",1024,120400);

"filePerms" slist => getindices("file");

methods:

	"any" usebundle => check_permissions("$(file[$(filePerms)][0])",
						"$(file[$(filePerms)][1])",
						"$(file[$(filePerms)][2])",
						"$(file[$(filePerms)][3])",
						"$(file[$(filePerms)][4])",
						"$(file[$(filePerms)][5])",
						"$(file[$(filePerms)][6])",
						"$(file[$(filePerms)][7])",
						"$(file[$(filePerms)][8])",
						"$(file[$(filePerms)][9])",
						"$(file[$(filePerms)][10])");

}

bundle agent check_permissions(policyInstanceId, fileName, user, group, mode, edit_user, edit_group, edit_mode, suid, sgid, recursion) {


vars:

	"identifier" string => canonify("$(policyInstanceId)$(fileName)");

	# See the explication below, before the "classes_defined" class definition
	classes_defined::

		"extended_modes"
			string     => "4",
			ifvarclass => "enable_suid.!enable_sgid";

		"extended_modes"
			string     => "2",
			ifvarclass => "!enable_suid.enable_sgid";

		"extended_modes"
			string     => "6",
			ifvarclass => "enable_suid.enable_sgid";

		"extended_modes"
			string     => "0",
			ifvarclass => "!enable_suid.!enable_sgid";

classes:

	"file_exists"   expression => fileexists(${fileName});

	"user_absent"   not => userexists("$(user)");

	"group_absent"  not => groupexists("$(group)");

	"edit_owner"    not => strcmp("${edit_user}","false");

	"edit_group"    not => strcmp("${edit_group}","false");

	"edit_mode"     not => strcmp("${edit_mode}","false");

	"edit_recurse"  not => strcmp("${recursion}","false");

	"enable_suid"  not => strcmp("${suid}","false");

	"enable_sgid"  not => strcmp("${sgid}","false");

	"is_symlink"    expression => islink("$(fileName)");

	# Again, normal ordering must be altered for this to work.
	# This class will block variable definition as long as the other
	# classes are not defined properly
	"classes_defined" expression => "any";

	# When $(suid_definition) exists, it means that we can now set SUID
	# and SGID bits.
	"can_edit_suid_sgid" expression => isvariable("extended_modes");

files:

	file_exists.edit_owner.!user_absent.!edit_recurse.!is_symlink::

		"${fileName}"
			perms => owner("${user}"),
			comment => "Setting the file owner",
			classes => kept_if_else("$(identifier)_owner_ok", "$(identifier)_owner_repaired", "$(identifier)_owner_not_repaired");

	file_exists.edit_group.!group_absent.!edit_recurse.!is_symlink::

		"${fileName}"
			perms => group("${group}"),
			comment => "Setting the file group",
			classes => kept_if_else("$(identifier)_group_ok", "$(identifier)_group_repaired", "$(identifier)_group_not_repaired");

	can_edit_suid_sgid.file_exists.edit_mode.!edit_recurse.!is_symlink::

		"${fileName}"
			perms => m("${extended_modes}${mode}"),
			comment => "Setting the file mode",
			classes => kept_if_else("$(identifier)_mode_ok", "$(identifier)_mode_repaired", "$(identifier)_mode_not_repaired");

	file_exists.edit_owner.!user_absent.edit_recurse.!is_symlink::

		"${fileName}"
			perms => owner("${user}"),
			depth_search => recurse_with_current("inf"),
			comment => "Setting the file owner",
			classes => kept_if_else("$(identifier)_owner_ok", "$(identifier)_owner_repaired", "$(identifier)_owner_not_repaired");

	file_exists.edit_group.!group_absent.edit_recurse.!is_symlink::

		"${fileName}"
			perms => group("${group}"),
			depth_search => recurse_with_current("inf"),
			comment => "Setting the file group",
			classes => kept_if_else("$(identifier)_group_ok", "$(identifier)_group_repaired", "$(identifier)_group_not_repaired");

	file_exists.edit_mode.edit_recurse.!is_symlink::

		"${fileName}"
			perms => m("${mode}"),
			depth_search => recurse_with_current("inf"),
			comment => "Setting the file mode",
			classes => kept_if_else("$(identifier)_mode_ok", "$(identifier)_mode_repaired", "$(identifier)_mode_not_repaired");

reports:

	is_symlink::
		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Will not adjust permissions on ${fileName}, because it is a symlink";

	!file_exists::
		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#File or directory not found: ${fileName}";

	user_absent::
		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#The requested user (${user}) was not found on this machine: ${fileName}'s owner can't be set";

	group_absent::
		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#The requested group (${group}) was not found on this machine: ${fileName}'s group can't be set";

	edit_recurse::
		"@@FilesPermissions@@log_info@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Permissions will be applied recursively for ${fileName}";

	file_exists.can_edit_suid_sgid::

	# User

		"@@FilesPermissions@@log_info@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner ${user} already matches current owner for: ${fileName}"
			ifvarclass => "$(identifier)_owner_ok.!$(identifier)_owner_repaired";

		"@@FilesPermissions@@log_repaired@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner reset to ${user} for: ${fileName}"
			ifvarclass => "$(identifier)_owner_repaired";

		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner ${user} could not be set for: ${fileName}"
			ifvarclass => "$(identifier)_owner_not_repaired";

	# Group

		"@@FilesPermissions@@log_info@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Group ${group} already matches current group for: ${fileName}"
			ifvarclass => "$(identifier)_group_ok.!$(identifier)_group_repaired";

		"@@FilesPermissions@@log_repaired@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Group reset to ${group} for: ${fileName}"
			ifvarclass => "$(identifier)_group_repaired";

		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Group ${group} could not be set for: ${fileName}"
			ifvarclass => "$(identifier)_group_not_repaired";

	# Mode

		"@@FilesPermissions@@log_info@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Mode ${extended_modes}${mode} already matches current mode for: ${fileName}"
			ifvarclass => "$(identifier)_mode_ok.!$(identifier)_mode_repaired";

		"@@FilesPermissions@@log_repaired@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Mode reset to ${extended_modes}${mode} for: ${fileName}"
			ifvarclass => "$(identifier)_mode_repaired";

		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Mode ${extended_modes}${mode} could not be set for: ${fileName}"
			ifvarclass => "$(identifier)_mode_not_repaired";

	# Final report

		"@@FilesPermissions@@result_success@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner, group and permissions already correct for ${fileName}"
			# Success if nothing in error AND nothing repaired
			ifvarclass => "(!$(identifier)_owner_not_repaired.!$(identifier)_group_not_repaired.!$(identifier)_mode_not_repaired).(!$(identifier)_owner_repaired.!$(identifier)_group_repaired.!$(identifier)_mode_repaired)";

		"@@FilesPermissions@@result_repaired@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner, group or permissions were fixed for: ${fileName}"
			# Repaired if nothing in error AND something repaired
			ifvarclass => "!$(identifier)_owner_not_repaired.!$(identifier)_group_not_repaired.!$(identifier)_mode_not_repaired.($(identifier)_owner_repaired|$(identifier)_group_repaired|$(identifier)_mode_repaired)";

		"@@FilesPermissions@@result_error@@$(policyInstanceId)@@File permissions@@${fileName}@@$(g.execRun)##$(g.uuid)@#Owner, group or permissions could not be set for: ${fileName}"
			# Error if something in error
			ifvarclass => "$(identifier)_owner_not_repaired|$(identifier)_group_not_repaired|$(identifier)_mode_not_repaired";

}
