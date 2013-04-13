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
      "file_count" int => readstringarrayidx("file","${sys.workdir}/inputs/fileManagement/2.0/manageFilesAndFoldersData", "#[^\n]*",":",9000,1600000);


&FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND:{cmd |      "file[&i0&][post_hook_command]" string => "&cmd&";
}&
&FILE_AND_FOLDER_MANAGEMENT_SYMLINK_SOURCE:{symsrc |      "file[&i0&][symlink_source]" string => "&symsrc&";
}&
&FILE_AND_FOLDER_DELETION_PATTERN:{pattern |      "file[&i0&][pattern]" string => "&pattern&";
}&


		"index" slist => getindices("file");

	classes:

		# Set a class to define when we need to run the post-modification hook
		&FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN:{run |"manageFilesAndFolders_post_hook_run_&i0&" expression => strcmp("&run&", "true");
}&

		&FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS:{perms |"manageFilesAndFolders_check_permissions_&i0&" expression => strcmp("&perms&", "true");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{nocreate | "manageFilesAndFolders_nocreate_&i0&" expression => strcmp("&nocreate&", "none");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createfile | "manageFilesAndFolders_createfile_&i0&" expression => strcmp("&createfile&", "file");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createdir | "manageFilesAndFolders_createdir_&i0&" expression => strcmp("&createdir&", "dir");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{createsymlink | "manageFilesAndFolders_createsymlink_&i0&" expression => strcmp("&createsymlink&", "symlink");
}&
		&FILE_AND_FOLDER_MANAGEMENT_ACTION:{clean | "manageFilesAndFolders_clean_&i0&" expression => strcmp("&clean&", "clean");
}&
		&FILE_AND_FOLDER_MANAGEMENT_RECURSIVE:{isrecursive | "manageFilesAndFolders_isrecursive_&i0&" expression => strcmp("&isrecursive&", "inf");
}&
		&FILE_AND_FOLDER_MANAGEMENT_OWNER:{userset | "manageFilesAndFolders_userset_&i0&" expression => strcmp("&userset&", "$(file[&i0&][2])");
}&
		&FILE_AND_FOLDER_MANAGEMENT_GROUP:{groupset | "manageFilesAndFolders_groupset_&i0&" expression => strcmp("&groupset&", "$(file[&i0&][3])");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_simple_&i0&" expression => strcmp("&delopt&", "none");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_single_recursive_&i0&" expression => strcmp("&delopt&", "single");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_full_recursive_&i0&" expression => strcmp("&delopt&", "full");
}&
		&FILE_AND_FOLDER_DELETION_OPTION:{delopt | "manageFilesAndFolders_deletion_exterminate_&i0&" expression => strcmp("&delopt&", "exterminate");
}&
		"manageFilesAndFolders_isdir_$(index)" expression => isdir("$(file[$(index)][0])");
		"manageFilesAndFolders_isfile_$(index)" expression => isplain("$(file[$(index)][0])");
		"manageFilesAndFolders_islink_$(index)" expression => islink("$(file[$(index)][0])");
 
	files:

    # Directory
      "${file[${index}][0]}/."
        create => "true",
        classes => kept_if_else("manageFolders_${index}_kept", "manageFolders_${index}_modified", "manageFolders_${index}_failed"),
        comment => "Enforcing the existance of folder ${file[${index}][0]}",
        ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createfile_${index}.manageFilesAndFolders_createdir_${index}).!manageFilesAndFolders_createsymlink_${index}";

    # File
      "${file[${index}][0]}"
        create => "true",
        classes => kept_if_else("manageFiles_${index}_kept", "manageFiles_${index}_modified", "manageFiles_${index}_failed"),
        comment => "Enforcing the existance of file ${file[${index}][0]}",
        ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_createfile_${index}).!manageFilesAndFolders_createsymlink_${index}";

    # Symlink
      "${file[${index}][0]}"
      # create => "true",
        link_from => ln_s("${file[${index}][symlink_source]}"),
        move_obstructions => "${file[${index}][4]}",
        classes => kept_if_else("manageSyms_${index}_kept", "manageSyms_${index}_modified", "manageSyms_${index}_failed"),
        ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.!manageFilesAndFolders_createfile_${index}).manageFilesAndFolders_createsymlink_${index}",
        comment => "Create the ${file[${index}][0]} symlink pointing to ${file[${index}][symlink_source]}";

		# Check the permissions none recursively
   ## With user and group
      "${file[${index}][0]}"
        perms => mog("${file[${index}][1]}", "${file[${index}][2]}", "${file[${index}][3]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}";
    ## With user
      "${file[${index}][0]}"
        perms => mo("${file[${index}][1]}", "${file[${index}][2]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}";
    ## With group
      "${file[${index}][0]}"
        perms => mg("${file[${index}][1]}", "${file[${index}][3]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}";
    # Check the permissions recursively
    ## With user and group
      "${file[${index}][0]}"
        depth_search => recurse_withroot("${file[${index}][5]}"),
        perms => mog("${file[${index}][1]}", "${file[${index}][2]}", "${file[${index}][3]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}";
    ## With user
      "${file[${index}][0]}"
        depth_search => recurse_withroot("${file[${index}][5]}"),
        perms => mo("${file[${index}][1]}", "${file[${index}][2]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}";
    ## With group
      "${file[${index}][0]}"
        depth_search => recurse_withroot("${file[${index}][5]}"),
        perms => mg("${file[${index}][1]}", "${file[${index}][3]}"),
        classes => kept_if_else("manageFilesAndFolders_perms_${index}_kept", "manageFilesAndFolders_perms_${index}_modified", "manageFilesAndFolders_perms_${index}_failed"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}";

    # This will not delete the parent
      "${file[${index}][0]}"
        delete => tidy,
        file_select => date_pattern("${file[${index}][6]}", "${file[${index}][pattern]}"),
        ifvarclass => "manageFilesAndFolders_clean_${index}.manageFilesAndFolders_deletion_single_recursive_${index}",
        depth_search => recurse("0"),
        classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

    # This will not delete the parent
      "${file[${index}][0]}"
        delete => tidy,
        file_select => date_pattern("${file[${index}][6]}", "${file[${index}][pattern]}"),
        depth_search => recurse("inf"),
        ifvarclass => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_full_recursive_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
        classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

    # This WILL delete the parent
      "${file[${index}][0]}"
        delete => tidy,
        file_select => date_pattern("${file[${index}][6]}", "${file[${index}][pattern]}"),
        ifvarclass => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_simple_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
        classes => kept_if_else("manageFilesAndFolders_delete_${index}_kept", "manageFilesAndFolders_delete_${index}_modified", "manageFilesAndFolders_delete_${index}_failed");

	commands:
      "${file[${index}][post_hook_command]}"
        classes => if_else("manageFilesAndFolders_${index}_command_run_ok", "manageFilesAndFolders_${index}_command_run_failed"),
        contain => in_shell,
        ifvarclass => "manageFilesAndFolders_post_hook_run_${index}.(manageFiles_${index}_modified|manageFolders_${index}_modified|manageSyms_${index}_modified|manageFilesAndFolders_perms_${index}_modified)";

	reports:

        (linux|windows)::

      # Reporting for creation
      ## Reporting for directory creation
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][0]} already exists"
        ifvarclass => "manageFolders_${index}_kept.!manageFolders_${index}_modified.manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_islink_${index}";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][0]} was successfully created"
        ifvarclass => "manageFolders_${index}_modified";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The folder ${file[${index}][0]} could not be created"
        ifvarclass => "manageFolders_${index}_failed|manageFolders_${index}_kept.(manageFilesAndFolders_isfile_${index}|manageFilesAndFolders_islink_${index})";

      ## Reporting for file creation
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][0]} already exists"
        ifvarclass => "manageFiles_${index}_kept.!manageFiles_${index}_modified.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_islink_${index}";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][0]} was successfully created"
        ifvarclass => "manageFiles_${index}_modified";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The file ${file[${index}][0]} could not be created"
        ifvarclass => "manageFiles_${index}_failed|manageFiles_${index}_kept.(manageFilesAndFolders_isdir_${index}|manageFilesAndFolders_islink_${index})";

      ## Reporting for symlink creation
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][0]} already exists"
        ifvarclass => "manageSyms_${index}_kept.!manageSyms_${index}_modified";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][0]} was successfully created"
        ifvarclass => "manageSyms_${index}_modified";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The symlink ${file[${index}][0]} could not be created"
        ifvarclass => "manageSyms_${index}_failed";

      ## Reporting for no change
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#No file creation action specified for ${file[${index}][0]}"
        ifvarclass => "manageFilesAndFolders_nocreate_${index}";
      
      # Reporting for the permissions
      ## Success if not set
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} was not requested to have its permission enforced"
        ifvarclass => "!manageFilesAndFolders_check_permissions_${index}";

      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The permission of the item ${file[${index}][0]} were correct"
        ifvarclass => "manageFilesAndFolders_perms_${index}_kept.!manageFilesAndFolders_perms_${index}_modified";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The permissions of the item ${file[${index}][0]} have been corrected"
        ifvarclass => "manageFilesAndFolders_perms_${index}_modified.!manageFilesAndFolders_perms_${index}_failed";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The permissions of the item ${file[${index}][0]} could not be set"
        ifvarclass => "manageFilesAndFolders_perms_${index}_failed";


      "@@manageFilesAndFolders@@log_info@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} will be handled recursively"
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

      "@@manageFilesAndFolders@@log_warn@@${file[${index}][7]}@@Permissions@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} will NOT be handled recursively, because it is either a file or a symlink"
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

      # Reporting for the deletion
      ## Report in the general component of the file
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#File cleaning was requested for ${file[${index}][0]}. Check specific reporting in the 'File cleaning options' component."
        ifvarclass => "manageFilesAndFolders_clean_${index}";
      ## Success if not set
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File cleaning options@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} was not requested to be deleted"
        ifvarclass => "!manageFilesAndFolders_clean_${index}";

      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@File cleaning options@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} was in conformity with the deletion policy"
        ifvarclass => "manageFilesAndFolders_clean_${index}.!manageFilesAndFolders_delete_${index}_modified.!manageFilesAndFolders_delete_${index}_failed";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@File cleaning options@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} has been put in conformity with the deletion policy"
        ifvarclass => "manageFilesAndFolders_delete_${index}_modified";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@File cleaning options@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#The item ${file[${index}][0]} deletion policy could not be enforced"
        ifvarclass => "manageFilesAndFolders_delete_${index}_failed";

      # Reporting for post-command execution
      "@@manageFilesAndFolders@@result_success@@${file[${index}][7]}@@Post-modification hook@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#Post-execution hook did not need running"
        ifvarclass => "!manageFilesAndFolders_post_hook_run_${index}|((manageFiles_${index}_kept|manageFolders_${index}_kept|manageSyms_${index}_kept|manageFilesAndFolders_perms_${index}_kept).!(manageFiles_${index}_modified|manageFolders_${index}_modified|manageSyms_${index}_modified|manageFilesAndFolders_perms_${index}_modified))";

      "@@manageFilesAndFolders@@result_repaired@@${file[${index}][7]}@@Post-modification hook@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#Post-execution hook successfully run"
        ifvarclass => "manageFilesAndFolders_${index}_command_run_ok";

      "@@manageFilesAndFolders@@result_error@@${file[${index}][7]}@@Post-modification hook@@${file[${index}][0]}@@${g.execRun}##${g.uuid}@#An error occured when running the post-execution hook"
        ifvarclass => "manageFilesAndFolders_${index}_command_run_failed";

}
