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

#################################################################
# Manage files and folders, enforcing their existence           #
#################################################################

bundle agent manageFilesAndFolders {

	vars:

		&FILE_AND_FOLDER_MANAGEMENT_PATH:{path |"file[&i&][path]" string => "&path&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_PERM:{perm |"file[&i&][mode]" string => "&perm&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_OWNER:{owner |"file[&i&][owner]" string => "&owner&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_GROUP:{group |"file[&i&][group]" string => "&group&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND:{cmd |"file[&i&][post_hook_command]" string => "&cmd&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_SYMLINK_SOURCE:{src |"file[&i&][source]" string => "&src&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE:{symlink_enforced | "file[&i&][symlink_enforced]" string => "&symlink_enforced&";
}&
		&FILE_AND_FOLDER_MANAGEMENT_RECURSIVE:{recursive |"file[&i&][recursive]" string => "&recursive&";
}&
		&FILE_AND_FOLDER_DELETION_DAYS:{ttl |"file[&i&][ttl]" string => "&ttl&";
}&
		&FILE_AND_FOLDER_DELETION_PATTERN:{pattern |"file[&i&][pattern]" string => "&pattern&";
}&
		&TRACKINGKEY:{directiveId |"file[&i&][uuid]" string => "&directiveId&";
}&

		"index" slist => getindices("file");

  iteration_1::
    "extended_modes_${index}"
      string     => "4",
      ifvarclass => "enable_suid_${index}.!enable_sgid_${index}";

    "extended_modes_${index}"
      string     => "2",
      ifvarclass => "!enable_suid_${index}.enable_sgid_${index}";

    "extended_modes_${index}"
      string     => "6",
      ifvarclass => "enable_suid_${index}.enable_sgid_${index}";

    "extended_modes_${index}"
      string     => "0",
      ifvarclass => "!enable_suid_${index}.!enable_sgid_${index}";


	classes:

		# Set a class to define when we need to run the post-modification hook
		&FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN:{run |"manageFilesAndFolders_post_hook_run_&i&" expression => strcmp("&run&", "true");
}&

		&FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS:{perms |"manageFilesAndFolders_check_permissions_&i&" expression => strcmp("&perms&", "true");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{nocreate | "manageFilesAndFolders_nocreate_&i&" expression => strcmp("&nocreate&", "none");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createfile | "manageFilesAndFolders_createfile_&i&" expression => strcmp("&createfile&", "file");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createdir | "manageFilesAndFolders_createdir_&i&" expression => strcmp("&createdir&", "dir");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{copy | "manageFilesAndFolders_local_cp_&i&" expression => strcmp("&copy&", "copy");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createsymlink | "manageFilesAndFolders_createsymlink_&i&" expression => strcmp("&createsymlink&", "symlink");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{clean | "manageFilesAndFolders_clean_&i&" expression => strcmp("&clean&", "clean");
}&
		&FILE_AND_FOLDER_MANAGEMENT_RECURSIVE:{isrecursive | "manageFilesAndFolders_isrecursive_&i&" expression => strcmp("&isrecursive&", "inf");
}&
		&FILE_AND_FOLDER_MANAGEMENT_OWNER:{userset | "manageFilesAndFolders_userset_&i&" expression => strcmp("&userset&", "${file[&i&][owner]}");
}&
		&FILE_AND_FOLDER_MANAGEMENT_GROUP:{groupset | "manageFilesAndFolders_groupset_&i&" expression => strcmp("&groupset&", "${file[&i&][group]}");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_simple_&i&" expression => strcmp("&delopt&", "none");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_single_recursive_&i&" expression => strcmp("&delopt&", "single");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_full_recursive_&i&" expression => strcmp("&delopt&", "full");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_exterminate_&i&" expression => strcmp("&delopt&", "exterminate");
}&

      &FILE_AND_FOLDER_MANAGEMENT_SUID:{suid |"enable_suid_&i&" expression => strcmp("&suid&", "true");
}&
      &FILE_AND_FOLDER_MANAGEMENT_SGID:{sgid |"enable_sgid_&i&" expression => strcmp("&sgid&", "true");
}&

      "manageFilesAndFolders_isdir_${index}" expression => isdir("${file[${index}][path]}");
      "manageFilesAndFolders_isfile_${index}" expression => isplain("${file[${index}][path]}");
      "manageFilesAndFolders_islink_${index}" expression => islink("${file[${index}][path]}");

      "iteration_2" expression => "iteration_1";
      "iteration_1" expression => "any";
 
	files:
      iteration_2::

		# Directory
		"${file[${index}][path]}/."
			create => "true",
			classes => kept_if_else("manageFolders_${index}_kept", "manageFolders_${index}_modified", "manageFolders_${index}_failed"),
			comment => "Enforcing the existance of folder ${file[${index}][path]}",
			ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createfile_${index}.manageFilesAndFolders_createdir_${index}).!manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}";

		# File
		"${file[${index}][path]}"
			create => "true",
			classes => kept_if_else("manageFiles_${index}_kept", "manageFiles_${index}_modified", "manageFiles_${index}_failed"),
			comment => "Enforcing the existance of file ${file[${index}][path]}",
			ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_createfile_${index}).!manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}";

		# Local copy
		"${file[${index}][path]}"
			copy_from => backup_local_cp("${file[${index}][source]}"),
			classes => kept_if_else("manageCp_${index}_kept", "manageCp_${index}_modified", "manageCp_${index}_failed"),
			ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.!manageFilesAndFolders_createfile_${index}).manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}",
			comment => "Create ${file[${index}][path]} file as copy of ${file[${index}][source]}";

		# Symlink
		"${file[${index}][path]}"
			# create => "true",
			link_from => ln_s("${file[${index}][source]}"),
			move_obstructions => "${file[${index}][symlink_enforced]}",
			classes => kept_if_else("manageSyms_${index}_kept", "manageSyms_${index}_modified", "manageSyms_${index}_failed"),
			ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.!manageFilesAndFolders_createfile_${index}).!manageFilesAndFolders_local_cp_${index}.manageFilesAndFolders_createsymlink_${index}",
			comment => "Create the ${file[${index}][path]} symlink pointing to ${file[${index}][source]}";

		# Check the permissions none recursively
		## With user and group
		"${file[${index}][path]}"
			perms => mog("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}", "${file[${index}][group]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}";
		## With user
		"${file[${index}][path]}"
			perms => mo("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}";
		## With group
		"${file[${index}][path]}"
			perms => mg("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][group]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}";
		# Check the permissions recursively
		## With user and group
		"${file[${index}][path]}"
			depth_search => recurse_withroot("${file[${index}][recursive]}"),
			perms => mog("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}", "${file[${index}][group]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}";
		## With user
		"${file[${index}][path]}"
			depth_search => recurse_withroot("${file[${index}][recursive]}"),
			perms => mo("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}";
		## With group
		"${file[${index}][path]}"
			depth_search => recurse_withroot("${file[${index}][recursive]}"),
			perms => mg("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][group]}"),
			classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}";

		# This will not delete the parent
		"${file[${index}][path]}" 
			delete => tidy,
			file_select => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
			ifvarclass => "manageFilesAndFolders_clean_${index}.manageFilesAndFolders_deletion_single_recursive_${index}",
			depth_search => recurse("0"),
			classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

		# This will not delete the parent
		"${file[${index}][path]}" 
			delete => tidy,
			file_select => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
			depth_search => recurse("inf"),
			ifvarclass => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_full_recursive_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
			classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

		# This WILL delete the parent
		"${file[${index}][path]}" 
			delete => tidy,
			file_select => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
			ifvarclass => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_simple_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
			classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

	commands:
		"${file[${index}][post_hook_command]}"
			classes => if_else("manageFilesAndFolders_${index}_command_run_ok", "manageFilesAndFolders_${index}_command_run_failed"),
			contain => in_shell,
			ifvarclass => "manageFilesAndFolders_post_hook_run_${index}.(manageFiles_${index}_modified|manageFolders_${index}_modified|manageCp_${index}_modified|manageSyms_${index}_modified|manageFilesAndFolders_perms_${index}_modified)";

	reports:

        (linux|windows)::

			# Reporting for creation
			## Reporting for directory creation
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][path]} already exists"
				ifvarclass => "manageFolders_${index}_kept.!manageFolders_${index}_modified.manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_islink_${index}";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][path]} was successfully created"
				ifvarclass => "manageFolders_${index}_modified";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][path]} could not be created"
				ifvarclass => "manageFolders_${index}_failed|manageFolders_${index}_kept.(manageFilesAndFolders_isfile_${index}|manageFilesAndFolders_islink_${index})";

			## Reporting for file creation
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} already exists"
				ifvarclass => "manageFiles_${index}_kept.!manageFiles_${index}_modified.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_islink_${index}";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} was successfully created"
				ifvarclass => "manageFiles_${index}_modified";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} could not be created"
				ifvarclass => "manageFiles_${index}_failed|manageFiles_${index}_kept.(manageFilesAndFolders_isdir_${index}|manageFilesAndFolders_islink_${index})";

			## Reporting for local cp
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} already exists and is up to date"
				ifvarclass => "manageCp_${index}_kept.!manageCp_${index}_modified.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_islink_${index}";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} was successfully copied from ${file[${index}][source]}"
				ifvarclass => "manageCp_${index}_modified";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][path]} could not be created"
				ifvarclass => "manageCp_${index}_failed|manageCp_${index}_kept.(manageFilesAndFolders_isdir_${index}|manageFilesAndFolders_islink_${index})";

			## Reporting for symlink creation
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][path]} already exists"
				ifvarclass => "manageSyms_${index}_kept.!manageSyms_${index}_modified";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][path]} was successfully created"
				ifvarclass => "manageSyms_${index}_modified";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][path]} could not be created"
				ifvarclass => "manageSyms_${index}_failed";

			## Reporting for no change
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#No file creation action specified for ${file[${index}][path]}"
                                ifvarclass => "manageFilesAndFolders_nocreate_${index}";
			
			# Reporting for the permissions
			## Success if not set
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} was not requested to have its permission enforced"
				ifvarclass => "!manageFilesAndFolders_check_permissions_${index}";

			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The permission of the item ${file[${index}][path]} were correct"
				ifvarclass => "manageFilesAndFolders_perms_${index}_kept.!manageFilesAndFolders_perms_${index}_modified";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The permissions of the item ${file[${index}][path]} have been corrected"
				ifvarclass => "manageFilesAndFolders_perms_${index}_modified.!manageFilesAndFolders_perms_${index}_failed";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The permissions of the item ${file[${index}][path]} could not be set"
				ifvarclass => "manageFilesAndFolders_perms_${index}_failed";


			"@@manageFilesAndFolders@@log_info@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} will be handled recursively"
				ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

			"@@manageFilesAndFolders@@log_warn@@${file[${index}][uuid]}@@Permissions@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} will NOT be handled recursively, because it is either a file or a symlink"
				ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

			# Reporting for the deletion
			## Report in the general component of the file
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#File cleaning was requested for ${file[${index}][path]}. Check specific reporting in the 'File cleaning options' component."
				ifvarclass => "manageFilesAndFolders_clean_${index}";
			## Success if not set
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File cleaning options@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} was not requested to be deleted"
				ifvarclass => "!manageFilesAndFolders_clean_${index}";

			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@File cleaning options@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} was in conformity with the deletion policy"
				ifvarclass => "manageFilesAndFolders_clean_${index}.!manageFilesAndFolders_delete_${index}_modified.!manageFilesAndFolders_delete_${index}_failed";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@File cleaning options@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} has been put in conformity with the deletion policy"
				ifvarclass => "manageFilesAndFolders_delete_${index}_modified";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@File cleaning options@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][path]} deletion policy could not be enforced"
				ifvarclass => "manageFilesAndFolders_delete_${index}_failed";

			# Reporting for post-command execution
			"@@manageFilesAndFolders@@result_success@@${file[${index}][uuid]}@@Post-modification hook@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#Post-execution hook did not need running"
				ifvarclass => "!manageFilesAndFolders_post_hook_run_${index}|((manageFiles_${index}_kept|manageFolders_${index}_kept|manageSyms_${index}_kept|manageFilesAndFolders_perms_${index}_kept).!(manageFiles_${index}_modified|manageFolders_${index}_modified|manageSyms_${index}_modified|manageFilesAndFolders_perms_${index}_modified))";

			"@@manageFilesAndFolders@@result_repaired@@${file[${index}][uuid]}@@Post-modification hook@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#Post-execution hook successfully run"
				ifvarclass => "manageFilesAndFolders_${index}_command_run_ok";

			"@@manageFilesAndFolders@@result_error@@${file[${index}][uuid]}@@Post-modification hook@@${file[${index}][path]}@@${g.execRun}##${g.uuid}@#An error occured when running the post-execution hook"
				ifvarclass => "manageFilesAndFolders_${index}_command_run_failed";

}
