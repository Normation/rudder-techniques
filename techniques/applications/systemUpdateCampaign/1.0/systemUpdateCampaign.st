# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2022 Normation SAS

bundle agent rudder_system_update_campaign_&RudderUniqueID& {
  vars:
      "enabled"                string => "&ENABLE_UPDATE&";
      "campaign_name"          string => "&CAMPAIGN_NAME&";
      "reboot"                 string => "&REBOOT&";
      "start"                  string => "&START&";
      "end"                    string => "&END&";
      "campaign_id"            string => canonify("${campaign_name}");
      "status_prefix"          string => "rudder_system_update_campaign";
      "reboot_opt"             string => "";
      "report_data.identifier" string => "0";

    pass1::
      "reboot_opt"    string => "--reboot",
                          if => "reboot";

    pass2::
      # We can't pass JSON content as module output as if can exceed the size limit
      # So we read it from file instead.
      "report"        string => readfile("${rudder_system_update_module.system_update_report}", "0"),
                          if => "${status_prefix}_report";

  classes:
      "has_py"    or => { returnszero("command -v python > /dev/null", "useshell"),
                          returnszero("command -v python2 > /dev/null", "useshell"),
                          returnszero("command -v python3 > /dev/null", "useshell") };
      "enabled"   expression => strcmp("${enabled}", "enabled");
      "reboot"    expression => strcmp("${reboot}", "enabled");

      "output"    and => { isvariable("rudder_system_update_module.system_update_message"),
                           isvariable("rudder_system_update_module.system_update_outcome") };

      "pass3"     expression => "pass2";
      "pass2"     expression => "pass1";
      "pass1"     expression => "any";

    pass2::
      "call"      expression => usemodule("system_update.py", "--package_manager=${package_module_knowledge.platform_default} --campaign_id=${campaign_name} --start=${start} --end=${end} --node_id=${g.uuid} --agent_schedule=${g.agent_run_interval} ${reboot_opt}"),
                          if => "enabled.has_py";

  methods:
    pass1::
      # Copy module script with ncf helper
      "module"     usebundle => additional_modules("${this.promise_dirname}/modules/");
      #
      # Module returns:
      #
      # * A `${status_prefix}_report` class if a report is done
      # * A `system_update_message` variable for user reporting
      # * A `system_update_report` variable for json report (if needed). It contains the path of
      #   the json report file.

    pass3::
      "context"    usebundle => _method_reporting_context_v4("System update", "None", "system-update");
      "json"       usebundle => rudder_common_report("system-update","report_json", "&TRACKINGKEY&", "campaign-system-update", "${campaign_name}", "${report}"),
                          if => "${status_prefix}_report";
      "inventory"  usebundle => rudder_inventory_trigger("post_update_inventory_${campaign_id}"),
                          if => "${status_prefix}_report";
      "report"     usebundle => _rudder_report_state("system-update", "${rudder_system_update_module.system_update_message}", "${rudder_system_update_module.system_update_outcome}"),
                          if => "has_py.enabled.output";
      "report"     usebundle => _rudder_report_state("system-update", "Broken system update module output", "result_error"),
                          if => "has_py.enabled.!output";
      "report"     usebundle => _rudder_report_state("system-update", "Missing python on the system, it is required for system update", "result_error"),
                      unless => "has_py";
      "report"     usebundle => _rudder_report_state("system-update", "Campaign is disabled", "result_na"),
                      unless => "enabled";
}
