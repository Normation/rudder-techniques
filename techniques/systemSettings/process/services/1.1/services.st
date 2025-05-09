# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Enforce the defined services parameters

bundle agent services_&RudderUniqueID&
{
  vars:

    &SERVICES_TECHNIQUE_NAME:{service |"service[&i&]" string => "&service&";
}&
    &SERVICES_TECHNIQUE_STATUS:{status |"status[&i&]" string => "&status&";
}&
    &SERVICES_TECHNIQUE_BOOT:{boot |"boot[&i&]" string => "&boot&";
}&
&SERVICES_TECHNIQUE_POSTHOOK:{posthook |"posthook[&i&]" string => "&posthook&";
}&
    &SERVICES_TECHNIQUE_POSTHOOK_PERSISTENT:{persistent |"persistent[&i&]" string => "&persistent&";
}&
    &TRACKINGKEY:{trackingkey |"trackingkey[&i&]" string => "&trackingkey&";
}&

      "index" slist => getindices("service");

      "technique_name"           string => "Services";
      "service_canon[${index}]"  string => canonify("${service[${index}]}");
      "posthook_canon[${index}]" string => canonify("${posthook[${index}]}");

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "boot_enabled_${index}"       expression => strcmp("${boot[${index}]}", "enabled");
      "boot_disabled_${index}"      expression => strcmp("${boot[${index}]}", "disabled");
      "boot_dont_change_${index}"   expression => strcmp("${boot[${index}]}", "ignore");

      "status_running_${index}"     expression => strcmp("${status[${index}]}", "running");
      "status_stopped_${index}"     expression => strcmp("${status[${index}]}", "stopped");
      "status_dont_change_${index}" expression => strcmp("${status[${index}]}", "ignore");


      #Posthook
      "no_posthook_specified_${index}" expression => strcmp("${posthook[${index}]}", "");
      "posthook_persistent_${index}"   expression => strcmp("${persistent[${index}]}", "true");

      "status_repaired_${index}" expression => "service_ensure_running_${service_canon[${index}]}_repaired|service_ensure_stopped_${service_canon[${index}]}_repaired";
      "boot_repaired_${index}"   expression => "service_ensure_started_at_boot_${service_canon[${index}]}_repaired|service_ensure_disabled_at_boot_${service_canon[${index}]}_repaired";
      "repaired_${index}"        expression => "boot_repaired_${index}|status_repaired_${index}";

      "posthook_launch_${index}"  expression => "!no_posthook_specified_${index}.repaired_${index}";
      "posthook_rerun_${index}_&RudderUniqueID&"
                                 expression => "posthook_persistent_${index}.command_execution_${posthook_canon[${index}]}_failed",
                                      scope => "namespace",
                                persistence => "10000";

  methods:
    #Status
    "apply_status_${index}" usebundle => service_ensure_running("${service[${index}]}"),
      ifvarclass => "status_running_${index}";

    "apply_status_${index}" usebundle => service_ensure_stopped("${service[${index}]}"),
      ifvarclass => "status_stopped_${index}";

    #Boot
    "apply_boot_${index}" usebundle => service_ensure_started_at_boot("${service[${index}]}"),
      ifvarclass => "boot_enabled_${index}";

    "apply_boot_${index}" usebundle => service_ensure_disabled_at_boot("${service[${index}]}"),
      ifvarclass => "boot_disabled_${index}";

    #Posthook
    "posthook_${index}" usebundle => command_execution("${posthook[${index}]}"),
      ifvarclass => "posthook_launch_${index}|posthook_rerun_${index}_&RudderUniqueID&";

    #Reporting

    #Technique
    "any" usebundle => rudder_common_reports_generic_index("${technique_name}", "service_ensure_running_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "The service status \"running\" for ${service[${index}]}", "${index}"),
      ifvarclass => "status_running_${index}";

    "any" usebundle => rudder_common_reports_generic_index("${technique_name}", "service_ensure_stopped_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "The service status \"stopped\" for ${service[${index}]}", "${index}"),
      ifvarclass => "status_stopped_${index}";

    "report_${index}" usebundle  => rudder_common_report_index("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "No status imposed", "${index}"),
      ifvarclass => "status_dont_change_${index}";




    "any" usebundle => rudder_common_reports_generic_index("${technique_name}", "service_ensure_started_at_boot_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "The service boot status \"enabled\" for ${service[${index}]}", "${index}"),
      ifvarclass => "boot_enabled_${index}";

    "any" usebundle => rudder_common_reports_generic_index("${technique_name}", "service_ensure_disabled_at_boot_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "The service boot status \"disabled\" for ${service[${index}]}", "${index}"),
      ifvarclass => "boot_disabled_${index}";

    "report_${index}" usebundle  => rudder_common_report_index("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "No boot status imposed", "${index}"),
      ifvarclass => "boot_dont_change_${index}";

    pass3::
      #Posthook
      #Case with execution
      "any" usebundle => rudder_common_reports_generic_index("${technique_name}", "command_execution_${posthook_canon[${index}]}", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "The command ${posthook[${index}]} from postHook execution ", "${index}"),
        ifvarclass => "command_execution_${posthook_canon[${index}]}_reached";

      #Case without execution
      "report_${index}" usebundle  => rudder_common_report_index("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "No post-modification needed to run", "${index}"),
        ifvarclass => "!repaired_${index}.!no_posthook_specified_${index}.!command_execution_${posthook_canon[${index}]}_reached";

      #Case where no posthook set
      "report_hook_${index}" usebundle  => rudder_common_report_index("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "No post-modification set to run", "${index}"),
        ifvarclass => "no_posthook_specified_${index}";

}

