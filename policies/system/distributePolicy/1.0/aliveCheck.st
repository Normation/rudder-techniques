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
#       bundlesequence => { "root_alive_check" };
#       inputs => { "/var/rudder/cfengine-community/inputs/common/1.0/cfengine_stdlib.cf", "/var/rudder/cfengine-community/inputs/common/1.0/core-lib.cf", "/var/rudder/cfengine-community/inputs/common/1.0/library.cf", "/var/rudder/cfengine-community/inputs/distributePolicy/1.0/initCheck.cf" };
#}

bundle agent root_alive_check {

	vars:

			"site_to_check" slist => { "http://127.0.0.1:8080/" };

			"cleanup_failed_classes" slist => { "site_down_once", "site_alivecheck_restart_jetty" };

		!site_down_once.!first_iteration_passed::

			"failed_result_class" string => "site_down_once";
			"site_failure_persist_time" string => "10";

		site_down_once.!first_iteration_passed::

			"failed_result_class" string => "site_alivecheck_restart_jetty";
			"site_failure_persist_time" string => "0";

	classes:

			"first_iteration_passed" expression => "any";

	methods:
	
			"any" usebundle => generic_process_check_process(".*java.*/opt/rudder/jetty7/start.jar", "jetty", "true"),
				ifvarclass => "site_alivecheck_restart_jetty",
				classes => set_persist_classes("site_alivecheck_jetty_restarted", "site_down_once" ,"0");

	commands:

			"/usr/bin/curl"
				args => "-f $(site_to_check)",
				contain => in_shell_silent,
        			classes => set_persist_classes_alivecheck("site_ok", "$(failed_result_class)", "@(root_alive_check.cleanup_failed_classes)", "$(site_failure_persist_time)"),
			        comment => "Checking if $(site_to_check) is alive";

	reports:

		linux::

			"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Rudder web application is running"
				ifvarclass => "site_ok.!site_down";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Rudder web application is DOWN!"
				ifvarclass => "site_down";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#This is the first time the web application failed to respond. Deferring the restart."
				ifvarclass => "site_down_once";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The web application failed to respond for the second time. Restarting jetty NOW !"
				ifvarclass => "site_alivecheck_restart_jetty";

}

body classes set_persist_classes_alivecheck(repaired, failed, cancelifok, length) {
  promise_kept     => { "$(repaired)" };
  promise_repaired => { "$(repaired)" };
  repair_failed    => { "$(failed)" };
  repair_denied    => { "$(failed)" };
  repair_timeout   => { "$(failed)" };
  
  cancel_kept => {"@(cancelifok)"};
  cancel_repaired => {"@(cancelifok)"};
  cancel_notkept => {"$(repaired)"};
   
  persist_time => "$(length)";
}
