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

bundle common server_info
{
  vars:
    any::
      "policy_files" string => "/var/rudder/share/&UUID&";   #directory where to look for promises in the server for that client

    policy_server::
      "cfserved"     string => "&POLICYSERVER&";

    !policy_server::
      "policy_server_file"
        string  => translatepath("${sys.workdir}/policy_server.dat"),
        comment => "Path to file containing address to policy server";
      "cfserved"     string =>  readfile("${policy_server_file}", 2048);
}

bundle agent update
{
  vars:
      "client_inputs"        string => "${sys.workdir}/inputs";  #where to put the files on the client when downloaded
      "file_to_check_update" string => "rudder_promises_generated";
    nova_edition::
      "server_inputs"        string => "${server_info.policy_files}/rules/cfengine-nova"; #actual directory with promises
    community_edition::
      "server_inputs"        string => "${server_info.policy_files}/rules/cfengine-community"; #actual directory with promises


  files:
    !root_server::
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

    root_server|(rudder_promises_generated_ok|(rudder_promises_generated_repaired.(config|config_ok)).!no_update.!rudder_promises_generated_error)::
      # Every time we check update inputs successfully (already up to date or
      # updated), touch a file to let other promises know we are doing ok
      "${sys.workdir}/last_successful_inputs_update"
        touch      => "true";

    # same here, if the dependencies have been updated, we can skup this part 
    rudder_promises_generated_repaired.(!windows|cygwin).!rudder_dependencies_updated.!rudder_dependencies_updated_ok::
      "${g.rudder_dependencies}"
        copy_from    => remote_unsecured("${server_info.cfserved}", "${g.rudder_dependencies_origin}"),
        #depth_search => recurse("inf"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        action       => immediate,
        classes      => success("rudder_dependencies_updated", "rudder_dependencies_update_error", "rudder_dependencies_updated_ok");

    rudder_promises_generated_repaired.(windows.!cygwin).!rudder_dependencies_updated.!rudder_dependencies_updated_ok::
      "${g.rudder_sbin}"
        copy_from    => remote_unsecured("${server_info.cfserved}", "${g.rudder_dependencies_origin}"),
        #depth_search => recurse("inf"),
        depth_search => recurse_ignore("inf", @{g.excludedreps}),
        action       => immediate,
        classes      => success("rudder_dependencies_updated", "rudder_dependencies_update_error", "rudder_dependencies_updated_ok");


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
    start_exec.!windows::
      "${sys.cf_execd}"
        action  => u_ifwin_bg,
        classes => outcome("executor");

    start_exec.cygwin::
      "${sys.cf_execd}"
        action  => u_ifwin_bg,
        classes => outcome("executor");

    start_server::
      "${sys.cf_serverd}"
        action  => u_ifwin_bg,
        classes => outcome("server");

#########################################################
  reports:
    # The use of the failsafe class here is to prevent the failsafe to do reports
    # (except in verbose mode) as it may prevent the normal execution to report due to lock
    server_ok::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Started the server (cf-serverd)";
    executor_ok::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Started the scheduler (cf-execd)";

    (!failsafe|verbose_mode).no_update::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Cannot update node's policy (CFEngine promises)";

    (!failsafe|verbose_mode).rudder_dependencies_update_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Cannot update dependencies";

    (!failsafe|verbose_mode).rudder_promises_generated_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Cannot update node's policy or dependencies";

    (!failsafe|verbose_mode).((rudder_promises_generated_ok|(rudder_dependencies_updated_ok.config_ok)).!(rudder_promises_generated_repaired|rudder_promises_generated_error|rudder_dependencies_updated|rudder_dependencies_update_error|config|no_update))::
      "@@Common@@result_success@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Policy and dependencies already up to date. No action required.";

    (!failsafe|verbose_mode).rudder_dependencies_updated::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Dependencies updated";

    (!failsafe|verbose_mode).config::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Node's policy (CFEngine promises) updated";

    (!failsafe|verbose_mode).(rudder_promises_generated_repaired|config|rudder_dependencies_updated|server_ok|executor_ok)::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Policy or dependencies were updated or CFEngine service restarted";

    (!failsafe|verbose_mode).policy_server::
      "@@Common@@result_success@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Policy server doesn't need to be updated";


    (!failsafe|verbose_mode).(rudder_promises_generated_error|no_update)::
				"*********************************************************************************
* rudder-agent could not get an updated configuration from the policy server.   *
* This can be caused by a network issue, an unavailable server, or if this      *
* node was deleted from the Rudder root server.                                 *
* Any existing configuration policy will continue to be applied without change. *
*********************************************************************************";
}


############################################
body classes outcome(x)
{
        promise_repaired => {"${x}_ok"};
}
############################################
body action u_background
{
        background => "true";
}
############################################
body classes success(if, else, kept)
{
        promise_kept     => { "${kept}" };
        promise_repaired => { "${if}" };
        repair_failed    => { "${else}" };
        repair_denied    => { "${else}" };
        repair_timeout   => { "${else}" };

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
