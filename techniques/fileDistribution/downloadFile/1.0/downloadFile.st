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

##################################################################################
# Download a file from an arbitrary http server ( or any supported curl source ) #
##################################################################################

bundle agent execute_file_download # WARNING : If there is many instance, isn't there a risk of a bundle name collision ???
{

classes:

	"file_not_found" not => fileexists("&DOWNLOADFILE_DESTINATION&");

commands:

        file_not_found::
                "\"${g.rudder_curl}\""
args => "-f -o \"&DOWNLOADFILE_DESTINATION&\" &DOWNLOADFILE_SOURCE&",
			comment => "Getting the file from the server",
			classes => kept_if_else("file_download_idle", "file_download_ok", "file_download_fail");

files:

	(android|linux)::
		"&DOWNLOADFILE_DESTINATION&"
			pathtype => "literal", 	# force literal interpretation
			perms => mog("&DOWNLOADFILE_MODE&","&DOWNLOADFILE_USER&","&DOWNLOADFILE_GROUP&"),
			classes => kept_if_else("file_perms_idle", "file_perms_ok", "file_perms_fail");

reports:


		file_download_ok::
			"@@downloadFile@@log_repaired@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The file &DOWNLOADFILE_SOURCE& has been successfully downloaded";

		file_download_fail::
			"@@downloadFile@@result_error@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The file &DOWNLOADFILE_SOURCE& was could not be downloaded";

		!file_not_found::
			"@@downloadFile@@log_info@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The file &DOWNLOADFILE_SOURCE& was already there. Skipping ...";

		file_perms_ok::
			"@@downloadFile@@log_repaired@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The permissions on file &DOWNLOADFILE_SOURCE& were successfully fixed";

		file_perms_fail::
			"@@downloadFile@@result_error@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The permissions on file &DOWNLOADFILE_SOURCE& were could not be fixed";

		file_perms_idle::
			"@@downloadFile@@log_info@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#The permissions on file &DOWNLOADFILE_SOURCE& are ok. Skipping ...";

		file_download_ok|file_perms_ok::
			"@@downloadFile@@result_repaired@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#File &DOWNLOADFILE_SOURCE& is now compliant";

		!file_not_found.file_perms_idle::
			"@@downloadFile@@result_success@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#File &DOWNLOADFILE_SOURCE& already present with correct permissions"
				ifvarclass => "android|linux";

		!file_not_found::
			"@@downloadFile@@result_success@@&TRACKINGKEY&@@downloadFile@@None@@$(g.execRun)##$(g.uuid)@#File &DOWNLOADFILE_SOURCE& already present with correct permissions"
				ifvarclass => "windows";

}
