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

bundle agent manageFilesAndFolders_RudderUniqueID {

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

      "manageFilesAndFolders_exists_${index}" expression => fileexists("${file[${index}][path]}");
      "manageFilesAndFolders_isdir_${index}" expression => isdir("${file[${index}][path]}");
      "manageFilesAndFolders_isfile_${index}" expression => isplain("${file[${index}][path]}");
      "manageFilesAndFolders_islink_${index}" expression => islink("${file[${index}][path]}");

      "iteration_2" expression => "iteration_1";
      "iteration_1" expression => "any";
 
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
      iteration_2::

    # Directory
    "${file[${index}][path]}/."
      create     => "true",
      classes    => rudder_common_classes("manageFolders_${index}_RudderUniqueID"),
      comment    => "Enforcing the existance of folder ${file[${index}][path]}",
      ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createfile_${index}.manageFilesAndFolders_createdir_${index}).!manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}";

    # File
    "${file[${index}][path]}"
      create     => "true",
      classes    => rudder_common_classes("manageFiles_${index}_RudderUniqueID"),
      comment    => "Enforcing the existance of file ${file[${index}][path]}",
      ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_createfile_${index}).!manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}";

    # Local copy
    "${file[${index}][path]}"
      copy_from  => backup_local_cp("${file[${index}][source]}"),
      classes    => rudder_common_classes("manageCp_${index}_RudderUniqueID"),
      ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.!manageFilesAndFolders_createfile_${index}).manageFilesAndFolders_local_cp_${index}.!manageFilesAndFolders_createsymlink_${index}",
      comment    => "Create ${file[${index}][path]} file as copy of ${file[${index}][source]}";

    # Symlink
    "${file[${index}][path]}"
      # create   => "true",
      link_from  => ln_s("${file[${index}][source]}"),
      move_obstructions => "${file[${index}][symlink_enforced]}",
      classes    => rudder_common_classes("manageSyms_${index}_RudderUniqueID"),
      ifvarclass => "(!manageFilesAndFolders_nocreate_${index}.!manageFilesAndFolders_createdir_${index}.!manageFilesAndFolders_createfile_${index}).!manageFilesAndFolders_local_cp_${index}.manageFilesAndFolders_createsymlink_${index}",
      comment    => "Create the ${file[${index}][path]} symlink pointing to ${file[${index}][source]}";

    # Check the permissions none recursively
    ## With user and group
    "${file[${index}][path]}"
      perms      => mog("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}", "${file[${index}][group]}"),
      classes    => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}";
    ## With user
    "${file[${index}][path]}"
      perms      => mo("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}"),
      classes    => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}";
    ## With group
    "${file[${index}][path]}"
      perms      => mg("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][group]}"),
      classes    => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}";
    # Check the permissions recursively on a folder
    ## With user and group
    "${file[${index}][path]}"
      depth_search => recurse_withroot("${file[${index}][recursive]}"),
      perms        => mog("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}", "${file[${index}][group]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_isfile_${index}.manageFilesAndFolders_isdir_${index}";
    ## With user
    "${file[${index}][path]}"
      depth_search => recurse_withroot("${file[${index}][recursive]}"),
      perms        => mo("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_isfile_${index}.manageFilesAndFolders_isdir_${index}";
    ## With group
    "${file[${index}][path]}"
      depth_search => recurse_withroot("${file[${index}][recursive]}"),
      perms        => mg("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][group]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_isfile_${index}.manageFilesAndFolders_isdir_${index}";
    # Check the permissions recursively on a file
    # Occurs when the recursive option is set, but in fact, we force a non recursive check due to an issue which prevents the check of a single file when using a recursive pattern.
    ## With user and group
    "${file[${index}][path]}"
      perms        => mog("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}", "${file[${index}][group]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.manageFilesAndFolders_groupset_${index}.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}";
    ## With user
    "${file[${index}][path]}"
      perms        => mo("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][owner]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_isfile_${index}.manageFilesAndFolders_isdir_${index}";
    ## With group
    "${file[${index}][path]}"
      perms        => mg("${extended_modes_${index}}${file[${index}][mode]}", "${file[${index}][group]}"),
      classes      => rudder_common_classes("manageFilesAndFolders_perms_${index}_RudderUniqueID"),
      ifvarclass   => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_isrecursive_${index}.manageFilesAndFolders_groupset_${index}.!manageFilesAndFolders_userset_${index}.!manageFilesAndFolders_isfile_${index}.manageFilesAndFolders_isdir_${index}";

    # This will not delete the parent
    "${file[${index}][path]}" 
      delete       => tidy,
      file_select  => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
      ifvarclass   => "manageFilesAndFolders_clean_${index}.manageFilesAndFolders_deletion_single_recursive_${index}",
      depth_search => recurse("0"),
      classes      => rudder_common_classes("manageFilesAndFolders_delete_${index}_RudderUniqueID");

    # This will not delete the parent
    "${file[${index}][path]}" 
      delete       => tidy,
      file_select  => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
      depth_search => recurse("inf"),
      ifvarclass   => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_full_recursive_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
      classes      => rudder_common_classes("manageFilesAndFolders_delete_${index}_RudderUniqueID");

    # This WILL delete the parent
    "${file[${index}][path]}" 
      delete       => tidy,
      file_select  => date_pattern("${file[${index}][ttl]}", "${file[${index}][pattern]}"),
      ifvarclass   => "manageFilesAndFolders_clean_${index}.(manageFilesAndFolders_deletion_simple_${index}|manageFilesAndFolders_deletion_exterminate_${index})",
      classes      => rudder_common_classes("manageFilesAndFolders_delete_${index}_RudderUniqueID");

  methods:

    pass3::

      # Reporting for creation
      ## Reporting for directory creation
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The folder ${file[${index}][path]} already exists", "${index}"),
        ifvarclass => "manageFolders_${index}_RudderUniqueID_kept.!manageFolders_${index}_RudderUniqueID_repaired.manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_islink_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The folder ${file[${index}][path]} was successfully created", "${index}"),
        ifvarclass => "manageFolders_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The folder ${file[${index}][path]} could not be created", "${index}"),
        ifvarclass => "manageFolders_${index}_RudderUniqueID_error|manageFolders_${index}_RudderUniqueID_kept.(manageFilesAndFolders_isfile_${index}|manageFilesAndFolders_islink_${index})"; # if we ask for folder creation, promise is kept, but it's a file, then it's a failure

      ## Reporting for file creation
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} already exists", "${index}"),
        ifvarclass => "manageFiles_${index}_RudderUniqueID_kept.!manageFiles_${index}_RudderUniqueID_repaired.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_islink_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} was successfully created", "${index}"),
        ifvarclass => "manageFiles_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} could not be created", "${index}"),
        ifvarclass => "manageFiles_${index}_RudderUniqueID_error|manageFiles_${index}_RudderUniqueID_kept.(manageFilesAndFolders_isdir_${index}|manageFilesAndFolders_islink_${index})";

      ## Reporting for local cp
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} already exists and is up to date", "${index}"),
        ifvarclass => "manageCp_${index}_RudderUniqueID_kept.!manageCp_${index}_RudderUniqueID_repaired.manageFilesAndFolders_isfile_${index}.!manageFilesAndFolders_isdir_${index}.!manageFilesAndFolders_islink_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} was successfully copied from ${file[${index}][source]}", "${index}"),
        ifvarclass => "manageCp_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The file ${file[${index}][path]} could not be created", "${index}"),
        ifvarclass => "manageCp_${index}_RudderUniqueID_error|manageCp_${index}_RudderUniqueID_kept.(manageFilesAndFolders_isdir_${index}|manageFilesAndFolders_islink_${index})";

      ## Reporting for symlink creation
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The symlink ${file[${index}][path]} already exists", "${index}"),
        ifvarclass => "manageSyms_${index}_RudderUniqueID_kept.!manageSyms_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The symlink ${file[${index}][path]} was successfully created", "${index}"),
        ifvarclass => "manageSyms_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "The symlink ${file[${index}][path]} could not be created", "${index}"),
        ifvarclass => "manageSyms_${index}_RudderUniqueID_error";

      ## Reporting for no change
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "No file creation action specified for ${file[${index}][path]}", "${index}"),
                                ifvarclass => "manageFilesAndFolders_nocreate_${index}";
      
      ### Reporting for the permissions
      ## Special cases
      # NA if no perms check setted
      # NA if the target does not exists and no creation setted
      # Error if no result permissions classes are defined (ie no check were executed, most likely on an unknown path without creation asked) AND no NA conditions already fulfilled
      ## Basic cases
      # Success if a kept class is defined
      # Repaired if a repaired class is defined
      # Error if an error class is defined

      ## NA if not set
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_na", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The item ${file[${index}][path]} was not requested to have its permission enforced", "${index}"),
        ifvarclass => "!manageFilesAndFolders_check_permissions_${index}";

      ## NA if the path does not exist, no creation rules setted and permissions check set to true
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_na", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The item ${file[${index}][path]} was not found but not requested to be created", "${index}"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_exists_${index}.manageFilesAndFolders_nocreate_${index}";

      ## Error if we are not in NA and there is no class defined or NA conditions verified (see above)
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The item ${file[${index}][path]} was not found", "${index}"),
        ifvarclass => "(manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_perms_${index}_RudderUniqueID_ok.!manageFilesAndFolders_perms_${index}_RudderUniqueID_not_ok).!(manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_exists_${index}.manageFilesAndFolders_nocreate_${index})";

      ## Basic permissions reports
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The permission of the item ${file[${index}][path]} were correct", "${index}"),
        ifvarclass => "manageFilesAndFolders_perms_${index}_RudderUniqueID_kept.!manageFilesAndFolders_perms_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The permissions of the item ${file[${index}][path]} have been corrected", "${index}"),
        ifvarclass => "manageFilesAndFolders_perms_${index}_RudderUniqueID_repaired.!manageFilesAndFolders_perms_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The permissions of the item ${file[${index}][path]} could not be set", "${index}"),
        ifvarclass => "manageFilesAndFolders_perms_${index}_RudderUniqueID_error";


      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "log_info", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The item ${file[${index}][path]} will be handled recursively", "${index}"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "log_warn", "${file[${index}][uuid]}", "Permissions", "${file[${index}][path]}", "The item ${file[${index}][path]} will NOT be handled recursively, because it is either a file or a symlink", "${index}"),
        ifvarclass => "manageFilesAndFolders_check_permissions_${index}.!manageFilesAndFolders_createdir_${index}.manageFilesAndFolders_recursive_${index}";

      # Reporting for the deletion
      ## Report in the general component of the file
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File", "${file[${index}][path]}", "File cleaning was requested for ${file[${index}][path]}. Check specific reporting in the 'File cleaning options' component.", "${index}"),
        ifvarclass => "manageFilesAndFolders_clean_${index}";
      ## N/A if not set
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_na", "${file[${index}][uuid]}", "File cleaning options", "${file[${index}][path]}", "The item ${file[${index}][path]} was not requested to be deleted", "${index}"),
        ifvarclass => "!manageFilesAndFolders_clean_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "File cleaning options", "${file[${index}][path]}", "The item ${file[${index}][path]} was in conformity with the deletion policy", "${index}"),
        ifvarclass => "manageFilesAndFolders_clean_${index}.!manageFilesAndFolders_delete_${index}_RudderUniqueID_repaired.!manageFilesAndFolders_delete_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "File cleaning options", "${file[${index}][path]}", "The item ${file[${index}][path]} has been put in conformity with the deletion policy", "${index}"),
        ifvarclass => "manageFilesAndFolders_delete_${index}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "File cleaning options", "${file[${index}][path]}", "The item ${file[${index}][path]} deletion policy could not be enforced", "${index}"),
        ifvarclass => "manageFilesAndFolders_delete_${index}_RudderUniqueID_error";

      # Reporting for post-command execution
      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_na", "${file[${index}][uuid]}", "Post-modification hook", "${file[${index}][path]}", "No post-execution hook set to run", "${index}"),
           ifvarclass => "!manageFilesAndFolders_post_hook_run_${index}";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_success", "${file[${index}][uuid]}", "Post-modification hook", "${file[${index}][path]}", "Post-execution hook did not need running", "${index}"),
           ifvarclass => "manageFilesAndFolders_post_hook_run_${index}.!(manageFilesAndFolders_delete_${index}_RudderUniqueID_repaired|manageFilesAndFolders_perms_${index}_RudderUniqueID_repaired|manageFolders_${index}_RudderUniqueID_repaired|manageFiles_${index}_RudderUniqueID_repaired|manageCp_${index}_RudderUniqueID_repaired|manageSyms_${index}_RudderUniqueID_repaired)";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_repaired", "${file[${index}][uuid]}", "Post-modification hook", "${file[${index}][path]}", "Post-execution hook successfully run", "${index}"),
           ifvarclass => "manageFilesAndFolders_${index}_RudderUniqueID_command_run_ok";

      "any" usebundle => rudder_common_report_index("manageFilesAndFolders", "result_error", "${file[${index}][uuid]}", "Post-modification hook", "${file[${index}][path]}", "An error occured when running the post-execution hook", "${index}"),
        ifvarclass => "manageFilesAndFolders_${index}_RudderUniqueID_command_run_failed";

  commands:
    pass2::
    "${file[${index}][post_hook_command]}"
      classes => if_else("manageFilesAndFolders_${index}_RudderUniqueID_command_run_ok", "manageFilesAndFolders_${index}_RudderUniqueID_command_run_failed"),
      contain => in_shell,
      ifvarclass => "manageFilesAndFolders_post_hook_run_${index}.(manageFilesAndFolders_delete_${index}_RudderUniqueID_repaired|manageFilesAndFolders_perms_${index}_RudderUniqueID_repaired|manageFolders_${index}_RudderUniqueID_repaired|manageFiles_${index}_RudderUniqueID_repaired|manageCp_${index}_RudderUniqueID_repaired|manageSyms_${index}_RudderUniqueID_repaired)";

}
