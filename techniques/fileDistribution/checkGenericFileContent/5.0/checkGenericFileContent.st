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
# Checks if a file matches a given content. If not, updates it. #
#################################################################

bundle agent check_generic_file_content {

        vars:

		tier1::

	                &GENERIC_FILE_CONTENT_PATH:{path |"generic_file_content_path[&i&]" string => "&path&";
}&

	                &GENERIC_FILE_CONTENT_OWNER:{owner |"generic_file_content_owner[&i&]" string => "&owner&";
}&

        	        &GENERIC_FILE_CONTENT_GROUP:{group |"generic_file_content_group[&i&]" string => "&group&";
}&

                	&GENERIC_FILE_CONTENT_PERM:{perms |"generic_file_content_perms[&i&]" string => "&perms&";
}&

# Because the stupid StringTemplate systems passes the indentation as-is inside the generated variable
&GENERIC_FILE_CONTENT_PAYLOAD:{payload |"generic_file_content_payload[&i&]" string => "&payload&";
}&

			&GENERIC_FILE_CONTENT_ENFORCE:{enforce |"generic_file_content_enforced[&i&]" string => "&enforce&";
}&
			&GENERIC_FILE_CONTENT_POST_HOOK_COMMAND:{command |"generic_file_content_posthook[&i&]" string => "&command&";
}&
			&GENERIC_FILE_CONTENT_DELETION_REGEXP:{delreg |"generic_file_content_deletion_regexp[&i&]" string => "&delreg&";
}&
			&GENERIC_FILE_CONTENT_MODIFICATION_REGEXP:{delreg |"generic_file_content_modification_regexp[&i&]" string => "&delreg&";
}&
			&GENERIC_FILE_CONTENT_MODIFICATION_DESTINATION:{destination |"generic_file_content_modification_destination[&i&]" string => "&destination&";
}&
      &GENERIC_FILE_SECTION_HEADER:{header |"generic_file_content_section_header[&i&]" string => "&header&";
}&
# Since content is multiline, it is not indented to prevent spurious space from being inserted within
&GENERIC_FILE_SECTION_CONTENT:{content |"generic_file_content_section_content[&i&]" string => "&content&";
}&
      &GENERIC_FILE_SECTION_FOOTER:{footer |"generic_file_content_section_footer[&i&]" string => "&footer&";
}&
	                &TRACKINGKEY:{piuuid |"generic_file_content_uuid[&i&]" string => "&piuuid&";
}&

      # Since classes of a bundle are not visible to the bundle edit_line, we need to define variable
      # and check their values in the bundle_edit_line
      &GENERIC_FILE_CONTENT_DELETION_BOOLEAN:{deletion | "generic_file_content_deletion_boolean[&i&]" string => "&deletion&";
}&
      &GENERIC_FILE_CONTENT_MODIFICATION_BOOLEAN:{modification |"generic_file_content_modification_boolean[&i&]" string => "&modification&";
}&
      &GENERIC_FILE_CONTENT_SECTION_MANAGEMENT:{enforce_section |"generic_file_content_section_boolean[&i&]" string => "&enforce_section&";
}&


			"index" slist => getindices("generic_file_content_path");

			"file_edit_go" string => "go";

                        # When we define the file to be checked only at creation, it means that we want to create it
&GENERIC_FILE_CONTENT_CREATE_BOOLEAN:{createfile |    tier1.!enforce_at_creation_only_&i&::
      "generic_file_content_creation[&i&]" string => "&createfile&";
}&
&GENERIC_FILE_CONTENT_CREATE_BOOLEAN:{createfile |    tier1.enforce_at_creation_only_&i&::
    "generic_file_content_creation[&i&]" string => "true";
}&

classes:

			# Set a class to define when we need to run the post-modification hook
			&GENERIC_FILE_CONTENT_POST_HOOK_RUN:{run |"execute_command_&i&" expression => strcmp("&run&", "true");
}&
			&GENERIC_FILE_CONTENT_PERMISSION_ADJUSTMENT:{adjust |"adjust_permissions_&i&" expression => strcmp("&adjust&", "true");
}&
			&GENERIC_FILE_CONTENT_DELETION_BOOLEAN:{deletion |"delete_lines_&i&" expression => strcmp("&deletion&", "true");
}&
			&GENERIC_FILE_CONTENT_MODIFICATION_BOOLEAN:{modification |"modify_lines_&i&" expression => strcmp("&modification&", "true");
}&
      &GENERIC_FILE_CONTENT_ENFORCE_CREATE_ONLY_BOOLEAN:{enforce_at_creation_only |"enforce_at_creation_only_&i&" expression => strcmp("&enforce_at_creation_only&", "true");
}&

      &GENERIC_FILE_CONTENT_SECTION_MANAGEMENT:{enforce_section |"enforce_section_&i&" expression => strcmp("&enforce_section&", "true");
}&
      "edit_section_valid_${index}" and => { isvariable("generic_file_content_section_header[${index}]"), isvariable("generic_file_content_section_footer[${index}]") } ;

      "file_doesnt_exist_${index}"                       not => fileexists("$(generic_file_content_path[$(index)])");
      "creation_only_but_already_exists_${index}" expression => "enforce_at_creation_only_${index}.!file_doesnt_exist_${index}";


      # Workaround for #3014: no value = empty value
      # In some conditions, the value of replacement is
      # considerered as null instead of empty.
      # This class will ensure that no variable (=null) will be considered
      # as an empty variable.
      "generic_file_content_modification_destination_defined_$(index)" expression => isvariable("generic_file_content_modification_destination[$(index)]");
      # Check that value has been set before to edit the file
      "edit_content_$(index)" expression => isvariable("generic_file_content_payload[$(index)]");

      "tier1" expression => "any";

      "tier2" expression => isvariable("file_edit_go");

  files:
    tier2::
      # Edit the file
      # Defines classes for the file edition globaly, as it can be globally kept even if part are modified
      # (for instance, section edition have a global status kept, but several repaired status)
      "$(generic_file_content_path[$(index)])"
        edit_line => check_generic_file_content_edition(
            "$(generic_file_content_payload[$(index)])", "$(generic_file_content_enforced[$(index)])",
            "$(generic_file_content_deletion_regexp[$(index)])", "$(generic_file_content_deletion_boolean[$(index)])",
            "$(generic_file_content_modification_regexp[$(index)])", "$(generic_file_content_modification_destination[$(index)])", "$(generic_file_content_modification_boolean[$(index)])",
            "${generic_file_content_section_header[${index}]}", "${generic_file_content_section_footer[${index}]}", "${generic_file_content_section_content[${index}]}", "${generic_file_content_section_boolean[${index}]}",
            "${index}"
        ),
        create => "$(generic_file_content_creation[$(index)])",
        edit_defaults => rudder_empty_select("$(generic_file_content_enforced[$(index)])"),
        ifvarclass => "!creation_only_but_already_exists_${index}",
        classes => kept_if_else("file_edition_global_files_status_$(index)_kept", "file_edition_global_files_status_$(index)_repaired", "file_edition_global_files_status_$(index)_failed"),
        comment => "Editing $(generic_file_content_path[$(index)])...";

      "$(generic_file_content_path[$(index)])"
        create => "$(generic_file_content_creation[$(index)])",
        perms => mog("$(generic_file_content_perms[$(index)])", "$(generic_file_content_owner[$(index)])", "$(generic_file_content_group[$(index)])"),
        classes => kept_if_else("perms_$(index)_kept", "perms_$(index)_modified", "perms_$(index)_failed"),
        ifvarclass => "adjust_permissions_$(index).!creation_only_but_already_exists_${index}",
        comment => "Setting $(generic_file_content_path[$(index)]) permissions...";

  commands:
    tier2::
      "$(generic_file_content_posthook[$(index)])"
        classes => if_else("generic_file_content_posthook_$(index)_command_run_ok", "generic_file_content_posthook_$(index)_command_run_failed"),
        contain => in_shell,
        ifvarclass => "execute_command_$(index).file_edition_global_files_status_$(index)_repaired";

  reports:
    tier2::
    # Files edition
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the policy"
        ifvarclass => "edit_content_$(index).((content_$(index)_kept.!content_$(index)_modified)|(file_edition_global_files_status_${index}_kept.!file_edition_global_files_status_${index}_repaired))";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated"
        ifvarclass => "content_$(index)_modified.file_edition_global_files_status_${index}_repaired";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) could not be updated"
        ifvarclass => "content_$(index)_failed";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#No content was given to check file $(generic_file_content_path[$(index)]), skipping"
        ifvarclass => "!edit_content_$(index)";

      # Files edition - deletion
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was not set for any line deletion"
        ifvarclass => "!delete_lines_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the deletion policy"
        ifvarclass => "delete_lines_$(index).((content_deletion_kept_$(index).!content_deletion_modified_$(index).!content_deletion_failed_$(index))|(file_edition_global_files_status_${index}_kept.!file_edition_global_files_status_${index}_repaired))";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated using the deletion policy"
        ifvarclass => "content_deletion_modified_$(index).file_edition_global_files_status_${index}_repaired";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) could not be updated using the deletion policy"
        ifvarclass => "content_deletion_failed_$(index)";

      # Files edition - replacement
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line replacement regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was not set for any line replacement"
        ifvarclass => "!modify_lines_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line replacement regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the replacement policy"
        ifvarclass => "content_modification_kept_$(index).!content_modification_modified_$(index).!content_modification_failed_$(index)";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@Line replacement regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated using the replacement policy"
        ifvarclass => "content_modification_modified_$(index)";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@Line replacement regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) could not be updated using the replacement policy"
        ifvarclass => "content_modification_failed_$(index)";

      # File edition - enforce only at creation
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) already exists, skipping content editing"
        ifvarclass => "edit_content_$(index).creation_only_but_already_exists_${index}";

      # Permissions edition
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Permission adjustment@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) uses default permissions"
        ifvarclass => "!adjust_permissions_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Permission adjustment@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) permissions are OK"
        ifvarclass => "perms_$(index)_kept";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@Permission adjustment@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) permissions were adjusted"
        ifvarclass => "perms_$(index)_modified";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@Permission adjustment@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) permissions could not be adjusted"
        ifvarclass => "perms_$(index)_failed";

      # Permissions edition - enforce only at creation
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Permission adjustment@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already existing, skipping permission checking"
        ifvarclass => "adjust_permissions_$(index).creation_only_but_already_exists_${index}";

      #Section edition
      "@@checkGenericFileContent@@result_success@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} was not set for section edition, skipping"
        ifvarclass => "!enforce_section_${index}";

      "@@checkGenericFileContent@@result_error@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} was set for section edition, but no header or footer was defined"
        ifvarclass => "enforce_section_${index}.!edit_section_valid_${index}";

      "@@checkGenericFileContent@@result_success@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} already exists, skipping section edition"
        ifvarclass => "enforce_section_${index}.creation_only_but_already_exists_${index}";

      "@@checkGenericFileContent@@result_success@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} was already in accordance with the section content policy"
        ifvarclass => "enforce_section_${index}.((section_content_modification_kept_${index}.!section_content_modification_modified_${index})|(file_edition_global_files_status_${index}_kept.!file_edition_global_files_status_${index}_repaired))";

      "@@checkGenericFileContent@@result_repaired@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} was successfully updated using the section content policy"
        ifvarclass => "section_content_modification_modified_${index}.!section_content_modification_failed_${index}.file_edition_global_files_status_${index}_repaired";

      "@@checkGenericFileContent@@result_error@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} could not be updated using the section content policy"
        ifvarclass => "section_content_modification_failed_${index}";



      # Posthook report
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#No command for $(generic_file_content_path[$(index)]) was to be executed"
        ifvarclass => "!execute_command_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#$(generic_file_content_path[$(index)]) was in the proper state, so no command to execute"
        ifvarclass => "execute_command_$(index).file_edition_global_files_status_${index}_kept.!file_edition_global_files_status_${index}_repaired";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) was correctly executed"
        ifvarclass => "generic_file_content_posthook_$(index)_command_run_ok";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) could not to be executed"
        ifvarclass => "generic_file_content_posthook_$(index)_command_run_failed";

      "@@checkGenericFileContent@@result_success@@${generic_file_content_uuid[${index}]}@@Post-modification hook@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#${generic_file_content_path[${index}]} already exists, skipping command execution"
        ifvarclass => "execute_command_${index}.creation_only_but_already_exists_${index}";

}


