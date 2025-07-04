# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

#
# Define what an agent has to do when it updates
# its promises
#

bundle common rudder_update_conf
{
  vars:
      "policy_server_hash_file" string => "${sys.workdir}/ppkeys/policy_server_hash";
    have_policy_server_hash::
      "policy_server_hash" string => readfile("${policy_server_hash_file}");

  classes:
      "have_policy_server_hash" expression => fileexists("${policy_server_hash_file}");
    have_policy_server_hash::
      "known_policy_server"     expression => fileexists("${sys.workdir}/ppkeys/root-${policy_server_hash}.pub"),
                                     scope => "namespace";
    !have_policy_server_hash|(have_policy_server_hash.!known_policy_server)::
      "trust_new_server"             scope => "namespace";
}

body copy_from remote(server, path)
{
        servers    => {
          "${server}"
        };
        source     => "${path}";
        compare    => "digest";
        preserve   => "false"; #do not preserve permissions
        verify     => "true";
        purge      => "true";
        copy_backup => "false";
        portnumber => "${system_common.community_port}";

&if(INITIAL)&
      trust_new_server.!root_server::
        trustkey    => "true";
&endif&

}

# Same as remote above, but don't fail on missing target
body copy_from try_remote(server, path)
{
        servers    => {
          "${server}"
        };
        source     => "${path}";
        compare    => "digest";
        preserve   => "false"; #do not preserve permissions
        verify     => "true";
        purge      => "true";
        copy_backup => "false";
        portnumber => "${system_common.community_port}";
        missing_ok => "true";

&if(INITIAL)&
      trust_new_server.!root_server::
        trustkey    => "true";
&endif&

}

# Local copy
body copy_from copy_digest_without_perms(from)
{
        source      => "${from}";
        copy_backup => "false";
        preserve    => "false";
        compare     => "digest";
        purge       => "true";
        portnumber  => "${system_common.community_port}";
}

bundle common server_info
{
  vars:
      "policy_files" string => "/var/rudder/share/${g.uuid}";   #directory where to look for promises in the server for that client

      "policy_server_file"
        string  => translatepath("${sys.workdir}/policy_server.dat"),
        comment => "Path to file containing address to policy server";

    #This part work, because for some reason, the evaluation converge in one pass, and allows to have
    # the correct value in policy_server value. In verbose output, policy_server_file_exists is defined first
    policy_server_file_exists::
      "policy_server_temp"   string => readfile("${policy_server_file}", 2048);
      # trim space in policy_server.dat
      "policy_server_temp2"  string => regex_replace("${policy_server_temp}", " ", "", "g");
      # separate host and port
      "policy_server_temp3"  slist  => string_split("${policy_server_temp2}", ":", "2");
      "policy_server"        string => nth("policy_server_temp3", "0");
    # pass3 is needed otherwise system_common.community_port is evaluated during pass2 where policy_server_has_port is always false
    server_info_pass3.policy_server_has_port::
      "policy_server_port"   string => nth("policy_server_temp3", "1");
    server_info_pass3.!policy_server_has_port::
      "policy_server_port"   string => "${system_common.cf_serverd_port}";


    !policy_server_file_exists::
      # Use "" as default policy_server if no policy_server.dat exists
      "policy_server" string => "";

    # For compatibility
    any::
      "cfserved"      string => "${policy_server}";

  classes:
      "policy_server_file_exists" expression => fileexists("${policy_server_file}");
      "policy_server_has_port"    expression => strcmp(length("policy_server_temp3"), "2");
      "server_info_pass3" expression => "server_info_pass2";
      "server_info_pass2" expression => "any";
}

