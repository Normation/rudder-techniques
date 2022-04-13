# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Warning: The content of this technique is very close to the content of the package_state() bundle in ncf
# particularly the log message building. All changes made here should also be done in ncf too.

#                     |
#   --------------------------------------------------------------------------------------
#   | !update                          | update.must_run_system_update                   | update.!must_run_system_update
#   NA (disabled)                      |                                                 |
#                               command_execution_once                    -----------------------------
#                                                                         | !flag_set                  | flag_set
#                                                                         NA (not yet applied)         NA (already patched)

bundle agent rudder_system_update {
  vars:
      "args"                      slist => { };
      "update"                   string => "&ENABLE_UPDATE&";
      "campaign_name"            string => "&CAMPAIGN_NAME&";
      "reboot"                   string => "&REBOOT&";
      "minutes_splay"            string => "&MINUTES_SPLAY&";
      "hours_splay"              string => "&HOURS_SPLAY&";
      "start_on_minutes"         string => "&START_ON_MINUTES&";
      "start_on_hours"           string => "&START_ON_HOURS&";
      "start_on_days_of_week"    string => "&START_ON_DAYS&";

      "must_run_system_update"   string => canonify("job_${campaign_name}_run");
      "canonified_campaign_name" string => canonify("${campaign_name}");

      "variable_reporting"       string => "Identifying the package manager.",
                                     if => not(or("use_yum_provider", "user_apt_provider", "user_zypper_provider"));
      "variable_reporting"       string => "Unsupported OS for the system update, identifying the package manager.",
                                     if => or("use_yum_provider", "user_apt_provider", "user_zypper_provider");

    use_yum_provider::
      "update_command"           string => "yum -y update";
    user_apt_provider::
      "update_command"           string => "export DEBIAN_FRONTEND=noninteractive \&\& apt-get update \&\& apt-get -y upgrade";
    use_zypper_provider::
      "update_command"           string => "zypper refresh \&\& zypper --non-interactive update";

    pass2::
      "na_message"               string => "System update already done for the campaign '${campaign_name}'. It",
                                     if => "flag_set";
      "na_message"               string => "System update scheduled for the campaign '${campaign_name}'. It is not ready yet. It",
                                     if => "!flag_set";

  classes:
    "pass3"    expression => "pass2";
    "pass2"    expression => "pass1";
    "pass1"    expression => "any";
    "update"   expression => strcmp("${update}", "enabled");
    "reboot"   expression => strcmp("${reboot}", "enabled");
    "use_zypper_provider" expression => strcmp("zypper", "${package_module_knowledge.platform_default}");
    "use_apt_provider"    expression => strcmp("apt",    "${package_module_knowledge.platform_default}");
    "use_yum_provider"    expression => strcmp("yum",    "${package_module_knowledge.platform_default}");


   pass2::
    "flag_set" expression => strcmp("${is_set[1]}", "set");

  methods:
    any::
      "Already done"         usebundle => get_flag(canonify("command_execution_once_${campaign_name}")),
                             useresult => "is_set";
      # Define a splaytime class
      "Schedule the update if needed" usebundle => schedule_simple_generic( "${canonified_campaign_name}",
                                                                            "&AGENT_RUN_INTERVAL&",
                                                                            "${minutes_splay}",
                                                                            "${hours_splay}",
                                                                            "${start_on_minutes}",
                                                                            "${start_on_hours}",
                                                                            "${start_on_days_of_week}",
                                                                            "0", # periodicity minutes
                                                                            "0", # periodicity hours
                                                                            "1", # periodicity days
                                                                            "stateless"
                                                                          );

      # Pre-Update
      "Setup variable context" usebundle => _method_reporting_context_v4("Setup variable context", "Setup variable context", "Setup variable context");
      "Unsupported OS"         usebundle => report_if_condition("variable_reporting", "use_yum_provider|user_apt_provider|user_zypper_provider");

    pass3::
      # Update
      "Update the system"     usebundle => _method_reporting_context_v4("Update the system", "Update the system", "Update the system");
      "Update the system"     usebundle => command_execution_once("${update_command}", "0", "any", "${campaign_name}"),
                                     if => and("update", "${must_run_system_update}", "!flag_set");

      "NA report by conf"     usebundle => log_na_rudder( "An update is needed but the update step is disabled by the directive configuration",
                                                          "Update the system",
                                                          "rudder_system_update_reboot",
                                                          @{args}
                                                        ),
                                    if  => not("update");
      "NA report by schedule" usebundle => log_na_rudder( "${na_message}",
                                                          "Update the system",
                                                          "rudder_system_update_reboot",
                                                          @{args}
                                                        ),
                                     if => or( and("update", not("${must_run_system_update}")),
                                               and("update",
                                                   "${must_run_system_update}",
                                                   "flag_set",
                                                   not(canonify("command_execution_once_${update_command}_reached")))
                                             );

      # Post update
      "Post update"           usebundle => _method_reporting_context_v4("Post update", "Post update","Post update");
      "Post update inventory" usebundle => rudder_inventory_trigger("post_update_inventory"),
                                     if => concat("command_execution_once_",canonify("${update_command}"),"_repaired");
      "Post update reboot"    usebundle => command_execution_once("reboot", "0", "any", "${campaign_name}_reboot"),
                                     if => and(concat("command_execution_once_",canonify("${update_command}"), "_repaired"),
                                            "reboot"
                                           );
      "NA report"             usebundle => log_na_rudder( "No reboot needed, method",
                                                          "Post update",
                                                          "rudder_system_update_reboot",
                                                          @{args}
                                                        ),
                                     if => not(and(concat("command_execution_once_",canonify("${update_command}"), "_repaired"),
                                                   "reboot"
                                              ));
}&
