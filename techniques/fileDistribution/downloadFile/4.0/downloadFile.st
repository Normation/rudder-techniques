###########################################################
# Download a file from an arbitrary http/https/ftp server #
###########################################################

bundle agent execute_file_download_&RudderUniqueID&
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

      "download_command[${index}]" string => "${g.rudder_curl} -L -f --proxy '' -o \"${destination[${index}]}\" ${source[${index}]}";

  classes:
      "file_not_found_${index}" not => fileexists("${destination[${index}]}");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    pass2::
      "${destination[${index}]}"
        pathtype => "literal", 	# force literal interpretation
        perms    => mog("${mode[${index}]}","${user[${index}]}","${group[${index}]}"),
        classes  => classes_generic("file_download_perms_${index}_&RudderUniqueID&");

  methods:
    # File downloading part
    pass3::
      "any" usebundle => rudder_common_report("downloadFile", "result_success", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} already present"),
           ifvarclass => "!file_not_found_${index}.!file_download_${index}_&RudderUniqueID&_ok.!file_download_${index}_&RudderUniqueID&_error";

      "any" usebundle => rudder_common_report("downloadFile", "result_repaired", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} has been successfully downloaded"),
           ifvarclass => "file_download_${index}_&RudderUniqueID&_ok.!file_download_${index}_&RudderUniqueID&_error";

      "any" usebundle => rudder_common_report("downloadFile", "result_error", "${trackingkey[${index}]}", "Download a file", "${source[${index}]}", "The file ${source[${index}]} was could not be downloaded"),
           ifvarclass => "file_download_${index}_&RudderUniqueID&_error";

    # File permissions part
    pass3::
      "any" usebundle => rudder_common_reports_generic("downloadFile", "file_download_perms_${index}_&RudderUniqueID&", "${trackingkey[${index}]}", "Permissions (on UNIX systems)", "${source[${index}]}", "Permissions on file ${source[${index}]}");

      "any" usebundle => rudder_common_report("downloadFile", "result_error", "${trackingkey[${index}]}", "Permissions (on UNIX systems)", "${source[${index}]}", "The file ${source[${index}]} was could not be downloaded"),
           ifvarclass => "!file_download_perms_${index}_&RudderUniqueID&_reached";

  commands:
      "${download_command[${index}]}"
        comment => "Getting the file from the server",
        classes => classes_generic("file_download_${index}_&RudderUniqueID&"),
        ifvarclass => "file_not_found_${index}";

}
