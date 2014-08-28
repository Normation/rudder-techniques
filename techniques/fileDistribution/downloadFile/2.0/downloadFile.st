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

###########################################################
# Download a file from an arbitrary http/https/ftp server #
###########################################################

bundle agent execute_file_download # WARNING : If there is many instance, isn't there a risk of a bundle name collision ???
{

  vars:

    # If curl is here, use it
    !windows.curl_installed::
      "download_command" string => "${g.rudder_curl} -f --proxy '' -o \"&DOWNLOADFILE_DESTINATION&\" &DOWNLOADFILE_SOURCE&";

    # If no curl is present, fallback to minicurl
    !windows.!curl_installed::
      "download_command" string => "${g.minicurl} --get --file \"&DOWNLOADFILE_DESTINATION&\" --url &DOWNLOADFILE_SOURCE&";

    # Windows always use curl
    windows::
      "download_command" string => "\"${g.rudder_curl}\" -f --proxy '' -o \"&DOWNLOADFILE_DESTINATION&\" &DOWNLOADFILE_SOURCE&";

  classes:

      "file_not_found" not => fileexists("&DOWNLOADFILE_DESTINATION&");

  commands:

    file_not_found::
      "${download_command}"
        comment => "Getting the file from the server",
        classes => kept_if_else("file_download_idle", "file_download_ok", "file_download_fail");

  files:

    !windows::
      "&DOWNLOADFILE_DESTINATION&"
        pathtype => "literal", 	# force literal interpretation
        perms => mog("&DOWNLOADFILE_MODE&","&DOWNLOADFILE_USER&","&DOWNLOADFILE_GROUP&"),
        classes => kept_if_else("file_perms_idle", "file_perms_ok", "file_perms_fail");

  reports:

    # File downloading part
    !curl_installed:
      "@@downloadFile@@log_info@@&TRACKINGKEY&@@Download a file@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#No usable cURL binary detected, falling back to miniperl instead";

    !file_not_found.!file_download_ok.!file_download_fail::
      "@@downloadFile@@result_success@@&TRACKINGKEY&@@Download a file@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The file &DOWNLOADFILE_SOURCE& already present";

    file_download_ok.!file_download_fail::
      "@@downloadFile@@result_repaired@@&TRACKINGKEY&@@Download a file@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The file &DOWNLOADFILE_SOURCE& has been successfully downloaded";

    file_download_fail::
      "@@downloadFile@@result_error@@&TRACKINGKEY&@@Download a file@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The file &DOWNLOADFILE_SOURCE& was could not be downloaded";

    # File permissions part
    !windows.file_perms_idle.!file_perms_ok.!file_perms_fail::
      "@@downloadFile@@result_success@@&TRACKINGKEY&@@Permissions (on UNIX systems)@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The permissions on file &DOWNLOADFILE_SOURCE& are ok. Skipping ...";

    !windows.file_perms_ok.!file_perms_fail::
      "@@downloadFile@@result_repaired@@&TRACKINGKEY&@@Permissions (on UNIX systems)@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The permissions on file &DOWNLOADFILE_SOURCE& were successfully fixed";

    !windows.file_perms_fail::
      "@@downloadFile@@result_error@@&TRACKINGKEY&@@Permissions (on UNIX systems)@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#The permissions on file &DOWNLOADFILE_SOURCE& were could not be fixed";

    windows::
      "@@downloadFile@@result_success@@&TRACKINGKEY&@@Permissions (on UNIX systems)@@&DOWNLOADFILE_SOURCE&@@${g.execRun}##${g.uuid}@#This is a windows machine. The &DOWNLOADFILE_SOURCE& file permissions will not be altered.";

}
