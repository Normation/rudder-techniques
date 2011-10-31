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

		&FILE_AND_FOLDER_MANAGEMENT_PATH:{path |"file_path[&i&]" string => "&path&";
}&

		&TRACKINGKEY:{piuuid |"file_uuid[&i&]" string => "&piuuid&";
}&

		"index" slist => getindices("file_uuid");

	files:

		"$(file_path[$(index)])/."
			create => "true",
			classes => kept_if_else("manageFilesAndFolders_$(index)_kept", "manageFilesAndFolders_$(index)_modified", "manageFilesAndFolders_$(index)_failed"),
			comment => "Enforcing the existance of folder $(file_path[$(index)])";

	reports:

        (linux|windows)::

			"@@manageFilesAndFolders@@result_success@@$(file_uuid[$(index)])@@File@@$(file_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The folder $(file_path[$(index)]) was already existing"
				ifvarclass => "manageFilesAndFolders_$(index)_kept.!manageFilesAndFolders_$(index)_modified";

			"@@manageFilesAndFolders@@result_repaired@@$(file_uuid[$(index)])@@File@@$(file_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The folder $(file_path[$(index)]) was successfully created"
				ifvarclass => "manageFilesAndFolders_$(index)_modified";

			"@@manageFilesAndFolders@@result_error@@$(file_uuid[$(index)])@@File@@$(file_path[$(index)])@@$(g.execRun)##$(g.uuid)@#The folder $(file_path[$(index)]) could not be created"
				ifvarclass => "manageFilesAndFolders_$(index)_failed";

}

