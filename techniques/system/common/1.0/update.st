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
# Define what an agent has to do when it updates
# its promises
#

#simple copy method
body copy_from remote(server, path)
{

        servers    => {
          "${server}"
        };
        encrypt    => "true";
        trustkey   => "true";
        source     => "${path}";
        compare    => "digest";
        preserve   => "false"; #preserver permissions
        verify     => "true";
        purge      => "true";
    community_edition::
        portnumber => "&COMMUNITYPORT&";

}

#simple copy method, unencrypted
body copy_from remote_unsecured(server, path)
{

        servers    => {
          "${server}"
        };
        encrypt    => "false";
        trustkey   => "true";
        source     => "${path}";
        compare    => "mtime";
        preserve   => "true"; #preserver permissions
        verify     => "true";
        purge      => "true";
    community_edition::
        portnumber => "&COMMUNITYPORT&";

}

body copy_from copy_digest_without_perms(from)
{
        source      => "${from}";
        copy_backup => "false";
        preserve    => "false";
        compare     => "digest";
        purge       => "true";
    community_edition::
        portnumber => "&COMMUNITYPORT&";
}

body copy_from remote_unsecured_without_perms(server, path)
{

        servers    => {
          "${server}"
        };
        encrypt    => "false";
        trustkey   => "true";
        source     => "${path}";
        compare    => "digest";
        preserve   => "false";
        verify     => "true";
        purge      => "true";
    community_edition::
        portnumber => "&COMMUNITYPORT&";

}

bundle common server_info
{
  vars:
    any::
      "policy_files" string => "/var/rudder/share/&UUID&";   #directory where to look for promises in the server for that client

      "policy_server_file"
        string  => translatepath("${sys.workdir}/policy_server.dat"),
        comment => "Path to file containing address to policy server";

   # Use localhost as default policy_server if no policy_server.dat exists
    policy_server_set::
      "cfserved" string => readfile("${policy_server_file}", 2048);
    !policy_server_set::
      "cfserved" string => "rudder";

  classes:
      "policy_server_set" expression => fileexists("${server_info.policy_server_file}");
}

# The update is now split in two parts
# - the action part, only launched during failsafe
#   it copies files, restarts deamons, defines persistent classes
# - the report part, not done during failsafe but during regular run
#   note that if in verbose_mode, then the reporting will be done
#   as well during failsafe
#
# Since the defined class are persistent, the classes are still
# available during the "normal" agent execution, for reporting
bundle agent update
{
  methods:
    failsafe::
      "update" usebundle => update_action;
    (!failsafe|verbose_mode)::
      "report" usebundle => update_reports;

  reports:
    # We want to have always reports if something goes bad
    rudder_promises_generated_error|no_update::
      "*********************************************************************************
* rudder-agent could not get an updated configuration from the policy server.   *
* This can be caused by a network issue, an unavailable server, or if this      *
* node was deleted from the Rudder root server.                                 *
* Any existing configuration policy will continue to be applied without change. *
*********************************************************************************"
      action => immediate;
}

