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

bundle agent root_init_check() {

	vars:

		"service[1][binary]" string => "/opt/rudder/libexec/slapd";
		"service[1][initscript]" string => "slapd";

		"service[2][binary]" string => ".*java.*/opt/rudder/jetty7/start.jar";
		"service[2][initscript]" string => "jetty";

		"service[3][binary]" string => "postgres: writer process";
		"service[3][initscript]" string => "postgresql";

		"service[4][binary]" string => "/var/rudder/cfengine-community/bin/cf-.*";
		"service[4][initscript]" string => "cfengine-community";

		"index" slist => getindices("service");

	methods:

		"any" usebundle => generic_process_check_process("$(service[$(index)][binary])", "$(service[$(index)][initscript])", "false");
		"any" usebundle => generic_process_check_bootstart("$(service[$(index)][binary])", "$(service[$(index)][initscript])");

}

bundle agent generic_process_check_process(binary, initscript, force_restart) {

	classes:

			"forced_trigger" expression => strcmp("$(force_restart)", "true");

	processes:

		# check the service status
		"$(binary)"
				comment => "Check the process status",
				restart_class => "process_restart",
				classes => kept_if_else("service_running", "service_anomaly", "service_error");

	commands:

		"/etc/init.d/$(initscript)"
			args => "restart </dev/null >/dev/null 2>/dev/null",
			contain => in_shell_silent,
			# action => bg("0", "120"),
			classes => kept_if_else("process_restart_ok", "process_restart_ok", "process_restart_error"),
			ifvarclass => "process_restart|forced_trigger";

	reports:

	  linux::

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(initscript) process is already running"
			ifvarclass => "!process_restart.!forced_trigger";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(initscript) process was not running and has been restarted"
			ifvarclass => "process_restart.process_restart_ok.!forced_trigger";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(initscript) process has been restarted"
			ifvarclass => "process_restart_ok.forced_trigger";

		"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(initscript) process couldn't be restarted"
			ifvarclass => "process_restart_error";

}

bundle agent generic_process_check_bootstart(binary, initscript) {

	commands:

	(SuSE|redhat)::

			"/sbin/chkconfig"
				args => "--check $(initscript)",
				classes => if_else("service_bootstarted", "service_unbootstarted"),
				comment => "Check if the service $(initscript) is started on boot";

			"/sbin/insserv"
				args => "-d $(initscript)",
				classes => if_else("service_bootstarted_ok", "service_bootstarted_fail"),
				ifvarclass => "service_unbootstarted",
				comment => "Set the service $(initscript) to start on boot";

	debian::

			"/usr/sbin/update-rc.d $(initscript) remove \&\& /usr/sbin/update-rc.d $(initscript) defaults"
				contain => in_shell,
				classes => if_else("service_bootstarted_ok", "service_bootstarted_fail"),
				ifvarclass => "service_unbootstarted",
				comment => "Set the service $(initscript) to start on boot";

	files:

		debian::

                        "/etc/rc2.d/S.*$(initscript).*"
                                create => "true",
                                action => WarnOnly,
                                classes => if_else("service_bootstarted", "service_unbootstarted");

	reports:

	  linux::

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#$(initscript) is started on boot as required"
			ifvarclass => "service_bootstarted";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#$(initscript) has been set to start on boot"
			ifvarclass => "!service_bootstarted.service_bootstarted_ok";

		"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Could not set $(initscript) to start on boot!"
			ifvarclass => "!service_bootstarted.service_bootstarted_fail";

}
