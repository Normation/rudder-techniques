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

#body common control {
#	bundlesequence => { "root_init_check" };
#	inputs => { "/var/rudder/cfengine-community/inputs/common/1.0/cfengine_stdlib.cf", "/var/rudder/cfengine-community/inputs/common/1.0/core-lib.cf", "/var/rudder/cfengine-community/inputs/common/1.0/library.cf" };
#}

bundle agent root_init_check {

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

	processes:

		# check the service status
		"$(service[$(index)][binary])"
				comment => "Check the process status",
				restart_class => "process_$(index)_restart",
				classes => kept_if_else("service_$(index)_running", "service_$(index)_anomaly", "service_$(index)_error");

	commands:

		"/etc/init.d/$(service[$(index)][initscript])"
			args => "start",
			action => bg("0", "120"),
			classes => kept_if_else("process_$(index)_restart_ok", "process_$(index)_restart_ok", "process_$(index)_restart_error"),
			ifvarclass => "process_$(index)_restart";

	(SuSE|redhat)::

			"/sbin/chkconfig"
				args => "--check $(service[$(index)][initscript])",
				classes => if_else("service_$(index)_bootstarted", "service_$(index)_unbootstarted"),
				comment => "Check if the service $(service[$(index)][initscript]) is started on boot";

			"/sbin/insserv"
				args => "-d $(service[$(index)][initscript])",
				classes => if_else("service_$(index)_bootstarted_ok", "service_$(index)_bootstarted_fail"),
				ifvarclass => "service_$(index)_unbootstarted",
				comment => "Set the service $(service[$(index)][initscript]) to start on boot";

	debian::

			"/usr/sbin/update-rc.d $(service[$(index)][initscript]) remove \&\& /usr/sbin/update-rc.d $(service[$(index)][initscript]) defaults"
				contain => in_shell,
				classes => if_else("service_$(index)_bootstarted_ok", "service_$(index)_bootstarted_fail"),
				ifvarclass => "service_$(index)_unbootstarted",
				comment => "Set the service $(service[$(index)][initscript]) to start on boot";

	files:

		debian::

                        "/etc/rc2.d/S.*$(service[$(index)][initscript]).*"
                                create => "true",
                                action => WarnOnly,
                                classes => if_else("service_$(index)_bootstarted", "service_$(index)_unbootstarted");

	reports:

	  linux::

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Process of $(service[$(index)][initscript]) was indeed running"
			ifvarclass => "!process_$(index)_restart";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Process of $(service[$(index)][initscript]) was not running and has been restarted"
			ifvarclass => "process_$(index)_restart.process_$(index)_restart_ok";

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#$(service[$(index)][initscript]): the process couldn't be started"
			ifvarclass => "process_$(index)_restart_error";

		# Service boot starting parameters

		"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#$(service[$(index)][initscript]) is started on boot as required"
			ifvarclass => "service_$(index)_bootstarted";

		"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#$(service[$(index)][initscript]) has been set to start on boot"
			ifvarclass => "!service_$(index)_bootstarted.service_$(index)_bootstarted_ok";

		"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Could not set $(service[$(index)][initscript]) to start on boot!"
			ifvarclass => "!service_$(index)_bootstarted.service_$(index)_bootstarted_fail";

}