bundle agent update_action
{
  vars:

      "client_inputs"        string => "${sys.workdir}/inputs";  #where to put the files on the client when downloaded
      "file_to_check_update" string => "rudder_promises_generated";
    nova_edition::
      "server_inputs"        string => "${server_info.policy_files}/rules/cfengine-nova"; #actual directory with promises
    community_edition::
      "server_inputs"        string => "${server_info.policy_files}/rules/cfengine-community"; #actual directory with promises

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    any::
      "${g.rudder_ncf}/."
        create  => "true",
        comment => "Make sure the ncf directory exists";

    root_server::
      "${g.rudder_ncf}/common"
        copy_from    => copy_digest_without_perms("${g.rudder_ncf_origin_common}"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        perms        => u_mog("644", "root", "root"),
        action       => immediate,
        classes      => success("rudder_ncf_common_updated", "rudder_ncf_common_update_error", "rudder_ncf_common_updated_ok"),
        comment      => "Update the common Rudder ncf instance";

      "${g.rudder_ncf}/local"
        copy_from    => copy_digest_without_perms("${g.rudder_ncf_origin_local}"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        perms        => u_mog("644", "root", "root"),
        action       => immediate,
        classes      => success("rudder_ncf_local_updated", "rudder_ncf_local_update_error", "rudder_ncf_local_updated_ok"),
        comment      => "Update the local Rudder ncf instance";

    !root_server::
      "${g.rudder_ncf}/common"
        copy_from    => remote_unsecured_without_perms("${server_info.cfserved}", "${g.rudder_ncf_origin_common}"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        perms        => u_mog("644", "root", "0"),
        action       => immediate,
        classes      => success("rudder_ncf_common_updated", "rudder_ncf_common_update_error", "rudder_ncf_common_updated_ok"),
        comment      => "Update the common Rudder ncf instance";

      "${g.rudder_ncf}/local"
        copy_from    => remote_unsecured_without_perms("${server_info.cfserved}", "${g.rudder_ncf_origin_local}"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        perms        => u_mog("644", "root", "0"),
        action       => immediate,
        classes      => success("rudder_ncf_local_updated", "rudder_ncf_local_update_error", "rudder_ncf_local_updated_ok"),
        comment      => "Update the local Rudder ncf instance";

      "${client_inputs}/${file_to_check_update}"
        copy_from    => remote("${server_info.cfserved}","${server_inputs}/${file_to_check_update}"),
        action       => immediate,
        classes      => success("rudder_promises_generated_repaired", "rudder_promises_generated_error", "rudder_promises_generated_ok");

    # The defined class are persistent, so if they are already set, promises has already been updated
    # a short while ago
    rudder_promises_generated_repaired.!root_server:: 
      "${client_inputs}"
        copy_from    => remote("${server_info.cfserved}","${server_inputs}"),
        depth_search => recurse("inf"),
        action       => immediate,
        classes      => success("config", "no_update", "config_ok");

    # If the file to check if update are available was updated, but the promises files failed to copy correctly, we must force a new copy of the promises at next run
    rudder_promises_generated_repaired.!root_server.no_update::
      "${client_inputs}/${file_to_check_update}"
        delete  => tidy,
        comment => "Deleting ${file_to_check_update} as the policy files couldn't be downloaded";

    root_server|(rudder_promises_generated_ok|(rudder_promises_generated_repaired.(config|config_ok)).!no_update.!rudder_promises_generated_error)::
      # Every time we check update inputs successfully (already up to date or
      # updated), touch a file to let other promises know we are doing ok
      "${sys.workdir}/last_successful_inputs_update"
        touch      => "true";

    # Copy the tools only if the file rudder_tools_updated is not up to date
    any::
      "${g.rudder_tools_updated}"
        copy_from    => remote_unsecured("${server_info.cfserved}", "${g.rudder_tools_updated_origin}"),
        action       => immediate,
        classes      => success("rudder_tools_updated_repaired", "rudder_tools_updated_error", "rudder_tools_updated_kept"),
        comment      => "Check if we need to update the tools";

    # We copy only if we have the class rudder_tools_updated_repaired
    rudder_tools_updated_repaired::
      "${g.rudder_tools}"
        copy_from    => remote_unsecured("${server_info.cfserved}", "${g.rudder_tools_origin}"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        action       => immediate,
        classes      => success("rudder_tools_updated", "rudder_tools_update_error", "rudder_tools_updated_ok"),
        comment      => "Update the Rudder tools";

    # If we couldn't update the tools, then we must force a copy at next run
    rudder_tools_update_error::
      "${g.rudder_tools_updated}"
        delete => tidy,
        comment => "Deleting ${g.rudder_tools_updated} as the tools couldn't be updated";

  methods:
    pass3.server_ok::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Started the server (cf-serverd)");
    pass3.executor_ok::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Started the scheduler (cf-execd)");

  processes:
    config.!windows::
      "cf-serverd" restart_class => "start_server";

    config.!windows::
      "cf-execd"   restart_class => "start_exec";

&if(NOVA)&
  services:
    windows::
      "CfengineNovaExec"
        service_policy => "start",
        service_method => u_bootstart,
        classes        => outcome("executor"),
        comment        => "Start the executor windows service now and at boot time";
&endif&

  commands:
    start_exec.(!windows|cygwin)::
      "${sys.cf_execd}"
        action  => u_ifwin_bg,
        classes => outcome("executor");

    start_server::
      "${sys.cf_serverd}"
        action  => u_ifwin_bg,
        classes => outcome("server");

#########################################################
}

# This bundle is responsible for the reporting of what happened in the update
# It can work because the classes defined during the update are persistent, so
# the classes are available for the next 4 minutes
bundle agent update_reports
{
  methods:
    no_update::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Update", "None", "Cannot update node's policy (CFEngine promises)");

    rudder_tools_update_error::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Update", "None", "Cannot update Rudder tools");

    rudder_ncf_common_update_error::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Update", "None", "Cannot update common Rudder ncf instance");

    rudder_ncf_local_update_error::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Update", "None", "Cannot update local Rudder ncf instance");

    rudder_promises_generated_error::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Update", "None", "Cannot update node's policy");

    (rudder_promises_generated_ok|(rudder_tools_updated_ok.rudder_ncf_common_updated_ok.rudder_ncf_local_updated_ok.config_ok)).!(rudder_promises_generated_repaired|rudder_promises_generated_error|rudder_tools_updated|rudder_tools_update_error|rudder_ncf_common_updated|rudder_ncf_common_update_error|rudder_ncf_local_updated|rudder_ncf_local_update_error|config|no_update)::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Update", "None", "Rudder policy, tools and ncf instance are already up to date. No action required.");

    rudder_tools_updated::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Rudder tools updated");

    rudder_ncf_common_updated::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Rudder ncf common instance updated");

    rudder_ncf_local_updated::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Rudder ncf local instance updated");

    config::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Update", "None", "Node's policy (CFEngine promises) updated");

    rudder_promises_generated_repaired|config|rudder_tools_updated|rudder_ncf_common_updated|rudder_ncf_local_updated|server_ok|executor_ok::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Update", "None", "Rudder policy, tools or ncf instance were updated or CFEngine service restarted");

    policy_server::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Update", "None", "Rudder policy server doesn't need to be updated");

}


############################################
body classes outcome(x)
{
        promise_repaired => {"${x}_ok"};
}
############################################
body classes success(if, else, kept)
{
        promise_kept     => { "${kept}" };
        promise_repaired => { "${if}" };
        repair_failed    => { "${else}" };
        repair_denied    => { "${else}" };
        repair_timeout   => { "${else}" };

        cancel_kept      => { "${else}" };
        cancel_repaired  => { "${else}" };

        # persist for 4 minutes so that it wont overlap with the next
        # execution in 5 minutes
        persist_time     => "4"; 
}

############################################
body action u_ifwin_bg
{
    windows::
        background => "true";
}

&if(NOVA)&
body service_method u_bootstart
{
        service_autostart_policy => "boot_time";
}
&endif&

body perms u_mog(mode,user,group)
{
owners => { "${user}" };
groups => { "${group}" };
mode   => "${mode}";
}
