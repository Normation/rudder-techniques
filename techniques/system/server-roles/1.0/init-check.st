#####################################################################################
# Copyright 2014 Normation SAS
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

bundle agent generic_process_check_process(binary, initscript, name, force_restart, check_on_relay_server) {

  vars:

      "canoname" string => canonify("${binary}");

  classes:

      "forced_trigger_${canoname}" expression => strcmp("${force_restart}", "true");

      # Raise this class if we are handling a process that should be checked even on
      # relay servers.
      "process_exception_on_relay" expression => strcmp("${check_on_relay_server}", "true");

  processes:

    root_server|process_exception_on_relay::

    # check the service status
      "${binary}"
        comment => "Check the process status",
        restart_class => "process_restart_${canoname}",
        classes => kept_if_else("service_running_${canoname}", "service_anomaly_${canoname}", "service_error_${canoname}");

  commands:

    root_server|process_exception_on_relay::

      "/etc/init.d/${initscript}"
        args => "restart </dev/null >/dev/null 2>/dev/null",
        contain => in_shell_silent,
      # action => bg("0", "120"),
        classes => kept_if_else("process_restart_ok_${canoname}", "process_restart_ok_${canoname}", "process_restart_error_${canoname}"),
        ifvarclass => "process_restart_${canoname}|forced_trigger_${canoname}";

  reports:

    root_server|process_exception_on_relay::

		"@@server-roles@@result_success@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process is already running"
			ifvarclass => "!process_restart_${canoname}.!forced_trigger_${canoname}";

		"@@server-roles@@result_repaired@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process was not running and has been restarted"
			ifvarclass => "process_restart_${canoname}.process_restart_ok_${canoname}.!forced_trigger_${canoname}";

		"@@server-roles@@result_repaired@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process has been restarted"
			ifvarclass => "process_restart_ok_${canoname}.forced_trigger_${canoname}";

		"@@server-roles@@result_error@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process couldn't be restarted"
			ifvarclass => "process_restart_error_${canoname}";

    policy_server.!root_server.!process_exception_on_relay::

		"@@server-roles@@result_success@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process do not need to be checked on relay servers. Skipping...";

}

bundle agent generic_process_check_bootstart(binary, initscript, name) {

  vars:

      "canoname" string => canonify("${binary}");

    SuSE::

      "check_command"     string => "/sbin/chkconfig --check ${initscript}";
      "bootstart_command" string => "/sbin/insserv -d ${initscript}";

    redhat::

      "check_command"     string => "/sbin/chkconfig --list ${initscript} | grep -q on";
      "bootstart_command" string => "/sbin/chkconfig ${initscript} on";

  files:

    debian::

      "/etc/rc2.d/S.*${initscript}.*"
        create => "true",
        action => WarnOnly,
        classes => if_else("service_bootstarted_${canoname}", "service_unbootstarted_${canoname}");

	commands:

    (SuSE|redhat)::

      "${check_command}"
        contain => in_shell_silent,
        classes => if_else("service_bootstarted_${canoname}", "service_unbootstarted_${canoname}"),
        comment => "Check if the service ${name} is started on boot";


      "${bootstart_command}"
        classes => if_else("service_bootstarted_ok_${canoname}", "service_bootstarted_fail_${canoname}"),
        ifvarclass => "service_unbootstarted_${canoname}",
        comment => "Set the service ${name} to start on boot";

    debian::

      "/usr/sbin/update-rc.d ${initscript} remove \&\& /usr/sbin/update-rc.d ${initscript} defaults"
        contain => in_shell,
        classes => if_else("service_bootstarted_ok_${canoname}", "service_bootstarted_fail_${canoname}"),
        ifvarclass => "service_unbootstarted_${canoname}",
        comment => "Set the service ${name} to start on boot";

  reports:

    cfengine::

      "@@server-roles@@result_success@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#${name} is started on boot as required"
        ifvarclass => "service_bootstarted_${canoname}";

      "@@server-roles@@result_repaired@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#${name} has been set to start on boot"
        ifvarclass => "!service_bootstarted_${canoname}.service_bootstarted_ok_${canoname}";

      "@@server-roles@@result_error@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#Could not set ${name} to start on boot!"
        ifvarclass => "!service_bootstarted_${canoname}.service_bootstarted_fail_${canoname}";

}