# The file edition should be unitary made in this bundle
bundle edit_line check_generic_file_content_edition(
    content, enforce_content_boolean,
    deletion_regex, deletion_boolean, 
    modification_regex, modification_replacement, modification_boolean, 
    section_start, section_end, section_content, section_boolean,
    index # For the reporting
    )
{

  vars:
  # define all the information for the section edition
      "csection"              string => canonify("${section_start}");
      "escaped_section_start" string => escape(${section_start});
      "escaped_section_end"   string => escape(${section_end});


  # define the classes that will define which edition we are to do
  classes:
      "preserve_content" expression => strcmp("true", "$(enforce_content_boolean)");

      # when need to check the validity of the content on the original value, otherwise local context is always true
      "edit_content" expression => isvariable("check_generic_file_content.generic_file_content_payload[$(index)]");
      "delete_lines" expression => strcmp("${deletion_boolean}", "true");

      "replace_lines" expression => strcmp("${modification_boolean}", "true");
      "replace_lines_destination_defined" expression => isvariable("check_generic_file_content.generic_file_content_modification_destination[$(index)]");

      "section_edition" expression => strcmp("${section_boolean}", "true");

      "edit_section_valid" and => { isvariable("check_generic_file_content.generic_file_content_section_header[${index}]"), isvariable("check_generic_file_content.generic_file_content_section_footer[${index}]") } ;

      # Detect if section is already there
      "has_$(csection)" expression => regline("${escaped_section_start}", "$(edit.filename)");


  delete_lines:
    delete_lines::
      "${deletion_regex}"
        classes => kept_if_else("content_deletion_kept_${index}", "content_deletion_modified_${index}", "content_deletion_failed_${index}"),
        comment => "Deleting lines using the given regexps...";

    section_edition.edit_section_valid::
      # Delete the content of the section
      ".*"
        select_region => rudder_section_selector("${escaped_section_start}", "${escaped_section_end}"),
        ifvarclass => "has_$(csection)";

  insert_lines:
    preserve_content.edit_content::
      "$(content)"
        classes => kept_if_else("content_${index}_kept", "content_${index}_modified", "content_${index}_failed"),
        insert_type => "preserve_block",
        comment => "Editing ...";

    !preserve_content.edit_content::
      "$(content)"
        classes => kept_if_else("content_${index}_kept", "content_${index}_modified", "content_${index}_failed"),
        comment => "Editing ...";

    section_edition.edit_section_valid::
      # Insert new, empty section if it doesn't exist already.
      "${section_start}
${section_end}"
        insert_type => "preserve_block",
        ifvarclass => "!has_${csection}";

      # Insert missing lines into the section
      "${section_content}"
        select_region => rudder_section_selector("${escaped_section_start}", "${escaped_section_end}"),
        classes => kept_if_else("section_content_modification_kept_${index}", "section_content_modification_modified_${index}", "section_content_modification_failed_${index}");


  replace_patterns:
    replace_lines.replace_lines_destination_defined::
      "$(modification_regex)"
        replace_with => value("${modification_replacement}"),
        classes => kept_if_else("content_modification_kept_${index}", "content_modification_modified_${index}", "content_modification_failed_${index}"),
        comment => "Replacing lines using the given regexps...";


    replace_lines.!replace_lines_destination_defined::
      "$(modification_regex)"
        replace_with => value(""),
        classes => kept_if_else("content_modification_kept_${index}", "content_modification_modified_${index}", "content_modification_failed_${index}"),
        comment => "Replacing lines using the given regexps...";


}

