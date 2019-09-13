
bundle agent file_alteration_monitor_RudderUniqueID
{

  vars:

                &MONITOR_ENTITY_NAME:{name |"monitor_entity[&i&][name]" string => "&name&";
}&
                &TRACKINGKEY:{uuid |"monitor_entity[&i&][uuid]" string => "&uuid&";
}&
      "index" slist => getindices("monitor_entity");

  classes:

      "isfile_${index}" expression => isplain("${monitor_entity[${index}][name]}");
      "isdir_${index}" expression  => isdir("${monitor_entity[${index}][name]}");

      # Should the technique report an error if the file does not exist ?
      &MONITOR_ERROR_NOFILE:{ nofile | "nofile_reports_error_&i&" expression  => strcmp("&nofile&", "true"); 
}&


    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

      "${monitor_entity[${index}][name]}"
        changes      => detect_all_change,
        classes      => classes_generic("file_alteration_monitor_${index}_RudderUniqueID"),
        depth_search => recurse("inf"),
        ifvarclass   => "isdir_${index}";

      "${monitor_entity[${index}][name]}"
        changes      => detect_all_change,
        classes      => classes_generic("file_alteration_monitor_${index}_RudderUniqueID"),
        ifvarclass   => "isfile_${index}";

  methods:

    pass3.cfengine::

      "any" usebundle => rudder_common_report_index("fileAlterationMonitoring", "result_success", "${monitor_entity[${index}][uuid]}", "File or directory to monitor", "${monitor_entity[${index}][name]}", "The content of ${monitor_entity[${index}][name]} is consistent", "${index}"),
        ifvarclass => "file_alteration_monitor_${index}_RudderUniqueID_kept.!file_alteration_monitor_${index}_RudderUniqueID_repaired.!file_alteration_monitor_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("fileAlterationMonitoring", "result_repaired", "${monitor_entity[${index}][uuid]}", "File or directory to monitor", "${monitor_entity[${index}][name]}", "The content of ${monitor_entity[${index}][name]} is INCONSISTENT: Either the file has changed or one of the elements in the directory has", "${index}"),
        ifvarclass => "file_alteration_monitor_${index}_RudderUniqueID_repaired.!file_alteration_monitor_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("fileAlterationMonitoring", "result_error", "${monitor_entity[${index}][uuid]}", "File or directory to monitor", "${monitor_entity[${index}][name]}", "The content of ${monitor_entity[${index}][name]} could not be checked", "${index}"),
        ifvarclass => "file_alteration_monitor_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("fileAlterationMonitoring", "result_error", "${monitor_entity[${index}][uuid]}", "File or directory to monitor", "${monitor_entity[${index}][name]}", "The entity ${monitor_entity[${index}][name]} does not exist: alteration monitoring impossible", "${index}"),
        ifvarclass => "(!isdir_${index}.!isfile_${index}).nofile_reports_error_${index}";

      "any" usebundle => rudder_common_report_index("fileAlterationMonitoring", "result_na", "${monitor_entity[${index}][uuid]}", "File or directory to monitor", "${monitor_entity[${index}][name]}", "The entity ${monitor_entity[${index}][name]} does not exist: alteration monitoring not applicable", "${index}"),
        ifvarclass => "(!isdir_${index}.!isfile_${index}).!nofile_reports_error_${index}";





}
