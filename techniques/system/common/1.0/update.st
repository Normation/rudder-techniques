# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021-2025 Normation SAS

# Policy updates using CFEngine's file copy protocol.
#
# We have three sources copied from the policy server:
#
# * the node's policies
# * the policies library, a.k.a. "ncf"
#   * common directory, containing the policies distributed with Rudder
#   * local directory, containing instance-specific files
#
# The update is split in two parts
# - the action part, only launched during failsafe
#   it copies files, restarts daemons, defines persistent classes
# - the report part, not done during failsafe but during regular run
#   see update_reports in promises.st
#
# Since the defined class are persistent, the classes are still
# available during the "normal" agent execution, for reporting

bundle common u_server_validation {
  vars:
      "policy_server_hash_file"     string => "${sys.workdir}/ppkeys/policy_server_hash";
    have_policy_server_hash::
      "policy_server_hash"          string => readfile("${policy_server_hash_file}");

  classes:
      "have_policy_server_hash" expression => fileexists("${policy_server_hash_file}");
    have_policy_server_hash::
      "known_policy_server"     expression => fileexists("${sys.workdir}/ppkeys/root-${policy_server_hash}.pub"),
                                     scope => "namespace";
    !have_policy_server_hash|(have_policy_server_hash.!known_policy_server)::
      "trust_new_server"             scope => "namespace";
}

bundle common server_info {
  vars:
      "local_inputs"          string => "${sys.workdir}/inputs";
      "remote_inputs"         string => "/var/rudder/share/${g.uuid}/rules/cfengine-community";

      "policy_server_file"    string => "${sys.workdir}/policy_server.dat";

    policy_server_file_exists::
      "policy_server_raw"     string => readfile("${policy_server_file}", 2048);
      "policy_server_trimmed" string => regex_replace("${policy_server_raw}", " ", "", "g");
      # We expect "host" or "host:port"
      "policy_server_split"   slist  => string_split("${policy_server_trimmed}", ":", "2");
      "policy_server"         string => nth("policy_server_split", "0");

      "policy_server_port"    string => "${system_common.cf_serverd_port}";
      "policy_server_port"    string => nth("policy_server_split", "1"),
                                  if => "policy_server_has_port";

    !policy_server_file_exists::
      # Use "" as default policy_server if no policy_server.dat exists
      "policy_server"         string => "";

  classes:
      "policy_server_file_exists" expression => fileexists("${policy_server_file}");
      "policy_server_has_port"    expression => strcmp(length("policy_server_split"), "2");
}

