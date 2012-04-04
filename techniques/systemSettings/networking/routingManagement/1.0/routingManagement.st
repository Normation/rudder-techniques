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

##########################################################################
# Routing management PT                                                  #
#                                                                        #
# Objective: Check the routing parameters according to the given ones   #
# and take the required actions (check or require)                       #
##########################################################################

bundle agent check_routing_parameters {

	vars:

		&ROUTING_FOUR_DESTINATION:{destination |"route[&i&]" string => "&destination&";
}&

		&ROUTING_FOUR_GATEWAY:{gateway |"gateway[&i&]" string => "&gateway&";
}&

		&ROUTING_FOUR_NETMASK:{netmask |"mask[&i&]" string => "&netmask&";
}&

		&ROUTING_FOUR_ACTION:{action |"action[&i&]" string => "&action&";
}&

		&TRACKINGKEY:{directiveId |"routing_directive_id[&i&]" string => "&directiveId&";
}&

		"routing_index" slist => getindices("route");

		"displayName[$(routing_index)]" string => "$(route[$(routing_index)]) / $(mask[$(routing_index)]) to $(gateway[$(routing_index)])";

	classes:

		"checkroute_present" expression => fileexists("${g.rudder_dependencies}/checkroute.pl");

	commands:

		linux.checkroute_present::

			"${g.rudder_dependencies}/checkroute.pl $(route[$(routing_index)]) $(mask[$(routing_index)]) $(gateway[$(routing_index)]) $(routing_index) $(action[$(routing_index)]) linux"
				contain => in_shell,
				module => "true",
				comment => "Analysing routes";

			"/sbin/route add -net $(route[$(routing_index)]) netmask $(mask[$(routing_index)]) gw $(gateway[$(routing_index)])"
				contain => in_shell,
				ifvarclass => canonify("route_$(routing_index)_add"),
				classes => cf2_if_else("route_$(routing_index)_added", "route_$(routing_index)_add_failed");

			"/sbin/route del -net $(route[$(routing_index)]) netmask $(mask[$(routing_index)]) gw $(gateway[$(routing_index)])"
				contain => in_shell,
				ifvarclass => canonify("route_$(routing_index)_delete"),
				classes => cf2_if_else("route_$(routing_index)_deleted", "route_$(routing_index)_delete_failed");


		windows.checkroute_present::

			"\"${g.rudder_base_sbin}\perl\bin\perl.exe\""
				args => "\"${g.rudder_dependencies}\checkroute.pl\" $(route[$(routing_index)]) $(mask[$(routing_index)]) $(gateway[$(routing_index)]) $(routing_index) $(action[$(routing_index)]) windows",
				contain => in_shell,
				module => "true",
				comment => "Analysing routes";

			"\"${sys.winsysdir}\route.exe\""
				args => "ADD $(route[$(routing_index)]) MASK $(mask[$(routing_index)]) $(gateway[$(routing_index)])",
				contain => in_shell,
				ifvarclass => canonify("route_$(routing_index)_add"),
				classes => cf2_if_else("route_$(routing_index)_added", "route_$(routing_index)_add_failed");

			"\"${sys.winsysdir}\route.exe\""
				args => "DELETE $(route[$(routing_index)])",
				contain => in_shell,
				ifvarclass => canonify("route_$(routing_index)_delete"),
				classes => cf2_if_else("route_$(routing_index)_deleted", "route_$(routing_index)_delete_failed");

	reports:

		(windows|linux).checkroute_present::
			
			"@@routingManagement@@result_success@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) found, as expected."
				ifvarclass => canonify("route_$(routing_index)_found");

			# This should be a log_warn, when it's supported
			"@@routingManagement@@result_error@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) found, and policy is: Check absence!"
				ifvarclass => canonify("route_$(routing_index)_found_warn");

			"@@routingManagement@@result_success@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) not found, as expected"
				ifvarclass => canonify("route_$(routing_index)_notfound");

			# This should be a log_warn, when it's supported
			"@@routingManagement@@result_error@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) not found , and policy is: Check presence!"
				ifvarclass => canonify("route_$(routing_index)_notfound_warn");

			"@@routingManagement@@log_info@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) not found, attempting to add route..."
				ifvarclass => canonify("route_$(routing_index)_add");

			"@@routingManagement@@result_repaired@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) added successfully!"
				ifvarclass => canonify("route_$(routing_index)_added");

			"@@routingManagement@@result_error@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Could not add route $(displayName[$(routing_index)])!"
				ifvarclass => canonify("route_$(routing_index)_add_failed");

			"@@routingManagement@@result_repaired@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Route $(displayName[$(routing_index)]) deleted successfully!"
				ifvarclass => canonify("route_$(routing_index)_deleted");

			"@@routingManagement@@result_error@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Could not delete route $(displayName[$(routing_index)])!"
				ifvarclass => canonify("route_$(routing_index)_delete_failed");

		(windows|linux).!checkroute_present::

			"@@routingManagement@@result_error@@$(routing_directive_id[$(routing_index)])@@IPv4 routing parameters@@$(route[$(routing_index)])@@$(g.execRun)##$(g.uuid)@#Could not add route $(displayName[$(routing_index)]): helper program checkroute.pl not found!";

}
