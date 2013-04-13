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


bundle agent download_from_shared_folder {

        vars:
       "file_count" int => readstringarrayidx("copyfile","${sys.workdir}/inputs/copyGitFile/2.0/copyFileFromSharedFolderData", "#[^\n]*",":",9000,1600000); 

               &COPYFILE_NAME:{name |"copyfile[&i0&][name]" string => "&name&";
}&

                &COPYFILE_POST_HOOK_COMMAND:{command |"copyfile[&i0&][posthook]" string => "&command&";
}&

		"shared_folder" string => "&SHARED_FILES_FOLDER&";

		"index" slist => getindices("copyfile");

	classes:
		"is_valid" not => strcmp("&SHARED_FILES_FOLDER&", "");

		"is_file_$(index)" not => isdir("$(copyfile[$(index)][5])");
		"exist_$(index)" expression => fileexists("$(copyfile[$(index)][5])");

                # Set a class to define when we need to run the post-modification hook
                &COPYFILE_POST_HOOK_RUN:{run |"execute_command_&i0&" expression => strcmp("&run&", "true");
}&


	files:
	  is_valid::
		
		"$(copyfile[$(index)][5])"
			copy_from => scp("&SHARED_FILES_FOLDER&/$(copyfile[$(index)][name])", "$(server_info.cfserved)", "$(copyfile[$(index)][3])", "false", "false", "false"),
			depth_search => recurse("$(copyfile[$(index)][0])"),
			perms => mog("$(copyfile[$(index)][4])"
					   , "$(copyfile[$(index)][1])"
					   , "$(copyfile[$(index)][2])"),
			comment => "Enforce content of $(copyfile[$(index)][5]) based on the content on the Rudder server with $(copyfile[$(index)][3]) method",
			classes => kept_if_else("copy_file_$(index)_kept", "copy_file_$(index)_modified", "copy_file_$(index)_failed"),
			ifvarclass => "!exist_$(index)|!is_file_$(index)";

		# If it's a file, the depth_search prevents from enforcing the file content
		"$(copyfile[$(index)][5])"
			copy_from => scp("&SHARED_FILES_FOLDER&/$(copyfile[$(index)][name])", "$(server_info.cfserved)", "$(copyfile[$(index)][3])", "false", "false", "false"),
			perms => mog("$(copyfile[$(index)][4])"
					   , "$(copyfile[$(index)][1])"
					   , "$(copyfile[$(index)][2])"),
			comment => "Enforce content of file $(copyfile[$(index)][5]) based on the content on the Rudder server with $(copyfile[$(index)][3]) method",
			classes => kept_if_else("copy_file_$(index)_kept", "copy_file_$(index)_modified", "copy_file_$(index)_failed"),
			ifvarclass => "exist_$(index).is_file_$(index)";

	commands:
		"$(copyfile[$(index)][posthook])"
			contain => in_shell,
			classes => if_else("copyfile_posthook_$(index)_command_run_ok", "copyfile_posthook_$(index)_command_run_failed"),
			ifvarclass => "execute_command_$(index).copy_file_$(index)_modified.!copy_file_$(index)_failed",
			comment => "Execute the posthook command if a file was changed";

	reports:
		linux|windows::
		"@@copyFile@@result_error@@$(copyfile[$(index)][6])@@Copy file@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#There is no shared folder on the Rudder Server, so it's not possible to copy a file from it"
			ifvarclass => "!is_valid";

		"@@copyFile@@result_success@@$(copyfile[$(index)][6])@@Copy file@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#The content of the file(s) is valid"
			ifvarclass => "copy_file_$(index)_kept.!copy_file_$(index)_modified";

		"@@copyFile@@result_repaired@@$(copyfile[$(index)][6])@@Copy file@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#The content or permissions of the file(s) has been repaired"
			ifvarclass => "copy_file_$(index)_modified";

		"@@copyFile@@result_error@@$(copyfile[$(index)][6])@@Copy file@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#The content or permissions of the file(s) could not have been repaired for some reason"
			ifvarclass => "copy_file_$(index)_failed";

		#posthook reports
		"@@copyFile@@result_success@@$(copyfile[$(index)][6])@@Post-modification hook@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#No post-hook command for $(copyfile[$(index)][5]) was defined, not executing"
                        ifvarclass => "!execute_command_$(index)";

                "@@copyFile@@result_success@@$(copyfile[$(index)][6])@@Post-modification hook@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#$(copyfile[$(index)][5]) was already in the desired state, so no command was executed"
                        ifvarclass => "execute_command_$(index).copy_file_$(index)_kept.!copy_file_$(index)_modified";

                "@@copyFile@@result_success@@$(copyfile[$(index)][6])@@Post-modification hook@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#The post-hook command for $(copyfile[$(index)][5]) was correctly executed"
                        ifvarclass => "copyfile_posthook_$(index)_command_run_ok";

                "@@copyFile@@result_error@@$(copyfile[$(index)][6])@@Post-modification hook@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#The post-hook command for $(copyfile[$(index)][5]) couldn't be executed"
                        ifvarclass => "copyfile_posthook_$(index)_command_run_failed";

}