bundle agent update_action {
  methods:
      "any" usebundle => u_prepare;

      "any" usebundle => u_check_inputs;
      "any" usebundle => u_check_ncf;

    !root_server::
      "any" usebundle => u_download_inputs,
                   if => "new_promises_available";
      "any" usebundle => u_download_ncf,
                   if => "new_promises_available|rudder_ncf_hash_update_repaired";

    root_server::
      "any" usebundle => u_root_copy_ncf;

  reports:
     !rudder_ncf_hash_update_error.(rudder_promises_generated_error|no_update|rudder_promises_generated_tmp_file_error)::
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

bundle agent u_prepare {
  files:
      "${g.rudder_ncf}/." create => "true";

&if(!INITIAL)&
      # establish trust for policy download
      "${u_server_validation.policy_server_hash_file}"
        create        => "true",
        edit_line     => u_rudder_update_lines_present("&POLICY_SERVER_KEY&"),
        edit_defaults => u_rudder_empty;
&endif&
}

# The check is in two phase:
# First copy rudder_promises_timestamp_tmp from the policy server, and check if it's newer
# (based on the timestamp written in it) than rudder_promises_timestamp.
# If so, copy all the promises

bundle agent u_check_inputs {
  vars:
      "rudder_promises_timestamp"     string => "rudder-promises-generated";
      "rudder_promises_timestamp_tmp" string => "rudder-promises-generated.tmp";

    current_promise_timestamp_defined::
      "current_promises_timestamp" string => readfile("${client_inputs}/${rudder_promises_timestamp}", 2048);

    # File ought to be there only in second pass, but since classes are persistent, we need to
    # enforce the check on pass_2
    pass2.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired).!rudder_promises_generated_tmp_file_error::
      "target_promises_timestamp" string => readfile("${client_inputs}/${rudder_promises_timestamp_tmp}", 2048);

  classes:
    current_promise_timestamp_defined::
      "current_promise_timestamp_valid"   expression => regcmp("[0-9]+", "${current_promises_timestamp}");

    any::
      "current_promise_timestamp_defined" expression => fileexists("${client_inputs}/${rudder_promises_timestamp}");

    # Check for the validity of the content of the files, and check if we ought to update the promises

    pass2.current_promise_timestamp_valid.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired)::
      "new_promises_available" not => strcmp("${target_promises_timestamp}", "${current_promises_timestamp}");
      "availability_checked";

    # Always update if current promise timestamp is not valid
    pass2.!current_promise_timestamp_valid.(rudder_promises_generated_tmp_file_kept|rudder_promises_generated_tmp_file_repaired)::
      "new_promises_available";
      "availability_checked";

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    # check if new promises are available
    !root_server::
      "${server_info.local_inputs}/${rudder_promises_timestamp_tmp}"
        copy_from         => u_copy_remote("${server_info.policy_server}","${server_info.remote_inputs}/${rudder_promises_timestamp}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_promises_generated_tmp_file");

    root_server|(rudder_promises_generated_tmp_file_kept|(new_promises_available.(config|config_ok)).!no_update.!rudder_promises_generated_tmp_file_error)::
      # Every time we check update inputs successfully (already up to date or
      # updated), touch a file to let other promises know we are doing ok
      "${sys.workdir}/last_successful_inputs_update"
        touch      => "true";
}

