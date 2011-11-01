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

                &GENERIC_FILE_CONTENT_PATH:{path |"generic_file_content_path[&i&]" string => "&path&";
}&

                &GENERIC_FILE_CONTENT_OWNER:{owner |"generic_file_content_owner[&i&]" string => "&owner&";
}&

                &GENERIC_FILE_CONTENT_GROUP:{group |"generic_file_content_group[&i&]" string => "&group&";
}&

                &GENERIC_FILE_CONTENT_PERM:{perms |"generic_file_content_perms[&i&]" string => "&perms&";
}&

&GENERIC_FILE_CONTENT_PAYLOAD:{payload |"generic_file_content_payload[&i&]" string => "&payload&";
}&

&GENERIC_FILE_CONTENT_ENFORCE:{enforce |"generic_file_content_enforced[&i&]" string => "&enforce&";
}&

&GENERIC_FILE_CONTENT_POST_HOOK_COMMAND:{command |"generic_file_content_posthook[&i&]" string => "&command&";
}&

                &TRACKINGKEY:{piuuid |"generic_file_content_uuid[&i&]" string => "&piuuid&";
}&

		"index" slist => getindices("generic_file_content_path");

	classes:
		"execute_command_$(index)" not => strcmp("$(generic_file_content_posthook[$(index)])",
														"");
	files:

		"$(generic_file_content_path[$(index)])"
			edit_line => set_arbitrary_file_content("$(generic_file_content_payload[$(index)])",
													"$(generic_file_content_enforced[$(index)])"),
			create => "true",
			edit_defaults => rudder_empty_select("$(generic_file_content_enforced[$(index)])"),
			perms => mog("$(generic_file_content_perms[$(index)])", "$(generic_file_content_owner[$(index)])", "$(generic_file_content_group[$(index)])"),
			classes => kept_if_else("content_$(index)_kept", "content_$(index)_modified", "content_$(index)_failed"),
			comment => "Editing $(generic_file_content_path[$(index)])...";

	commands:
		"$(generic_file_content_posthook[$(index)])"
			classes => if_else("generic_file_content_posthook_$(index)_command_run_ok", "generic_file_content_posthook_$(index)_command_run_failed"),
			contain => in_shell,
			ifvarclass => "content_$(index)_modified.execute_command_$(index).!content_$(index)_failed";
	reports:

        (linux|windows)::

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was already in accordance with the policy"
                        ifvarclass => "content_$(index)_kept.!content_$(index)_modified";

		"@@checkGenericFileContent@@result_repaired@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) was successfully updated"
			ifvarclass => "content_$(index)_modified";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@File@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The file $(generic_file_content_path[$(index)]) could not be updated"
                        ifvarclass => "content_$(index)_failed";

		# Posthook report
                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@PostHook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#No command for $(generic_file_content_path[$(index)]) was to be executed"
			ifvarclass => "!execute_command_$(index)";

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@PostHook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#$(generic_file_content_path[$(index)]) was in the proper state, so no command to execute"
			ifvarclass => "execute_command_$(index).content_$(index)_kept.!content_$(index)_modified";

                "@@checkGenericFileContent@@result_success@@$(generic_file_content_uuid[$(index)])@@PostHook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) was correctly executed"
			ifvarclass => "generic_file_content_posthook_$(index)_command_run_ok";

                "@@checkGenericFileContent@@result_error@@$(generic_file_content_uuid[$(index)])@@PostHook@@$(generic_file_content_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The command for $(generic_file_content_path[$(index)]) could not to be executed"
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
