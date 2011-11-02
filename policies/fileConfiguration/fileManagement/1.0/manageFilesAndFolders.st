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

		&TRACKINGKEY:{piuuid |"file[&i&][uuid]" string => "&piuuid&";
}&


		"index" slist => getindices("file");

	classes:
		# Set a class to define when we need to run the post-modification hook
		&FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN:{run |"manageFilesAndFolders_post_hook_run_&i&" expression => strcmp("&run&", "true");
}&

		&FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS:{perms |"manageFilesAndFolders_check_permissions_&i&" expression => strcmp("&perms&", "true");
}&

	files:

		"$(file[$(index)][path])/."
			create => "true",
			classes => kept_if_else("manageFilesAndFolders_$(index)_kept", "manageFilesAndFolders_$(index)_modified", "manageFilesAndFolders_$(index)_failed"),
			comment => "Enforcing the existance of folder $(file[$(index)][path])";


		# Check the permission
		"$(file[$(index)][path])"
			perms => mog("$(file[$(index)][mode])", "$(file[$(index)][owner])", "$(file[$(index)][group])"),
			classes => kept_if_else("manageFilesAndFolders_perms_$(index)_kept", "manageFilesAndFolders_perms_$(index)_modified", "manageFilesAndFolders_perms_$(index)_failed"),
			ifvarclass => "manageFilesAndFolders_check_permissions_$(index)";

	commands:
		"$(file[$(index)][post_hook_command])"
			classes => if_else("manageFilesAndFolders_$(index)_command_run_ok", "manageFilesAndFolders_$(index)_command_run_failed"),
			contain => in_shell,
			ifvarclass => "manageFilesAndFolders_post_hook_run_$(index).manageFilesAndFolders_$(index)_modified";

	reports:

        (linux|windows)::

			# Reporting for directory creation
			"@@manageFilesAndFolders@@result_success@@$(file[$(index)][uuid])@@File@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The folder $(file[$(index)][path]) already exists"
				ifvarclass => "manageFilesAndFolders_$(index)_kept.!manageFilesAndFolders_$(index)_modified";

			"@@manageFilesAndFolders@@result_repaired@@$(file[$(index)][uuid])@@File@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The folder $(file[$(index)][path]) was successfully created"
				ifvarclass => "manageFilesAndFolders_$(index)_modified";

			"@@manageFilesAndFolders@@result_error@@$(file[$(index)][uuid])@@File@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The folder $(file[$(index)][path]) could not be created"
				ifvarclass => "manageFilesAndFolders_$(index)_failed";

			# Reporting for the permissions
			"@@manageFilesAndFolders@@result_success@@$(file[$(index)][uuid])@@Permissions@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The item $(file[$(index)][path]) was not requested to have its permission enforced"
				ifvarclass => "!manageFilesAndFolders_check_permissions_$(index)";

			"@@manageFilesAndFolders@@result_success@@$(file[$(index)][uuid])@@Permissions@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The permission of the item $(file[$(index)][path]) were correct"
				ifvarclass => "manageFilesAndFolders_perms_$(index)_kept.!manageFilesAndFolders_perms_$(index)_modified";

			"@@manageFilesAndFolders@@result_repaired@@$(file[$(index)][uuid])@@Permissions@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The permissions of the item $(file[$(index)][path]) have been corrected"
				ifvarclass => "manageFilesAndFolders_perms_$(index)_modified.!manageFilesAndFolders_perms_$(index)_failed";

			"@@manageFilesAndFolders@@result_error@@$(file[$(index)][uuid])@@Permissions@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The item $(file[$(index)][path]) couldn't have its permission changed"
				ifvarclass => "manageFilesAndFolders_perms_$(index)_failed";


			# Reporting for post-command execution
			"@@manageFilesAndFolders@@result_success@@$(file[$(index)][uuid])@@Post-modification hook@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#Post-execution hook did not need running"
				ifvarclass => "!manageFilesAndFolders_post_hook_run_$(index)|(manageFilesAndFolders_$(index)_kept.!manageFilesAndFolders_$(index)_modified)";

			"@@manageFilesAndFolders@@result_repaired@@$(file[$(index)][uuid])@@Post-modification hook@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#Post-execution hook successfully run"
				ifvarclass => "manageFilesAndFolders_$(index)_command_run_ok";

			"@@manageFilesAndFolders@@result_error@@$(file[$(index)][uuid])@@Post-modification hook@@$(file[$(index)][path])@@$(g.execRun)##$(g.uuid)@#An error occured when running the post-execution hook"
				ifvarclass => "manageFilesAndFolders_$(index)_command_run_failed";
}