bundle agent u_check_ncf {
  files:
    # do not copy potentially incompatible ncf if inputs are not up to date
    !root_server.(availability_checked.!rudder_policies_update_error)::
      "${g.rudder_ncf}/common/${g.rudder_ncf_hash_file}"
        copy_from         => u_copy_remote("${server_info.policy_server}","${g.rudder_ncf_origin_common_hash}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_hash_update");

      "${g.rudder_ncf}/local/${g.rudder_ncf_hash_file}"
        copy_from         => u_copy_remote("${server_info.policy_server}","${g.rudder_ncf_origin_local_hash}"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_hash_update");

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
}

bundle agent u_download_inputs {
  files:
    # The defined class are persistent, so if they are already set, promises has already been updated a short while ago

      "${client_inputs}"
        copy_from         => u_copy_remote("${server_info.policy_server}","${server_inputs}"),
        depth_search      => recurse("inf"),
        action            => immediate,
        move_obstructions => "true",
        file_select       => exclude("${u_check_inputs.rudder_promises_timestamp_tmp}"),
        classes           => u_classes_generic_persist("rudder_policies_update");

    # If the file to check if update are available was updated, but the promises files failed to copy correctly, we must force a new copy of the promises at next run
    no_update::
      "${client_inputs}/${u_check_inputs.rudder_promises_timestamp}"
        delete  => tidy,
        comment => "Deleting ${u_check_inputs.rudder_promises_timestamp} as the policy files couldn't be downloaded";
}

# Copy the file locally, on a root server
bundle agent u_root_copy_ncf {
  files:
      "${g.rudder_ncf}/common"
        copy_from         => u_copy_local("${g.rudder_ncf_origin_common}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("644", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_common");

      "${g.rudder_ncf}/local"
        copy_from         => u_copy_local("${g.rudder_ncf_origin_local}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("600", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_local");
}

# Download the files on a non-root server, if the hash file changed or if promises have been updated
bundle agent u_download_ncf {
  files:
    # We copy ncf on non root server if ncf hash file changed, or if  promises have been updated
      "${g.rudder_ncf}/common"
        copy_from         => u_copy_remote("${server_info.policy_server}", "${g.rudder_ncf_origin_common}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("644", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_common");

      "${g.rudder_ncf}/local"
        copy_from         => u_copy_remote("${server_info.policy_server}", "${g.rudder_ncf_origin_local}"),
        depth_search      => recurse_ignore("inf", @{g.ncf_excludedreps}),
        perms             => u_mog("600", "root", "0"),
        action            => immediate,
        move_obstructions => "true",
        classes           => u_classes_generic_persist("rudder_ncf_local");

    rudder_ncf_common_update_error::
      "${g.rudder_ncf}/common/${g.rudder_ncf_hash_file}"
        delete  => tidy,
        comment => "Deleting ${g.rudder_ncf_hash_file} as common ncf files couldn't be downloaded";

    rudder_ncf_local_update_error::
      "${g.rudder_ncf}/local/${g.rudder_ncf_hash_file}"
        delete  => tidy,
        comment => "Deleting ${g.rudder_ncf_hash_file} as custom ncf files couldn't be downloaded";
}

#######################################################
# Node ID check

bundle agent u_check_node_id
{
  classes:
      # Abort if no node id is defined
      "should_not_continue" expression => "wrong_id|no_id";
      "no_id" not => fileexists("${g.uuid_file}");
    !initial_promises.!no_id::
      "wrong_id" not => strcmp("${system_common.uuid}", "${g.uuid}");

  reports:
    initial_promises.wrong_id::
      "FATAL: The node ID in ${g.uuid_file} (${g.uuid}) doesn't match the ID recorded for this node in your Rudder server (${system_common.uuid})";
    no_id::
      "FATAL: The node ID file ${g.uuid_file} is missing. Please run 'rudder agent check' to generate a new one or restore it from a backup.";
}

############################################

body classes u_classes_generic_persist(x)
{
      promise_repaired => { "$(x)_repaired", "$(x)_ok",     "$(x)_reached",      "$(x)_not_kept" };
      repair_failed    => { "$(x)_failed",   "$(x)_not_ok", "$(x)_error",        "$(x)_not_kept", "$(x)_not_repaired", "$(x)_reached" };
      repair_denied    => { "$(x)_denied",   "$(x)_not_ok", "$(x)_error",        "$(x)_not_kept", "$(x)_not_repaired", "$(x)_reached" };
      repair_timeout   => { "$(x)_timeout",  "$(x)_not_ok", "$(x)_error",        "$(x)_not_kept", "$(x)_not_repaired", "$(x)_reached" };
      promise_kept     => { "$(x)_kept",     "$(x)_ok",     "$(x)_not_repaired", "$(x)_reached" };

      # persist for 4 minutes so that it wont overlap with the next
      # execution in 5 minutes
      persist_time     => "4";
}

body perms u_mog(mode,user,group) {
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
      edit_backup               => "false";
}

body copy_from u_copy_remote(server, path) {
      servers     => {
        "${server}"
      };
      source      => "${path}";
      compare     => "digest";
      preserve    => "false";
      verify      => "true";
      purge       => "true";
      copy_backup => "false";
      portnumber  => "${system_common.community_port}";
      missing_ok  => "false";

&if(INITIAL)&
    trust_new_server.!root_server::
      trustkey    => "true";
&endif&
}

body copy_from u_copy_remote_missing_ok(server, path) {
      servers     => {
        "${server}"
      };
      source      => "${path}";
      compare     => "digest";
      preserve    => "false";
      verify      => "true";
      purge       => "true";
      copy_backup => "false";
      portnumber  => "${system_common.community_port}";
      missing_ok  => "true";

&if(INITIAL)&
    trust_new_server.!root_server::
      trustkey    => "true";
&endif&
}

body copy_from u_copy_local(from) {
       source      => "${from}";
       compare     => "digest";
       preserve    => "false";
       purge       => "true";
       copy_backup => "false";
       portnumber  => "${system_common.community_port}";
}