# The update is now split in two parts
# - the action part, only launched during failsafe
#   it copies files, restarts daemons, defines persistent classes
# - the report part, not done during failsafe but during regular run
#   see update_reports in promises.st
#
# Since the defined class are persistent, the classes are still
# available during the "normal" agent execution, for reporting
bundle agent update_action
{
  vars:
      "client_inputs"        string => "${sys.workdir}/inputs";  #where to put the files on the client when downloaded

       # The check is in two phase:
       # First copy rudder_promises_timestamp_tmp from the policy server, and check if it's newer
       # (based on the timestamp written in it) than rudder_promises_timestamp.
       # If so, copy all the promises
       "rudder_promises_timestamp"     string => "rudder-promises-generated";
       "rudder_promises_timestamp_tmp" string => "rudder-promises-generated.tmp";

     current_promise_timestamp_defined::
       "current_promises_timestamp" string => readfile("${client_inputs}/${rudder_promises_timestamp}", 2048);

     # File ought to be there only in second pass, but since classes are persistent, we need to
     # enforce the check on pass_2
     pass2.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired).!rudder_promises_generated_tmp_file_error::
       "target_promises_timestamp" string => readfile("${client_inputs}/${rudder_promises_timestamp_tmp}", 2048);

     any::
       "server_inputs"        string => "${server_info.policy_files}/rules/cfengine-community"; #actual directory with promises

      "classes_to_persist"   slist  => { "rudder_ncf_local_updated", "rudder_ncf_local_update_error", "rudder_ncf_local_updated_ok",
                                         "rudder_ncf_common_updated", "rudder_ncf_common_update_error", "rudder_ncf_common_updated_ok",
                                         "rudder_ncf_hash_update_repaired", "rudder_ncf_hash_update_error", "rudder_ncf_hash_update_ok",
                                         "config", "no_update", "config_ok",
                                         "rudder_promises_generated_tmp_file_repaired", "rudder_promises_generated_tmp_file_error", "rudder_promises_generated_tmp_file_kept",
                                       };

  classes:
    current_promise_timestamp_defined::
      "current_promise_timestamp_valid" expression => regcmp("[0-9]+", "${current_promises_timestamp}");

    any::
      "current_promise_timestamp_defined" expression => fileexists("${client_inputs}/${rudder_promises_timestamp}");

    # Check for the validity of the content of the files, and check if we ought to update the promises

    pass2.current_promise_timestamp_valid.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired)::
      "new_promises_available" expression => isgreaterthan("${target_promises_timestamp}", "${current_promises_timestamp}");
      "availability_checked" expression => "any";

    # always update if current promise timestamp is not valid
    pass2.!current_promise_timestamp_valid.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired)::
      "new_promises_available" expression => "any";
      "availability_checked" expression => "any";

    # We need the pass_2 otherwise CFEngine tries to be clever, defines pass_1 and go back to define all other vars, including those that
    # shouldn't yet (notably target_promises_timestamp)

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

&if(!INITIAL)&
    # establish trust for policy download
    "${rudder_update_conf.policy_server_hash_file}"
        create        => "true",
        edit_line     => u_rudder_update_lines_present("&POLICY_SERVER_KEY&"),
        edit_defaults => u_rudder_empty;
