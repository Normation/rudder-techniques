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


#
# Fetch the promises from the server to be available for others machines
# Must not do it on the RootServer though...


bundle agent propagatePromises
{

  vars:
    any::
      "server_data" string => "${server_info.policy_files}/share"; #actual directory with data to propagate
      "client_data" string => "${g.rudder_var}/share/";  #where to put the files on the client when downloaded

  classes:
    root_server::
      "rudder_tools_updated_exists" expression => fileexists("${g.rudder_tools_updated_origin}");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    root_server::

      "${g.rudder_tools}"
        copy_from    => copy("${g.rudder_base}/share/tools"),
        depth_search => recurse_visible("inf"),
        comment => "Fetching the tools for the promises execution",
        classes => classes_generic("propagate_tools");

      "${g.rudder_ncf_origin_local}/ncf.conf"
        copy_from    => copy_digest("${sys.workdir}/inputs/distributePolicy/ncf/ncf.conf"),
        comment      => "Enforce the ncf configuration file",
        classes      => classes_generic("configure_ncf_config");

    policy_server.!root_server::

      "${client_data}"  #that's a loop on each files in client_inputs
        copy_from    => remote("${server_info.cfserved}","${server_data}"),
        depth_search => recurse_visible("inf"),
        comment => "Fetching the promises to propagate",
        classes => if_else("promises_propagated", "could_not_propagate_promise");

      "${g.rudder_ncf_origin_local}"
        copy_from    => remote("${server_info.cfserved}","${g.rudder_ncf_origin_local}"),
        depth_search => recurse_visible("inf"),
        comment      => "Fetching the ncf local to propagate",
        classes      => if_else("ncf_local_promises_propagated", "could_not_propagate_ncf_local_promise");

      "${g.rudder_ncf_origin_common}"
        copy_from    => remote("${server_info.cfserved}","${g.rudder_ncf_origin_common}"),
        depth_search => recurse_visible("inf"),
        comment      => "Fetching the ncf common to propagate",
        classes      => if_else("ncf_common_promises_propagated", "could_not_propagate_ncf_common_promise");

      "&SHARED_FILES_FOLDER&"
        copy_from    => remote("${server_info.cfserved}","&SHARED_FILES_FOLDER&"),
        depth_search => recurse_visible("inf"),
        comment => "Fetching the files shared for the promises execution",
        classes => if_else("files_propagated", "could_not_propagate_files");

      "${g.rudder_tools}"
        copy_from    => remote_unsecured("${server_info.cfserved}","${g.rudder_tools}"),
        depth_search => recurse_visible("inf"),
        comment => "Fetching the tools for the promises execution",
        classes => classes_generic("propagate_tools");

      "${sys.workdir}/masterfiles"
        copy_from    => remote("${server_info.cfserved}","${sys.workdir}/masterfiles"),
        depth_search => recurse_visible("inf"),
        file_select => no_license_dat, #We don't want to propagate a wrong license.dat
        comment => "Fetching the bootstrap promises",
        classes => if_else("masterfiles_propagated", "could_not_propagate_masterfiles");

&if(NOVA)&
      "${sys.workdir}/masterfiles/license.dat"
        copy_from    => local_cp("${sys.workdir}/inputs/license.dat"),
        comment => "Putting the right license in the bootstrap",
        classes => if_else("license_copied", "could_not_copy_license");
&endif&

    # If rudder_tools_updated doesn't exist, or if the tools have been updated,
    # set rudder_tools_updated content to current timestamp
    root_server.(!rudder_tools_updated_exists|propagate_tools_repaired)::
      "${g.rudder_tools_updated_origin}"
        create        => "true",
        edit_defaults => empty,
        edit_line     => insert_lines("${sys.date}"),
        comment       => "Update the timestamp in the rudder tool updated file";

  methods:
    root_server::
      "any" usebundle => rudder_common_reports_generic("DistributePolicy", "configure_ncf_config", "&TRACKINGKEY&", "Configure ncf", "None", "Configure ncf");
    !root_server::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_na", "&TRACKINGKEY&", "Configure ncf", "None", "Configuration of ncf is not necessary on non root servers");

    # Success if files are updated or not changed (kept or repaired).
    # root server have only tools to be updated and others have tools,
    # promises, masterfiles folder and licenses to be updated.
    pass3.(((root_server.propagate_tools_ok)|(!root_server.propagate_tools_ok.promises_propagated.masterfiles_propagated.ncf_local_promises_propagated.ncf_common_promises_propagated)).!(propagate_tools_error|could_not_propagate_promise|could_not_propagate_masterfiles|could_not_copy_license|could_not_propagate_ncf_local_promise|could_not_propagate_ncf_common_promise))::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Propagate promises", "None", "All files have been propagated");
    pass3.could_not_propagate_promise::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate policy files");

    pass3.could_not_propagate_files::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate shared files");

    pass3.propagate_tools_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate tools");

    pass3.could_not_propagate_ncf_local_promise::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate local ncf promises");

    pass3.could_not_propagate_ncf_common_promise::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate common ncf promises");

    pass3.could_not_propagate_masterfiles::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot propagate masterfiles");

    pass3.could_not_copy_license::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Propagate promises", "None", "Cannot copy local license");

}

