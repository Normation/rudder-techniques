#####################################################################################
# Copyright 2012 Normation SAS
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

bundle agent root_networks_check {

	vars:

			"networks" string => join("$(const.n)Allow from ","def.acl");

	files:

			"/opt/rudder/etc/rudder-networks.conf"
				create => "true",
				perms => mog("644", "root", "root"),
				edit_defaults => empty,
				edit_line => insert_lines("Allow from 127.0.0.0/8$(const.n)Allow from $(networks)"),
				classes => kept_if_else("rudder_networks_ok", "rudder_networks_repaired","rudder_networks_failed"),
			        comment => "Copying rudder apache configuration";


	commands:

		rudder_networks_repaired::

			"/etc/init.d/apache2"
				args => "reload",
				classes => if_else("apache_restarted", "apache_restart_failed");

	reports:

		linux::

			"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(file_path) apache configuration file is OK"
				ifvarclass => "rudder_networks_ok.!rudder_networks_repaired.!rudder_networks_failed";

			"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(file_path) apache configuration file has been corrected"
				ifvarclass => "rudder_networks_repaired.!rudder_networks_failed";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The $(file_path) apache configuration file was NOT edited because of an error"
				ifvarclass => "rudder_networks_failed";

			"@@DistributePolicy@@log_info@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Apache HTTPd has been reloaded successfully"
				ifvarclass => "apache_restarted.!apache_restart_failed";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Apache HTTPd failed to restart"
				ifvarclass => "apache_restart_failed";

}
