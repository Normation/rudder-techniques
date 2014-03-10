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

bundle agent root_init_check()
{

  vars:

    "service[1][name]" string => "slapd";
    "service[1][binary]" string => "/opt/rudder/libexec/slapd";
    "service[1][initscript]" string => "rudder-slapd";
    "service[1][check_on_relay_server]" string => "false";

    "service[2][name]" string => "jetty";
    "service[2][binary]" string => ".*java.*/opt/rudder/jetty7/start.jar";
    "service[2][initscript]" string => "rudder-jetty";
    "service[2][check_on_relay_server]" string => "false";

    "service[3][name]" string => "postgresql";
    "service[3][binary]" string => "postgres: writer process";
    "service[3][initscript]" string => "postgresql";
    "service[3][check_on_relay_server]" string => "false";

    "service[4][name]" string => "apache";
    "service[4][check_on_relay_server]" string => "true";

    !redhat::

      "service[4][binary]" string => "apache2";
      "service[4][initscript]" string => "apache2";

    redhat::

      "service[4][binary]" string => "httpd";
      "service[4][initscript]" string => "httpd";

    any::

      "index" slist => getindices("service");

  methods:

    "any" usebundle => generic_process_check_process("${service[${index}][binary]}", "${service[${index}][initscript]}", "${service[${index}][name]}", "false", "${service[${index}][check_on_relay_server]}");
    "any" usebundle => generic_process_check_bootstart("${service[${index}][binary]}", "${service[${index}][initscript]}", "${service[${index}][name]}");

}

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

      "${g.service_management_binary} ${initscript}"
        args => "restart </dev/null >/dev/null 2>/dev/null",
        contain => in_shell_silent,
      # action => bg("0", "120"),
        classes => kept_if_else("process_restart_ok_${canoname}", "process_restart_ok_${canoname}", "process_restart_error_${canoname}"),
        ifvarclass => "process_restart_${canoname}|forced_trigger_${canoname}";

  reports:

    root_server|process_exception_on_relay::

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process is already running"
			ifvarclass => "!process_restart_${canoname}.!forced_trigger_${canoname}";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process was not running and has been restarted"
			ifvarclass => "process_restart_${canoname}.process_restart_ok_${canoname}.!forced_trigger_${canoname}";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process has been restarted"
			ifvarclass => "process_restart_ok_${canoname}.forced_trigger_${canoname}";

		"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process couldn't be restarted"
			ifvarclass => "process_restart_error_${canoname}";

    policy_server.!root_server.!process_exception_on_relay::

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check ${name} process@@None@@${g.execRun}##${g.uuid}@#The ${name} process do not need to be checked on relay servers. Skipping...";

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

  files:

    debian::

      "/etc/rc2.d/S.*${initscript}.*"
        create => "true",
        action => WarnOnly,
        classes => if_else("service_bootstarted_${canoname}", "service_unbootstarted_${canoname}");

  reports:

    cfengine::

      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#${name} is started on boot as required"
        ifvarclass => "service_bootstarted_${canoname}";

      "@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#${name} has been set to start on boot"
        ifvarclass => "!service_bootstarted_${canoname}.service_bootstarted_ok_${canoname}";

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check ${name} boot script@@None@@${g.execRun}##${g.uuid}@#Could not set ${name} to start on boot!"
        ifvarclass => "!service_bootstarted_${canoname}.service_bootstarted_fail_${canoname}";

}
