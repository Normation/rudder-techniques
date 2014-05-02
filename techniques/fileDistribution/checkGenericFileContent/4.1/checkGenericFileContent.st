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
      # Add content to the file only if the content has been set
      "$(generic_file_content_path[$(index)])"
        edit_line => set_arbitrary_file_content("$(generic_file_content_payload[$(index)])",
						"$(generic_file_content_enforced[$(index)])"),
        create => "$(generic_file_content_creation[$(index)])",
        edit_defaults => rudder_empty_select("$(generic_file_content_enforced[$(index)])"),
        classes => kept_if_else("content_$(index)_kept", "content_$(index)_modified", "content_$(index)_failed"),
        ifvarclass => "edit_content_$(index).!creation_only_but_already_exists_${index}",
        comment => "Editing $(generic_file_content_path[$(index)])...";

      "$(generic_file_content_path[$(index)])"
        edit_line => delete_lines_matching("$(generic_file_content_deletion_regexp[$(index)])"),
        create => "$(generic_file_content_creation[$(index)])",
        edit_defaults => noempty_backup,
        classes => kept_if_else("content_deletion_kept_$(index)", "content_deletion_modified_$(index)", "content_deletion_failed_$(index)"),
        ifvarclass => "delete_lines_$(index).!creation_only_but_already_exists_${index}",
        comment => "Deleting lines in $(generic_file_content_path[$(index)]) using the given regexps...";

      # Replace the matching line(s) of the file by values of replacement
      # if replacement has been set
      "$(generic_file_content_path[$(index)])"
        edit_line => set_arbitrary_file_content_modify("$(generic_file_content_modification_regexp[$(index)])", "$(generic_file_content_modification_destination[$(index)])"),
        create => "$(generic_file_content_creation[$(index)])",
        edit_defaults => noempty_backup,
        classes => kept_if_else("content_modification_kept_$(index)", "content_modification_modified_$(index)", "content_modification_failed_$(index)"),
        ifvarclass => "modify_lines_$(index).generic_file_content_modification_destination_defined_$(index).!creation_only_but_already_exists_${index}",
        comment => "Replacing lines in $(generic_file_content_path[$(index)]) using the given regexps...";

      # Replace the matching line(s) of the file by an empty line
      # if replacement is not set
      "$(generic_file_content_path[$(index)])"
        edit_line => set_arbitrary_file_content_modify("$(generic_file_content_modification_regexp[$(index)])", ""),
        create => "$(generic_file_content_creation[$(index)])",
        edit_defaults => noempty_backup,
        classes => kept_if_else("content_modification_kept_$(index)", "content_modification_modified_$(index)", "content_modification_failed_$(index)"),
        ifvarclass => "modify_lines_$(index).!generic_file_content_modification_destination_defined_$(index).!creation_only_but_already_exists_${index}",
        comment => "Replacing lines in $(generic_file_content_path[$(index)]) using the given regexps...";

      # Enforce the content of section in file
      "${generic_file_content_path[${index}]}"
        edit_line => rudder_ensure_section_content("${generic_file_content_section_header[${index}]}", "${generic_file_content_section_footer[${index}]}", "${generic_file_content_section_content[${index}]}"),
        create => "${generic_file_content_creation[${index}]}",
        edit_defaults => noempty_backup,
        classes => kept_if_else("section_content_modification_kept_${index}", "section_content_modification_modified_${index}", "section_content_modification_failed_${index}"),
        ifvarclass => "enforce_section_${index}.!creation_only_but_already_exists_${index}.edit_section_valid_${index}",
        comment => "Enforcing content of section in ${generic_file_content_path[${index}]}";


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
        ifvarclass => "execute_command_$(index).!(content_$(index)_failed|content_deletion_failed_$(index)|content_modification_failed_$(index)).(content_$(index)_modified|content_deletion_modified_$(index)|content_modification_modified_$(index)|section_content_modification_modified_${index})";

  reports:
    (linux|windows).tier2::
    # Files edition
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the policy"
        ifvarclass => "content_$(index)_kept.!content_$(index)_modified";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated"
        ifvarclass => "content_$(index)_modified";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) could not be updated"
        ifvarclass => "content_$(index)_failed";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#No content was given to check file $(generic_file_content_path[$(index)]), skipping"
        ifvarclass => "!edit_content_$(index)";

      # Files edition - deletion
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was not set for any line deletion"
        ifvarclass => "!delete_lines_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the deletion policy"
        ifvarclass => "content_deletion_kept_$(index).!content_deletion_modified_$(index).!content_deletion_failed_$(index)";

      "@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@Line deletion regular expressions@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated using the deletion policy"
        ifvarclass => "content_deletion_modified_$(index)";

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
        ifvarclass => "section_content_modification_kept_${index}.!section_content_modification_modified_${index}";

      "@@checkGenericFileContent@@result_repaired@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} was successfully updated using the section content policy"
        ifvarclass => "section_content_modification_modified_${index}.!section_content_modification_failed_${index}";

      "@@checkGenericFileContent@@result_error@@${generic_file_content_uuid[${index}]}@@Enforce content by section@@${generic_file_content_path[${index}]}@@${g.execRun}##${g.uuid}@#The file ${generic_file_content_path[${index}]} could not be updated using the section content policy"
        ifvarclass => "section_content_modification_failed_${index}";



      # Posthook report
      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#No command for $(generic_file_content_path[$(index)]) was to be executed"
        ifvarclass => "!execute_command_$(index)";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#$(generic_file_content_path[$(index)]) was in the proper state, so no command to execute"
        ifvarclass => "execute_command_$(index).content_$(index)_kept.!content_$(index)_modified";

      "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) was correctly executed"
        ifvarclass => "generic_file_content_posthook_$(index)_command_run_ok";

      "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@Post-modification hook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) could not to be executed"
        ifvarclass => "generic_file_content_posthook_$(index)_command_run_failed";

}

bundle edit_line set_arbitrary_file_content(content, enforce)
{

  classes:
      "preserve_file_content" expression => strcmp("true", "$(enforce)");

  insert_lines:
    preserve_file_content::
      "$(content)"
        insert_type => "preserve_block";

    !preserve_file_content::
      "$(content)";

}

bundle edit_line set_arbitrary_file_content_modify(regexp, destination)
{
  replace_patterns:
      "$(regexp)"
        replace_with => value("$(destination)");

}

