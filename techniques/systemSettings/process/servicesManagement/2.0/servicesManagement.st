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

    SuSE::
      "service_check_boot_status_cmd_${index}" string => "/sbin/chkconfig --check ${service[${index}][name]}";
      "service_add_boot_cmd_${index}"          string => "/sbin/insserv -d ${service[${index}][name]}";
      "service_remove_boot_cmd_${index}"       string => "/sbin/insserv -rd ${service[${index}][name]}";

    redhat::
      "service_check_boot_status_cmd_${index}" string => "/sbin/chkconfig ${service[${index}][name]}";
      "service_add_boot_cmd_${index}"          string => "/sbin/chkconfig ${service[${index}][name]} on";
      "service_remove_boot_cmd_${index}"       string => "/sbin/chkconfig ${service[${index}][name]} off";

    debian::
      "service_add_boot_cmd_${index}"          string => "/usr/sbin/update-rc.d ${service[${index}][name]} remove \&\& /usr/sbin/update-rc.d ${service[${index}][name]} defaults";
      "service_remove_boot_cmd_${index}"       string => "/usr/sbin/update-rc.d -f ${service[${index}][name]} remove \&\& /usr/sbin/update-rc.d ${service[${index}][name]} stop 20 2 3 4 5 .";


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

  files:

    debian::

      "/etc/rc2.d/S.*${service[${index}][name]}.*"
        create => "true",
        action => WarnOnly,
        classes => if_else("service_${index}_bootstarted", "service_${index}_unbootstarted");

  processes:

    # check the service status
      "${service[${index}][process]}"
        comment => "Check the process status",
        restart_class => "process_${index}_restart",
        classes => kept_if_else("service_${index}_running", "service_${index}_anomaly", "service_${index}_error"),
        ifvarclass => "defined_process_name_${index}.(start_process_${index}|(stop_process_${index}.graceful_stop_process_${index}))";

    # enforce that the process is stopped gracefully
    # Should be using process stop, but du to https://cfengine.com/bugtracker/view.php?id=758, it does not work now
    #"${service[${index}][process]}"
    #		comment => "Stop gracefully the process",
    #		process_stop => "/etc/init.d/${service[${index}][name]} stop",
    #		classes => kept_if_else("service_${index}_already_stopped", "service_${index}_stopped", "service_${index}_error"),
    #		ifvarclass => "defined_process_name_${index}.stop_process_${index}.graceful_stop_process_${index}";



    # enforce that the process is stopped not so gracefully
      "${service[${index}][process]}"
        comment => "Stop not so gracefully the process",
        signals => { "${service[${index}][killMethod]}" },
        classes => kept_if_else("service_${index}_already_stopped", "service_${index}_stopped", "service_${index}_error"),
        ifvarclass => "defined_process_name_${index}.stop_process_${index}.(term_stop_process_${index}|kill_stop_process_${index})";


    # check the range
      "${service[${index}][process]}"
        comment => "Check the range of process",
        process_count => check_range("${service[${index}][name]}", "${service[${index}][min_instance]}", "${service[${index}][max_instance]}"),
        ifvarclass => "defined_process_name_${index}.check_process_range_${index}";


  commands:

      "/etc/init.d/${service[${index}][name]}"
        args => "start",
        classes => kept_if_else("process_${index}_restart_ok", "process_${index}_restart_ok", "process_${index}_restart_error"),
        ifvarclass => "process_${index}_restart.start_process_${index}";


      "/etc/init.d/${service[${index}][name]}"
        args => "stop",
        classes => kept_if_else("process_${index}_stopped_ok", "process_${index}_stopped_ok", "process_${index}_stop_error"),
        ifvarclass => "!process_${index}_restart.stop_process_${index}";

      "/etc/init.d/${service[${index}][name]}"
        args => "restart",
        classes => kept_if_else("process_${index}_out_of_range_restart_ok", "process_${index}_out_of_range_restart_ok", "process_${index}_out_of_range_restart_error"),
        ifvarclass => canonify("${service[${index}][name]}_out_of_range");


    # Check whether the service is already configured to start on boot

    !debian:: # Debian uses a files promise for this, see above

      "${service_check_boot_status_cmd_${index}}"
        classes => if_else("service_${index}_bootstarted", "service_${index}_unbootstarted"),
        ifvarclass => "bootstart_process_${index}|bootstart_prevent_process_${index}",
        comment => "Check if the service ${service[${index}][name]} is started on boot";

    any::

      "${service_add_boot_cmd_${index}}"
        contain => in_shell,
        classes => if_else("service_${index}_bootstarted_ok", "service_${index}_bootstarted_fail"),
        ifvarclass => "service_${index}_unbootstarted.bootstart_process_${index}",
        comment => "Set the service ${service[${index}][name]} to start on boot";

      "${service_remove_boot_cmd_${index}}"
        contain => in_shell,
        classes => if_else("service_${index}_unbootstarted_ok", "service_${index}_unbootstarted_fail"),
        ifvarclass => "service_${index}_bootstarted.bootstart_prevent_process_${index}",
        comment => "Set the service ${service[${index}][name]} to not be started on boot";

  reports:
    linux::

      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} didn't need to have its process checked"
        ifvarclass => "!start_process_${index}.!stop_process_${index}";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Cannot check the status of ${service[${index}][name]}: the process name is not filed"
        ifvarclass => "!defined_process_name_${index}.(start_process_${index}|stop_process_${index})";

      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was indeed running"
        ifvarclass => "service_${index}_running.!service_${index}_anomaly.!process_${index}_restart.start_process_${index}";

      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was not running and has been restarted"
        ifvarclass => "process_${index}_restart.process_${index}_restart_ok.start_process_${index}";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]}: the process couldn't be started"
        ifvarclass => "process_${index}_restart_error";

      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was indeed not running"
        ifvarclass => "stop_process_${index}.process_${index}_restart.graceful_stop_process_${index}";

      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was stopped"
        ifvarclass => "stop_process_${index}.!process_${index}_restart.process_${index}_stopped_ok.graceful_stop_process_${index}";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]}: the process could't be stopped"
        ifvarclass => "stop_process_${index}.!process_${index}_restart.process_${index}_stop_error.graceful_stop_process_${index}";



      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was indeed not running"
        ifvarclass => "stop_process_${index}.service_${index}_already_stopped.!service_${index}_stopped.!graceful_stop_process_${index}";

      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Process of ${service[${index}][name]} was stopped"
        ifvarclass => "stop_process_${index}.service_${index}_stopped.!graceful_stop_process_${index}";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Process@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]}: the process count could't be stopped"
        ifvarclass => "stop_process_${index}.service_${index}_error.!graceful_stop_process_${index}";


      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Advanced options@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#The process range is not to be checked for service ${service[${index}][name]}"
        ifvarclass => "!check_process_range_${index}";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Advanced options@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#The process range for service ${service[${index}][name]} cannot to be checked, for the process name is not set"
        ifvarclass => "check_process_range_${index}.!defined_process_name_${index}";


      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Advanced options@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#The process range for service ${service[${index}][name]} is correct"
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.!${service[${index}][canon_name]}_out_of_range";


      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Advanced options@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#The process range for service ${service[${index}][name]} was not correct, but was repaired"
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.${service[${index}][canon_name]}_out_of_range.process_${index}_out_of_range_restart_ok";


      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Advanced options@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#The process range for service ${service[${index}][name]} was not correct, but was repaired"
        ifvarclass => "check_process_range_${index}.defined_process_name_${index}.${service[${index}][canon_name]}_out_of_range.process_${index}_out_of_range_restart_error";


    # Service boot starting parameters

      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} starting parameters check not required"
        ifvarclass => "!bootstart_process_${index}.!bootstart_prevent_process_${index}";

      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} is started on boot as required"
        ifvarclass => "bootstart_process_${index}.service_${index}_bootstarted";

      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} has been set to start on boot"
        ifvarclass => "bootstart_process_${index}.service_${index}_bootstarted_ok";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Could not set ${service[${index}][name]} to start on boot!"
        ifvarclass => "bootstart_process_${index}.service_${index}_bootstarted_fail";



      "@@ServicesManagement@@result_success@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} is not started on boot as required"
        ifvarclass => "!bootstart_process_${index}.bootstart_prevent_process_${index}";

      "@@ServicesManagement@@result_repaired@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#${service[${index}][name]} has been prevented to start on boot"
        ifvarclass => "bootstart_prevent_process_${index}.service_${index}_unbootstarted_ok";

      "@@ServicesManagement@@result_error@@${service[${index}][uuid]}@@Service starting parameters@@${service[${index}][name]}@@${g.execRun}##${g.uuid}@#Could not prevent ${service[${index}][name]} to start on boot!"
        ifvarclass => "bootstart_prevent_process_${index}.service_${index}_unbootstarted_fail";


}
