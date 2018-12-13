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

bundle agent check_routing_parameters
{

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

      "displayName[${routing_index}]" string => "${route[${routing_index}]} / ${mask[${routing_index}]} to ${gateway[${routing_index}]}";

  classes:

      "checkroute_present" expression => fileexists("${g.rudder_tools}/checkroute.pl");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    pass3.checkroute_present::

      "any" usebundle => rudder_common_report_index("routingManagement", "result_success", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} found, as expected.", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_found");

      # This should be a log_warn, when it's supported
      "any" usebundle => rudder_common_report_index("routingManagement", "result_error", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} found, and policy is: Check absence!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_found_warn");

      "any" usebundle => rudder_common_report_index("routingManagement", "result_success", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} not found, as expected", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_notfound");

      # This should be a log_warn, when it's supported
      "any" usebundle => rudder_common_report_index("routingManagement", "result_error", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} not found , and policy is: Check presence!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_notfound_warn");

      "any" usebundle => rudder_common_report_index("routingManagement", "log_info", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} not found, attempting to add route...", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_add");

      "any" usebundle => rudder_common_report_index("routingManagement", "result_repaired", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} added successfully!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_added");

      "any" usebundle => rudder_common_report_index("routingManagement", "result_error", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Could not add route ${displayName[${routing_index}]}!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_add_failed");

      "any" usebundle => rudder_common_report_index("routingManagement", "result_repaired", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Route ${displayName[${routing_index}]} deleted successfully!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_deleted");

      "any" usebundle => rudder_common_report_index("routingManagement", "result_error", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Could not delete route ${displayName[${routing_index}]}!", "${routing_index}"),
        ifvarclass => canonify("route_${routing_index}_delete_failed");

    pass3.(!checkroute_present)::

      "any" usebundle => rudder_common_report_index("routingManagement", "result_error", "${routing_directive_id[${routing_index}]}", "IPv4 routing parameters", "${route[${routing_index}]}", "Could not add route ${displayName[${routing_index}]}: helper program checkroute.pl not found!", "${routing_index}");

  commands:

    checkroute_present::

      "${g.rudder_tools}/checkroute.pl ${route[${routing_index}]} ${mask[${routing_index}]} ${gateway[${routing_index}]} ${routing_index} ${action[${routing_index}]} linux"
        contain => in_shell,
        module => "true",
        comment => "Analysing routes";

      "/sbin/route add -net ${route[${routing_index}]} netmask ${mask[${routing_index}]} gw ${gateway[${routing_index}]}"
        contain => in_shell,
        ifvarclass => canonify("route_${routing_index}_add"),
        classes => cf2_if_else("route_${routing_index}_added", "route_${routing_index}_add_failed");

      "/sbin/route del -net ${route[${routing_index}]} netmask ${mask[${routing_index}]} gw ${gateway[${routing_index}]}"
        contain => in_shell,
        ifvarclass => canonify("route_${routing_index}_delete"),
        classes => cf2_if_else("route_${routing_index}_deleted", "route_${routing_index}_delete_failed");

}
