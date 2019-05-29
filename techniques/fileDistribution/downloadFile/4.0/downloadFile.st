#####################################################################################
# Copyright 2011-2018 Normation SAS
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

bundle agent execute_file_download_RudderUniqueID
{

  vars:
      &DOWNLOADFILE_DESTINATION:{destination |"destination[&i&]" string => "&destination&";
}&

      &DOWNLOADFILE_SOURCE:{source |"source[&i&]" string => "&source&";
}&

      &DOWNLOADFILE_MODE:{mode |"mode[&i&]" string => "&mode&";
}&

      &DOWNLOADFILE_USER:{user |"user[&i&]" string => "&user&";
}&

      &DOWNLOADFILE_GROUP:{group |"group[&i&]" string => "&group&";
}&

      &TRACKINGKEY:{uuid |"trackingkey[&i&]" string => "&uuid&";
}&


      "index" slist => getindices("destination");

    # If curl is here, use it
    !windows.curl_installed::
      "download_command[${index}]" string => "${g.rudder_curl} -L -f --proxy '' -o \"${destination[${index}]}\" ${source[${index}]}";

    # If no curl is present, fallback to minicurl
    !windows.!curl_installed::
      "download_command[${index}]" string => "${g.minicurl} --get --file \"${destination[${index}]}\" --url ${source[${index}]}";

    # Windows always use curl
    windows::
      "download_command[${index}]" string => "\"${g.rudder_curl}\" -L -f --proxy '' -o \"${destination[${index}]}\" ${source[${index}]}";


  classes:
      "file_not_found_${index}" not => fileexists("${destination[${index}]}");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    !windows.pass2::
      "${destination[${index}]}"
        pathtype => "literal", 	# force literal interpretation
        perms    => mog("${mode[${index}]}","${user[${index}]}","${group[${index}]}"),
        classes  => classes_generic("file_download_perms_${index}_RudderUniqueID");

  methods:
    # File downloading part
    pass3.(!curl_installed)::
      "any" usebundle => rudder_common_report("downloadFile", "log_info", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "No usable cURL binary detected, falling back to minicurl instead");

    pass3::
      "any" usebundle => rudder_common_report("downloadFile", "result_success", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} already present"),
           ifvarclass => "!file_not_found_${index}.!file_download_${index}_RudderUniqueID_ok.!file_download_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report("downloadFile", "result_repaired", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} has been successfully downloaded"),
           ifvarclass => "file_download_${index}_RudderUniqueID_ok.!file_download_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report("downloadFile", "result_error", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} was could not be downloaded"),
           ifvarclass => "file_download_${index}_RudderUniqueID_error";

    # File permissions part
    pass3.!windows::
      "any" usebundle => rudder_common_reports_generic("downloadFile", "file_download_perms_${index}_RudderUniqueID", "${trackingkey[${index}]}", "Permissions (on UNIX systems)", "${source[${index}]}", "Permissions on file ${source[${index}]}");

      "any" usebundle => rudder_common_report("downloadFile", "result_error", "${trackingkey[${index}]}", "Permissions (on UNIX systems)", "${source[${index}]}", "The file ${source[${index}]} was could not be downloaded"),
           ifvarclass => "!file_download_perms_${index}_RudderUniqueID_reached";

    pass3.windows::
      "any" usebundle => rudder_common_report("downloadFile", "result_na", "${trackingkey[${index}]}", "Permissions (on UNIX systems)", "${source[${index}]}", "This is a windows machine. The ${source[${index}]} file permissions will not be altered.");

  commands:
      "${download_command[${index}]}"
        comment => "Getting the file from the server",
        classes => classes_generic("file_download_${index}_RudderUniqueID"),
        ifvarclass => "file_not_found_${index}";

}