&endif&

    any::
      "${g.rudder_ncf}/."
        create  => "true",
        comment => "Make sure the ncf directory exists";

    # check if new promises are available
    # ncf_only is used to update only ncf and nothing that could be private (this can be used when an agent is not yet registered)
    !root_server.!ncf_only::
      "${client_inputs}/${rudder_promises_timestamp_tmp}"
        copy_from         => remote("${server_info.policy_server}","${server_inputs}/${rudder_promises_timestamp}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_promises_generated_tmp_file_repaired", "rudder_promises_generated_tmp_file_error", "rudder_promises_generated_tmp_file_kept");

    # The defined class are persistent, so if they are already set, promises has already been updated a short while ago
    new_promises_available.!root_server.!ncf_only::
      "${client_inputs}"
        copy_from         => remote("${server_info.policy_server}","${server_inputs}"),
        depth_search      => recurse("inf"),
        action            => immediate,
        move_obstructions => "true",
        file_select       => exclude("${rudder_promises_timestamp_tmp}"),
        classes           => success("config", "no_update", "config_ok");


    root_server::
      "${g.rudder_ncf}/common"
        copy_from         => copy_digest_without_perms("${g.rudder_ncf_origin_common}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("644", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_common_updated", "rudder_ncf_common_update_error", "rudder_ncf_common_updated_ok"),
        comment           => "Update the common Rudder ncf instance";

      "${g.rudder_ncf}/local"
        copy_from         => copy_digest_without_perms("${g.rudder_ncf_origin_local}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("600", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_local_updated", "rudder_ncf_local_update_error", "rudder_ncf_local_updated_ok"),
        comment           => "Update the local Rudder ncf instance";

    # do not copy potentially incompatible ncf if inputs are not up to date
    !root_server.(availability_checked.!no_update)::
      # Check if the hashes of ncf changed
      "${g.rudder_ncf}/common/${g.rudder_ncf_hash_file}"
        copy_from         => remote("${server_info.policy_server}","${g.rudder_ncf_origin_common_hash}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_hash_update_repaired", "rudder_ncf_hash_update_error", "rudder_ncf_hash_update_ok");

      "${g.rudder_ncf}/local/${g.rudder_ncf_hash_file}"
        copy_from         => remote("${server_info.policy_server}","${g.rudder_ncf_origin_local_hash}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_hash_update_repaired", "rudder_ncf_hash_update_error", "rudder_ncf_hash_update_ok");

    # We copy ncf on non root server if ncf hash file changed, or if  promises have been updated
    !root_server.(new_promises_available|rudder_ncf_hash_update_repaired)::
      "${g.rudder_ncf}/common"
        copy_from         => remote("${server_info.policy_server}", "${g.rudder_ncf_origin_common}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("644", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_common_updated", "rudder_ncf_common_update_error", "rudder_ncf_common_updated_ok"),
        comment           => "Update the common Rudder ncf instance";

      "${g.rudder_ncf}/local"
        copy_from         => remote("${server_info.policy_server}", "${g.rudder_ncf_origin_local}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("600", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => success("rudder_ncf_local_updated", "rudder_ncf_local_update_error", "rudder_ncf_local_updated_ok"),
        comment           => "Update the local Rudder ncf instance";

    # If the file to check if update are available was updated, but the promises files failed to copy correctly, we must force a new copy of the promises at next run
    new_promises_available.!root_server.no_update.!ncf_only::
      "${client_inputs}/${rudder_promises_timestamp}"
        delete  => tidy,
        comment => "Deleting ${rudder_promises_timestamp} as the policy files couldn't be downloaded";

    (new_promises_available|rudder_ncf_hash_update_repaired).!root_server.rudder_ncf_common_update_error::
      "${g.rudder_ncf}/common/${g.rudder_ncf_hash_file}"
        delete  => tidy,
        comment => "Deleting ${g.rudder_ncf_hash_file} as common ncf files couldn't be downloaded";

    (new_promises_available|rudder_ncf_hash_update_repaired).!root_server.rudder_ncf_local_update_error::
      "${g.rudder_ncf}/local/${g.rudder_ncf_hash_file}"
        delete  => tidy,
        comment => "Deleting ${g.rudder_ncf_hash_file} as custom ncf files couldn't be downloaded";

    root_server|(rudder_promises_generated_tmp_file_kept|(new_promises_available.(config|config_ok)).!no_update.!rudder_promises_generated_tmp_file_error).!ncf_only::
      # Every time we check update inputs successfully (already up to date or
      # updated), touch a file to let other promises know we are doing ok
      "${sys.workdir}/last_successful_inputs_update"
        touch      => "true";

  reports:
    # We want to have always reports if something goes bad
    rudder_ncf_hash_update_error::
      "******************************************************************************
* rudder-agent could not get an updated configuration from the policy server.   *
* This can be caused by:                                                        *
*   * a networking issue                                                        *
*   * an unavailable server                                                     *
*   * the node changed policy server without running                            *
*     'rudder agent server-keys-reset'                                          *
*   * if the node's IP is not in the allowed networks of its policy server.     *
* Any existing configuration policy will continue to be applied without change. *
*********************************************************************************"
      action => immediate;

     !rudder_ncf_hash_update_error.(rudder_promises_generated_error|no_update|rudder_promises_generated_tmp_file_error).!ncf_only::
&if(INITIAL)&
        "*********************************************************************************
  *  You must accept this node on the server before updating this node            *
  *  This node uses initial policies, some error message are expected until       *
  *  the node is accepted.                                                        *
  *********************************************************************************"
&endif&

&if(!INITIAL)&
       "******************************************************************************
* rudder-agent could not get an updated configuration from the policy server.   *
* This can be caused by:                                                        *
*   * an agent key that has been changed                                        *
*   * if this node is not accepted or deleted node on the Rudder root server    *
*   * if this node has changed policy server without sending a new inventory    *
* Any existing configuration policy will continue to be applied without change. *
*********************************************************************************"
&endif&

      action => immediate;
}

# Only persist classes once as it is a very expensive operation now.
# Done outside of update_action as some actions are done in files promises during last pass.
bundle agent rudder_persist_update_classes {
  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    pass3::
      "p_${update_action.classes_to_persist}" expression => "${update_action.classes_to_persist}",
                                           # persist for 4 minutes so that it wont overlap with the next
                                           # execution in 5 minutes
                                           persistence => "4",
                                                 scope => "namespace";
}

#######################################################
# UUID file checking

bundle agent check_uuid
{
  classes:
      # Abort if no uuid is defined
      "should_not_continue" expression => "wrong_uuid|no_uuid";
      "no_uuid" not => fileexists("${g.uuid_file}");
    !initial_promises.!no_uuid::
      "wrong_uuid" not => strcmp("${system_common.uuid}", "${g.uuid}");

  reports:
    initial_promises.wrong_uuid::
      "FATAL: The UUID in ${g.uuid_file} (${g.uuid}) doesn't match the UUID recorded for this node in your Rudder server (${system_common.uuid})";

    no_uuid::
      "FATAL: The UUID file ${g.uuid_file} is missing. Please run 'rudder agent check' to generate a new one or restore it from a backup.";
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
}

body perms u_mog(mode,user,group)
{
  mode   => "${mode}";
  owners => { "${user}" };
  groups => { "${group}" };
  rxdirs => "true";
}


bundle edit_line u_rudder_update_lines_present(lines)
{
  insert_lines:
      "${lines}";
}

body edit_defaults u_rudder_empty
{
      empty_file_before_editing => "true";
      edit_backup => "false";
}