# Sending the inventory to cmdb (or syncing with the server if we are a simple relay)
# We cannot use list of paths (i.e. {"incoming", "accepted-nodes-updates"}) to send the inventories because it cause the transformer to fail
# for some unknown reason, see https://www.rudder-project.org/redmine/issues/4094
bundle agent sendInventoryToCmdb
{

  vars:
    any::
      "incoming_inventory_files" slist => findfiles("${g.rudder_inventories}/incoming/*.ocs", "${g.rudder_inventories}/incoming/*.ocs.gz");
      "updates_inventory_files" slist => findfiles("${g.rudder_inventories}/accepted-nodes-updates/*.ocs", "${g.rudder_inventories}/accepted-nodes-updates/*.ocs.gz");

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    # Root server and relay-top send to the endpoint, every other send as usual to their policy server
    root_server|role_rudder_relay_top::

      "${incoming_inventory_files}"
        transformer => "${g.rudder_tools}/send-clean.sh &CMDBENDPOINT& ${this.promiser} ${g.rudder_inventories}/received/ ${g.rudder_inventories}/failed/",
        classes => rudder_common_classes("rudder_inventory_processing"),
        ifvarclass => "!rudder_inventory_processing_error",
        comment => "Processing a local inventory";

      "${updates_inventory_files}"
        transformer => "${g.rudder_tools}/send-clean.sh &CMDBENDPOINT& ${this.promiser} ${g.rudder_inventories}/received/ ${g.rudder_inventories}/failed/",
        classes => rudder_common_classes("rudder_inventory_processing"),
        ifvarclass => "!rudder_inventory_processing_error",
        comment => "Processing a local inventory";

    policy_server.!(root_server|role_rudder_relay_top)::

      "${g.rudder_inventories}/incoming"
        transformer => "/usr/bin/curl -f -s --proxy '' --user rudder:rudder -T ${this.promiser}  ${g.inventory_upload_protocol}://${server_info.cfserved}/inventories/",
        depth_search => recurse_visible(1),
        file_select => by_name("@{g.inventory_file_types}"),
        classes => rudder_common_classes("rudder_inventory_relay"),
        comment => "Sending an inventory to the root server";

      "${g.rudder_inventories}/accepted-nodes-updates"
        transformer => "/usr/bin/curl -f -s --proxy '' --user ${g.davuser}:${g.davpw} -T ${this.promiser}  ${g.inventory_upload_protocol}://${server_info.cfserved}/inventory-updates/",
        depth_search => recurse_visible(1),
        file_select => by_name("@{g.inventory_file_types}"),
        classes => rudder_common_classes("rudder_inventory_relay"),
        comment => "Sending an inventory to the root server";

    policy_server.!(root_server|role_rudder_relay_top).!rudder_inventory_relay_error::

      "${g.rudder_inventories}/incoming"
        transformer => "/bin/rm -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select => by_name("@{g.inventory_file_types}"),
        classes => rudder_common_classes("rudder_inventory_cleanup"),
        comment => "Purging the received inventory files after processing";

      "${g.rudder_inventories}/accepted-nodes-updates"
        transformer => "/bin/rm -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select => by_name("@{g.inventory_file_types}"),
        classes => rudder_common_classes("rudder_inventory_cleanup"),
        comment => "Purging the received inventory files after processing";

  methods:

    pass3.(rudder_inventory_processing_repaired.!rudder_inventory_processing_error)::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Incoming inventories were successfully added to Rudder");

    pass3.rudder_inventory_processing_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Some inventories failed to add successfully to Rudder");

    pass3.((root_server|role_rudder_relay_top).!rudder_inventory_processing_repaired.!rudder_inventory_processing_error)::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "No inventory to send");

    pass3.(rudder_inventory_relay_repaired.!rudder_inventory_relay_error)::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Incoming inventories were successfully relayed to the root server");

    pass3.rudder_inventory_relay_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Cannot relay some inventories to the root server");

    pass3.(policy_server.!(root_server|role_rudder_relay_top).!rudder_inventory_relay_repaired.!rudder_inventory_relay_error)::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "No inventory to relay");

    pass3.(rudder_inventory_cleanup_repaired.!rudder_inventory_cleanup_error)::
      "any" usebundle => rudder_common_report("DistributePolicy", "log_info", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Sent incoming inventories were removed from local cache");

    pass3.rudder_inventory_cleanup_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Send inventories to CMDB", "None", "Cannot remove incoming inventories from local cache");

}

body file_select no_license_dat
{
        leaf_name => { "license\.dat" };
        file_result => "!leaf_name";
}
