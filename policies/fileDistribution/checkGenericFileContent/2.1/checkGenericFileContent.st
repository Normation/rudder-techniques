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

                "generic_file_content_path" string => "&GENERIC_FILE_CONTENT_PATH&";

                "generic_file_content_owner" string => "&GENERIC_FILE_CONTENT_OWNER&";

                "generic_file_content_group" string => "&GENERIC_FILE_CONTENT_GROUP&";

                "generic_file_content_perms" string => "&GENERIC_FILE_CONTENT_PERM&";

		"generic_file_content_payload" string => "&GENERIC_FILE_CONTENT_PAYLOAD&";

		"generic_file_content_enforced" string => "&GENERIC_FILE_CONTENT_ENFORCE&";

		"generic_file_content_posthook" string => "&GENERIC_FILE_CONTENT_POST_HOOK_COMMAND&";

		"line_deletion_regexp"  slist => {&GENERIC_FILE_CONTENT_DELETION_REGEXP: { "&it&" };separator=", "&};

		&GENERIC_FILE_CONTENT_MODIFICATION_REGEXP:{regexp |"line_modification_regexp[&i&]" string => "&regexp&";
}&
		&GENERIC_FILE_CONTENT_MODIFICATION_DESTINATION:{destination |"line_modification_destination[&i&]" string => "&destination&";
}&
                "generic_file_content_uuid" string => "&TRACKINGKEY&";

		"index" slist => getindices("line_modification_regexp");

	classes:

		# Set a class to define when we need to run the post-modification hook
		"execute_command" expression => strcmp("&GENERIC_FILE_CONTENT_POST_HOOK_RUN&", "true");

		"adjust_permissions" expression => strcmp("&GENERIC_FILE_CONTENT_PERMISSION_ADJUSTMENT&", "true");

		"delete_lines" expression => strcmp("&GENERIC_FILE_CONTENT_DELETION_BOOLEAN&", "true");

		"replace_lines" expression => strcmp("&GENERIC_FILE_CONTENT_MODIFICATION_BOOLEAN&", "true");

	files:

		"$(generic_file_content_path)"
			edit_line => set_arbitrary_file_content("$(generic_file_content_payload)", "$(generic_file_content_enforced)"),
			create => "true",
			edit_defaults => rudder_empty_select("$(generic_file_content_enforced)"),
			classes => kept_if_else("content_kept", "content_modified", "content_failed"),
			comment => "Editing $(generic_file_content_path)...";

		"$(generic_file_content_path)"
			edit_line => delete_lines_matching("@(check_generic_file_content.line_deletion_regexp)"),
			create => "true",
			# edit_defaults => rudder_empty_select("$(generic_file_content_enforced)"),
			classes => kept_if_else("content_deletion_kept", "content_deletion_modified", "content_deletion_failed"),
			ifvarclass => "delete_lines",
			comment => "Deleting lines in $(generic_file_content_path) using the given regexps...";

		"$(generic_file_content_path)"
			edit_line => set_arbitrary_file_content_modify("$(check_generic_file_content.line_modification_regexp[$(index)])", "$(check_generic_file_content.line_modification_destination[$(index)])"),
			create => "true",
			# edit_defaults => rudder_empty_select("$(generic_file_content_enforced)"),
			classes => kept_if_else("content_modification_kept", "content_modification_modified", "content_modification_failed"),
			ifvarclass => "replace_lines",
			comment => "Replacing lines in $(generic_file_content_path) using the given regexps...";

		"$(generic_file_content_path)"
			create => "true",
			perms => mog("$(generic_file_content_perms)", "$(generic_file_content_owner)", "$(generic_file_content_group)"),
			classes => kept_if_else("perms_kept", "perms_modified", "perms_failed"),
			ifvarclass => "adjust_permissions",
			comment => "Setting $(generic_file_content_path) permissions...";

	commands:
		"$(generic_file_content_posthook)"
			classes => if_else("generic_file_content_posthook_command_run_ok", "generic_file_content_posthook_command_run_failed"),
			contain => in_shell,
			ifvarclass => "content_modified.execute_command.!content_failed";
	reports:

        (linux|windows)::

			# Files edition
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@File@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was already in accordance with the addition policy"
					ifvarclass => "content_kept.!content_modified.!content_failed";

		"@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid)@@File@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was successfully updated using the addition policy"
					ifvarclass => "content_modified";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid)@@File@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) could not be updated using the deletion policy"
					ifvarclass => "content_failed";

			# Files edition - deletion
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Line deletion regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was already in accordance with the deletion policy"
					ifvarclass => "content_deletion_kept.!content_deletion_modified.!content_deletion_failed";

		"@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid)@@Line deletion regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was successfully updated using the deletion policy"
					ifvarclass => "content_deletion_modified";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid)@@Line deletion regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) could not be updated using the deletion policy"
					ifvarclass => "content_deletion_failed";

			# Files edition - replacement
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Line replacement regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was already in accordance with the deletion policy"
					ifvarclass => "content_modification_kept.!content_modification_modified.!content_modification_failed";

		"@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid)@@Line replacement regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) was successfully updated using the deletion policy"
					ifvarclass => "content_modification_modified";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid)@@Line replacement regular expressions@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) could not be updated using the deletion policy"
					ifvarclass => "content_modification_failed";

			# Permissions edition
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Permission adjustment@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) uses default permissions"
					ifvarclass => "!adjust_permissions";

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Permission adjustment@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) permissions are OK"
					ifvarclass => "perms_kept";

		"@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid)@@Permission adjustment@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) permissions were adjusted"
					ifvarclass => "perms_modified";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid)@@Permission adjustment@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path) permissions could not be adjusted"
					ifvarclass => "perms_failed";

		# Posthook report
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Post-modification hook@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#No command for $(generic_file_content_path) was to be executed"
			ifvarclass => "!execute_command";

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Post-modification hook@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#$(generic_file_content_path) was in the proper state, so no command to execute"
			ifvarclass => "execute_command_$(index).content_kept.!content_modified";

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid)@@Post-modification hook@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path) was correctly executed"
			ifvarclass => "generic_file_content_posthook_command_run_ok";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid)@@Post-modification hook@@$(generic_file_content_path)@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path) could not to be executed"
			ifvarclass => "generic_file_content_posthook_command_run_failed";

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
