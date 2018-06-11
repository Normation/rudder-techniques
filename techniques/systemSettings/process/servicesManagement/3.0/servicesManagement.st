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

# Enforce the defined services parameters

bundle agent services_management
{
  vars:

    &SERVICE_MANAGED_NAME:{name |"service[&i&][name]" string => "&name&";
}&
    &SERVICE_MANAGED_NAME:{name |"service[&i&][canon_name]" string => canonify("&name&");
}&
    &PROCESS_MANAGED_NAME:{process |"service[&i&][process]" string => "&process&";
}&
    &PROCESS_MANAGED_RUNNING:{running |"service[&i&][running]" string => "&running&";
}&
    &PROCESS_MANAGED_KILLING_METHOD:{kill |"service[&i&][killMethod]" string => "&kill&";
}&
    &PROCESS_MANAGED_MIN_INSTANCES:{min_instance |"service[&i&][min_instance]" string => "&min_instance&";
}&
    &PROCESS_MANAGED_MAX_INSTANCES:{max_instance |"service[&i&][max_instance]" string => "&max_instance&";
}&
    &TRACKINGKEY:{piuuid |"service[&i&][uuid]" string => "&piuuid&";
}&

      "index" slist => getindices("service");

  classes:
    &PROCESS_MANAGED_NAME:{name |"defined_process_name_&i&" not => strcmp("&name&", "");
}&
    &PROCESS_MANAGED_CHECK_RANGE:{check |"check_process_range_&i&" expression => strcmp("&check&", "true");
}&
    &PROCESS_MANAGED_RUNNING:{running |"start_process_&i&" expression => strcmp("&running&", "true");
}&
    &PROCESS_MANAGED_RUNNING:{running |"stop_process_&i&" expression => strcmp("&running&", "false");
}&
    &PROCESS_MANAGED_KILLING_METHOD:{kill |"graceful_stop_process_&i&" expression => strcmp("&kill&", "graceful");
}&
    &PROCESS_MANAGED_KILLING_METHOD:{kill |"term_stop_process_&i&" expression => strcmp("&kill&", "term");
}&
    &PROCESS_MANAGED_KILLING_METHOD:{kill |"kill_stop_process_&i&" expression => strcmp("&kill&", "kill");
}&
    &PROCESS_MANAGED_BOOTSTART:{bootstart |"bootstart_process_&i&" expression => strcmp("&bootstart&", "true");
}&
    &PROCESS_MANAGED_BOOTSTART:{bootstart |"bootstart_prevent_process_&i&" expression => strcmp("&bootstart&", "false");
}&

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    debian::

      "/etc/rc2.d/S.*${service[${index}][name]}.*"
        create => "true",
        action => WarnOnly,
        classes => if_else("service_${index}_bootstarted", "service_${index}_unbootstarted");

  methods:

    pass2::

      "bootstart_process"   usebundle => service_ensure_started_at_boot("${service[${index}][name]}"),
                           ifvarclass => "bootstart_process_${index}";

      "unbootstart_process" usebundle => service_ensure_disabled_at_boot("${service[${index}][name]}"),
                           ifvarclass => "bootstart_prevent_process_${index}|(stop_process_${index}.graceful_stop_process_${index})";


    # This is doner after the CFEngine built in services promises (which are used at the end of the bundle)
    # The process name must be filled in order to manage the process status
      "start_process"       usebundle => service_start("${service[${index}][name]}"),
                           ifvarclass => "(process_${index}_restart|windows).start_process_${index}.defined_process_name_${index}";

    # Stop process is used only when a "gracefull" stop is selected by the user
      "stop_process"        usebundle => service_stop("${service[${index}][name]}"),
                           ifvarclass => "(!process_${index}_restart|windows).(stop_process_${index}.!service_${index}_already_stopped).defined_process_name_${index}";

    # Used when the process number is out of range
      "restart_process"     usebundle => service_restart("${service[${index}][name]}"),
                           ifvarclass => "${service[${index}][canon_name]}_out_of_range.defined_process_name_${index}";

    pass3::

      "any" usebundle => rudder_common_report("ServicesManagement", "result_success", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "${service[${index}][name]} didn't need to have its process checked"),
        ifvarclass => "!start_process_${index}.!stop_process_${index}";

    # On windows, we don't use processes promises type to check if process are running, as we rely directly on services
    !windows.pass3::
    # Error when a state (start, stop, etc.) is selected but no process name is given
      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Cannot check the status of ${service[${index}][name]}: the process name is not filed"),
        ifvarclass => "!defined_process_name_${index}.(start_process_${index}|stop_process_${index})";

    # Process start/restart
      "any" usebundle => rudder_common_report("ServicesManagement", "result_success", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} is running"),
        ifvarclass => "service_${index}_running.!service_${index}_anomaly.!process_${index}_restart.start_process_${index}";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_repaired", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} was not running and has been restarted"),
        ifvarclass => "process_${index}_restart.start_process_${index}.service_start_${service[${index}][canon_name]}_repaired";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "${service[${index}][name]}: the process couldn't be started"),
        ifvarclass => "service_start_${service[${index}][canon_name]}_not_ok";

    # Process stop
    # For graceful stop we use the ncf service_stop, for less graceful stopping we use unix signals and cf-engine processes promises
      "any" usebundle => rudder_common_report("ServicesManagement", "result_success", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} is not running"),
        ifvarclass => "stop_process_${index}.process_${index}_restart.graceful_stop_process_${index}";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_repaired", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} was stopped"),
        ifvarclass => "stop_process_${index}.!process_${index}_restart.service_stop_${service[${index}][canon_name]}_repaired.graceful_stop_process_${index}";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "${service[${index}][name]}: the process could't be stopped"),
        ifvarclass => "stop_process_${index}.!process_${index}_restart.service_stop_${service[${index}][canon_name]}_not_ok";


      "any" usebundle => rudder_common_report("ServicesManagement", "result_success", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} is not running"),
        ifvarclass => "stop_process_${index}.service_${index}_already_stopped.!service_${index}_stopped.!graceful_stop_process_${index}";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_repaired", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Process of ${service[${index}][name]} was stopped"),
        ifvarclass => "stop_process_${index}.service_${index}_stopped.!graceful_stop_process_${index}";

      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "${service[${index}][name]}: the process count could't be stopped"),
        ifvarclass => "stop_process_${index}.service_${index}_error.!graceful_stop_process_${index}";

  # on windows, the generic methods are directly defining the correct classes, without relying on the process check before hand
    windows.pass3::
      "any" usebundle => rudder_common_reports_generic("ServicesManagement", "service_start_${service[${index}][canon_name]}", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Service ${service[${index}][name]} start" ),
           ifvarclass => "start_process_${index}";
      "any" usebundle => rudder_common_reports_generic("ServicesManagement", "service_stop_${service[${index}][canon_name]}", "${service[${index}][uuid]}", "Process", "${service[${index}][name]}", "Service ${service[${index}][name]} stop" ),
           ifvarclass => "stop_process_${index}";

    pass3::
      "any" usebundle => rudder_common_report("ServicesManagement", "result_na", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "The process range is not to be checked for service ${service[${index}][name]}"),
        ifvarclass => "!check_process_range_${index}";

    # The number of process range is not checked on windows
    !windows.pass3::
      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "The process range for service ${service[${index}][name]} cannot to be checked, for the process name is not set"),
        ifvarclass => "check_process_range_${index}.!defined_process_name_${index}";


      "any" usebundle => rudder_common_report("ServicesManagement", "result_success", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "The process range for service ${service[${index}][name]} is correct"),
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.!${service[${index}][canon_name]}_out_of_range";


      "any" usebundle => rudder_common_report("ServicesManagement", "result_repaired", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "The process range for service ${service[${index}][name]} was not correct, but was repaired"),
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.${service[${index}][canon_name]}_out_of_range.service_restart_${service[${index}][canon_name]}_repaired";


      "any" usebundle => rudder_common_report("ServicesManagement", "result_error", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "The process range for service ${service[${index}][name]} was not correct, and could not be repaired"),
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.${service[${index}][canon_name]}_out_of_range.service_restart_${service[${index}][canon_name]}_not_ok";

    windows.pass3::
      "any" usebundle => rudder_common_report("ServicesManagement", "result_na", "${service[${index}][uuid]}", "Advanced options", "${service[${index}][name]}", "Checking the number of processes within a range is not implemened on Windows"),
        ifvarclass => "check_process_range_${index}";


    # Service boot starting parameters
    pass3::
      "any" usebundle => rudder_common_report("ServicesManagement", "result_na", "${service[${index}][uuid]}", "Service starting parameters", "${service[${index}][name]}", "${service[${index}][name]} starting parameters check not required"),
        ifvarclass => "!bootstart_process_${index}.!bootstart_prevent_process_${index}";
        
      "any" usebundle => rudder_common_reports_generic("ServicesManagement", "service_ensure_started_at_boot_${service[${index}][canon_name]}", "${service[${index}][uuid]}", "Service starting parameters", "${service[${index}][name]}", "The ${service[${index}][name]} boot starting configuration"),
        ifvarclass => "bootstart_process_${index}";
          
      "any" usebundle => rudder_common_reports_generic("ServicesManagement", "service_ensure_disabled_at_boot_${service[${index}][canon_name]}", "${service[${index}][uuid]}", "Service starting parameters", "${service[${index}][name]}", "The ${service[${index}][name]} boot starting configuration"),
        ifvarclass => "bootstart_prevent_process_${index}";


  processes:
    !windows::
    # check the service status
      "${service[${index}][process]}"
        comment => "Check the process status",
        restart_class => "process_${index}_restart",
        classes => kept_if_else("service_${index}_running", "service_${index}_anomaly", "service_${index}_error"),
        ifvarclass => "defined_process_name_${index}.(start_process_${index}|(stop_process_${index}.graceful_stop_process_${index}))";

    # enforce that the process is stopped except when "gracefully" is selected
      "${service[${index}][process]}"
        comment => "Stop not so gracefully the process",
        signals => { "${service[${index}][killMethod]}" },
        classes => kept_if_else("service_${index}_already_stopped", "service_${index}_stopped", "service_${index}_error"),
        ifvarclass => "defined_process_name_${index}.stop_process_${index}.(term_stop_process_${index}|kill_stop_process_${index})";

    # check the process number
      "${service[${index}][process]}"
        comment => "Check the range of process",
        process_count => check_range("${service[${index}][name]}", "${service[${index}][min_instance]}", "${service[${index}][max_instance]}"),
        ifvarclass => "defined_process_name_${index}.check_process_range_${index}";

}
