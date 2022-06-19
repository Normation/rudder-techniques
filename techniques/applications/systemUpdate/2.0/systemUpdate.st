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

      "canonified_campaign_name" string => canonify("${campaign_name}");

    pass1::
      "variable_reporting"       string => "Identifying the package manager.",
                                     if => or("use_yum_provider", "use_apt_provider", "use_zypper_provider");
      "variable_reporting"       string => "Unsupported OS for the system update, identifying the package manager.",
                                     unless => or("use_yum_provider", "use_apt_provider", "use_zypper_provider");

      "update_command"           string => "yum -y update",
                                     if => "use_yum_provider";
      "update_command"           string => "export DEBIAN_FRONTEND=noninteractive \&\& apt-get update \&\& apt-get -y upgrade",
                                     if => "use_apt_provider";
      "update_command"           string => "zypper refresh \&\& zypper --non-interactive update",
                                     if => "use_zypper_provider";

    pass2::
      "na_message"               string => "An update is needed but the update step is disabled by the directive configuration",
                                     if => not("update");
      "na_message"               string => "System update already done for the campaign '${campaign_name}'.",
                                     if => "flag_set";
      "na_message"               string => "System update scheduled for the campaign '${campaign_name}'. It is not ready yet.",
                                     if => "!flag_set";

  classes:
      "pass3"    expression => "pass2";
      "pass2"    expression => "pass1";
      "pass1"    expression => "any";
      "update"   expression => strcmp("${update}", "true");
      "update"   expression => strcmp("${update}", "enabled");
      "reboot"   expression => strcmp("${reboot}", "true");
      "reboot"   expression => strcmp("${reboot}", "enabled");
      "use_zypper_provider" expression => strcmp("zypper" , "${package_module_knowledge.platform_default}");
      "use_apt_provider"    expression => strcmp("apt_get", "${package_module_knowledge.platform_default}");
      "use_yum_provider"    expression => strcmp("yum"    , "${package_module_knowledge.platform_default}");


    pass2::
      "flag_set" expression => strcmp("${is_set[1]}", "set");
    pass3::
      "must_run_system_update" expression => "any",
                                       if => "schedule_simple_${canonified_campaign_name}_repaired";
  methods:
    any::
      "Already done"         usebundle => get_flag(canonify("command_execution_once_${campaign_name}")),
                             useresult => "is_set";
      # Define a splaytime class
      "Schedule context" usebundle => _method_reporting_context_v4("Setup schedule", "None", "system-update");
      "disable_reporting"   usebundle => disable_reporting;
      "Schedule the update if needed" usebundle => schedule_simple( "${canonified_campaign_name}",
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
      "enable_reporting"   usebundle => enable_reporting;

      # Pre-Update
    pass2::
      "Setup variable context" usebundle => _method_reporting_context_v4("OS Support", "", "system-update");
      "Setup variable context" usebundle => _rudder_report_state("system-update", "Unsupported OS for system update", "result_error"),
                                  unless => or("use_yum_provider", "use_apt_provider", "use_zypper_provider");
    pass3::
      # Update
      "Update the system"     usebundle => _method_reporting_context_v4("Update the system", "", "system-update");
      "Update the system"     usebundle => command_execution_once("${update_command}", "0", "any", "${campaign_name}"),
                                     if => and("update", "must_run_system_update", "!flag_set");

      "NA update" usebundle => _rudder_report_state("system-update", "${na_message}", "result_na"),
                                     if => or( not("update"),
                                               and("update", not("must_run_system_update")),
                                               and("update",
                                                   "must_run_system_update",
                                                   "flag_set"
                                               )
                                           );

      # Post update
      "Post update"           usebundle => _method_reporting_context_v4("Reboot", "","system-update");
      "Post update inventory" usebundle => rudder_inventory_trigger("post_update_inventory"),
                                     if => concat("command_execution_once_",canonify("${update_command}"),"_repaired");
      "Post update reboot"    usebundle => command_execution_once("reboot", "0", "any", "${campaign_name}_reboot"),
                                     if => and(concat("command_execution_once_",canonify("${update_command}"), "_repaired"),
                                            "reboot"
                                           );
      "NA reboot" usebundle => _rudder_report_state("system-update", "No reboot needed", "result_na"),
                                     if => or (
                                             not("reboot"),
                                             not(
                                               and (
                                                 concat("command_execution_once_",canonify("${update_command}"), "_repaired"),
                                                 "reboot"
                                               )
                                             )
                                           );
}&
