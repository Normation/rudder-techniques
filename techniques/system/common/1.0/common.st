# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Common variable for common system technique
bundle common system_common {
  vars:
    "directiveId"           string => "&TRACKINGKEY&";
    "sharedfiles_folder"    string => "${g.shared_files}";
    "cf_serverd_port"       string => "&COMMUNITYPORT&";
    "community_port"        string => "${server_info.policy_server_port}";
    "uuid"                  string => "&UUID&";
    "davuser"               string => "&DAVUSER&";
    "davpw"                 string => "&DAVPASSWORD&";
    "rudder_configuration_repository"
                            string => "&CONFIGURATION_REPOSITORY_FOLDER&";
    "rudder_node_config_id" string => "&RUDDER_NODE_CONFIG_ID&";
    "agent_run_interval"    string => "&AGENT_RUN_INTERVAL&";

    "cf_serverd_service_name" string => "rudder-cf-serverd";

    pass3.executor::
      # first line is the data used to create splay hash
      # +0 is the uid of the user we use to run (root)
      # Other lines are used to compute real splay time
      "executor_data"       string => execresult("printf '${sys.fqhost}+${sys.ipv4}+0\n${sys.systime}\n&AGENT_RUN_SPLAYTIME&\n${agent_run_interval}\n' > /var/rudder/tmp/cf-execd.data ", "useshell");

  classes:
&if(INITIAL)&
    "initial_promises" expression => "any", scope => "namespace";
&endif&

    "pass3" expression => "pass2";
    "pass2" expression => "any";

}
