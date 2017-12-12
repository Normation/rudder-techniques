#####################################################################################
# Copyright 2017 Normation SAS
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

# Enforce the defined services parameters

bundle agent services
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

      "technique_name" string => "Services technique";
      "service_canon[${index}]" string => canonify("${service[${index}]}");
      "posthook_canon[${index}]" string => canonify("${posthook[${index}]}");

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "boot_enabled_${index}" expression => strcmp("${boot[${index}]}", "enabled");
      "boot_disabled_${index}" expression => strcmp("${boot[${index}]}", "disabled");
      "boot_dont_change_${index}" expression => strcmp("${boot[${index}]}", "ignore");

      "status_running_${index}" expression => strcmp("${status[${index}]}", "running");
      "status_stopped_${index}" expression => strcmp("${status[${index}]}", "stopped");
      "status_dont_change_${index}" expression => strcmp("${status[${index}]}", "ignore");


      #Posthook
      "posthook_specified_${index}" not => strcmp("${posthook[${index}]}", "");
      "posthook_persistent_${index}" expression => strcmp("${persistent[${index}]}", "true");

      "status_repaired_${index}" expression => "service_ensure_running_${service_canon[${index}]}_repaired|service_ensure_stopped_${service_canon[${index}]}_repaired";
      "boot_repaired_${index}" expression => "service_ensure_started_at_boot_${service_canon[${index}]}_repaired|service_ensure_disabled_at_boot_${service_canon[${index}]}_repaired";
      "repaired_${index}" expression => "boot_repaired_${index}|status_repaired_${index}";

      "posthook_lauch_${index}" expression => "posthook_specified_${index}.repaired_${index}";
      "posthook_rerun_${index}" expression => "posthook_persistent_${index}.command_execution_${posthook_canon[${index}]}_failed",
                                scope =>"namespace",
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
      ifvarclass => "posthook_lauch_${index}|posthook_rerun_${index}";

    #Reporting

    #Technique
    "any" usebundle => rudder_common_reports_generic("${technique_name}", "service_ensure_running_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "The service status \"running\" for ${service[${index}]}"),
      ifvarclass => "status_running_${index}";

    "any" usebundle => rudder_common_reports_generic("${technique_name}", "service_ensure_stopped_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "The service status \"stopped\" for ${service[${index}]}"),
      ifvarclass => "status_stopped_${index}";

    "report_${index}" usebundle  => rudder_common_report("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services status", "${service[${index}]}", "No status imposed"),
      ifvarclass => "status_dont_change_${index}";




    "any" usebundle => rudder_common_reports_generic("${technique_name}", "service_ensure_started_at_boot_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "The service boot status \"enabled\" for ${service[${index}]}"),
      ifvarclass => "boot_enabled_${index}";

    "any" usebundle => rudder_common_reports_generic("${technique_name}", "service_ensure_disabled_at_boot_${service_canon[${index}]}", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "The service boot status \"disabled\" for ${service[${index}]}"),
      ifvarclass => "boot_disabled_${index}";

    "report_${index}" usebundle  => rudder_common_report("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services boot status", "${service[${index}]}", "No boot status imposed"),
      ifvarclass => "boot_dont_change_${index}";

    pass3::
      #Posthook
      #Case with execution
      "any" usebundle => rudder_common_reports_generic("${technique_name}", "command_execution_${posthook_canon[${index}]}", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "The command ${posthook[${index}]} from postHook execution "),
        ifvarclass => "command_execution_${posthook_canon[${index}]}_reached";

      #Case without execution
      "report_${index}" usebundle  => rudder_common_report("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "No post-modification needed to run"),
        ifvarclass => "!repaired_${index}.posthook_specified_${index}.!command_execution_${posthook_canon[${index}]}_reached";

      #Case where no posthook set
      "report_hook_${index}" usebundle  => rudder_common_report("${technique_name}", "result_na", "${trackingkey[${index}]}", "Services posthook", "${service[${index}]}", "No post-modification set to run"),
        ifvarclass => "!posthook_specified_${index}";

}

